import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(OpenAIGenerableMacros)
import OpenAIGenerableMacros

let testMacros: [String: Macro.Type] = [
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

    func testArrayFields() throws {
        #if canImport(OpenAIGenerableMacros)
        assertMacroExpansion(
            """
            @OpenAIScheme
            struct ArrayExample {
                var tags: [String]
                var scores: [Int]
                var values: [Double]
            }
            """,
            expandedSource: """
            struct ArrayExample {
                var tags: [String]
                var scores: [Int]
                var values: [Double]

                static var openAISchema: [String: Any] {
                    [
                        "type": "json_schema",
                        "name": "ArrayExample",
                        "strict": true,
                        "schema": [
                            "type": "object",
                            "properties": [
                            "tags": ["type": "array", "items": ["type": "string"]],
                            "scores": ["type": "array", "items": ["type": "integer"]],
                            "values": ["type": "array", "items": ["type": "number"]]
                            ],
                            "required": ["tags", "scores", "values"],
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

    func testArrayOfCustomTypes() throws {
        #if canImport(OpenAIGenerableMacros)
        assertMacroExpansion(
            """
            @OpenAIScheme
            struct Person {
                var name: String
            }

            @OpenAIScheme
            struct Team {
                var members: [Person]
            }
            """,
            expandedSource: """
            struct Person {
                var name: String

                static var openAISchema: [String: Any] {
                    [
                        "type": "json_schema",
                        "name": "Person",
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
            struct Team {
                var members: [Person]

                static var openAISchema: [String: Any] {
                    [
                        "type": "json_schema",
                        "name": "Team",
                        "strict": true,
                        "schema": [
                            "type": "object",
                            "properties": [
                            "members": ["type": "array", "items": Person.openAISchema["schema"] as! [String: Any]]
                            ],
                            "required": ["members"],
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

    func testComplexNestedEnums() throws {
        #if canImport(OpenAIGenerableMacros)
        assertMacroExpansion(
            """
            @OpenAIScheme
            enum GarageTool {
                case scissors
                case screw
            }

            @OpenAIScheme
            enum GardenTool {
                case shovel
                case spade
            }

            @OpenAIScheme
            enum HouseTool {
                case garden(GardenTool)
                case garage(GarageTool)
            }

            @OpenAIScheme
            enum Quantity {
                case count(Int)
                case pounds(Double)
            }

            @OpenAIScheme
            struct Inventory {
                var quantity: Quantity
                var houseTool: HouseTool
            }
            """,
            expandedSource: """
            enum GarageTool {
                case scissors
                case screw

                static var openAISchema: [String: Any] {
                    [
                        "type": "json_schema",
                        "name": "GarageTool",
                        "strict": true,
                        "schema": [
                            "type": "string",
                            "enum": ["scissors", "screw"]
                        ]
                    ]
                }
            }
            enum GardenTool {
                case shovel
                case spade

                static var openAISchema: [String: Any] {
                    [
                        "type": "json_schema",
                        "name": "GardenTool",
                        "strict": true,
                        "schema": [
                            "type": "string",
                            "enum": ["shovel", "spade"]
                        ]
                    ]
                }
            }
            enum HouseTool {
                case garden(GardenTool)
                case garage(GarageTool)

                static var openAISchema: [String: Any] {
                    [
                        "type": "json_schema",
                        "name": "HouseTool",
                        "strict": true,
                        "schema": [
                            "anyOf": [
                            [
                                    "type": "object",
                                    "properties": [
                                        "garden": [
                                            "type": "object",
                                            "properties": [
                                            "_0": GardenTool.openAISchema["schema"] as! [String: Any]
                                            ],
                                            "required": ["_0"],
                                            "additionalProperties": false
                                        ]
                                    ],
                                    "required": ["garden"],
                                    "additionalProperties": false
                                ],
                            [
                                    "type": "object",
                                    "properties": [
                                        "garage": [
                                            "type": "object",
                                            "properties": [
                                            "_0": GarageTool.openAISchema["schema"] as! [String: Any]
                                            ],
                                            "required": ["_0"],
                                            "additionalProperties": false
                                        ]
                                    ],
                                    "required": ["garage"],
                                    "additionalProperties": false
                                ]
                            ]
                        ]
                    ]
                }
            }
            enum Quantity {
                case count(Int)
                case pounds(Double)

                static var openAISchema: [String: Any] {
                    [
                        "type": "json_schema",
                        "name": "Quantity",
                        "strict": true,
                        "schema": [
                            "anyOf": [
                            [
                                    "type": "object",
                                    "properties": [
                                        "count": [
                                            "type": "object",
                                            "properties": [
                                            "_0": ["type": "integer"]
                                            ],
                                            "required": ["_0"],
                                            "additionalProperties": false
                                        ]
                                    ],
                                    "required": ["count"],
                                    "additionalProperties": false
                                ],
                            [
                                    "type": "object",
                                    "properties": [
                                        "pounds": [
                                            "type": "object",
                                            "properties": [
                                            "_0": ["type": "number"]
                                            ],
                                            "required": ["_0"],
                                            "additionalProperties": false
                                        ]
                                    ],
                                    "required": ["pounds"],
                                    "additionalProperties": false
                                ]
                            ]
                        ]
                    ]
                }
            }
            struct Inventory {
                var quantity: Quantity
                var houseTool: HouseTool

                static var openAISchema: [String: Any] {
                    [
                        "type": "json_schema",
                        "name": "Inventory",
                        "strict": true,
                        "schema": [
                            "type": "object",
                            "properties": [
                            "quantity": Quantity.openAISchema["schema"] as! [String: Any],
                            "houseTool": HouseTool.openAISchema["schema"] as! [String: Any]
                            ],
                            "required": ["quantity", "houseTool"],
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
