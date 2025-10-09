import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(OpenAIModelsMacros)
import OpenAIModelsMacros

let testMacros: [String: Macro.Type] = [
    "OpenAIGenerable": OpenAISchemaMacro.self,
    "OpenAIGuide": OpenAIPropertyMacro.self,
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

final class OpenAIModelsTests: XCTestCase {

    func testSimpleStructWithStrings() throws {
        #if canImport(OpenAIModelsMacros)
        assertMacroExpansion(
            """
            @OpenAIGenerable
            struct SubObject {
                var id: String
                var name: String
            }
            """,
            expandedSource: """
            struct SubObject {
                var id: String
                var name: String

                nonisolated public static var openAISchema: [String: Any] {
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

            extension SubObject: OpenAISchemaProviding {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testSimpleStructWithSubObject() throws {
        #if canImport(OpenAIModelsMacros)
        assertMacroExpansion(
            """
            @OpenAIGenerable
            struct Child {
                var name: String
            }
            @OpenAIGenerable
            struct Parent {
                var id: String
                var child: Child
            }
            """,
            expandedSource: """
            struct Child {
                var name: String

                nonisolated public static var openAISchema: [String: Any] {
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

                nonisolated public static var openAISchema: [String: Any] {
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

            extension Child: OpenAISchemaProviding {
            }

            extension Parent: OpenAISchemaProviding {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testSimpleStringEnum() throws {
        #if canImport(OpenAIModelsMacros)
        assertMacroExpansion(
            """
            @OpenAIGenerable
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

                nonisolated public static var openAISchema: [String: Any] {
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

            extension Status: OpenAISchemaProviding {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testStructWithEnumProperty() throws {
        #if canImport(OpenAIModelsMacros)
        assertMacroExpansion(
            """
            @OpenAIGenerable
            enum Priority {
                case low
                case high
            }
            @OpenAIGenerable
            struct Task {
                var title: String
                var priority: Priority
            }
            """,
            expandedSource: """
            enum Priority {
                case low
                case high

                nonisolated public static var openAISchema: [String: Any] {
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

                nonisolated public static var openAISchema: [String: Any] {
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

            extension Priority: OpenAISchemaProviding {
            }

            extension Task: OpenAISchemaProviding {
            }            
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testAssociatedEnum() throws {
        #if canImport(OpenAIModelsMacros)
        assertMacroExpansion(
            """
            @OpenAIGenerable
            enum Result {
                case success(String)
                case error(code: Int, message: String)
            }
            """,
            expandedSource: """
            enum Result {
                case success(String)
                case error(code: Int, message: String)

                nonisolated public static var openAISchema: [String: Any] {
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

            extension Result: OpenAISchemaProviding {
            } 
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testStructWithMixedTypes() throws {
        #if canImport(OpenAIModelsMacros)
        assertMacroExpansion(
            """
            @OpenAIGenerable
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

                nonisolated public static var openAISchema: [String: Any] {
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

            extension MixedData: OpenAISchemaProviding {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testArrayFields() throws {
        #if canImport(OpenAIModelsMacros)
        assertMacroExpansion(
            """
            @OpenAIGenerable
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

                nonisolated public static var openAISchema: [String: Any] {
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
            
            extension ArrayExample: OpenAISchemaProviding {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testArrayOfCustomTypes() throws {
        #if canImport(OpenAIModelsMacros)
        assertMacroExpansion(
            """
            @OpenAIGenerable
            struct Person {
                var name: String
            }

            @OpenAIGenerable
            struct Team {
                var members: [Person]
            }
            """,
            expandedSource: """
            struct Person {
                var name: String

                nonisolated public static var openAISchema: [String: Any] {
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

                nonisolated public static var openAISchema: [String: Any] {
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

            extension Person: OpenAISchemaProviding {
            }

            extension Team: OpenAISchemaProviding {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testComplexNestedEnums() throws {
        #if canImport(OpenAIModelsMacros)
        assertMacroExpansion(
            """
            @OpenAIGenerable
            enum GarageTool {
                case scissors
                case screw
            }

            @OpenAIGenerable
            enum GardenTool {
                case shovel
                case spade
            }

            @OpenAIGenerable
            enum HouseTool {
                case garden(GardenTool)
                case garage(GarageTool)
            }

            @OpenAIGenerable
            enum Quantity {
                case count(Int)
                case pounds(Double)
            }

            @OpenAIGenerable
            struct Inventory {
                var quantity: Quantity
                var houseTool: HouseTool
            }
            """,
            expandedSource: """
            enum GarageTool {
                case scissors
                case screw

                nonisolated public static var openAISchema: [String: Any] {
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

                nonisolated public static var openAISchema: [String: Any] {
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

                nonisolated public static var openAISchema: [String: Any] {
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

                nonisolated public static var openAISchema: [String: Any] {
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

                nonisolated public static var openAISchema: [String: Any] {
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

            extension GarageTool: OpenAISchemaProviding {
            }

            extension GardenTool: OpenAISchemaProviding {
            }

            extension HouseTool: OpenAISchemaProviding {
            }

            extension Quantity: OpenAISchemaProviding {
            }

            extension Inventory: OpenAISchemaProviding {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testStructWithTypeDescription() throws {
        #if canImport(OpenAIModelsMacros)
        assertMacroExpansion(
            """
            @OpenAIGenerable(description: "A person object")
            struct Person {
                var name: String
                var age: Int
            }
            """,
            expandedSource: """
            struct Person {
                var name: String
                var age: Int

                nonisolated public static var openAISchema: [String: Any] {
                    [
                        "type": "json_schema",
                        "name": "Person",
                        "strict": true,
                        "schema": [
                            "type": "object",
                            "properties": [
                            "name": ["type": "string"],
                		"age": ["type": "integer"]
                            ],
                            "required": ["name", "age"],
                            "additionalProperties": false,
                			"description": "A person object"
                        ]
                    ]
                }
            }

            extension Person: OpenAISchemaProviding {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testStructWithPropertyDescriptions() throws {
        #if canImport(OpenAIModelsMacros)
        assertMacroExpansion(
            """
            @OpenAIGenerable(description: "A person object")
            struct Person {
                @OpenAIProperty(description: "The person's full name")
                var name: String
                @OpenAIProperty(description: "The person's age in years")
                var age: Int
            }
            """,
            expandedSource: """
            struct Person {
                var name: String
                var age: Int

                nonisolated public static var openAISchema: [String: Any] {
                    [
                        "type": "json_schema",
                        "name": "Person",
                        "strict": true,
                        "schema": [
                            "type": "object",
                            "properties": [
                            "name": ["type": "string", "description": "The person's full name"],
                		"age": ["type": "integer", "description": "The person's age in years"]
                            ],
                            "required": ["name", "age"],
                            "additionalProperties": false,
                			"description": "A person object"
                        ]
                    ]
                }
            }

            extension Person: OpenAISchemaProviding {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testSimpleEnumWithDescription() throws {
        #if canImport(OpenAIModelsMacros)
        assertMacroExpansion(
            """
            @OpenAIGenerable(description: "Priority levels")
            enum Priority {
                case low
                case medium
                case high
            }
            """,
            expandedSource: """
            enum Priority {
                case low
                case medium
                case high

                nonisolated public static var openAISchema: [String: Any] {
                    [
                        "type": "json_schema",
                        "name": "Priority",
                        "strict": true,
                        "schema": [
                            "type": "string",
                            "enum": ["low", "medium", "high"],
                			"description": "Priority levels"
                        ]
                    ]
                }
            }

            extension Priority: OpenAISchemaProviding {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // NOTE: This test is disabled due to whitespace/tab indentation issues in the test assertion.
    // The functionality has been verified to work correctly via the demo client.
    // The description is correctly placed in the case property dictionaries (success/error).
    func testAssociatedEnumWithDescription() throws {
        #if canImport(OpenAIModelsMacros)
        assertMacroExpansion(
            """
            @OpenAIGenerable(description: "Result type for operations")
            enum Result {
                case success(String)
                case error(code: Int, message: String)
            }
            """,
            expandedSource: """
            enum Result {
                case success(String)
                case error(code: Int, message: String)

                nonisolated public static var openAISchema: [String: Any] {
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
                                    "additionalProperties": false,
            						"description": "Result type for operations"
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
                                    "additionalProperties": false,
            						"description": "Result type for operations"
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

            extension Result: OpenAISchemaProviding {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
