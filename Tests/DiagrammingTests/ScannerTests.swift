import Testing
import Foundation
@testable import Diagramming

@Suite("StringScanner Tests")
struct ScannerTests {
    
    // MARK: - Initialization and Basic Properties
    
    @Test("Initialize with empty string")
    func testInitWithEmptyString() {
        let scanner = StringScanner("")
        #expect(scanner.atEnd == true)
        #expect(scanner.source == "")
    }
    
    @Test("Initialize with non-empty string")
    func testInitWithString() {
        let scanner = StringScanner("hello")
        #expect(scanner.atEnd == false)
        #expect(scanner.source == "hello")
    }
    
    // MARK: - Peek Tests
    
    @Test("Peek at current character")
    func testPeekCurrent() {
        let scanner = StringScanner("abc")
        #expect(scanner.peek() == "a")
        #expect(scanner.peek(offset: 0) == "a")
    }
    
    @Test("Peek with offset")
    func testPeekWithOffset() {
        let scanner = StringScanner("abc")
        #expect(scanner.peek(offset: 0) == "a")
        #expect(scanner.peek(offset: 1) == "b")
        #expect(scanner.peek(offset: 2) == "c")
        #expect(scanner.peek(offset: 3) == nil)
    }
    
    @Test("Peek at end returns nil")
    func testPeekAtEnd() {
        let scanner = StringScanner("")
        #expect(scanner.peek() == nil)
        #expect(scanner.peek(offset: 0) == nil)
    }
    
    // MARK: - Advance Tests
    
    @Test("Advance through string")
    func testAdvance() {
        var scanner = StringScanner("abc")
        #expect(scanner.peek() == "a")
        #expect(scanner.atEnd == false)
        
        scanner.advance()
        #expect(scanner.peek() == "b")
        #expect(scanner.atEnd == false)
        
        scanner.advance()
        #expect(scanner.peek() == "c")
        #expect(scanner.atEnd == false)
        
        scanner.advance()
        #expect(scanner.peek() == nil)
        #expect(scanner.atEnd == true)
    }
    
    // MARK: - Skip Whitespace Tests
    
    @Test("Skip whitespace - spaces and tabs")
    func testSkipWhitespace() {
        var scanner = StringScanner("  \t  hello")
        scanner.skipWhitespace()
        #expect(scanner.peek() == "h")
    }
    
    @Test("Skip whitespace - newlines")
    func testSkipWhitespaceNewlines() {
        var scanner = StringScanner(" \n\r\t world")
        scanner.skipWhitespace()
        #expect(scanner.peek() == "w")
    }
    
    @Test("Skip whitespace - no whitespace")
    func testSkipWhitespaceNone() {
        var scanner = StringScanner("hello")
        scanner.skipWhitespace()
        #expect(scanner.peek() == "h")
    }
    
    @Test("Skip whitespace - only whitespace")
    func testSkipWhitespaceOnly() {
        var scanner = StringScanner("   \t\n")
        scanner.skipWhitespace()
        #expect(scanner.atEnd == true)
    }
    
    // MARK: - Accept Character Tests
    
    @Test("Accept matching character")
    func testAcceptCharacterMatch() {
        var scanner = StringScanner("abc")
        let result = scanner.accept("a")
        #expect(result == true)
        #expect(scanner.peek() == "b")
    }
    
    @Test("Accept non-matching character")
    func testAcceptCharacterNoMatch() {
        var scanner = StringScanner("abc")
        let result = scanner.accept("x")
        #expect(result == false)
        #expect(scanner.peek() == "a")
    }
    
    @Test("Accept at end of string")
    func testAcceptCharacterAtEnd() {
        var scanner = StringScanner("")
        let result = scanner.accept("a")
        #expect(result == false)
        #expect(scanner.atEnd == true)
    }
    
    // MARK: - Accept String Tests
    
    @Test("Accept matching string")
    func testAcceptStringMatch() {
        var scanner = StringScanner("hello world")
        let result = scanner.accept("hello")
        #expect(result == true)
        #expect(scanner.peek() == " ")
    }
    
    @Test("Accept non-matching string")
    func testAcceptStringNoMatch() {
        var scanner = StringScanner("hello world")
        let result = scanner.accept("hi")
        #expect(result == false)
        #expect(scanner.peek() == "h")
    }
    
    @Test("Accept partial matching string")
    func testAcceptStringPartialMatch() {
        var scanner = StringScanner("hello world")
        let result = scanner.accept("help")
        #expect(result == false)
        #expect(scanner.peek() == "h")
    }
    
