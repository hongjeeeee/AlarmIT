import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 11.0, macOS 10.13, tvOS 11.0, *)
extension ColorResource {

}

// MARK: - Image Symbols -

@available(iOS 11.0, macOS 10.7, tvOS 11.0, *)
extension ImageResource {

    /// The "알림it_AI융합전공_logo" asset catalog image resource.
    static let 알림itAI융합전공Logo = ImageResource(name: "알림it_AI융합전공_logo", bundle: resourceBundle)

    /// The "알림it_ICT로고" asset catalog image resource.
    static let 알림itICT로고 = ImageResource(name: "알림it_ICT로고", bundle: resourceBundle)

    /// The "알림it_ICT융합학부_logo" asset catalog image resource.
    static let 알림itICT융합학부Logo = ImageResource(name: "알림it_ICT융합학부_logo", bundle: resourceBundle)

    /// The "알림it_IT융합학부_logo" asset catalog image resource.
    static let 알림itIT융합학부Logo = ImageResource(name: "알림it_IT융합학부_logo", bundle: resourceBundle)

    /// The "알림it_back" asset catalog image resource.
    static let 알림itBack = ImageResource(name: "알림it_back", bundle: resourceBundle)

    /// The "알림it_bell" asset catalog image resource.
    static let 알림itBell = ImageResource(name: "알림it_bell", bundle: resourceBundle)

    /// The "알림it_bell_O" asset catalog image resource.
    static let 알림itBellO = ImageResource(name: "알림it_bell_O", bundle: resourceBundle)

    /// The "알림it_bell_X" asset catalog image resource.
    static let 알림itBellX = ImageResource(name: "알림it_bell_X", bundle: resourceBundle)

    /// The "알림it_bell_f" asset catalog image resource.
    static let 알림itBellF = ImageResource(name: "알림it_bell_f", bundle: resourceBundle)

    /// The "알림it_checkButton_O" asset catalog image resource.
    static let 알림itCheckButtonO = ImageResource(name: "알림it_checkButton_O", bundle: resourceBundle)

    /// The "알림it_checkButton_X" asset catalog image resource.
    static let 알림itCheckButtonX = ImageResource(name: "알림it_checkButton_X", bundle: resourceBundle)

    /// The "알림it_icon" asset catalog image resource.
    static let 알림itIcon = ImageResource(name: "알림it_icon", bundle: resourceBundle)

    /// The "알림it_page_1" asset catalog image resource.
    static let 알림itPage1 = ImageResource(name: "알림it_page_1", bundle: resourceBundle)

    /// The "알림it_page_2" asset catalog image resource.
    static let 알림itPage2 = ImageResource(name: "알림it_page_2", bundle: resourceBundle)

    /// The "알림it_page_3" asset catalog image resource.
    static let 알림itPage3 = ImageResource(name: "알림it_page_3", bundle: resourceBundle)

    /// The "알림it_page_4" asset catalog image resource.
    static let 알림itPage4 = ImageResource(name: "알림it_page_4", bundle: resourceBundle)

    /// The "알림it_splash_icon" asset catalog image resource.
    static let 알림itSplashIcon = ImageResource(name: "알림it_splash_icon", bundle: resourceBundle)

    /// The "알림it_trash" asset catalog image resource.
    static let 알림itTrash = ImageResource(name: "알림it_trash", bundle: resourceBundle)

    /// The "알림it_검색" asset catalog image resource.
    static let 알림it검색 = ImageResource(name: "알림it_검색", bundle: resourceBundle)

    /// The "알림it_북마_O" asset catalog image resource.
    static let 알림it북마O = ImageResource(name: "알림it_북마_O", bundle: resourceBundle)

    /// The "알림it_북마_X" asset catalog image resource.
    static let 알림it북마X = ImageResource(name: "알림it_북마_X", bundle: resourceBundle)

    /// The "알림it_북마크_O" asset catalog image resource.
    static let 알림it북마크O = ImageResource(name: "알림it_북마크_O", bundle: resourceBundle)

    /// The "알림it_북마크_X" asset catalog image resource.
    static let 알림it북마크X = ImageResource(name: "알림it_북마크_X", bundle: resourceBundle)

    /// The "알림it_웹버튼" asset catalog image resource.
    static let 알림it웹버튼 = ImageResource(name: "알림it_웹버튼", bundle: resourceBundle)

    /// The "알림it_전체_O" asset catalog image resource.
    static let 알림it전체O = ImageResource(name: "알림it_전체_O", bundle: resourceBundle)

    /// The "알림it_전체_X" asset catalog image resource.
    static let 알림it전체X = ImageResource(name: "알림it_전체_X", bundle: resourceBundle)

    /// The "알림it_중요공지_O" asset catalog image resource.
    static let 알림it중요공지O = ImageResource(name: "알림it_중요공지_O", bundle: resourceBundle)

    /// The "알림it_중요공지_X" asset catalog image resource.
    static let 알림it중요공지X = ImageResource(name: "알림it_중요공지_X", bundle: resourceBundle)

}

// MARK: - Backwards Deployment Support -

/// A color resource.
struct ColorResource: Swift.Hashable, Swift.Sendable {

    /// An asset catalog color resource name.
    fileprivate let name: Swift.String

    /// An asset catalog color resource bundle.
    fileprivate let bundle: Foundation.Bundle

    /// Initialize a `ColorResource` with `name` and `bundle`.
    init(name: Swift.String, bundle: Foundation.Bundle) {
        self.name = name
        self.bundle = bundle
    }

}

/// An image resource.
struct ImageResource: Swift.Hashable, Swift.Sendable {

    /// An asset catalog image resource name.
    fileprivate let name: Swift.String

    /// An asset catalog image resource bundle.
    fileprivate let bundle: Foundation.Bundle

    /// Initialize an `ImageResource` with `name` and `bundle`.
    init(name: Swift.String, bundle: Foundation.Bundle) {
        self.name = name
        self.bundle = bundle
    }

}

#if canImport(AppKit)
@available(macOS 10.13, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    /// Initialize a `NSColor` with a color resource.
    convenience init(resource: ColorResource) {
        self.init(named: NSColor.Name(resource.name), bundle: resource.bundle)!
    }

}

protocol _ACResourceInitProtocol {}
extension AppKit.NSImage: _ACResourceInitProtocol {}

@available(macOS 10.7, *)
@available(macCatalyst, unavailable)
extension _ACResourceInitProtocol {

    /// Initialize a `NSImage` with an image resource.
    init(resource: ImageResource) {
        self = resource.bundle.image(forResource: NSImage.Name(resource.name))! as! Self
    }

}
#endif

#if canImport(UIKit)
@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    /// Initialize a `UIColor` with a color resource.
    convenience init(resource: ColorResource) {
#if !os(watchOS)
        self.init(named: resource.name, in: resource.bundle, compatibleWith: nil)!
#else
        self.init()
#endif
    }

}

@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// Initialize a `UIImage` with an image resource.
    convenience init(resource: ImageResource) {
#if !os(watchOS)
        self.init(named: resource.name, in: resource.bundle, compatibleWith: nil)!
#else
        self.init()
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.Color {

    /// Initialize a `Color` with a color resource.
    init(_ resource: ColorResource) {
        self.init(resource.name, bundle: resource.bundle)
    }

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.Image {

    /// Initialize an `Image` with an image resource.
    init(_ resource: ImageResource) {
        self.init(resource.name, bundle: resource.bundle)
    }

}
#endif