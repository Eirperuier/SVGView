//
//  SVGSettings.swift
//  SVGView
//
//  Created by Yuri Strot on 29.05.2022.
//

import Foundation
import CoreGraphics

public struct SVGSettings {

    public static let `default` = SVGSettings()

    public let linker: SVGLinker
    public let logger: SVGLogger
    public let fontSize: CGFloat
    public let ppi: Double
    public let cacheConfig: SVGCacheConfig

    public init(linker: SVGLinker = .none, logger: SVGLogger = .console, fontSize: CGFloat = 16, ppi: CGFloat = 96, cacheConfig: SVGCacheConfig = .default) {
        self.linker = linker
        self.logger = logger
        self.fontSize = fontSize
        self.ppi = ppi
        self.cacheConfig = cacheConfig
    }

    func linkIfNeeded(to svgURL: URL) -> SVGSettings {
        if linker === SVGLinker.none {
            return SVGSettings(linker: .relative(to: svgURL), logger: logger, fontSize: fontSize, ppi: ppi, cacheConfig: cacheConfig)
        }
        return self
    }

}