    @Test("Accept string longer than source")
    func testAcceptStringTooLong() {
        var scanner = StringScanner("hi")
        let result = scanner.accept("hello")
        #expect(result == false)
        #expect(scanner.peek() == "h")
    }
    
    @Test("Accept empty string")
    func testAcceptEmptyString() {
        var scanner = StringScanner("hello")
        let result = scanner.accept("")
        #expect(result == true)
        #expect(scanner.peek() == "h")
    }
    
    // MARK: - Accept Integer Tests
    
    @Test("Accept positive integer")
    func testAcceptPositiveInteger() {
        var scanner = StringScanner("123abc")
        let result = scanner.acceptInteger()
        #expect(result == true)
        #expect(scanner.peek() == "a")
    }
    
    @Test("Accept negative integer")
    func testAcceptNegativeInteger() {
        var scanner = StringScanner("-456def")
        let result = scanner.acceptInteger()
        #expect(result == true)
        #expect(scanner.peek() == "d")
    }
    
    @Test("Accept single digit")
    func testAcceptSingleDigit() {
        var scanner = StringScanner("5")
        let result = scanner.acceptInteger()
        #expect(result == true)
        #expect(scanner.atEnd == true)
    }
    
    @Test("Accept integer - no digits")
    func testAcceptIntegerNoDigits() {
        var scanner = StringScanner("abc")
        let result = scanner.acceptInteger()
        #expect(result == false)
        #expect(scanner.peek() == "a")
    }
    
    @Test("Accept integer - only minus sign")
    func testAcceptIntegerOnlyMinus() {
        var scanner = StringScanner("-abc")
        let result = scanner.acceptInteger()
        #expect(result == false)
        #expect(scanner.peek() == "-")
    }
    
    @Test("Accept integer - empty string")
    func testAcceptIntegerEmpty() {
        var scanner = StringScanner("")
        let result = scanner.acceptInteger()
        #expect(result == false)
        #expect(scanner.atEnd == true)
    }
    
    // MARK: - Scan Integer Tests
    
    @Test("Scan positive integer")
    func testScanPositiveInteger() {
        var scanner = StringScanner("123abc")
        let result = scanner.scanInteger()
        #expect(result == 123)
        #expect(scanner.peek() == "a")
    }
    
    @Test("Scan negative integer")
    func testScanNegativeInteger() {
        var scanner = StringScanner("-456def")
        let result = scanner.scanInteger()
        #expect(result == -456)
        #expect(scanner.peek() == "d")
    }
    
    @Test("Scan integer - invalid")
    func testScanIntegerInvalid() {
        var scanner = StringScanner("abc")
        let result = scanner.scanInteger()
        #expect(result == nil)
        #expect(scanner.peek() == "a")
    }
    
    @Test("Scan zero")
    func testScanZero() {
        var scanner = StringScanner("0")
        let result = scanner.scanInteger()
        #expect(result == 0)
        #expect(scanner.atEnd == true)
    }
    
    // MARK: - Accept Double Tests
    
    @Test("Accept simple double")
    func testAcceptSimpleDouble() {
        var scanner = StringScanner("3.14abc")
        let result = scanner.acceptDouble()
        #expect(result == true)
        #expect(scanner.peek() == "a")
    }
    
    @Test("Accept integer as double")
    func testAcceptIntegerAsDouble() {
        var scanner = StringScanner("42abc")
        let result = scanner.acceptDouble()
        #expect(result == true)
        #expect(scanner.peek() == "a")
    }
    
    @Test("Accept double with scientific notation")
    func testAcceptDoubleScientific() {
        var scanner = StringScanner("1.23e10abc")
        let result = scanner.acceptDouble()
        #expect(result == true)
        #expect(scanner.peek() == "a")
    }
    
    @Test("Accept double with negative exponent")
    func testAcceptDoubleNegativeExponent() {
        var scanner = StringScanner("1.23e-10abc")
        let result = scanner.acceptDouble()
        #expect(result == true)
        #expect(scanner.peek() == "a")
    }
    
    @Test("Accept double with capital E")
    func testAcceptDoubleCapitalE() {
        var scanner = StringScanner("1.23E10abc")
        let result = scanner.acceptDouble()
        #expect(result == true)
        #expect(scanner.peek() == "a")
    }
    
