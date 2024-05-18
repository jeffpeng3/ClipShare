#include "flutter_window.h"

#include <codecvt>
#include <Windows.h>

#include "clip_listener_window.h"

#include <optional>
#include <thread>
#include <.plugin_symlinks/desktop_multi_window/windows/base_flutter_window.h>
#include <flutter/encodable_value.h>

#include "flutter/standard_method_codec.h"
#include "flutter/generated_plugin_registrant.h"
#include "desktop_multi_window/desktop_multi_window_plugin.h"
#include <vector>
#include <shlobj.h>
#include <atlbase.h> // CComPtr
#include "utils.h"

boolean GetSelectedFilesFromDesktop(std::vector<std::wstring>& paths) {
	return false;
}
boolean GetSelectedFilesFromExplorer(std::vector<std::wstring>& paths)
{
	HRESULT hr;
	hr = CoInitialize(NULL);
	if (!SUCCEEDED(hr))
		return false;

	CComPtr<IShellWindows> shellWindows;
	hr = shellWindows.CoCreateInstance(CLSID_ShellWindows);
	if (!SUCCEEDED(hr))
		return false;

	long count;
	shellWindows->get_Count(&count);
	HWND foregroundWindow = GetForegroundWindow();
	//HWND handle = FindWindow(L"CabinetWClass", nullptr);
	for (long i = 0; i < count; ++i)
	{
		VARIANT index;
		index.vt = VT_I4;
		index.lVal = i;

		CComPtr<IDispatch> dispatch;
		shellWindows->Item(index, &dispatch);
		//参考：https://cloud.tencent.com/developer/ask/sof/114218481
		CComPtr<IServiceProvider> sp;
		hr = dispatch->QueryInterface(IID_IServiceProvider, (void**)&sp);
		if (!SUCCEEDED(hr))
			return false;

		CComPtr<IShellBrowser> browser;
		hr = sp->QueryService(SID_STopLevelBrowser, IID_IShellBrowser, (void**)&browser);
		if (!SUCCEEDED(hr))
			return false;

		//webBrowser用于获取shellwindow的hwnd
		CComPtr<IWebBrowserApp> webBrowser;
		hr = dispatch->QueryInterface(IID_IWebBrowserApp, (void**)&webBrowser);
		if (!SUCCEEDED(hr))
			return false;

		HWND hwnd;
		hr = webBrowser->get_HWND((SHANDLE_PTR*)&hwnd);
		if (!SUCCEEDED(hr) || foregroundWindow != hwnd) {
			//不在前台，跳过
			continue;
		}

		CComPtr<IShellView > sw;
		hr = browser->QueryActiveShellView(&sw);
		if (!SUCCEEDED(hr))
			return false;

		CComPtr<IDataObject > items;
		hr = sw->GetItemObject(SVGIO_SELECTION, IID_PPV_ARGS(&items));
		if (!SUCCEEDED(hr))
			return false;

		FORMATETC fmt = { CF_HDROP, NULL, DVASPECT_CONTENT, -1, TYMED_HGLOBAL };
		STGMEDIUM stg;
		hr = items->GetData(&fmt, &stg);
		if (!SUCCEEDED(hr))
			return false;

		HDROP hDrop = static_cast<HDROP>(GlobalLock(stg.hGlobal));
		if (hDrop != NULL) {
			UINT numPaths = DragQueryFileW(hDrop, 0xFFFFFFFF, NULL, 0);

			for (UINT j = 0; j < numPaths; ++j) {
				UINT bufferSize = DragQueryFileW(hDrop, j, NULL, 0) + 1;
				std::wstring path(bufferSize, L'\0');
				DragQueryFileW(hDrop, j, &path[0], bufferSize);
				path.resize(bufferSize - 1);
				paths.push_back(path);
			}
			GlobalUnlock(stg.hGlobal);
			ReleaseStgMedium(&stg);
		}
	}

	//// Clean up and exit
	CoUninitialize();
	return true;
}

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
	: project_(project)
{
}

FlutterWindow::~FlutterWindow()
{
}

