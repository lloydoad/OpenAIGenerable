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

extension String {
    func withoutWhitespaces() -> String {
        self
        .split(separator: "\n")
        .map { $0.trimmingCharacters(in: .whitespaces) } 
        .filter { !$0.isEmpty }
        .joined(separator: " ")
    }
}

final class OpenAIGenerableTests: XCTestCase {

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

    func testSimpleStringEnum() throws {
        #if canImport(OpenAIGenerableMacros)
        assertMacroExpansion(
            """
            @OpenAIScheme
            enum Status {
                case pending
                case approved
                case rejected
            }
            """,
            expandedSource: """
            enum Status {
                case pending
                case approved
                case rejected

                static var openAISchema: [String: Any] {
                    [
                        "type": "json_schema",
                        "name": "Status",
                        "strict": true,
                        "schema": [
                            "type": "string",
                            "enum": ["pending", "approved", "rejected"]
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

    func testStructWithEnumProperty() throws {
        #if canImport(OpenAIGenerableMacros)
        assertMacroExpansion(
            """
            @OpenAIScheme
            enum Priority {
                case low
                case high
            }
            @OpenAIScheme
            struct Task {
                var title: String
                var priority: Priority
            }
            """,
            expandedSource: """
            enum Priority {
                case low
                case high

                static var openAISchema: [String: Any] {
                    [
                        "type": "json_schema",
                        "name": "Priority",
                        "strict": true,
                        "schema": [
                            "type": "string",
                            "enum": ["low", "high"]
                        ]
                    ]
                }
            }
            struct Task {
                var title: String
                var priority: Priority

                static var openAISchema: [String: Any] {
                    [
                        "type": "json_schema",
                        "name": "Task",
                        "strict": true,
                        "schema": [
                            "type": "object",
                            "properties": [
                            "title": ["type": "string"],
                            "priority": Priority.openAISchema["schema"] as! [String: Any]
                            ],
                            "required": ["title", "priority"],
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

    func testAssociatedEnum() throws {
        #if canImport(OpenAIGenerableMacros)
        assertMacroExpansion(
            """
            @OpenAIScheme
            enum Result {
                case success(String)
                case error(code: Int, message: String)
            }
            """,
            expandedSource: """
            enum Result {
                case success(String)
                case error(code: Int, message: String)

                static var openAISchema: [String: Any] {
                    [
                        "type": "json_schema",
                        "name": "Result",
                        "strict": true,
                        "schema": [
                            "anyOf": [
                            [
                                    "type": "object",
                                    "properties": [
                                        "success": [
                                            "type": "object",
                                            "properties": [
                                            "_0": ["type": "string"]
                                            ],
                                            "required": ["_0"],
                                            "additionalProperties": false
                                        ]
                                    ],
                                    "required": ["success"],
                                    "additionalProperties": false
                                ],
                            [
                                    "type": "object",
                                    "properties": [
                                        "error": [
                                            "type": "object",
                                            "properties": [
                                            "code": ["type": "integer"],
                                            "message": ["type": "string"]
                                            ],
                                            "required": ["code", "message"],
                                            "additionalProperties": false
                                        ]
                                    ],
                                    "required": ["error"],
                                    "additionalProperties": false
                                ]
                            ]
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
