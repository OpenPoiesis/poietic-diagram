//
//  Scanner.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 03/07/2025.
//

import Foundation

/// String utility for simple character or common token type parsing.
///
/// StringScanner offers string parsing capabilities for implementing simple parsers and tokenisers.
/// It provides methods for:
///
/// - Character-by-character advancement and peeking: ``peek(offset:)``
/// - Whitespace skipping: ``skipWhitespace()``
/// - Pattern matching and acceptance ``accept(_:)``, ``accept(_:)-mtvr``
/// - Number parsing (integers and doubles with scientific notation): ``scanDouble()``, ``scanInteger()``.
/// - Identifier scanning (alphanumeric with underscores): ``scanIdentifier()``
/// - Text extraction up to specified characters or character sets: ``scanUpToCharacter(_:)``, ``scanUpToCharacter(from:)``
///
/// All parsing methods are non-destructive - they either succeed and advance the position,
/// or fail and leave the position unchanged.
///
/// Example usage:
/// ```swift
/// var scanner = StringScanner("hello 123 world")
/// scanner.scanIdentifier() // Returns "hello"
/// scanner.skipWhitespace()
/// scanner.scanInteger()     // Returns 123
/// ```
///
public struct StringScanner {
    /// The source string being scanned.
    public let source: String
    
    /// The current position within the source string.
    @usableFromInline
    var currentIndex: String.Index
    
    /// The end position of the source string.
    @usableFromInline
    var endIndex: String.Index

    /// Returns true if the scanner has reached the end of the source string.
    ///
    public var atEnd: Bool { currentIndex >= endIndex }

    /// Creates a new StringScanner for the given source string.
    ///
    /// - Parameter string: The string to scan
    ///
    public init(_ string: String) {
        self.source = string
        self.currentIndex = source.startIndex
        self.endIndex = source.endIndex
    }
    /// Returns the character at the current position plus the given offset without advancing.
    ///
    /// - Parameter offset: The offset from the current position (default: 0)
    /// - Returns: The character at the specified position, or nil if beyond the string bounds
    ///
    @inlinable
    public func peek(offset: Int = 0) -> Character? {
        guard !atEnd else {
            return nil
        }
        guard let peekIndex = source.index(currentIndex, offsetBy: offset, limitedBy: endIndex), peekIndex < endIndex else {
            return nil
        }
        return source[peekIndex]
    }
    
    /// Advances the scanner position by one character.
    ///
    /// Does nothing if already at the end of the string.
    ///
    @inlinable
    public mutating func advance() {
        currentIndex = source.index(after: currentIndex)
    }

    /// Advances the scanner position past any whitespace and newline characters.
    ///
    public mutating func skipWhitespace() {
        while let char = peek(), char.isWhitespace || char.isNewline {
            advance()
        }
    }
    
    /// Attempts to match and consume the specified character.
    ///
    /// - Parameter character: The character to match
    /// - Returns: true if the character was matched and consumed, false otherwise
    ///
    @discardableResult
    public mutating func accept(_ character: Character) -> Bool {
        if peek() == character {
            advance()
            return true
        }
        else {
            return false
        }
    }
    
    /// Attempts to match and consume the specified string.
    ///
    /// - Parameter string: The string to match
    /// - Returns: true if the string was matched and consumed, false otherwise
    ///
    @discardableResult
    public mutating func accept(_ string: String) -> Bool {
        let savedIndex = self.currentIndex
        for char in string {
            if !accept(char) {
                self.currentIndex = savedIndex
                return false
            }
        }
        return true
    }
    
    /// Attempts to match and consume an integer (with optional minus sign).
    ///
    /// - Returns: true if an integer was matched and consumed, false otherwise
    ///
    public mutating func acceptInteger() -> Bool {
        let startIndex = currentIndex
        
        guard !atEnd else { return false }

        accept("-")

        guard let char = peek(), char.isWholeNumber else {
            self.currentIndex = startIndex
            return false
        }
        
        while let char = peek() {
            guard char.isWholeNumber else {
                break
            }
            advance()
        }
        return true
    }

