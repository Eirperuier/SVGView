//
//  AsyncSVGParser.swift
//  SVGView
//
//  Created by Assistant on 2024.
//

import Combine
import SwiftUI

/// 异步SVG解析器，支持异步加载和解析SVG文件
public struct AsyncSVGParser {

  /// 异步解析URL中的SVG文件
  static public func parseAsync(contentsOf url: URL, settings: SVGSettings = .default) async throws
    -> SVGNode?
  {
    // 先检查缓存
    if let cachedNode = SVGCache.shared.getSVGNode(for: url, settings: settings) {
      return cachedNode
    }
    
    return try await withCheckedThrowingContinuation { continuation in
      DispatchQueue.global(qos: .userInitiated).async {
        do {
          let xml = DOMParser.parse(contentsOf: url, logger: settings.logger)
          let result = parse(xml: xml, settings: settings.linkIfNeeded(to: url))
          
          // 缓存解析结果
          if let result = result {
            SVGCache.shared.cacheSVGNode(result, for: url, settings: settings)
          }
          
          continuation.resume(returning: result)
        } catch {
          continuation.resume(throwing: error)
        }
      }
    }
  }

  /// 异步解析Data中的SVG内容
  static public func parseAsync(data: Data, settings: SVGSettings = .default) async throws
    -> SVGNode?
  {
    // 先检查缓存
    if let cachedNode = SVGCache.shared.getSVGNode(for: data, settings: settings) {
      return cachedNode
    }
    
    return try await withCheckedThrowingContinuation { continuation in
      DispatchQueue.global(qos: .userInitiated).async {
        do {
          let xml = DOMParser.parse(data: data, logger: settings.logger)
          let result = parse(xml: xml, settings: settings)
          
          // 缓存解析结果
          if let result = result {
            SVGCache.shared.cacheSVGNode(result, for: data, settings: settings)
          }
          
          continuation.resume(returning: result)
        } catch {
          continuation.resume(throwing: error)
        }
      }
    }
  }

  /// 异步解析字符串中的SVG内容
  static public func parseAsync(string: String, settings: SVGSettings = .default) async throws
    -> SVGNode?
  {
    // 先检查缓存
    if let cachedNode = SVGCache.shared.getSVGNode(for: string, settings: settings) {
      return cachedNode
    }
    
    return try await withCheckedThrowingContinuation { continuation in
      DispatchQueue.global(qos: .userInitiated).async {
        do {
          let xml = DOMParser.parse(string: string, logger: settings.logger)
          let result = parse(xml: xml, settings: settings)
          
          // 缓存解析结果
          if let result = result {
            SVGCache.shared.cacheSVGNode(result, for: string, settings: settings)
          }
          
          continuation.resume(returning: result)
        } catch {
          continuation.resume(throwing: error)
        }
      }
    }
  }

  /// 异步解析InputStream中的SVG内容
  static public func parseAsync(stream: InputStream, settings: SVGSettings = .default) async throws
    -> SVGNode?
  {
    return try await withCheckedThrowingContinuation { continuation in
      DispatchQueue.global(qos: .userInitiated).async {
        do {
          let xml = DOMParser.parse(stream: stream, logger: settings.logger)
          let result = parse(xml: xml, settings: settings)
          continuation.resume(returning: result)
        } catch {
          continuation.resume(throwing: error)
        }
      }
    }
  }

  /// 使用Combine发布者进行异步解析
  static public func parsePublisher(contentsOf url: URL, settings: SVGSettings = .default)
    -> AnyPublisher<SVGNode?, Error>
  {
    // 先检查缓存
    if let cachedNode = SVGCache.shared.getSVGNode(for: url, settings: settings) {
      return Just(cachedNode)
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    }
    
    return Future<SVGNode?, Error> { promise in
      DispatchQueue.global(qos: .userInitiated).async {
        do {
          let xml = DOMParser.parse(contentsOf: url, logger: settings.logger)
          let result = parse(xml: xml, settings: settings.linkIfNeeded(to: url))
          
          // 缓存解析结果
          if let result = result {
            SVGCache.shared.cacheSVGNode(result, for: url, settings: settings)
          }
          
          promise(.success(result))
        } catch {
          promise(.failure(error))
        }
      }
    }
    .eraseToAnyPublisher()
  }

  /// 使用Combine发布者进行异步解析Data
  static public func parsePublisher(data: Data, settings: SVGSettings = .default) -> AnyPublisher<
    SVGNode?, Error
  > {
    // 先检查缓存
    if let cachedNode = SVGCache.shared.getSVGNode(for: data, settings: settings) {
      return Just(cachedNode)
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    }
    
    return Future<SVGNode?, Error> { promise in
      DispatchQueue.global(qos: .userInitiated).async {
        do {
          let xml = DOMParser.parse(data: data, logger: settings.logger)
          let result = parse(xml: xml, settings: settings)
          
          // 缓存解析结果
          if let result = result {
            SVGCache.shared.cacheSVGNode(result, for: data, settings: settings)
          }
          
          promise(.success(result))
        } catch {
          promise(.failure(error))
        }
      }
    }
    .eraseToAnyPublisher()
  }

  // MARK: - Private Methods

  private static func parse(xml: XMLElement?, settings: SVGSettings) -> SVGNode? {
    guard let xml = xml else { return nil }

    return parse(
      element: xml,
      parentContext: SVGRootContext(
        logger: settings.logger,
        linker: settings.linker,
        screen: SVGScreen.main(ppi: settings.ppi),
        index: SVGIndex(element: xml),
        defaultFontSize: settings.fontSize))
  }

  private static func parse(element: XMLElement, parentContext: SVGContext) -> SVGNode? {
    guard let context = parentContext.create(for: element) else { return nil }
    return parse(context: context)
  }

  private static let parsers: [String: SVGElementParser] = [
    "svg": SVGViewportParser(),
    "g": SVGGroupParser(),
    "use": SVGUseParser(),
    "text": SVGTextParser(),
    "image": SVGImageParser(),
    "rect": SVGRectParser(),
    "circle": SVGCircleParser(),
    "ellipse": SVGEllipseParser(),
    "line": SVGLineParser(),
    "polygon": SVGPolygonParser(),
    "polyline": SVGPolylineParser(),
    "path": SVGPathParser(),
  ]

  private static func parse(context: SVGNodeContext) -> SVGNode? {
    return parsers[context.element.name]?.parse(context: context) {
      parse(element: $0, parentContext: context)
    }
  }
}
