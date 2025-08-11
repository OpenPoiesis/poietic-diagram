import Testing
import Foundation
@testable import Diagramming

@Suite("SVG Transform Tests")
struct SVGTransformTests {
    
    // MARK: - Basic Transform Parsing
    
    @Test("Parse empty transform")
    func testParseEmptyTransform() {
        let transform = SVGTransformList(string: "")
        #expect(transform.components.isEmpty)
    }
    
    @Test("Parse translate with two parameters")
    func testParseTranslateTwoParams() {
        let transform = SVGTransformList(string: "translate(10, 20)")
        #expect(transform.components.count == 1)
        
        if case .translate(let tx, let ty) = transform.components[0] {
            #expect(tx == 10.0)
            #expect(ty == 20.0)
        } else {
            #expect(Bool(false), "Expected translate transform")
        }
    }
    
    @Test("Parse translate with one parameter")
    func testParseTranslateOneParam() throws {
        let transform = SVGTransformList(string: "translate(15)")
        try #require(transform.components.count == 1)
        
        if case .translate(let tx, let ty) = transform.components[0] {
            #expect(tx == 15.0)
            #expect(ty == 0.0)
        } else {
            #expect(Bool(false), "Expected translate transform")
        }
    }
    
    @Test("Parse rotate without center")
    func testParseRotateWithoutCenter() throws {
        let transform = SVGTransformList(string: "rotate(45)")
        try #require(transform.components.count == 1)
        
        if case .rotate(let angle, let cx, let cy) = transform.components[0] {
            #expect(angle == 45.0)
            #expect(cx == nil)
            #expect(cy == nil)
        } else {
            #expect(Bool(false), "Expected rotate transform")
        }
    }
    
    @Test("Parse rotate with center")
    func testParseRotateWithCenter() throws {
        let transform = SVGTransformList(string: "rotate(90, 50, 100)")
        try #require(transform.components.count == 1)
        
        if case .rotate(let angle, let cx, let cy) = transform.components[0] {
            #expect(angle == 90.0)
            #expect(cx == 50.0)
            #expect(cy == 100.0)
        } else {
            #expect(Bool(false), "Expected rotate transform")
        }
    }
    
    @Test("Parse scale with two parameters")
    func testParseScaleTwoParams() throws {
        let transform = SVGTransformList(string: "scale(2, 3)")
        try #require(transform.components.count == 1)
        
        if case .scale(let sx, let sy) = transform.components[0] {
            #expect(sx == 2.0)
            #expect(sy == 3.0)
        } else {
            #expect(Bool(false), "Expected scale transform")
        }
    }
    
    @Test("Parse scale with one parameter")
    func testParseScaleOneParam() {
        let transform = SVGTransformList(string: "scale(1.5)")
        #expect(transform.components.count == 1)
        
        if case .scale(let sx, let sy) = transform.components[0] {
            #expect(sx == 1.5)
            #expect(sy == 1.5)
        } else {
            #expect(Bool(false), "Expected scale transform")
        }
    }
    
    @Test("Parse matrix transform")
    func testParseMatrix() {
        let transform = SVGTransformList(string: "matrix(1, 0, 0, 1, 30, 40)")
        #expect(transform.components.count == 1)
        
        if case .matrix(let a, let b, let c, let d, let e, let f) = transform.components[0] {
            #expect(a == 1.0)
            #expect(b == 0.0)
            #expect(c == 0.0)
            #expect(d == 1.0)
            #expect(e == 30.0)
            #expect(f == 40.0)
        } else {
            #expect(Bool(false), "Expected matrix transform")
        }
    }
    
    @Test("Parse skewX transform")
    func testParseSkewX() {
        let transform = SVGTransformList(string: "skewX(30)")
        #expect(transform.components.count == 1)
        
        if case .skewX(let angle) = transform.components[0] {
            #expect(angle == 30.0)
        } else {
            #expect(Bool(false), "Expected skewX transform")
        }
    }
    
    @Test("Parse skewY transform")
    func testParseSkewY() {
        let transform = SVGTransformList(string: "skewY(45)")
        #expect(transform.components.count == 1)
        
        if case .skewY(let angle) = transform.components[0] {
            #expect(angle == 45.0)
        } else {
            #expect(Bool(false), "Expected skewY transform")
        }
    }
    
    // MARK: - Multiple Transforms
    
    @Test("Parse multiple transforms")
    func testParseMultipleTransforms() {
        let transform = SVGTransformList(string: "translate(10, 20) rotate(45) scale(2)")
        #expect(transform.components.count == 3)
        
        if case .translate(let tx, let ty) = transform.components[0] {
            #expect(tx == 10.0)
            #expect(ty == 20.0)
        } else {
            #expect(Bool(false), "Expected translate transform")
        }
        
        if case .rotate(let angle, let cx, let cy) = transform.components[1] {
            #expect(angle == 45.0)
            #expect(cx == nil)
            #expect(cy == nil)
        } else {
            #expect(Bool(false), "Expected rotate transform")
        }
        
        if case .scale(let sx, let sy) = transform.components[2] {
            #expect(sx == 2.0)
            #expect(sy == 2.0)
        } else {
            #expect(Bool(false), "Expected scale transform")
        }
    }
    
    // MARK: - Whitespace Handling
    
    @Test("Parse with extra whitespace")
    func testParseWithExtraWhitespace() {
        let transform = SVGTransformList(string: "  translate( 10 , 20 )  rotate( 45 )  ")
        #expect(transform.components.count == 2)
        
        if case .translate(let tx, let ty) = transform.components[0] {
            #expect(tx == 10.0)
            #expect(ty == 20.0)
        } else {
            #expect(Bool(false), "Expected translate transform")
        }
        
        if case .rotate(let angle, _, _) = transform.components[1] {
            #expect(angle == 45.0)
        } else {
            #expect(Bool(false), "Expected rotate transform")
        }
    }
    
