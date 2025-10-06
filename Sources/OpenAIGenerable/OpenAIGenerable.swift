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
   case one(some Codable)
   case two(some Codable)
}

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