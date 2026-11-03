import SwiftUI
import WebKit

/// WebView for Google login.
struct LoginWebView: NSViewRepresentable {
    @Environment(WebKitManager.self) private var webKitManager

    /// Callback when navigation completes to YouTube Music.
    var onNavigationToYouTubeMusic: (() -> Void)?
    var onOriginChange: ((String?) -> Void)?
    var onNavigationBlocked: (() -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onNavigationToYouTubeMusic: self.onNavigationToYouTubeMusic,
            onOriginChange: self.onOriginChange,
            onNavigationBlocked: self.onNavigationBlocked
        )
    }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = self.webKitManager.createSessionSwitchWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.customUserAgent = WebKitManager.userAgent
        #if DEBUG
            webView.isInspectable = true
        #endif

        // Load YouTube Music login page
        if let url = URL(string: "https://accounts.google.com/ServiceLogin?service=youtube&uilel=3&passive=true&continue=https%3A%2F%2Fwww.youtube.com%2Fsignin%3Faction_handle_signin%3Dtrue%26app%3Ddesktop%26hl%3Den%26next%3Dhttps%253A%252F%252Fmusic.youtube.com%252F") {
            webView.load(URLRequest(url: url))
        }

        return webView
    }

    func updateNSView(_: WKWebView, context _: Context) {
        // No updates needed
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, WKNavigationDelegate {
        var onNavigationToYouTubeMusic: (() -> Void)?
        var onOriginChange: ((String?) -> Void)?
        var onNavigationBlocked: (() -> Void)?

        init(
            onNavigationToYouTubeMusic: (() -> Void)?,
            onOriginChange: ((String?) -> Void)? = nil,
            onNavigationBlocked: (() -> Void)? = nil
        ) {
            self.onNavigationToYouTubeMusic = onNavigationToYouTubeMusic
            self.onOriginChange = onOriginChange
            self.onNavigationBlocked = onNavigationBlocked
        }

        func webView(
            _: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            // Popups have no visible origin bar. Do not open them or forward
            // credential-bearing URLs to another application.
            guard navigationAction.targetFrame != nil,
                  !navigationAction.shouldPerformDownload,
                  LoginNavigationPolicy.allows(
                      navigationAction.request.url,
                      isMainFrame: navigationAction.targetFrame?.isMainFrame ?? true
                  )
            else {
                self.onNavigationBlocked?()
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }

        func webView(
            _: WKWebView,
            decidePolicyFor navigationResponse: WKNavigationResponse,
            decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
        ) {
            guard navigationResponse.canShowMIMEType,
                  LoginNavigationPolicy.allows(navigationResponse.response.url, isMainFrame: navigationResponse.isForMainFrame)
            else {
                self.onNavigationBlocked?()
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didCommit _: WKNavigation!) {
            self.onOriginChange?(LoginNavigationPolicy.allows(webView.url) ? webView.url?.host : nil)
        }

        func webView(_: WKWebView, didStartProvisionalNavigation _: WKNavigation!) {
            self.onOriginChange?(nil)
        }

        func webView(_ webView: WKWebView, didFinish _: WKNavigation!) {
            // Check if we've navigated to YouTube Music
            if LoginNavigationPolicy.completesLogin(webView.url) {
                self.onNavigationToYouTubeMusic?()
            }
        }
    }
}

#Preview {
    LoginWebView()
        .environment(WebKitManager.shared)
        .frame(width: 500, height: 600)
}
