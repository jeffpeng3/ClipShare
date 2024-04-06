#include "clip_listener_window.h"

#include <codecvt>
#include <sstream>
#include <flutter/encodable_value.h>
#include "flutter/standard_method_codec.h"
#include <atlenc.h>

#pragma warning(disable : 4996)  // 禁用废弃警告
ClipListenerWindow::ClipListenerWindow(flutter::MethodChannel<flutter::EncodableValue>* channel): channel_(channel)
{
}

ClipListenerWindow::~ClipListenerWindow()
{
}
std::wstring Utf16FromUtf8(const std::string& string) {
	int size_needed = MultiByteToWideChar(CP_UTF8, 0, string.c_str(), -1, nullptr, 0);
	if (size_needed == 0) {
		return {};
	}
	std::wstring wstrTo(size_needed, 0);
	int converted_length = MultiByteToWideChar(CP_UTF8, 0, string.c_str(), -1, &wstrTo[0], size_needed);
	if (converted_length == 0) {
		return {};
	}
	return wstrTo;
}
bool ClipListenerWindow::OnCreate()
{
	if (!Win32Window::OnCreate())
	{
		return false;
	}

	channel_->SetMethodCallHandler([this](const auto& call, auto result)
	{
		if (call.method_name() == "copy")
		{
			auto* arguments = std::get_if<flutter::EncodableMap>(call.arguments());
			auto type = std::get<std::string>(arguments->at(flutter::EncodableValue("type")));
			auto content = std::get<std::string>(arguments->at(flutter::EncodableValue("content")));
			SetClipboard(type, content);
			result->Success(flutter::EncodableValue(true));
		}
	});
	// std::stringstream ss;
	// ss << GetHandle();
	// std::string s("listener handle: " + ss.str() + "\n");
	// std::wstring wideString(s.begin(), s.end());
	// OutputDebugString(wideString.c_str());
	// 注册为剪贴板查看器
	hWndNextViewer_ = SetClipboardViewer(GetHandle());

	return true;
}

void ClipListenerWindow::OnDestroy()
{
	Win32Window::OnDestroy();
	// 移除剪贴板查看器
	ChangeClipboardChain(GetHandle(), hWndNextViewer_);
}

void ClipListenerWindow::SendClip(std::wstring& content)
{
	// 定义一个 locale，用于字符集转换
	std::locale loc("en_US.UTF-8");

	// 创建一个 codecvt 对象
	std::wstring_convert<std::codecvt_utf8<wchar_t>> converter;

	// 将宽字符字符串转换为窄字符字符串
	std::string str = converter.to_bytes(content);
	// 构建要传递的参数
	flutter::EncodableMap args;
	args[flutter::EncodableValue("text")] = flutter::EncodableValue(str.c_str());

	// 调用Flutter方法
	channel_->InvokeMethod("setClipText", std::make_unique<flutter::EncodableValue>(args));
}

void ClipListenerWindow::SetClipboard(std::string type, std::string content, int retry)
{
	// 尝试打开剪贴板
	bool isOpen = OpenClipboard(nullptr);
	if (!isOpen)
	{
		if (retry > 5)
		{
			return;
		}
		Sleep(100);
		return SetClipboard(type, content, retry + 1);
	}

	// 清空剪贴板内容
	EmptyClipboard();
	std::wstring data = Utf16FromUtf8(content).c_str();
	// 分配全局内存，用于存放文本
	HGLOBAL hClipboardData = GlobalAlloc(GMEM_MOVEABLE, (wcslen(data.c_str()) + 1) * sizeof(wchar_t));
	if (!hClipboardData)
	{
		CloseClipboard();
		std::cerr << "Failed to allocate memory for clipboard!" << std::endl;
		return;
	}
	//文本类型
	if (type == "Text")
	{
		// 将文本复制到全局内存中
		wchar_t* pchData = static_cast<wchar_t*>(GlobalLock(hClipboardData));
		wcscpy_s(pchData, wcslen(data.c_str())+1, data.c_str());
		GlobalUnlock(hClipboardData);

		// 将全局内存放入剪贴板
		SetClipboardData(CF_UNICODETEXT, hClipboardData);
	}


	// 关闭剪贴板
	CloseClipboard();
}

std::wstring ClipListenerWindow::GetClipboardText(int retry)
{
	std::wstring empty = L"";
	// 尝试打开剪贴板
	bool isOpen = OpenClipboard(nullptr);
	if (!isOpen)
	{
		if (retry > 5)
		{
			return empty;
		}
		Sleep(100);
		return GetClipboardText(retry + 1);
	}

	// 尝试获取剪贴板中的数据
	HANDLE hData = GetClipboardData(CF_UNICODETEXT);
	if (hData == nullptr)
	{
		CloseClipboard();
		return empty;
	}

	// 锁定内存并获取数据
	wchar_t* pszText = static_cast<wchar_t*>(GlobalLock(hData));
	if (pszText == nullptr)
	{
		CloseClipboard();
		return empty;
	}

	// 复制数据到字符串
	std::wstring clipboardText(pszText);

	// 释放内存和关闭剪贴板
	GlobalUnlock(hData);
	CloseClipboard();

	return clipboardText;
}

LRESULT ClipListenerWindow::MessageHandler(HWND hwnd, UINT const uMsg, WPARAM const wParam,
                                           LPARAM const lParam) noexcept
{
	// hwnd: 表示窗口的句柄（handle），是消息发送或接收的窗口的标识符。在函数内，您可以使用这个句柄与窗口进行交互。
	//
	// uMsg : 表示窗口消息的标识符。它指定了要处理的消息类型。例如，WM_DRAWCLIPBOARD 表示剪贴板内容发生变化的消息。
	// WM_DRAWCLIPBOARD 中，wParam 和 lParam 分别表示剪贴板触发事件的原因和相关的句柄。
	//
	// 	wParam : 通常用于传递一些消息相关的信息，如通知消息的原因、按下的键值等。
	//
	// 	lParam : 通常用于传递指针或句柄，指向消息相关的数据结构或对象。

	std::string s("listener handle: " + std::to_string(uMsg) + "\n");
	std::wstring wideString(s.begin(), s.end());
	OutputDebugString(wideString.c_str());
	switch (uMsg)
	{
	case WM_DRAWCLIPBOARD:
		{
			// 剪贴板内容发生变化
			// 处理剪贴板变化的代码可以放在这里
			std::wstring text = GetClipboardText();
			if (!text.empty() && text != lastText)
				SendClip(text);
			lastText = text;
			// 转发消息给下一个剪贴板查看器
			SendMessage(hWndNextViewer_, WM_DRAWCLIPBOARD, wParam, lParam);
		}
		break;
	case WM_CHANGECBCHAIN:
		{
			// 处理剪贴板链的变化
			if ((HWND)wParam == hWndNextViewer_)
				hWndNextViewer_ = (HWND)lParam;
			else if (hWndNextViewer_ != nullptr)
				SendMessage(hWndNextViewer_, uMsg, wParam, lParam);
		}
		break;
	}

	return Win32Window::MessageHandler(hwnd, uMsg, wParam, lParam);
}