bool FlutterWindow::OnCreate()
{
	if (!Win32Window::OnCreate())
	{
		return false;
	}

	RECT frame = GetClientArea();

	// The size here must match the window dimensions to avoid unnecessary surface
	// creation / destruction in the startup path.
	flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
		frame.right - frame.left, frame.bottom - frame.top, project_);
	// Ensure that basic setup of the controller was successful.
	if (!flutter_controller_->engine() || !flutter_controller_->view())
	{
		return false;
	}
	RegisterPlugins(flutter_controller_->engine());
	SetChildContent(flutter_controller_->view()->GetNativeWindow());

	//获得一个解码器的实例
	const flutter::StandardMethodCodec& codec = flutter::StandardMethodCodec::GetInstance();

	chip_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
		flutter_controller_->engine()->messenger(), "top.coclyun.clipshare/clip", &codec);
	common_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
		flutter_controller_->engine()->messenger(), "top.coclyun.clipshare/common", &codec);

	common_channel_.get()->SetMethodCallHandler([this](const auto& call, auto result)
		{
			if (call.method_name() == "getSelectedFiles") {
				std::vector<std::wstring> paths;
				HWND foregroundHwnd = GetForegroundWindow();
				boolean isdeskTop = false;
				// 获取前台窗口的类名
				wchar_t className[256];
				GetClassNameW(foregroundHwnd, className, sizeof(className) / sizeof(className[0]));
				// 判断窗口类名是否为桌面窗口的类名
				if (wcscmp(className, L"Progman") == 0 || wcscmp(className, L"WorkerW") == 0) {
					isdeskTop = true;
				}
				boolean succeeded = isdeskTop ? GetSelectedFilesFromDesktop(paths) : GetSelectedFilesFromExplorer(paths);
				std::string fileList;
				for (const auto& path : paths) {
					fileList += Utf8FromUtf16(path.c_str()) + ";";
				}
				// 构建要传递的参数
				flutter::EncodableMap args;
				args[flutter::EncodableValue("list")] = flutter::EncodableValue(fileList);
				args[flutter::EncodableValue("succeeded")] = flutter::EncodableValue(succeeded);
				auto res = flutter::EncodableValue(args);
				result->Success(res);
				std::cout << paths.size() << std::endl;
			}
		});

	flutter_controller_->engine()->SetNextFrameCallback([&]()
		{
			//			this->Show();
			std::thread t([&]()
				{
					ClipListenerWindow clipListenerWindow(chip_channel_.get());
					Win32Window::Point origin(10, 10);
					Win32Window::Size size(1280, 720);
					if (clipListenerWindow.Create(L"clip", origin, size))
					{
						clipListenerWindow.SetQuitOnClose(true);
					}
					clipListenerWindow.RunMessageLoop();
				});
			t.detach();
		});

	DesktopMultiWindowSetWindowCreatedCallback([](void* controller)
		{
			auto* flutter_view_controller = reinterpret_cast<flutter::FlutterViewController*>(controller);
			HWND hwnd = flutter_view_controller->view()->GetNativeWindow();
			hwnd = GetParent(hwnd);
			// 获取当前窗口样式
			LONG style = GetWindowLong(hwnd, GWL_STYLE);

			// 移除最大化和最小化按钮的样式标志
			style &= ~WS_MAXIMIZEBOX; // 移除最大化按钮
			style &= ~WS_MINIMIZEBOX; // 移除最小化按钮
			// 添加WS_POPUP样式，使窗口成为弹窗
			style |= WS_POPUP;

			// 设置新的窗口样式
			SetWindowLong(hwnd, GWL_STYLE, style);

			//设置置顶
			::SetWindowPos(hwnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOSIZE | SWP_NOMOVE | SWP_NOACTIVATE);
		});
	flutter_controller_->ForceRedraw();
	return true;
}
void FlutterWindow::OnDestroy()
{
	if (flutter_controller_)
	{
		flutter_controller_ = nullptr;
	}

	Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
	WPARAM const wparam,
	LPARAM const lparam) noexcept
{
	// Give Flutter, including plugins, an opportunity to handle window messages.
	if (flutter_controller_)
	{
		std::optional<LRESULT> result =
			flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
				lparam);
		if (result)
		{
			return *result;
		}
	}

	switch (message)
	{
	case WM_FONTCHANGE:
		flutter_controller_->engine()->ReloadSystemFonts();
		break;
	}

	return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
