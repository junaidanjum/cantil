import Foundation
import Testing
@testable import Kaset

struct LoginNavigationPolicyTests {
    @Test(arguments: [
        "https://accounts.google.com/ServiceLogin",
        "https://accounts.youtube.com/accounts/SetSID",
        "https://consent.google.com/",
        "https://consent.youtube.com/",
        "https://www.youtube.com/signin",
        "https://youtube.com/",
        "https://music.youtube.com/",
        "https://ACCOUNTS.GOOGLE.COM:443/",
    ])
    func trustedNavigationAllowed(_ address: String) {
        #expect(LoginNavigationPolicy.allows(URL(string: address)))
    }

    @Test(arguments: [
        "http://accounts.google.com/",
        "https://accounts.google.com.attacker.example/",
        "https://accounts.youtube.com.attacker.example/accounts/SetSID",
        "https://evilgoogle.com/",
        "https://music.youtube.com.attacker.example/",
        "https://attacker.example/music.youtube.com",
        "https://accounts.google.com@attacker.example/",
        "https://user@accounts.google.com/",
        "https://accounts.google.com:8443/",
        "https://mail.google.com/",
        "file:///tmp/login.html",
        "data:text/html,login",
        "javascript:alert(1)",
        "about:blank",
        "kaset://play",
    ])
    func untrustedNavigationBlocked(_ address: String) {
        #expect(!LoginNavigationPolicy.allows(URL(string: address)))
        #expect(!LoginNavigationPolicy.completesLogin(URL(string: address)))
    }

    @Test
    func captchaFramesCannotBecomeSignInPages() {
        for address in [
            "https://www.google.com/recaptcha/api2/anchor",
            "https://recaptcha.google.com/recaptcha/api2/anchor",
            "https://www.recaptcha.net/recaptcha/api2/bframe",
            "about:blank",
        ] {
            let url = URL(string: address)
            #expect(LoginNavigationPolicy.allows(url, isMainFrame: false))
            #expect(!LoginNavigationPolicy.allows(url))
        }
        #expect(!LoginNavigationPolicy.allows(URL(string: "https://www.google.com/search"), isMainFrame: false))
        #expect(!LoginNavigationPolicy.allows(URL(string: "https://attacker.example/recaptcha/api2/anchor"), isMainFrame: false))
    }

    @Test
    func completionRequiresExactMusicOrigin() {
        #expect(LoginNavigationPolicy.completesLogin(URL(string: "https://music.youtube.com/")))
        #expect(!LoginNavigationPolicy.completesLogin(URL(string: "https://accounts.google.com/")))
        #expect(!LoginNavigationPolicy.completesLogin(nil))
        #expect(!LoginNavigationPolicy.allows(nil))
    }
}