    /// Scans and returns the next character, advancing the position.
    ///
    /// - Returns: The next character, or nil if at the end of the string
    ///
    public mutating func scanCharacter() -> Character? {
        guard !atEnd else { return nil }
        let char = peek()
        advance()
        return char
    }
    
    /// Scans and returns an integer value.
    ///
    /// Supports negative integers with leading minus sign.
    ///
    /// - Returns: The parsed integer value, or nil if no valid integer found
    ///
    public mutating func scanInteger() -> Int? {
        let startIndex = currentIndex
        guard acceptInteger() else { return nil }
        return Int(source[startIndex..<currentIndex])
    }
    
    /// Attempts to match and consume a double value.
    ///
    /// Supports decimal notation (123.456) and scientific notation (1.23e-4, 1.23E+5).
    ///
    /// - Returns: true if a double was matched and consumed, false otherwise
    ///
    public mutating func acceptDouble() -> Bool {
        let startIndex = currentIndex

        guard !atEnd else { return false }

        guard acceptInteger() else {
            self.currentIndex = startIndex
            return false
        }
        
        if accept(".") {
            guard acceptInteger() else {
                self.currentIndex = startIndex
                return false
            }
        }

        if accept("e") || accept("E") {
            guard acceptInteger() else {
                self.currentIndex = startIndex
                return false
            }
        }
        return true
    }

    /// Scans and returns a double value.
    ///
    /// Supports decimal notation (123.456) and scientific notation (1.23e-4, 1.23E+5).
    ///
    /// - Returns: The parsed double value, or nil if no valid double found
    ///
    public mutating func scanDouble() -> Double? {
        let startIndex = currentIndex
        guard acceptDouble() else { return nil }
        return Double(source[startIndex..<currentIndex])
    }

    /// Scan up to (but not including) the specified character.
    /// Returns the scanned string, or nil if the character is not found.
    /// The scanner position will be at the terminating character if found, or at the end if not found.
    public mutating func scanUpToCharacter(_ character: Character) -> String? {
        let startIndex = currentIndex
        
        while !atEnd && peek() != character {
            advance()
        }
        
        guard startIndex < currentIndex else {
            return nil
        }
        
        return String(source[startIndex..<currentIndex])
    }
    
    /// Scan up to (but not including) any character from the specified character set.
    /// Returns the scanned string, or nil if no characters from the set are found.
    /// The scanner position will be at the first matching character if found, or at the end if not found.
    public mutating func scanUpToCharacter(from characterSet: CharacterSet) -> String? {
        let startIndex = currentIndex
        
        while !atEnd {
            guard let char = peek() else { break }
            if characterSet.contains(char.unicodeScalars.first!) {
                break
            }
            advance()
        }
        
        guard startIndex < currentIndex else {
            return nil
        }
        
        return String(source[startIndex..<currentIndex])
    }
    
    /// Scan an identifier (letter or underscore, followed by alphanumeric or underscore characters).
    /// Returns the identifier string, or nil if no valid identifier is found at the current position.
    public mutating func scanIdentifier() -> String? {
        let startIndex = currentIndex
        
        guard !atEnd else { return nil }
        
        // First character must be letter or underscore
        guard let firstChar = peek(),
              firstChar.isLetter || firstChar == "_" else {
            return nil
        }
        
        advance()
        
        // Subsequent characters can be letters, digits, or underscores
        while let char = peek(),
              char.isLetter || char.isNumber || char == "_" {
            advance()
        }
        
        return String(source[startIndex..<currentIndex])
    }

    /// Scan two comma-separated floating point number (double) values as a 2D vector.
    public mutating func scanPoint() -> Vector2D? {
        let savedIndex = self.currentIndex

        self.skipWhitespace()
        guard let x = scanDouble() else {
            self.currentIndex = savedIndex
            return nil
        }

        self.skipWhitespace()
        guard accept(",") else {
            self.currentIndex = savedIndex
            return nil
        }
        self.skipWhitespace()

        guard let y = scanDouble() else {
            self.currentIndex = savedIndex
            return nil
        }
        return Vector2D(x, y)
    }
}
