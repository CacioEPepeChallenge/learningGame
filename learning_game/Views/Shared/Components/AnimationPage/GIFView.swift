//
//  GIFView.swift
//  learning_game
//
//  Created by Rudi Butarbutar on 22/11/26.
//

import SwiftUI
import WebKit

struct GIFView: UIViewRepresentable {
    let name: String
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.backgroundColor = .clear
        
        if let url = Bundle.main.url(forResource: name, withExtension: "gif"),
           let data = try? Data (contentsOf: url) {
            webView.load(
                data,
                mimeType: "image/gif",
                characterEncodingName: "UTF-8",
                baseURL: url.deletingLastPathComponent()
            )
        }
        return webView
    }
    func updateUIView(_ uiView: UIViewType, context: Context) {}
}
