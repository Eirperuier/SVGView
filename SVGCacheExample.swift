//
//  SVGCacheExample.swift
//  SVGView
//
//  Created by Assistant on 2024.
//

import SwiftUI
import Combine

/// SVG缓存功能使用示例
struct SVGCacheExample: View {
    @State private var cacheStats: (itemCount: Int, totalSize: Int) = (0, 0)
    @State private var showingCacheConfig = false
    @State private var customCacheConfig = SVGCacheConfig.default
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("SVG缓存功能示例")
                    .font(.title)
                    .padding()
                
                // 缓存统计信息
                GroupBox("缓存统计") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("缓存项数量:")
                            Spacer()
                            Text("\(cacheStats.itemCount)")
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Text("总大小:")
                            Spacer()
                            Text(formatBytes(cacheStats.totalSize))
                                .fontWeight(.semibold)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .padding(.horizontal)
                
                // 缓存操作按钮
                VStack(spacing: 12) {
                    Button("刷新缓存统计") {
                        updateCacheStats()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("清理缓存") {
                        SVGView.clearCache()
                        updateCacheStats()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("缓存配置") {
                        showingCacheConfig = true
                    }
                    .buttonStyle(.bordered)
                }
                
                Divider()
                
                // SVG示例（会使用缓存）
                Text("SVG示例（启用缓存）")
                    .font(.headline)
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(0..<5, id: \.self) { index in
                            VStack {
                                Text("SVG #\(index + 1)")
                                    .font(.caption)
                                
                                // 使用相同的URL多次加载，展示缓存效果
                                if let url = Bundle.main.url(forResource: "example", withExtension: "svg") {
                                    AsyncSVGView(
                                        contentsOf: url,
                                        settings: SVGSettings(
                                            cacheConfig: customCacheConfig
                                        ),
                                        loadingView: {
                                            ProgressView("加载中...")
                                                .frame(height: 100)
                                        },
                                        errorView: { error in
                                            VStack {
                                                Image(systemName: "exclamationmark.triangle")
                                                    .foregroundColor(.red)
                                                Text("加载失败")
                                                    .font(.caption)
                                            }
                                            .frame(height: 100)
                                        }
                                    )
                                    .frame(width: 150, height: 100)
                                    .border(Color.gray.opacity(0.3))
                                } else {
                                    // 使用字符串SVG作为示例
                                    let svgString = """
                                    <svg width="100" height="100" xmlns="http://www.w3.org/2000/svg">
                                        <circle cx="50" cy="50" r="\(20 + index * 5)" fill="hsl(\(index * 60), 70%, 50%)"/>
                                        <text x="50" y="55" text-anchor="middle" fill="white" font-size="12">\(index + 1)</text>
                                    </svg>
                                    """
                                    
                                    AsyncSVGView(
                                        string: svgString,
                                        settings: SVGSettings(
                                            cacheConfig: customCacheConfig
                                        ),
                                        loadingView: {
                                            ProgressView("加载中...")
                                                .frame(height: 100)
                                        },
                                        errorView: { error in
                                            VStack {
                                                Image(systemName: "exclamationmark.triangle")
                                                    .foregroundColor(.red)
                                                Text("加载失败")
                                                    .font(.caption)
                                            }
                                            .frame(height: 100)
                                        }
                                    )
                                    .frame(width: 150, height: 100)
                                    .border(Color.gray.opacity(0.3))
                                }
                            }
                        }
                    }
                    .padding()
                }
                
                Spacer()
            }
            .navigationTitle("SVG缓存")
            .onAppear {
                updateCacheStats()
            }
            .sheet(isPresented: $showingCacheConfig) {
                CacheConfigView(config: $customCacheConfig)
            }
        }
    }
    
    private func updateCacheStats() {
        cacheStats = SVGView.getCacheStats()
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

/// 缓存配置视图
struct CacheConfigView: View {
    @Binding var config: SVGCacheConfig
    @Environment(\.dismiss) private var dismiss
    
    @State private var maxItems: Double
    @State private var maxSizeMB: Double
    @State private var expireTimeMinutes: Double
    @State private var enabled: Bool
    
    init(config: Binding<SVGCacheConfig>) {
        self._config = config
        self._maxItems = State(initialValue: Double(config.wrappedValue.maxItems))
        self._maxSizeMB = State(initialValue: Double(config.wrappedValue.maxSize) / (1024 * 1024))
        self._expireTimeMinutes = State(initialValue: config.wrappedValue.expireTime / 60)
        self._enabled = State(initialValue: config.wrappedValue.enabled)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("基本设置") {
                    Toggle("启用缓存", isOn: $enabled)
                }
                
                Section("缓存限制") {
                    VStack(alignment: .leading) {
                        Text("最大缓存项数量: \(Int(maxItems))")
                        Slider(value: $maxItems, in: 10...200, step: 10)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("最大缓存大小: \(Int(maxSizeMB))MB")
                        Slider(value: $maxSizeMB, in: 10...500, step: 10)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("缓存过期时间: \(Int(expireTimeMinutes))分钟")
                        Slider(value: $expireTimeMinutes, in: 5...120, step: 5)
                    }
                }
                
                Section("预设配置") {
                    Button("默认配置") {
                        applyPreset(.default)
                    }
                    
                    Button("高性能配置") {
                        applyPreset(SVGCacheConfig(
                            maxItems: 100,
                            maxSize: 100 * 1024 * 1024,
                            expireTime: 7200,
                            enabled: true
                        ))
                    }
                    
                    Button("节省内存配置") {
                        applyPreset(SVGCacheConfig(
                            maxItems: 20,
                            maxSize: 20 * 1024 * 1024,
                            expireTime: 1800,
                            enabled: true
                        ))
                    }
                    
                    Button("禁用缓存") {
                        applyPreset(.disabled)
                    }
                }
            }
            .navigationTitle("缓存配置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveConfig()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func applyPreset(_ preset: SVGCacheConfig) {
        maxItems = Double(preset.maxItems)
        maxSizeMB = Double(preset.maxSize) / (1024 * 1024)
        expireTimeMinutes = preset.expireTime / 60
        enabled = preset.enabled
    }
    
    private func saveConfig() {
        let newConfig = SVGCacheConfig(
            maxItems: Int(maxItems),
            maxSize: Int(maxSizeMB * 1024 * 1024),
            expireTime: expireTimeMinutes * 60,
            enabled: enabled
        )
        
        config = newConfig
        SVGView.updateCacheConfig(newConfig)
    }
}

// MARK: - Preview

struct SVGCacheExample_Previews: PreviewProvider {
    static var previews: some View {
        SVGCacheExample()
    }
}

struct CacheConfigView_Previews: PreviewProvider {
    static var previews: some View {
        CacheConfigView(config: .constant(.default))
    }
}