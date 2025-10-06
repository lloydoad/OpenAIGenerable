// The Swift Programming Language
// https://docs.swift.org/swift-book

/// A macro that produces both a value and a string containing the
/// source code that generated the value. For example,
///
///     #stringify(x + y)
///
/// produces a tuple `(x + y, "x + y")`.
@freestanding(expression)
public macro stringify<T>(_ value: T) -> (T, String) = #externalMacro(module: "OpenAIGenerableMacros", type: "StringifyMacro")

@attached(member, names: named(openAISchema))
public macro OpenAIScheme() = #externalMacro(module: "OpenAIGenerableMacros", type: "OpenAISchemaMacro")
/*
___
simple case
input ==>

struct SubObject {
  var id: String
  var name: String
}

==> output json 
extension SubObject {
    public var jsonSchema: [String: Any] {
        [
            "name": "SubObject"
            "strict": true,
            "schema": [
                "type": "object",
                "properties": [
                    "id": [
                        "type": "string",
                        "description": "some unique identifier"
                    ]
                    "name": [
                        "type": "string",
                        "description": "some name of the object"
                    ]
                ]
                "required": ["id", "name"],
                "additionalProperties": false
            ]
        ]
    }
}

___


enum AssociatedEnumObject {
   case one(AssociatedType, SecondAssociatedType)
   case two(myKey: AssociatedType)
   case three(ThirdAssociatedType)
}

[
    "anyOf": [
        [
            "type": "object",
            "properties": [
                "one": [
                    "type": "object",
                    "properties": [
                        "_0": AssociatedType.openAISchema["schema"] as! [String: Any],
                        "_1": SecondAssociatedType.openAISchema["schema"] as! [String: Any]
                    ],
                    "required": ["_0", "_1"],
                    "additionalProperties": false
                ],
            ],
            "required": ["one"],
            "additionalProperties": false
        ],
        [
            "type": "object",
            "properties": [
                "two": [
                    "type": "object",
                    "properties": [
                        "myKey": AssociatedType.openAISchema["schema"] as! [String: Any],
                    ],
                    "required": ["myKey"],
                    "additionalProperties": false
                ],
            ],
            "required": ["two"],
            "additionalProperties": false
        ],
        [
            "type": "object",
            "properties": [
                "three": [
                    "type": "object",
                    "properties": [
                        "_0": ThirdAssociatedType.openAISchema["schema"] as! [String: Any],
                    ],
                    "required": ["_0"],
                    "additionalProperties": false
                ],
            ],
            "required": ["three"],
            "additionalProperties": false
        ]
    ]
]

{
    "anyOf": [
        {
            "type": "object",
            "properties": {
                "one": {
                    "type": "object",
                    "properties": {
                        "value": Codable...
                    }
                    "required": ["value"],
                    "additionalProperties": false
                }
            }
            "required": ["one"],
            "additionalProperties": false
        },
        {
            "type": "object",
            "properties": {
                "two": {
                    "type": "object",
                    "properties": {
                        "value": Codable...
                    }
                    "required": ["value"],
                    "additionalProperties": false
                }
            }
            "required": ["two"],
            "additionalProperties": false
        }
    ]
}
____

enum SimpleEnumObject {
    case one
    case two
}

{
   "type": "string",
   "enum": ["one", "two"],
   "description": "some options of the simple enum"
}
____

struct MainObject {
   var id: String
   var stringField: String
   var intField: Int
   var doubleField: Double
   var objectField: SubObject
   var listField: [String|Int|Double|SubObject]
   var optionalField: String?
}

*/