#include "flutter/method_channel.h"
#include <memory>

#include "win32_window.h"
// A window that does nothing but host a Flutter view.
class ClipListenerWindow : public Win32Window {
public:
    // Creates a new ClipListenerWindow hosting a Flutter view running |project|.
    explicit ClipListenerWindow(flutter::MethodChannel<flutter::EncodableValue>* channel);
    virtual ~ClipListenerWindow(); 
    void RunMessageLoop() {
        MSG msg;
        while (GetMessage(&msg, nullptr, 0, 0)) {
            TranslateMessage(&msg);
            DispatchMessage(&msg);
        }
    }

protected:
    // Win32Window:
    bool OnCreate() override;
    void OnDestroy() override;
    LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                           LPARAM const lparam) noexcept override;

private:
    flutter::MethodChannel<flutter::EncodableValue>* channel_;
    HWND hWndNextViewer_;
    std::wstring lastText = L"";
    void SendClip(std::wstring& content);
    std::wstring GetClipboardText(int retry = 0);
};