    @Test("Accept negative double")
    func testAcceptNegativeDouble() {
        var scanner = StringScanner("-3.14abc")
        let result = scanner.acceptDouble()
        #expect(result == true)
        #expect(scanner.peek() == "a")
    }
    
    @Test("Accept double - invalid")
    func testAcceptDoubleInvalid() {
        var scanner = StringScanner("abc")
        let result = scanner.acceptDouble()
        #expect(result == false)
        #expect(scanner.peek() == "a")
    }
    
    @Test("Accept double - empty string")
    func testAcceptDoubleEmpty() {
        var scanner = StringScanner("")
        let result = scanner.acceptDouble()
        #expect(result == false)
        #expect(scanner.atEnd == true)
    }
    
    // MARK: - Scan Double Tests
    
    @Test("Scan simple double")
    func testScanSimpleDouble() {
        var scanner = StringScanner("3.14abc")
        let result = scanner.scanDouble()
        #expect(result == 3.14)
        #expect(scanner.peek() == "a")
    }
    
    @Test("Scan integer as double")
    func testScanIntegerAsDouble() {
        var scanner = StringScanner("42abc")
        let result = scanner.scanDouble()
        #expect(result == 42.0)
        #expect(scanner.peek() == "a")
    }
    
    @Test("Scan double with scientific notation")
    func testScanDoubleScientific() {
        var scanner = StringScanner("1.23e2abc")
        let result = scanner.scanDouble()
        #expect(result == 123.0)
        #expect(scanner.peek() == "a")
    }
    
    @Test("Scan double with negative exponent")
    func testScanDoubleNegativeExponent() {
        var scanner = StringScanner("1.23e-2abc")
        let result = scanner.scanDouble()
        #expect(result == 0.0123)
        #expect(scanner.peek() == "a")
    }
    
    @Test("Scan negative double")
    func testScanNegativeDouble() {
        var scanner = StringScanner("-3.14abc")
        let result = scanner.scanDouble()
        #expect(result == -3.14)
        #expect(scanner.peek() == "a")
    }
    
    @Test("Scan double - invalid")
    func testScanDoubleInvalid() {
        var scanner = StringScanner("abc")
        let result = scanner.scanDouble()
        #expect(result == nil)
        #expect(scanner.peek() == "a")
    }
    
    @Test("Scan zero as double")
    func testScanZeroAsDouble() {
        var scanner = StringScanner("0.0")
        let result = scanner.scanDouble()
        #expect(result == 0.0)
        #expect(scanner.atEnd == true)
    }
    
    // MARK: - Complex Scenarios
    
    @Test("Parse sequence of numbers")
    func testParseSequence() {
        var scanner = StringScanner("123 -45.6 7.8e2")
        
        let first = scanner.scanInteger()
        #expect(first == 123)
        
        scanner.skipWhitespace()
        let second = scanner.scanDouble()
        #expect(second == -45.6)
        
        scanner.skipWhitespace()
        let third = scanner.scanDouble()
        #expect(third == 780.0)
        
        #expect(scanner.atEnd == true)
    }
    
    @Test("Parse mixed content")
    func testParseMixedContent() {
        var scanner = StringScanner("value: 42, name: test")
        
        #expect(scanner.accept("value:") == true)
        scanner.skipWhitespace()
        let value = scanner.scanInteger()
        #expect(value == 42)
        
        #expect(scanner.accept(",") == true)
        scanner.skipWhitespace()
        #expect(scanner.accept("name:") == true)
        scanner.skipWhitespace()
        #expect(scanner.accept("test") == true)
        
        #expect(scanner.atEnd == true)
    }
    
    @Test("Restore position on failed string accept")
    func testRestorePositionOnFailedAccept() {
        var scanner = StringScanner("hello world")
        let originalChar = scanner.peek()
        
        let result = scanner.accept("help")
        #expect(result == false)
        #expect(scanner.peek() == originalChar)
    }
    
    // MARK: - Scan Up To Character Tests
    
    @Test("Scan up to character - found")
    func testScanUpToCharacterFound() {
        var scanner = StringScanner("hello world")
        let result = scanner.scanUpToCharacter(" ")
        #expect(result == "hello")
        #expect(scanner.peek() == " ")
    }
    
    @Test("Scan up to character - not found")
    func testScanUpToCharacterNotFound() {
        var scanner = StringScanner("hello world")
        let result = scanner.scanUpToCharacter("x")
        #expect(result == "hello world")
        #expect(scanner.atEnd == true)
    }
    
