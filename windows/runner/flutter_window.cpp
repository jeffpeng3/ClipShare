#include "flutter_window.h"

#include <codecvt>

#include "clip_listener_window.h"

#include <optional>
#include <thread>
#include <flutter/encodable_value.h>

#include "flutter/standard_method_codec.h"
#include "flutter/generated_plugin_registrant.h"
#pragma warning(disable : 4996)  // 禁用废弃警告
#pragma warning(disable : 4244)  // 禁用wstring转string数据丢失警告
std::wstring GetGuid()
{
	std::wstring empty;
	HKEY hKey;
	if (RegOpenKeyExW(HKEY_LOCAL_MACHINE, L"SYSTEM\\CurrentControlSet\\Control\\IDConfigDB\\Hardware Profiles\\0001", 0, KEY_READ, &hKey) == ERROR_SUCCESS) {
		wchar_t guid[40];
		DWORD dataSize = sizeof(guid);
		if (RegQueryValueExW(hKey, L"HwProfileGuid", nullptr, nullptr, reinterpret_cast<LPBYTE>(guid), &dataSize) == ERROR_SUCCESS) {
			std::wstring g(guid);
			return g;
		}
		RegCloseKey(hKey);
		return empty;
	}
	return empty;
}
std::wstring GetDeviceName() {
	// 获取计算机名称的缓冲区大小
	DWORD bufferSize = MAX_COMPUTERNAME_LENGTH +1;
	// unsigned long bufferSize = 255;
	wchar_t computerName[MAX_COMPUTERNAME_LENGTH + 1];

	// 获取计算机名称
	if (GetComputerName(computerName, &bufferSize)) {
		// 返回设备名称
		return std::wstring(computerName);
	}
	else {
		// 获取失败时返回空字符串或者你认为合适的默认值
		return L"";
	}
}

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
	: project_(project)
{
}

FlutterWindow::~FlutterWindow()
{
}
void FlutterWindow::InitCommonChannel()
{

	// 定义一个 locale，用于字符集转换
	std::locale loc("en_US.UTF-8");

	// 创建一个 codecvt 对象
	std::wstring_convert<std::codecvt_utf8<wchar_t>> converter;
	common_channel_->SetMethodCallHandler([&](const flutter::MethodCall<>& call, std::unique_ptr<flutter::MethodResult<>> result) {
			if (call.method_name().compare("getBaseInfo") == 0) {
				std::wstring guid = GetGuid();
				std::wstring dev = GetDeviceName();
				// 将宽字符字符串转换为窄字符字符串
				// std::string guid = converter.to_bytes();
				// std::string dev = converter.to_bytes(GetDeviceName());
				// 构建要传递的参数
				flutter::EncodableMap args;
				args[flutter::EncodableValue("guid")] = flutter::EncodableValue(std::string(guid.begin(), guid.end()).c_str());
				args[flutter::EncodableValue("dev")] = flutter::EncodableValue(std::string(dev.begin(), dev.end()).c_str());
				args[flutter::EncodableValue("type")] = flutter::EncodableValue("Windows");
				result->Success(args);
			}
			else {
				result->NotImplemented();
			}
		}
	);
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
		flutter_controller_->engine()->messenger(), "clip", &codec);
	common_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
		flutter_controller_->engine()->messenger(), "common", &codec);
	InitCommonChannel();

	flutter_controller_->engine()->SetNextFrameCallback([&]()
		{
			this->Show();
			std::thread t([&]()
			{
					ClipListenerWindow clipListenerWindow(chip_channel_.get());
					Win32Window::Point origin(10, 10);
					Win32Window::Size size(1280, 720);
					if (clipListenerWindow.Create(L"clip", origin, size)) {
						clipListenerWindow.SetQuitOnClose(true);
					}
					clipListenerWindow.RunMessageLoop();
			});
			t.detach();
	});

	// Flutter can complete the first frame before the "show window" callback is
	// registered. The following call ensures a frame is pending to ensure the
	// window is shown. It is a no-op if the first frame hasn't completed yet.
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