    @Test("Parse with space separators")
    func testParseWithSpaceSeparators() {
        let transform = SVGTransformList(string: "translate(10 20) matrix(1 0 0 1 30 40)")
        #expect(transform.components.count == 2)
        
        if case .translate(let tx, let ty) = transform.components[0] {
            #expect(tx == 10.0)
            #expect(ty == 20.0)
        } else {
            #expect(Bool(false), "Expected translate transform")
        }
        
        if case .matrix(let a, let b, let c, let d, let e, let f) = transform.components[1] {
            #expect(a == 1.0)
            #expect(b == 0.0)
            #expect(c == 0.0)
            #expect(d == 1.0)
            #expect(e == 30.0)
            #expect(f == 40.0)
        } else {
            #expect(Bool(false), "Expected matrix transform")
        }
    }
    
    // MARK: - Case Insensitive Parsing
    
    @Test("Parse case insensitive function names")
    func testParseCaseInsensitive() {
        let transform = SVGTransformList(string: "TRANSLATE(10, 20) Rotate(45) SkewX(30)")
        #expect(transform.components.count == 3)
        
        if case .translate(let tx, let ty) = transform.components[0] {
            #expect(tx == 10.0)
            #expect(ty == 20.0)
        } else {
            #expect(Bool(false), "Expected translate transform")
        }
        
        if case .rotate(let angle, _, _) = transform.components[1] {
            #expect(angle == 45.0)
        } else {
            #expect(Bool(false), "Expected rotate transform")
        }
        
        if case .skewX(let angle) = transform.components[2] {
            #expect(angle == 30.0)
        } else {
            #expect(Bool(false), "Expected skewX transform")
        }
    }
    
    // MARK: - Negative Numbers and Scientific Notation
    
    @Test("Parse with negative numbers")
    func testParseWithNegativeNumbers() {
        let transform = SVGTransformList(string: "translate(-10, -20) rotate(-45)")
        #expect(transform.components.count == 2)
        
        if case .translate(let tx, let ty) = transform.components[0] {
            #expect(tx == -10.0)
            #expect(ty == -20.0)
        } else {
            #expect(Bool(false), "Expected translate transform")
        }
        
        if case .rotate(let angle, _, _) = transform.components[1] {
            #expect(angle == -45.0)
        } else {
            #expect(Bool(false), "Expected rotate transform")
        }
    }
    
    @Test("Parse with decimal numbers")
    func testParseWithDecimalNumbers() {
        let transform = SVGTransformList(string: "translate(10.5, 20.25) scale(1.5, 2.75)")
        #expect(transform.components.count == 2)
        
        if case .translate(let tx, let ty) = transform.components[0] {
            #expect(tx == 10.5)
            #expect(ty == 20.25)
        } else {
            #expect(Bool(false), "Expected translate transform")
        }
        
        if case .scale(let sx, let sy) = transform.components[1] {
            #expect(sx == 1.5)
            #expect(sy == 2.75)
        } else {
            #expect(Bool(false), "Expected scale transform")
        }
    }
    
    @Test("Parse with scientific notation")
    func testParseWithScientificNotation() {
        let transform = SVGTransformList(string: "translate(1e2, 2.5e1)")
        #expect(transform.components.count == 1)
        
        if case .translate(let tx, let ty) = transform.components[0] {
            #expect(tx == 100.0)
            #expect(ty == 25.0)
        } else {
            #expect(Bool(false), "Expected translate transform")
        }
    }
    
    // MARK: - Error Handling
    
    @Test("Parse invalid function name")
    func testParseInvalidFunctionName() {
        let transform = SVGTransformList(string: "invalidFunction(10, 20)")
        #expect(transform.components.isEmpty)
    }
    
    @Test("Parse malformed syntax")
    func testParseMalformedSyntax() {
        let transform = SVGTransformList(string: "translate(10, 20 rotate(45)")
        #expect(transform.components.isEmpty)
    }
    
    @Test("Parse insufficient parameters")
    func testParseInsufficientParameters() {
        let transform = SVGTransformList(string: "matrix(1, 0, 0)")
        #expect(transform.components.isEmpty)
    }
    
    // MARK: - Real-world Examples
    
    @Test("Parse complex real-world transform")
    func testParseComplexRealWorldTransform() {
        let transformString = "translate(100, 50) rotate(30, 50, 50) scale(1.2, 0.8) skewX(15)"
        let transform = SVGTransformList(string: transformString)
        #expect(transform.components.count == 4)
        
        if case .translate(let tx, let ty) = transform.components[0] {
            #expect(tx == 100.0)
            #expect(ty == 50.0)
        } else {
            #expect(Bool(false), "Expected translate transform")
        }
        
        if case .rotate(let angle, let cx, let cy) = transform.components[1] {
            #expect(angle == 30.0)
            #expect(cx == 50.0)
            #expect(cy == 50.0)
        } else {
            #expect(Bool(false), "Expected rotate transform")
        }
        
        if case .scale(let sx, let sy) = transform.components[2] {
            #expect(sx == 1.2)
            #expect(sy == 0.8)
        } else {
            #expect(Bool(false), "Expected scale transform")
        }
        
        if case .skewX(let angle) = transform.components[3] {
            #expect(angle == 15.0)
        } else {
            #expect(Bool(false), "Expected skewX transform")
        }
    }
    
    @Test("Parse typical CSS transform")
    func testParseTypicalCSSTransform() {
        let transform = SVGTransformList(string: "translate(50px, 100px) rotate(45deg)")
        // Should fail to parse because px and deg are not valid numbers in SVG transforms
        #expect(transform.components.count == 0)
    }
}