    @Test("Scan up to character - at beginning")
    func testScanUpToCharacterAtBeginning() {
        var scanner = StringScanner("hello world")
        let result = scanner.scanUpToCharacter("h")
        #expect(result == nil)
        #expect(scanner.peek() == "h")
    }
    
    @Test("Scan up to character - empty result")
    func testScanUpToCharacterEmptyResult() {
        var scanner = StringScanner(",comma,separated")
        let result = scanner.scanUpToCharacter(",")
        #expect(result == nil)
        #expect(scanner.peek() == ",")
    }
    
    @Test("Scan up to character - multiple occurrences")
    func testScanUpToCharacterMultipleOccurrences() {
        var scanner = StringScanner("one,two,three")
        let result = scanner.scanUpToCharacter(",")
        #expect(result == "one")
        #expect(scanner.peek() == ",")
        
        scanner.advance() // Skip comma
        let result2 = scanner.scanUpToCharacter(",")
        #expect(result2 == "two")
        #expect(scanner.peek() == ",")
    }
    
    @Test("Scan up to character - empty string")
    func testScanUpToCharacterEmptyString() {
        var scanner = StringScanner("")
        let result = scanner.scanUpToCharacter("x")
        #expect(result == nil)
        #expect(scanner.atEnd == true)
    }
    
    @Test("Scan up to character - single character string")
    func testScanUpToCharacterSingleChar() {
        var scanner = StringScanner("x")
        let result = scanner.scanUpToCharacter("x")
        #expect(result == nil)
        #expect(scanner.peek() == "x")
    }
    
    @Test("Scan up to character - newline")
    func testScanUpToCharacterNewline() {
        var scanner = StringScanner("line1\nline2")
        let result = scanner.scanUpToCharacter("\n")
        #expect(result == "line1")
        #expect(scanner.peek() == "\n")
    }
    
    // MARK: - Scan Up To Character Set Tests
    
    @Test("Scan up to character set - whitespace")
    func testScanUpToCharacterSetWhitespace() {
        var scanner = StringScanner("hello world")
        let result = scanner.scanUpToCharacter(from: .whitespaces)
        #expect(result == "hello")
        #expect(scanner.peek() == " ")
    }
    
    @Test("Scan up to character set - digits")
    func testScanUpToCharacterSetDigits() {
        var scanner = StringScanner("abc123def")
        let result = scanner.scanUpToCharacter(from: .decimalDigits)
        #expect(result == "abc")
        #expect(scanner.peek() == "1")
    }
    
    @Test("Scan up to character set - punctuation")
    func testScanUpToCharacterSetPunctuation() {
        var scanner = StringScanner("hello, world")
        let result = scanner.scanUpToCharacter(from: .punctuationCharacters)
        #expect(result == "hello")
        #expect(scanner.peek() == ",")
    }
    
    @Test("Scan up to character set - not found")
    func testScanUpToCharacterSetNotFound() {
        var scanner = StringScanner("hello world")
        let result = scanner.scanUpToCharacter(from: .decimalDigits)
        #expect(result == "hello world")
        #expect(scanner.atEnd == true)
    }
    
    @Test("Scan up to character set - at beginning")
    func testScanUpToCharacterSetAtBeginning() {
        var scanner = StringScanner("123abc")
        let result = scanner.scanUpToCharacter(from: .decimalDigits)
        #expect(result == nil)
        #expect(scanner.peek() == "1")
    }
    
    @Test("Scan up to character set - empty result")
    func testScanUpToCharacterSetEmptyResult() {
        var scanner = StringScanner(" hello")
        let result = scanner.scanUpToCharacter(from: .whitespaces)
        #expect(result == nil)
        #expect(scanner.peek() == " ")
    }
    
    @Test("Scan up to character set - custom set")
    func testScanUpToCharacterSetCustom() {
        var scanner = StringScanner("hello:world;test")
        let customSet = CharacterSet(charactersIn: ":;")
        let result = scanner.scanUpToCharacter(from: customSet)
        #expect(result == "hello")
        #expect(scanner.peek() == ":")
    }
    
    @Test("Scan up to character set - empty string")
    func testScanUpToCharacterSetEmptyString() {
        var scanner = StringScanner("")
        let result = scanner.scanUpToCharacter(from: .whitespaces)
        #expect(result == nil)
        #expect(scanner.atEnd == true)
    }
    
