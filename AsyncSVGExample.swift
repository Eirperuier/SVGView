//
//  AsyncSVGExample.swift
//  SVGView
//
//  Created by Assistant on 2024.
//

import SwiftUI
import Combine

/// 异步SVG使用示例
struct AsyncSVGExample: View {
    @State private var svgNode: SVGNode?
    @State private var isLoading = false
    @State private var error: Error?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("异步SVG加载示例")
                .font(.title)
                .padding()
            
            // 方法1: 使用AsyncSVGView（推荐）
            Group {
                Text("方法1: 使用AsyncSVGView")
                    .font(.headline)
                
                AsyncSVGView(
                    contentsOf: Bundle.main.url(forResource: "example", withExtension: "svg")!,
                    loadingView: {
                        VStack {
                            ProgressView()
                            Text("加载中...")
                        }
                    },
                    errorView: { error in
                        VStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.red)
                            Text("加载失败: \(error.localizedDescription)")
                                .foregroundColor(.secondary)
                        }
                    }
                )
                .frame(width: 200, height: 200)
                .border(Color.gray)
            }
            
            Divider()
            
            // 方法2: 使用SVGView.async静态方法
            Group {
                Text("方法2: 使用SVGView.async")
                    .font(.headline)
                
                SVGView.async(
                    contentsOf: Bundle.main.url(forResource: "example", withExtension: "svg")!,
                    loadingView: {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("正在加载SVG...")
                                .font(.caption)
                        }
                    },
                    errorView: { error in
                        Text("加载失败")
                            .foregroundColor(.red)
                    }
                )
                .frame(width: 200, height: 200)
                .border(Color.blue)
            }
            
            Divider()
            
            // 方法3: 手动使用async/await
            Group {
                Text("方法3: 手动async/await")
                    .font(.headline)
                
                if isLoading {
                    ProgressView("手动加载中...")
                } else if let error = error {
                    Text("错误: \(error.localizedDescription)")
                        .foregroundColor(.red)
                } else if let svgNode = svgNode {
                    svgNode.toSwiftUI()
                        .frame(width: 200, height: 200)
                        .border(Color.green)
                } else {
                    Button("开始加载") {
                        loadSVGManually()
                    }
                }
            }
            
            Divider()
            
            // 方法4: 使用Combine Publisher
            Group {
                Text("方法4: 使用Combine Publisher")
                    .font(.headline)
                
                CombineSVGExample()
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func loadSVGManually() {
        guard let url = Bundle.main.url(forResource: "example", withExtension: "svg") else {
            error = SVGError.invalidData
            return
        }
        
        isLoading = true
        error = nil
        
        Task {
            do {
                let node = try await SVGParser.parseAsync(contentsOf: url)
                await MainActor.run {
                    self.svgNode = node
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
}

/// 使用Combine的SVG加载示例
struct CombineSVGExample: View {
    @StateObject private var viewModel = CombineSVGViewModel()
    
    var body: some View {
        Group {
            switch viewModel.state {
            case .idle:
                Button("使用Combine加载") {
                    viewModel.loadSVG()
                }
            case .loading:
                ProgressView("Combine加载中...")
            case let .loaded(svgNode):
                svgNode.toSwiftUI()
                    .frame(width: 200, height: 200)
                    .border(Color.orange)
            case let .failed(error):
                VStack {
                    Text("Combine加载失败")
                        .foregroundColor(.red)
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

class CombineSVGViewModel: ObservableObject {
    @Published var state: AsyncSVGLoadingState = .idle
    private var cancellables = Set<AnyCancellable>()
    
    func loadSVG() {
        guard let url = Bundle.main.url(forResource: "example", withExtension: "svg") else {
            state = .failed(SVGError.invalidData)
            return
        }
        
        state = .loading
        
        SVGParser.parsePublisher(contentsOf: url)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.state = .failed(error)
                    }
                },
                receiveValue: { [weak self] svgNode in
                    if let svgNode = svgNode {
                        self?.state = .loaded(svgNode)
                    } else {
                        self?.state = .failed(SVGError.parsingFailed)
                    }
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: - Preview

struct AsyncSVGExample_Previews: PreviewProvider {
    static var previews: some View {
        AsyncSVGExample()
    }
}