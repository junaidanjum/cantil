import Foundation

enum LoginNavigationPolicy {
    private static let allowedHosts: Set<String> = [
        "accounts.google.com", "accounts.youtube.com", "consent.google.com", "consent.youtube.com",
        "youtube.com", "www.youtube.com", "music.youtube.com",
    ]

    static func allows(_ url: URL?, isMainFrame: Bool = true) -> Bool {
        if !isMainFrame, url?.absoluteString == "about:blank" {
            return true
        }
        guard let url,
              url.scheme?.lowercased() == "https",
              url.user == nil, url.password == nil,
              url.port == nil || url.port == 443,
              let host = url.host?.lowercased()
        else { return false }
        if self.allowedHosts.contains(host) {
            return true
        }
        // Google's bot checks load inside a frame, never as the sign-in page.
        return !isMainFrame
            && ["www.google.com", "www.recaptcha.net"].contains(host)
            && url.path.hasPrefix("/recaptcha/")
    }

    static func completesLogin(_ url: URL?) -> Bool {
        self.allows(url) && url?.host?.lowercased() == "music.youtube.com"
    }
}