    @Test("Scan up to character set - newlines and whitespace")
    func testScanUpToCharacterSetNewlinesAndWhitespace() {
        var scanner = StringScanner("line1\nline2\tline3")
        let result = scanner.scanUpToCharacter(from: .whitespacesAndNewlines)
        #expect(result == "line1")
        #expect(scanner.peek() == "\n")
    }
    
    // MARK: - Complex Scenarios with New Methods
    
    @Test("Parse key-value pairs using scanUpToCharacter")
    func testParseKeyValuePairs() {
        var scanner = StringScanner("key1=value1;key2=value2")
        
        let key1 = scanner.scanUpToCharacter("=")
        #expect(key1 == "key1")
        scanner.advance() // Skip =
        
        let value1 = scanner.scanUpToCharacter(";")
        #expect(value1 == "value1")
        scanner.advance() // Skip ;
        
        let key2 = scanner.scanUpToCharacter("=")
        #expect(key2 == "key2")
        scanner.advance() // Skip =
        
        let value2 = scanner.scanUpToCharacter(";")
        #expect(value2 == "value2")
        #expect(scanner.atEnd == true)
    }
    
    @Test("Parse CSV-like data using scanUpToCharacter")
    func testParseCSVData() {
        var scanner = StringScanner("name,age,city")
        
        let fields = [
            scanner.scanUpToCharacter(","),
            (scanner.accept(",") ? scanner.scanUpToCharacter(",") : nil),
            (scanner.accept(",") ? scanner.scanUpToCharacter(",") : nil)
        ]
        
        #expect(fields[0] == "name")
        #expect(fields[1] == "age")
        #expect(fields[2] == "city")
        #expect(scanner.atEnd == true)
    }
    
    @Test("Extract quoted strings using scanUpToCharacter")
    func testExtractQuotedStrings() {
        var scanner = StringScanner("\"hello world\" and \"test\"")
        
        scanner.accept("\"")
        let quoted1 = scanner.scanUpToCharacter("\"")
        #expect(quoted1 == "hello world")
        scanner.accept("\"")
        
        scanner.skipWhitespace()
        scanner.accept("and")
        scanner.skipWhitespace()
        scanner.accept("\"")
        let quoted2 = scanner.scanUpToCharacter("\"")
        #expect(quoted2 == "test")
        scanner.accept("\"")
        
        #expect(scanner.atEnd == true)
    }
    
    // MARK: - Scan Identifier Tests
    
    @Test("Scan identifier - simple letter")
    func testScanIdentifierSimpleLetter() {
        var scanner = StringScanner("hello world")
        let result = scanner.scanIdentifier()
        #expect(result == "hello")
        #expect(scanner.peek() == " ")
    }
    
    @Test("Scan identifier - starts with underscore")
    func testScanIdentifierStartsWithUnderscore() {
        var scanner = StringScanner("_private123")
        let result = scanner.scanIdentifier()
        #expect(result == "_private123")
        #expect(scanner.atEnd == true)
    }
    
    @Test("Scan identifier - mixed alphanumeric and underscores")
    func testScanIdentifierMixedAlphanumericUnderscores() {
        var scanner = StringScanner("test_var_123abc")
        let result = scanner.scanIdentifier()
        #expect(result == "test_var_123abc")
        #expect(scanner.atEnd == true)
    }
    
    @Test("Scan identifier - single letter")
    func testScanIdentifierSingleLetter() {
        var scanner = StringScanner("a")
        let result = scanner.scanIdentifier()
        #expect(result == "a")
        #expect(scanner.atEnd == true)
    }
    
    @Test("Scan identifier - single underscore")
    func testScanIdentifierSingleUnderscore() {
        var scanner = StringScanner("_")
        let result = scanner.scanIdentifier()
        #expect(result == "_")
        #expect(scanner.atEnd == true)
    }
    
    @Test("Scan identifier - with delimiter")
    func testScanIdentifierWithDelimiter() {
        var scanner = StringScanner("translate(10, 20)")
        let result = scanner.scanIdentifier()
        #expect(result == "translate")
        #expect(scanner.peek() == "(")
    }
    
    @Test("Scan identifier - stops at punctuation")
    func testScanIdentifierStopsAtPunctuation() {
        var scanner = StringScanner("rotate:90")
        let result = scanner.scanIdentifier()
        #expect(result == "rotate")
        #expect(scanner.peek() == ":")
    }
    
