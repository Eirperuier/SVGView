//
//  AsyncSVGView.swift
//  SVGView
//
//  Created by Assistant on 2024.
//

import SwiftUI
import Combine

/// 异步SVG视图的加载状态
public enum AsyncSVGLoadingState {
    case idle
    case loading
    case loaded(SVGNode)
    case failed(Error)
}

/// 支持异步加载的SVG视图
public struct AsyncSVGView: View {
    @StateObject private var viewModel: AsyncSVGViewModel
    
    private let loadingView: AnyView?
    private let errorView: ((Error) -> AnyView)?
    
    // MARK: - Initializers
    
    /// 从URL异步加载SVG
    public init(
        contentsOf url: URL,
        settings: SVGSettings = .default
    ) {
        let viewModel = AsyncSVGViewModel()
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.loadingView = nil
        self.errorView = nil
        
        // 在初始化后立即开始加载
        Task {
            await viewModel.loadSVG(from: url, settings: settings)
        }
    }
    
    /// 从URL异步加载SVG（带自定义视图）
    public init<LoadingView: View, ErrorView: View>(
        contentsOf url: URL,
        settings: SVGSettings = .default,
        @ViewBuilder loadingView: @escaping () -> LoadingView,
        @ViewBuilder errorView: @escaping (Error) -> ErrorView
    ) {
        let viewModel = AsyncSVGViewModel()
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.loadingView = AnyView(loadingView())
        self.errorView = { error in AnyView(errorView(error)) }
        
        // 在初始化后立即开始加载
        Task {
            await viewModel.loadSVG(from: url, settings: settings)
        }
    }
    
    /// 从Data异步加载SVG
    public init(
        data: Data,
        settings: SVGSettings = .default
    ) {
        let viewModel = AsyncSVGViewModel()
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.loadingView = nil
        self.errorView = nil
        
        // 在初始化后立即开始加载
        Task {
            await viewModel.loadSVG(from: data, settings: settings)
        }
    }
    
    /// 从Data异步加载SVG（带自定义视图）
    public init<LoadingView: View, ErrorView: View>(
        data: Data,
        settings: SVGSettings = .default,
        @ViewBuilder loadingView: @escaping () -> LoadingView,
        @ViewBuilder errorView: @escaping (Error) -> ErrorView
    ) {
        let viewModel = AsyncSVGViewModel()
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.loadingView = AnyView(loadingView())
        self.errorView = { error in AnyView(errorView(error)) }
        
        // 在初始化后立即开始加载
        Task {
            await viewModel.loadSVG(from: data, settings: settings)
        }
    }
    
    /// 从字符串异步加载SVG
    public init(
        string: String,
        settings: SVGSettings = .default
    ) {
        let viewModel = AsyncSVGViewModel()
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.loadingView = nil
        self.errorView = nil
        
        // 在初始化后立即开始加载
        Task {
            await viewModel.loadSVG(from: string, settings: settings)
        }
    }
    
    /// 从字符串异步加载SVG（带自定义视图）
    public init<LoadingView: View, ErrorView: View>(
        string: String,
        settings: SVGSettings = .default,
        @ViewBuilder loadingView: @escaping () -> LoadingView,
        @ViewBuilder errorView: @escaping (Error) -> ErrorView
    ) {
        let viewModel = AsyncSVGViewModel()
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.loadingView = AnyView(loadingView())
        self.errorView = { error in AnyView(errorView(error)) }
        
        // 在初始化后立即开始加载
        Task {
            await viewModel.loadSVG(from: string, settings: settings)
        }
    }
    
    // MARK: - Body
    
    public var body: some View {
        switch viewModel.state {
        case .idle:
            Color.clear
        case .loading:
            if let loadingView = loadingView {
                loadingView
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            }
        case .loaded(let svgNode):
            svgNode.toSwiftUI()
        case .failed(let error):
            if let errorView = errorView {
                errorView(error)
            } else {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.red)
                    Text("加载失败")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    /// 获取指定ID的节点
    public func getNode(byId id: String) -> SVGNode? {
        if case .loaded(let svgNode) = viewModel.state {
            return svgNode.getNode(byId: id)
        }
        return nil
    }
    
    /// 重新加载SVG
    public func reload() {
        viewModel.reload()
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

// MARK: - ViewModel

@MainActor
class AsyncSVGViewModel: ObservableObject {
    @Published var state: AsyncSVGLoadingState = .idle
    
    private var cancellables = Set<AnyCancellable>()
    private var currentLoadingTask: (() -> Void)?
    
    func loadSVG(from url: URL, settings: SVGSettings) async {
        currentLoadingTask = { [weak self] in
            Task {
                await self?.loadSVG(from: url, settings: settings)
            }
        }
        
        state = .loading
        
        do {
            let svgNode = try await AsyncSVGParser.parseAsync(contentsOf: url, settings: settings)
            if let svgNode = svgNode {
                self.state = .loaded(svgNode)
            } else {
                self.state = .failed(SVGError.parsingFailed)
            }
        } catch {
            self.state = .failed(error)
        }
    }
    
    func loadSVG(from data: Data, settings: SVGSettings) async {
        currentLoadingTask = { [weak self] in
            Task {
                await self?.loadSVG(from: data, settings: settings)
            }
        }
        
        state = .loading
        
        do {
            let svgNode = try await AsyncSVGParser.parseAsync(data: data, settings: settings)
            if let svgNode = svgNode {
                self.state = .loaded(svgNode)
            } else {
                self.state = .failed(SVGError.parsingFailed)
            }
        } catch {
            self.state = .failed(error)
        }
    }
    
    func loadSVG(from string: String, settings: SVGSettings) async {
        currentLoadingTask = { [weak self] in
            Task {
                await self?.loadSVG(from: string, settings: settings)
            }
        }
        
        state = .loading
        
        do {
            let svgNode = try await AsyncSVGParser.parseAsync(string: string, settings: settings)
            if let svgNode = svgNode {
                self.state = .loaded(svgNode)
            } else {
                self.state = .failed(SVGError.parsingFailed)
            }
        } catch {
            self.state = .failed(error)
        }
    }
    
    func reload() {
        currentLoadingTask?()
    }
}

// MARK: - Error Types

public enum SVGError: Error, LocalizedError {
    case parsingFailed
    case invalidData
    case networkError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .parsingFailed:
            return "SVG解析失败"
        case .invalidData:
            return "无效的SVG数据"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        }
    }
}