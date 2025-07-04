//
//  Scanner.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 03/07/2025.
//

import Foundation

public struct StringScanner {
    public let source: String
    @usableFromInline
    var currentIndex: String.Index
    @usableFromInline
    var endIndex: String.Index

    /// Flag whether the reader is at the end of the source string.
    ///
    public var atEnd: Bool { currentIndex >= endIndex }

    public init(_ string: String) {
        self.source = string
        self.currentIndex = source.startIndex
        self.endIndex = source.endIndex
    }
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
    
    @inlinable
    public mutating func advance() {
        currentIndex = source.index(after: currentIndex)
    }

    public mutating func skipWhitespace() {
        while let char = peek(), char.isWhitespace || char.isNewline {
            advance()
        }
    }
    
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

    public mutating func scanInteger() -> Int? {
        let startIndex = currentIndex
        guard acceptInteger() else { return nil }
        return Int(source[startIndex..<currentIndex])
    }
    
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

}
