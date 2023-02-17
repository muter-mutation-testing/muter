//import XCTest
//
//@testable import muterCore
//
//final class ImplicitReturnRewriterTests: XCTestCase {
//    func test_closureImplicitReturn() throws {
//        let code = try sourceCode(
//            """
//            foo.map {
//                $0 + 1
//            }
//            """
//        )
//        
//        let sut = ImplicitReturnRewriter().visit(code)
//                
//        XCTAssertEqual(
//            sut.description,
//            """
//            foo.map {
//            return $0 + 1
//            }
//            """
//        )
//    }
//    
//    func test_functionImplicitReturn() throws {
//        let code = try sourceCode(
//            """
//            func baz() -> Int { 0 }
//            """
//        )
//        
//        let sut = ImplicitReturnRewriter().visit(code)
//        
//        XCTAssertEqual(
//            sut.description,
//            """
//            func baz() -> Int { \nreturn 0 }
//            """
//        )
//    }
//    
//    func test_patternBindingImplicitReturn() throws {
//        let code = try sourceCode(
//            """
//            static var bar: Int { 0 }
//            """
//        )
//        
//        let sut = ImplicitReturnRewriter().visit(code)
//        
//        XCTAssertEqual(
//            sut.description,
//            """
//            static var bar: Int { \nreturn 0 }
//            """
//        )    }
//    
//    func test_getterImplicitReturn() throws {
//        let code = try sourceCode(
//            """
//            var bar: Int {
//                get { 0 }
//                set { }
//            }
//            """
//        )
//        
//        let sut = ImplicitReturnRewriter().visit(code)
//        
//        XCTAssertEqual(
//            sut.description,
//            """
//            var bar: Int {
//                set { }
//                get { \nreturn 0 }
//            }
//            """
//        )
//    }
//    
//    func test_implicitReturn() throws {
//        let code = try sourceCode(
//            """
//            func adapt(attributes theAttributes: StyleAttributes, to traitCollection: UITraitCollection) -> StyleAttributes? {
//                guard var font = theAttributes[AttributeName.nonAdaptedFont] as? BONFont else {
//                    fatalError("The designated font is set when the adaptive style is added")
//                }
//                let pointSize = font.pointSize
//                let contentSizeCategory = traitCollection.bon_preferredContentSizeCategory
//                var styleAttributes = theAttributes
//                switch behavior {
//                case .control:
//                    font = UIFont(descriptor: font.fontDescriptor, size: AdaptiveStyle.adapt(designatedSize: pointSize, for: contentSizeCategory))
//                case .body:
//                    font = UIFont(descriptor: font.fontDescriptor, size: AdaptiveStyle.adaptBody(designatedSize: pointSize, for: contentSizeCategory))
//                case .preferred:
//                    if let textStyle = font.textStyle {
//                        font = UIFont.bon_preferredFont(forTextStyle: textStyle, compatibleWith: traitCollection)
//                    }
//                    else {
//                        print("No text style in the font, can not adapt")
//                    }
//                case .fontMetrics:
//                    if #available(iOS 11, tvOS 11, *) {
//                        let metrics = UIFontMetrics(forTextStyle: textStyle ?? .body)
//                        if let maxPointSize = maxPointSize {
//                            font = metrics.scaledFont(for: font, maximumPointSize: maxPointSize, compatibleWith: traitCollection)
//                        }
//                        else {
//                            font = metrics.scaledFont(for: font, compatibleWith: traitCollection)
//                        }
//                    }
//                case .above(let size, let fontName):
//                    font = pointSize > size ? font.fontWithSameAttributes(named: fontName) : font
//                case .below(let size, let family):
//                    font = pointSize < size ? font.fontWithSameAttributes(named: family) : font
//                }
//                styleAttributes[.font] = font
//                return styleAttributes
//            }
//            """
//        )
//        
//        let sm: [SchemataMutationMapping] = MutationOperator.Id.allCases.reduce(into: []) { accum, next in
//            let visitor = next.schemataVisitor(
//                MuterConfiguration(),
//                SourceFileInfo(path: "", source: code.description)
//            )
//
//            
//            visitor.walk(code)
//            
//            accum.append(visitor.schemataMappings)
//        }
//        
//        let sut = MutationSchemataRewriter(sm.mergeByFileName().first!).visit(code)
//        
//        XCTAssertEqual(
//            sut.description,
//            """
//            """
//        )
//    }
//}
