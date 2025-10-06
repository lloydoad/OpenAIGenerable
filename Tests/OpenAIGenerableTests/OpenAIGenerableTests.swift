import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(OpenAIGenerableMacros)
import OpenAIGenerableMacros

let testMacros: [String: Macro.Type] = [
    "stringify": StringifyMacro.self,
    "OpenAIScheme": OpenAISchemaMacro.self,
]
#endif

final class OpenAIGenerableTests: XCTestCase {
    func testMacro() throws {
        #if canImport(OpenAIGenerableMacros)
        assertMacroExpansion(
            """
            #stringify(a + b)
            """,
            expandedSource: """
            (a + b, "a + b")
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testMacroWithStringLiteral() throws {
        #if canImport(OpenAIGenerableMacros)
        assertMacroExpansion(
            #"""
            #stringify("Hello, \(name)")
            """#,
            expandedSource: #"""
            ("Hello, \(name)", #""Hello, \(name)""#)
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testSimpleStructWithStrings() throws {
        #if canImport(OpenAIGenerableMacros)
        assertMacroExpansion(
            """
            @OpenAIScheme
            struct SubObject {
                var id: String
                var name: String
            }
            """,
            expandedSource: """
            struct SubObject {
                var id: String
                var name: String

                static var openAISchema: [String: Any] {
                    [
                        "type": "json_schema",
                        "name": "SubObject",
                        "strict": true,
                        "schema": [
                            "type": "object",
                            "properties": [
                            "id": ["type": "string"],
                            "name": ["type": "string"]
                            ],
                            "required": ["id", "name"],
                            "additionalProperties": false
                        ]
                    ]
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testSimpleStructWithSubObject() throws {
        #if canImport(OpenAIGenerableMacros)
        assertMacroExpansion(
            """
            @OpenAIScheme
            struct Child {
                var name: String
            }
            @OpenAIScheme
            struct Parent {
                var id: String
                var child: Child
            }
            """,
            expandedSource: """
            struct Child {
                var name: String

                static var openAISchema: [String: Any] {
                    [
                        "type": "json_schema",
                        "name": "Child",
                        "strict": true,
                        "schema": [
                            "type": "object",
                            "properties": [
                            "name": ["type": "string"]
                            ],
                            "required": ["name"],
                            "additionalProperties": false
                        ]
                    ]
                }
            }
            struct Parent {
                var id: String
                var child: Child

                static var openAISchema: [String: Any] {
                    [
                        "type": "json_schema",
                        "name": "Parent",
                        "strict": true,
                        "schema": [
                            "type": "object",
                            "properties": [
                            "id": ["type": "string"],
                            "child": Child.openAISchema["schema"] as! [String: Any]
                            ],
                            "required": ["id", "child"],
                            "additionalProperties": false
                        ]
                    ]
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testStructWithMixedTypes() throws {
        #if canImport(OpenAIGenerableMacros)
        assertMacroExpansion(
            """
            @OpenAIScheme
            struct MixedData {
                var name: String
                var age: Int
                var score: Double
            }
            """,
            expandedSource: """
            struct MixedData {
                var name: String
                var age: Int
                var score: Double

                static var openAISchema: [String: Any] {
                    [
                        "type": "json_schema",
                        "name": "MixedData",
                        "strict": true,
                        "schema": [
                            "type": "object",
                            "properties": [
                            "name": ["type": "string"],
                            "age": ["type": "integer"],
                            "score": ["type": "number"]
                            ],
                            "required": ["name", "age", "score"],
                            "additionalProperties": false
                        ]
                    ]
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
