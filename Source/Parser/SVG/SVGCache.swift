//
//  SVGCache.swift
//  SVGView
//
//  Created by Assistant on 2024.
//

import Combine
import Foundation

/// SVG缓存项
public struct SVGCacheItem {
  let svgNode: SVGNode
  let timestamp: Date
  let size: Int  // 估算的内存大小

  init(svgNode: SVGNode, size: Int = 0) {
    self.svgNode = svgNode
    self.timestamp = Date()
    self.size = size
  }
}

/// SVG缓存配置
public struct SVGCacheConfig {
  /// 最大缓存项数量
  public let maxItems: Int
  /// 最大缓存大小（字节）
  public let maxSize: Int
  /// 缓存过期时间（秒）
  public let expireTime: TimeInterval
  /// 是否启用缓存
  public let enabled: Bool

  public init(
    maxItems: Int = 50, maxSize: Int = 50 * 1024 * 1024, expireTime: TimeInterval = 3600,
    enabled: Bool = true
  ) {
    self.maxItems = maxItems
    self.maxSize = maxSize
    self.expireTime = expireTime
    self.enabled = enabled
  }

  /// 默认缓存配置
  public static let `default` = SVGCacheConfig()

  /// 禁用缓存的配置
  public static let disabled = SVGCacheConfig(enabled: false)
}

/// SVG缓存管理器
public class SVGCache {
  public static let shared = SVGCache()

  private var cache: [String: SVGCacheItem] = [:]
  private var accessOrder: [String] = []  // LRU访问顺序
  private let queue = DispatchQueue(label: "com.svgview.cache", attributes: .concurrent)
  private var config: SVGCacheConfig

  public init(config: SVGCacheConfig = .default) {
    self.config = config
  }

  /// 更新缓存配置
  public func updateConfig(_ newConfig: SVGCacheConfig) {
    queue.async(flags: .barrier) {
      self.config = newConfig
      if !newConfig.enabled {
        self.cache.removeAll()
        self.accessOrder.removeAll()
      } else {
        self.cleanupIfNeeded()
      }
    }
  }

  /// 生成缓存键
  private func cacheKey(for url: URL, settings: SVGSettings) -> String {
    let settingsHash = "\(settings.fontSize)_\(settings.ppi)_\(settings.linker.description)"
    return "\(url.absoluteString)_\(settingsHash)"
  }

  private func cacheKey(for data: Data, settings: SVGSettings) -> String {
    let dataHash = data.hashValue
    let settingsHash = "\(settings.fontSize)_\(settings.ppi)_\(settings.linker.description)"
    return "data_\(dataHash)_\(settingsHash)"
  }

  private func cacheKey(for string: String, settings: SVGSettings) -> String {
    let stringHash = string.hashValue
    let settingsHash = "\(settings.fontSize)_\(settings.ppi)_\(settings.linker.description)"
    return "string_\(stringHash)_\(settingsHash)"
  }

  /// 从缓存获取SVG节点
  public func getSVGNode(for url: URL, settings: SVGSettings) -> SVGNode? {
    guard config.enabled else { return nil }

    let key = cacheKey(for: url, settings: settings)
    return queue.sync(flags: .barrier) {
      guard let item = cache[key] else { return nil }

      // 检查是否过期
      if Date().timeIntervalSince(item.timestamp) > config.expireTime {
        cache.removeValue(forKey: key)
        accessOrder.removeAll { $0 == key }
        return nil
      }

      // 更新访问顺序（LRU）
      accessOrder.removeAll { $0 == key }
      accessOrder.append(key)

      return item.svgNode
    }
  }

  public func getSVGNode(for data: Data, settings: SVGSettings) -> SVGNode? {
    guard config.enabled else { return nil }

    let key = cacheKey(for: data, settings: settings)
    return queue.sync(flags: .barrier) {
      guard let item = cache[key] else { return nil }

      // 检查是否过期
      if Date().timeIntervalSince(item.timestamp) > config.expireTime {
        cache.removeValue(forKey: key)
        accessOrder.removeAll { $0 == key }
        return nil
      }

      // 更新访问顺序（LRU）
      accessOrder.removeAll { $0 == key }
      accessOrder.append(key)

      return item.svgNode
    }
  }