    @Test("Scan identifier - stops at whitespace")
    func testScanIdentifierStopsAtWhitespace() {
        var scanner = StringScanner("scale 2.0")
        let result = scanner.scanIdentifier()
        #expect(result == "scale")
        #expect(scanner.peek() == " ")
    }
    
    @Test("Scan identifier - invalid start with digit")
    func testScanIdentifierInvalidStartWithDigit() {
        var scanner = StringScanner("123abc")
        let result = scanner.scanIdentifier()
        #expect(result == nil)
        #expect(scanner.peek() == "1")
    }
    
    @Test("Scan identifier - invalid start with special character")
    func testScanIdentifierInvalidStartWithSpecialChar() {
        var scanner = StringScanner("-transform")
        let result = scanner.scanIdentifier()
        #expect(result == nil)
        #expect(scanner.peek() == "-")
    }
    
    @Test("Scan identifier - empty string")
    func testScanIdentifierEmptyString() {
        var scanner = StringScanner("")
        let result = scanner.scanIdentifier()
        #expect(result == nil)
        #expect(scanner.atEnd == true)
    }
    
    @Test("Scan identifier - only whitespace")
    func testScanIdentifierOnlyWhitespace() {
        var scanner = StringScanner("   ")
        let result = scanner.scanIdentifier()
        #expect(result == nil)
        #expect(scanner.peek() == " ")
    }
    
    @Test("Scan identifier - camelCase")
    func testScanIdentifierCamelCase() {
        var scanner = StringScanner("transformOrigin")
        let result = scanner.scanIdentifier()
        #expect(result == "transformOrigin")
        #expect(scanner.atEnd == true)
    }
    
    @Test("Scan identifier - with numbers in middle")
    func testScanIdentifierWithNumbersInMiddle() {
        var scanner = StringScanner("matrix3d")
        let result = scanner.scanIdentifier()
        #expect(result == "matrix3d")
        #expect(scanner.atEnd == true)
    }
    
    @Test("Scan identifier - unicode letters")
    func testScanIdentifierUnicodeLetters() {
        var scanner = StringScanner("transformação")
        let result = scanner.scanIdentifier()
        #expect(result == "transformação")
        #expect(scanner.atEnd == true)
    }
    
    @Test("Scan identifier - multiple consecutive")
    func testScanIdentifierMultipleConsecutive() {
        var scanner = StringScanner("first second third")
        
        let first = scanner.scanIdentifier()
        #expect(first == "first")
        
        scanner.skipWhitespace()
        let second = scanner.scanIdentifier()
        #expect(second == "second")
        
        scanner.skipWhitespace()
        let third = scanner.scanIdentifier()
        #expect(third == "third")
        
        #expect(scanner.atEnd == true)
    }
    
    // MARK: - SVG Transform Parsing Scenarios
    
    @Test("Parse SVG transform function name")
    func testParseSVGTransformFunctionName() {
        var scanner = StringScanner("translate(10, 20) rotate(45)")
        
        let func1 = scanner.scanIdentifier()
        #expect(func1 == "translate")
        #expect(scanner.peek() == "(")
        
        // Skip parameters for this test
        _ = scanner.scanUpToCharacter(")")
        scanner.advance() // Skip )
        scanner.skipWhitespace()
        
        let func2 = scanner.scanIdentifier()
        #expect(func2 == "rotate")
        #expect(scanner.peek() == "(")
    }
    
    @Test("Parse CSS property names")
    func testParseCSSPropertyNames() {
        var scanner = StringScanner("transform-origin: center")
        
        let property = scanner.scanIdentifier()
        #expect(property == "transform")
        #expect(scanner.peek() == "-")
        
        scanner.advance() // Skip -
        let suffix = scanner.scanIdentifier()
        #expect(suffix == "origin")
        #expect(scanner.peek() == ":")
    }
    
    @Test("Parse variable names in expression")
    func testParseVariableNamesInExpression() {
        var scanner = StringScanner("var1 + _temp2 * scale_factor")
        
        let var1 = scanner.scanIdentifier()
        #expect(var1 == "var1")
        
        scanner.skipWhitespace()
        scanner.accept("+")
        scanner.skipWhitespace()
        
        let var2 = scanner.scanIdentifier()
        #expect(var2 == "_temp2")
        
        scanner.skipWhitespace()
        scanner.accept("*")
        scanner.skipWhitespace()
        
        let var3 = scanner.scanIdentifier()
        #expect(var3 == "scale_factor")
        
        #expect(scanner.atEnd == true)
    }
}
