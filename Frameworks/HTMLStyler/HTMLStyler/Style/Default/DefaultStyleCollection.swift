//
//  Created for xikolo-ios under MIT license.
//  Copyright © HPI. All rights reserved.
//

import Foundation

public struct DefaultStyleCollection: StyleCollection {

    let tintColor: UIColor
    let imageLoader: ImageLoader.Type

    public init(tintColor: UIColor, imageLoader: ImageLoader.Type = DefaultImageLoader.self) {
        self.tintColor = tintColor
        self.imageLoader = imageLoader
    }

    private var paragraphStyle: NSMutableParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.15
        paragraphStyle.paragraphSpacing = UIFont.labelFontSize / 3 * 2
        return paragraphStyle
    }

    public var baseStyle: Style {
        let font: UIFont
        if #available(iOS 11, *) {
            font = UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body))
        } else {
            font = UIFont.preferredFont(forTextStyle: .body)
        }
        return [
            .font: font,
            .paragraphStyle: self.paragraphStyle,
        ]
    }

    public func style(for tag: Tag, isLastSibling: Bool) -> Style? {

        func wrappedFont(textStyle: UIFont.TextStyle, font: UIFont) -> UIFont {
            if #available(iOS 11, *) {
                return UIFontMetrics(forTextStyle: textStyle).scaledFont(for: font)
            } else {
                return font
            }
        }

        let defaultPointSize = UIFont.preferredFont(forTextStyle: .body).pointSize
        switch tag {
        case .headline1:

            let style: UIFont.TextStyle
            if #available(iOS 11, *) {
                style = .largeTitle
            } else {
                style = .title1
            }

            return [
                .font: wrappedFont(textStyle: style, font: UIFont.preferredFont(forTextStyle: style))
            ]
        case .headline2:
            return [
                .font: wrappedFont(textStyle: .title1, font: UIFont.preferredFont(forTextStyle: .title1))
            ]
        case .headline3:
            return [
                .font: wrappedFont(textStyle: .title2, font: UIFont.preferredFont(forTextStyle: .title2))
            ]
        case .headline4:
            return [
                .font: wrappedFont(textStyle: .title2, font: UIFont.preferredFont(forTextStyle: .title2))
            ]
        case .headline5:
            return [
                .font: wrappedFont(textStyle: .title3, font: UIFont.preferredFont(forTextStyle: .title3))
            ]
        case .headline6:
            return [
                .font: wrappedFont(textStyle: .headline, font: UIFont.preferredFont(forTextStyle: .headline))
            ]
        case .bold:

            let font = UIFont.preferredFont(forTextStyle: .body)
            let descriptor = font.fontDescriptor.withSymbolicTraits(.traitBold)
            return [
                .font:  wrappedFont(textStyle: .body, font: UIFont(descriptor: descriptor!, size: font.pointSize))
            ]
        case .italic:
            let font = UIFont.preferredFont(forTextStyle: .body)
            let descriptor = font.fontDescriptor.withSymbolicTraits(.traitItalic)
            return [
                .font:  wrappedFont(textStyle: .body, font: UIFont(descriptor: descriptor!, size: font.pointSize))
            ]
        case let .link(url):
            return [
                .link: url,
                .foregroundColor: self.tintColor,
            ]
        case .code:
            return [
                .font: wrappedFont(textStyle: .body, font: UIFont(name: "Courier New", size: defaultPointSize)!),
            ]
        case .listItem(style: _, depth: _):
            let paragraphStyle = self.paragraphStyle
            paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: 16, options: [:])]
            paragraphStyle.defaultTabInterval = 16
            paragraphStyle.firstLineHeadIndent = 0
            paragraphStyle.headIndent = 16

            if !isLastSibling {
                paragraphStyle.paragraphSpacing = 0
            }

            return [
                .paragraphStyle: paragraphStyle,
            ]
        default:
            return nil
        }
    }

    public func replacement(for tag: Tag) -> NSAttributedString? {
        switch tag {
        case let .image(url, alt):
            if let image = self.imageLoader.load(for: url) {
                let attachment = ImageTextAttachment()
                attachment.image = image
                let attachmentString = NSAttributedString(attachment: attachment)
                let attributedString = NSMutableAttributedString(attributedString: attachmentString)
                attributedString.append(NSAttributedString(string: "\n"))
                return attributedString
            } else if let altString = alt {
                return NSAttributedString(string: altString)
            }

            return nil
        default:
            return nil
        }
    }
}
