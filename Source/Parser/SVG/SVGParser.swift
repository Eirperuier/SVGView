//
//  SVGView.swift
//  SVGView
//
//  Created by Alisa Mylnikova on 20/07/2020.
//

import SwiftUI
import Combine

public struct SVGParser {

    static public func parse(contentsOf url: URL, settings: SVGSettings = .default) -> SVGNode? {
        // 先检查缓存
        if let cachedNode = SVGCache.shared.getSVGNode(for: url, settings: settings) {
            return cachedNode
        }
        
        let xml = DOMParser.parse(contentsOf: url, logger: settings.logger)
        let result = parse(xml: xml, settings: settings.linkIfNeeded(to: url))
        
        // 缓存解析结果
        if let result = result {
            SVGCache.shared.cacheSVGNode(result, for: url, settings: settings)
        }
        
        return result
    }

    static public func parse(data: Data, settings: SVGSettings = .default) -> SVGNode? {
        // 先检查缓存
        if let cachedNode = SVGCache.shared.getSVGNode(for: data, settings: settings) {
            return cachedNode
        }
        
        let xml = DOMParser.parse(data: data, logger: settings.logger)
        let result = parse(xml: xml, settings: settings)
        
        // 缓存解析结果
        if let result = result {
            SVGCache.shared.cacheSVGNode(result, for: data, settings: settings)
        }
        
        return result
    }

    static public func parse(string: String, settings: SVGSettings = .default) -> SVGNode? {
        // 先检查缓存
        if let cachedNode = SVGCache.shared.getSVGNode(for: string, settings: settings) {
            return cachedNode
        }
        
        let xml = DOMParser.parse(string: string, logger: settings.logger)
        let result = parse(xml: xml, settings: settings)
        
        // 缓存解析结果
        if let result = result {
            SVGCache.shared.cacheSVGNode(result, for: string, settings: settings)
        }
        
        return result
    }

    static public func parse(stream: InputStream, settings: SVGSettings = .default) -> SVGNode? {
        let xml = DOMParser.parse(stream: stream, logger: settings.logger)
        return parse(xml: xml, settings: settings)
    }

    static public func parse(xml: XMLElement?, settings: SVGSettings = .default) -> SVGNode? {
        guard let xml = xml else { return nil }

        return parse(element: xml, parentContext: SVGRootContext(
            logger: settings.logger,
            linker: settings.linker,
            screen: SVGScreen.main(ppi: settings.ppi),
            index: SVGIndex(element: xml),
            defaultFontSize: settings.fontSize))
    }

    @available(*, deprecated, message: "Use parse(contentsOf:) function instead")
    static public func parse(fileURL: URL) -> SVGNode? {
        return parse(contentsOf: fileURL)
    }
    
    // MARK: - Async Methods
    
    /// 异步解析URL中的SVG文件
    static public func parseAsync(contentsOf url: URL, settings: SVGSettings = .default) async throws -> SVGNode? {
        return try await AsyncSVGParser.parseAsync(contentsOf: url, settings: settings)
    }
    
    /// 异步解析Data中的SVG内容
    static public func parseAsync(data: Data, settings: SVGSettings = .default) async throws -> SVGNode? {
        return try await AsyncSVGParser.parseAsync(data: data, settings: settings)
    }
    
    /// 异步解析字符串中的SVG内容
    static public func parseAsync(string: String, settings: SVGSettings = .default) async throws -> SVGNode? {
        return try await AsyncSVGParser.parseAsync(string: string, settings: settings)
    }
    
    /// 异步解析InputStream中的SVG内容
    static public func parseAsync(stream: InputStream, settings: SVGSettings = .default) async throws -> SVGNode? {
        return try await AsyncSVGParser.parseAsync(stream: stream, settings: settings)
    }
    
    // MARK: - Combine Publishers
    
    /// 使用Combine发布者进行异步解析
    static public func parsePublisher(contentsOf url: URL, settings: SVGSettings = .default) -> AnyPublisher<SVGNode?, Error> {
        return AsyncSVGParser.parsePublisher(contentsOf: url, settings: settings)
    }
    
    /// 使用Combine发布者进行异步解析Data
    static public func parsePublisher(data: Data, settings: SVGSettings = .default) -> AnyPublisher<SVGNode?, Error> {
        return AsyncSVGParser.parsePublisher(data: data, settings: settings)
    }

    private static func parse(element: XMLElement, parentContext: SVGContext) -> SVGNode? {
        guard let context = parentContext.create(for: element) else { return nil }
        return parse(context: context)
    }

    private static let parsers: [String:SVGElementParser] = [
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

    static func getStyleAttributes(xml: XMLElement, index: SVGIndex) -> [String: String] {
        var styleDict = xml.attributes.filter { SVGConstants.availableStyleAttributes.contains($0.key) }
            .filter { $0.value != "inherit" }

        for (att, val) in index.cssStyle(for: xml) {
            if styleDict.index(forKey: att) == nil {
                styleDict.updateValue(val, forKey: att)
            }
        }

        if let cssStyle = xml.attributes["style"] {
            let styleParts = cssStyle.replacingOccurrences(of: " ", with: "").components(separatedBy: ";")
            styleParts.forEach { styleAttribute in
                let currentStyle = styleAttribute.components(separatedBy: ":")
                if currentStyle.count == 2 {
                    styleDict.updateValue(currentStyle[1], forKey: currentStyle[0])
                }
            }
        }

        // TODO: it's a temporary solution. Need to create a correct style merging mechanics
        if styleDict["fill"] == "currentColor", let color = styleDict["color"] {
            styleDict["fill"] = color
        }

        return styleDict
    }

}