  public func getSVGNode(for string: String, settings: SVGSettings) -> SVGNode? {
    guard config.enabled else { return nil }

    let key = cacheKey(for: string, settings: settings)
    return queue.sync(flags: .barrier) {
      guard let item = cache[key] else { return nil }

      // 检查是否过期
      if Date().timeIntervalSince(item.timestamp) > config.expireTime {
        cache.removeValue(forKey: key)
        accessOrder.removeAll { $0 == key }
        return nil
      }

      // 更新访问顺序（LRU）
      accessOrder.removeAll { $0 == key }
      accessOrder.append(key)

      return item.svgNode
    }
  }

  /// 缓存SVG节点
  public func cacheSVGNode(_ svgNode: SVGNode, for url: URL, settings: SVGSettings) {
    guard config.enabled else { return }

    let key = cacheKey(for: url, settings: settings)
    let estimatedSize = estimateSize(of: svgNode)
    let item = SVGCacheItem(svgNode: svgNode, size: estimatedSize)

    queue.async(flags: .barrier) {
      self.cache[key] = item
      self.accessOrder.removeAll { $0 == key }
      self.accessOrder.append(key)
      self.cleanupIfNeeded()
    }
  }

  public func cacheSVGNode(_ svgNode: SVGNode, for data: Data, settings: SVGSettings) {
    guard config.enabled else { return }

    let key = cacheKey(for: data, settings: settings)
    let estimatedSize = estimateSize(of: svgNode)
    let item = SVGCacheItem(svgNode: svgNode, size: estimatedSize)

    queue.async(flags: .barrier) {
      self.cache[key] = item
      self.accessOrder.removeAll { $0 == key }
      self.accessOrder.append(key)
      self.cleanupIfNeeded()
    }
  }

  public func cacheSVGNode(_ svgNode: SVGNode, for string: String, settings: SVGSettings) {
    guard config.enabled else { return }

    let key = cacheKey(for: string, settings: settings)
    let estimatedSize = estimateSize(of: svgNode)
    let item = SVGCacheItem(svgNode: svgNode, size: estimatedSize)

    queue.async(flags: .barrier) {
      self.cache[key] = item
      self.accessOrder.removeAll { $0 == key }
      self.accessOrder.append(key)
      self.cleanupIfNeeded()
    }
  }

  /// 清理缓存
  public func clearCache() {
    queue.async(flags: .barrier) {
      self.cache.removeAll()
      self.accessOrder.removeAll()
    }
  }

  /// 获取缓存统计信息
  public func getCacheStats() -> (itemCount: Int, totalSize: Int) {
    return queue.sync {
      let totalSize = cache.values.reduce(0) { $0 + $1.size }
      return (itemCount: cache.count, totalSize: totalSize)
    }
  }

  // MARK: - Private Methods

  private func cleanupIfNeeded() {
    // 清理过期项
    let now = Date()
    let expiredKeys = cache.compactMap { key, item in
      now.timeIntervalSince(item.timestamp) > config.expireTime ? key : nil
    }

    for key in expiredKeys {
      cache.removeValue(forKey: key)
      accessOrder.removeAll { $0 == key }
    }

    // 检查数量限制
    while cache.count > config.maxItems {
      if let oldestKey = accessOrder.first {
        cache.removeValue(forKey: oldestKey)
        accessOrder.removeFirst()
      } else {
        break
      }
    }

    // 检查大小限制
    let totalSize = cache.values.reduce(0) { $0 + $1.size }
    if totalSize > config.maxSize {
      // 按LRU顺序移除项目直到满足大小限制
      var currentSize = totalSize
      while currentSize > config.maxSize && !accessOrder.isEmpty {
        let oldestKey = accessOrder.removeFirst()
        if let item = cache.removeValue(forKey: oldestKey) {
          currentSize -= item.size
        }
      }
    }
  }

  private func estimateSize(of svgNode: SVGNode) -> Int {
    // 简单的大小估算，可以根据需要改进
    return 1024  // 默认1KB估算
  }
}

// MARK: - SVGLinker Extension

extension SVGLinker: Equatable {
  public static func == (lhs: SVGLinker, rhs: SVGLinker) -> Bool {
    // 比较类实例
    if lhs === SVGLinker.none && rhs === SVGLinker.none {
      return true
    }

    if let lhsURL = lhs as? SVGURLLinker, let rhsURL = rhs as? SVGURLLinker {
      return lhsURL.url == rhsURL.url
    }

    return false
  }

  var description: String {
    if self === SVGLinker.none {
      return "none"
    }

    if let urlLinker = self as? SVGURLLinker {
      return "relative_\(urlLinker.url.absoluteString)"
    }

    return "unknown"
  }
}
