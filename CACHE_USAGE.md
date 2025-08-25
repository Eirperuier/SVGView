# SVG缓存功能使用指南

## 概述

SVGView库现在支持智能缓存功能，可以显著提高重复加载相同SVG文件的性能。缓存系统会自动管理内存使用，支持LRU（最近最少使用）淘汰策略，并提供灵活的配置选项。

## 主要特性

- **自动缓存**: 所有SVG解析结果都会自动缓存
- **智能管理**: 支持基于时间、数量和大小的缓存淘汰
- **LRU策略**: 优先保留最近使用的缓存项
- **线程安全**: 支持多线程并发访问
- **灵活配置**: 可自定义缓存参数或完全禁用

## 基本使用

### 默认缓存行为

缓存功能默认启用，无需额外配置：

```swift
// 第一次加载 - 从网络/文件加载并缓存
let svgView1 = AsyncSVGView(contentsOf: url)

// 第二次加载相同URL - 直接从缓存获取
let svgView2 = AsyncSVGView(contentsOf: url)
```

### 同步加载也支持缓存

```swift
// 同步解析也会使用缓存
let svgNode = SVGParser.parse(contentsOf: url)
```

## 缓存配置

### 自定义缓存配置

```swift
// 创建自定义缓存配置
let cacheConfig = SVGCacheConfig(
    maxItems: 100,           // 最大缓存项数量
    maxSize: 50 * 1024 * 1024, // 最大缓存大小（50MB）
    expireTime: 3600,        // 缓存过期时间（1小时）
    enabled: true            // 启用缓存
)

// 在SVGSettings中使用自定义缓存配置
let settings = SVGSettings(
    cacheConfig: cacheConfig
)

// 使用自定义设置加载SVG
let svgView = AsyncSVGView(
    contentsOf: url,
    settings: settings
)
```

### 预设配置

```swift
// 默认配置
let defaultConfig = SVGCacheConfig.default

// 禁用缓存
let disabledConfig = SVGCacheConfig.disabled

// 高性能配置（更大的缓存）
let highPerformanceConfig = SVGCacheConfig(
    maxItems: 200,
    maxSize: 100 * 1024 * 1024,
    expireTime: 7200,
    enabled: true
)

// 节省内存配置（较小的缓存）
let memoryEfficientConfig = SVGCacheConfig(
    maxItems: 20,
    maxSize: 10 * 1024 * 1024,
    expireTime: 1800,
    enabled: true
)
```

## 缓存管理

### 清理缓存

```swift
// 清理所有缓存
SVGView.clearCache()
// 或者
AsyncSVGView.clearCache()
```

### 获取缓存统计信息

```swift
let stats = SVGView.getCacheStats()
print("缓存项数量: \(stats.itemCount)")
print("总大小: \(stats.totalSize) 字节")
```

### 动态更新缓存配置

```swift
// 运行时更新缓存配置
let newConfig = SVGCacheConfig(
    maxItems: 50,
    maxSize: 25 * 1024 * 1024,
    expireTime: 1800,
    enabled: true
)

SVGView.updateCacheConfig(newConfig)
```

## 缓存键生成规则

缓存系统会根据以下因素生成唯一的缓存键：

1. **URL**: 对于URL加载的SVG
2. **Data哈希**: 对于Data加载的SVG
3. **字符串哈希**: 对于字符串加载的SVG
4. **设置参数**: fontSize、ppi、linker等设置

这确保了相同内容和设置的SVG会命中缓存，而不同设置的相同SVG会分别缓存。

## 性能优化建议

### 1. 合理设置缓存大小

```swift
// 根据应用内存预算调整缓存大小
let config = SVGCacheConfig(
    maxItems: 50,
    maxSize: 30 * 1024 * 1024, // 30MB
    expireTime: 3600,
    enabled: true
)
```

### 2. 预加载常用SVG

```swift
// 在应用启动时预加载常用SVG
Task {
    for url in commonSVGUrls {
        _ = try? await AsyncSVGParser.parseAsync(contentsOf: url)
    }
}
```

### 3. 在适当时机清理缓存

```swift
// 在内存警告时清理缓存
NotificationCenter.default.addObserver(
    forName: UIApplication.didReceiveMemoryWarningNotification,
    object: nil,
    queue: .main
) { _ in
    SVGView.clearCache()
}
```

### 4. 针对不同场景使用不同配置

```swift
// 列表页面 - 使用较小的缓存
let listConfig = SVGCacheConfig(
    maxItems: 30,
    maxSize: 15 * 1024 * 1024,
    expireTime: 1800,
    enabled: true
)

// 详情页面 - 使用较大的缓存
let detailConfig = SVGCacheConfig(
    maxItems: 100,
    maxSize: 50 * 1024 * 1024,
    expireTime: 3600,
    enabled: true
)
```

## 示例应用

查看 `SVGCacheExample.swift` 文件获取完整的使用示例，包括：

- 缓存统计信息显示
- 动态缓存配置
- 缓存效果演示
- 配置界面实现

## 注意事项

1. **内存使用**: 缓存会占用内存，请根据应用需求合理配置
2. **线程安全**: 缓存操作是线程安全的，可以在任何线程调用
3. **自动清理**: 缓存会根据配置自动清理过期和超限的项目
4. **设置影响**: 不同的SVGSettings会产生不同的缓存项
5. **禁用缓存**: 如果不需要缓存，可以设置 `enabled: false`

## 故障排除

### 缓存未生效

1. 检查缓存是否启用：`cacheConfig.enabled == true`
2. 确认使用相同的URL和设置
3. 检查缓存是否已过期
4. 验证缓存统计信息

### 内存使用过高

1. 减少 `maxItems` 和 `maxSize`
2. 缩短 `expireTime`
3. 定期调用 `clearCache()`
4. 监控缓存统计信息

### 性能问题

1. 确保缓存已启用
2. 检查缓存命中率
3. 考虑预加载策略
4. 优化SVG文件大小