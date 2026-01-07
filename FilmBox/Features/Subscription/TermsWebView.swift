//
//  TermsWebView.swift
//  FilmBox
//
//  In-app WebView for Terms & Privacy Policy
//

import SwiftUI
import WebKit

// MARK: - Terms URL

enum LegalLinks {
    static let termsAndPrivacy = "https://drive.google.com/file/d/15etIHMx2DzSINTV1sUNBEPkmbm3Wx3tN/view?usp=sharing"
}

// MARK: - Terms WebView

struct TermsWebView: View {
    @Environment(\.dismiss) private var dismiss

    let url: String
    let title: String

    init(url: String = LegalLinks.termsAndPrivacy, title: String = "Terms & Privacy") {
        self.url = url
        self.title = title
    }

    var body: some View {
        NavigationStack {
            WebViewRepresentable(url: url)
                .ignoresSafeArea(edges: .bottom)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.black, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text(title.lowercased())
                            .font(.system(size: 17, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.white)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - WebView Representable

private struct WebViewRepresentable: UIViewRepresentable {
    let url: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black

        if let url = URL(string: url) {
            webView.load(URLRequest(url: url))
        }

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

// MARK: - Preview

#Preview {
    TermsWebView()
}
