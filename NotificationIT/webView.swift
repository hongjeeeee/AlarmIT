// webView.dart 변환
import SwiftUI
import WebKit

// WebViewController(WKWebView) 대응 UIViewRepresentable
struct WebViewRepresentable: UIViewRepresentable {
    let url: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true // JavaScriptMode.unrestricted
        let webView = WKWebView(frame: .zero, configuration: config)
        if let requestUrl = URL(string: url) {
            webView.load(URLRequest(url: requestUrl)) // loadRequest
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

struct WebViewPage: View {
    let url: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // body Stack: WebViewWidget + Positioned back 버튼
            WebViewRepresentable(url: url)
                .ignoresSafeArea()

            // Positioned(bottom: 700, right: 320)
            ZStack(alignment: .bottomTrailing) {
                Color.clear
                Button {
                    dismiss()
                } label: {
                    svgImage("assets/icons/알림it_back.svg")
                }
                .frame(width: 59, height: 62)
                .padding(.bottom, 700)
                .padding(.trailing, 320)
            }
        }
        // floatingActionButton: 웹버튼 → 사파리 열기
        .overlay(alignment: .bottomTrailing) {
            Button {
                launchURL()
            } label: {
                ZStack {
                    Circle().fill(Color.clear)
                    svgImage("assets/icons/알림it_웹버튼.svg")
                        .frame(width: 40, height: 40)
                }
                .frame(width: 115, height: 42)
            }
            .padding()
        }
        .navigationBarBackButtonHidden(true)
    }

    private func launchURL() {
        if UrlLauncher.canLaunch(url) {
            UrlLauncher.launch(url)  // URL을 사파리에서 열기
        } else {
            print("Could not launch \(url)")
        }
    }
}
