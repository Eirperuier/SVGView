//
//  SVGView.swift
//  SVGView
//
//  Created by Alisa Mylnikova on 20/08/2020.
//

import SwiftUI
import Combine

public struct SVGView: View {

    public let svg: SVGNode?

    public init(contentsOf url: URL) {
        self.svg = SVGParser.parse(contentsOf: url)
    }

    @available(*, deprecated, message: "Use (contentsOf:) initializer instead")
    public init(fileURL: URL) {
        self.svg = SVGParser.parse(contentsOf: fileURL)
    }

    public init(data: Data) {
        self.svg = SVGParser.parse(data: data)
    }

    public init(string: String) {
        self.svg = SVGParser.parse(string: string)
    }

    public init(stream: InputStream) {
        self.svg = SVGParser.parse(stream: stream)
    }

    public init(xml: XMLElement) {
        self.svg = SVGParser.parse(xml: xml)
    }

    public init(svg: SVGNode) {
        self.svg = svg
    }
    
    // MARK: - Async Initializers
    
    /// 异步加载SVG从URL
    public static func async(
        contentsOf url: URL,
        settings: SVGSettings = .default
    ) -> AsyncSVGView {
        return AsyncSVGView(
            contentsOf: url,
            settings: settings
        )
    }
    
    /// 异步加载SVG从URL（带自定义视图）
    public static func async<LoadingView: View, ErrorView: View>(
        contentsOf url: URL,
        settings: SVGSettings = .default,
        @ViewBuilder loadingView: @escaping () -> LoadingView,
        @ViewBuilder errorView: @escaping (Error) -> ErrorView
    ) -> AsyncSVGView {
        return AsyncSVGView(
            contentsOf: url,
            settings: settings,
            loadingView: loadingView,
            errorView: errorView
        )
    }
    
    /// 异步加载SVG从Data
    public static func async(
        data: Data,
        settings: SVGSettings = .default
    ) -> AsyncSVGView {
        return AsyncSVGView(
            data: data,
            settings: settings
        )
    }
    
    /// 异步加载SVG从Data（带自定义视图）
    public static func async<LoadingView: View, ErrorView: View>(
        data: Data,
        settings: SVGSettings = .default,
        @ViewBuilder loadingView: @escaping () -> LoadingView,
        @ViewBuilder errorView: @escaping (Error) -> ErrorView
    ) -> AsyncSVGView {
        return AsyncSVGView(
            data: data,
            settings: settings,
            loadingView: loadingView,
            errorView: errorView
        )
    }
    
    /// 异步加载SVG从字符串
    public static func async(
        string: String,
        settings: SVGSettings = .default
    ) -> AsyncSVGView {
        return AsyncSVGView(
            string: string,
            settings: settings
        )
    }
    
    /// 异步加载SVG从字符串（带自定义视图）
    public static func async<LoadingView: View, ErrorView: View>(
        string: String,
        settings: SVGSettings = .default,
        @ViewBuilder loadingView: @escaping () -> LoadingView,
        @ViewBuilder errorView: @escaping (Error) -> ErrorView
    ) -> AsyncSVGView {
        return AsyncSVGView(
            string: string,
            settings: settings,
            loadingView: loadingView,
            errorView: errorView
        )
    }

    public func getNode(byId id: String) -> SVGNode? {
        return svg?.getNode(byId: id)
    }

    public var body: some View {
        svg?.toSwiftUI()
    }
    
    /// 清理SVG缓存
    public static func clearCache() {
        SVGCache.shared.clearCache()
    }
    
    /// 获取缓存统计信息
    public static func getCacheStats() -> (itemCount: Int, totalSize: Int) {
        return SVGCache.shared.getCacheStats()
    }
    
    /// 更新缓存配置
    public static func updateCacheConfig(_ config: SVGCacheConfig) {
        SVGCache.shared.updateConfig(config)
    }

}
