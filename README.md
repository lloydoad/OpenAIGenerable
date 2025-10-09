# OpenAISwiftHelper

A Swift macro library that automatically generates OpenAI-compliant JSON schemas for your Swift types using the Structured Outputs format.

## Features

- 🎯 **Automatic Schema Generation**: Convert Swift structs and enums to OpenAI JSON schemas with a simple macro
- 📝 **Property Descriptions**: Add detailed descriptions to guide the AI model
- 🔄 **Complex Type Support**: Handles nested structs, enums with associated values, and arrays
- ✅ **Type Safety**: Leverages Swift's type system for compile-time validation
- 🎭 **Optional Properties**: Support for optional fields using nullable union types
- 🚀 **Zero Runtime Overhead**: All schema generation happens at compile time

## Installation

### Swift Package Manager

Add the following to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/OpenAISwiftHelper.git", from: "1.0.0")
]
```

Then add the dependency to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: ["OpenAIModels"]
)
```

## Usage

### Basic Example

Import the module and annotate your types:

```swift
import OpenAIModels

@OpenAIGenerable(description: "A person entity")
struct Person {
    @OpenAIGuide(description: "Full name")
    var name: String

    @OpenAIGuide(description: "Age in years")
    var age: Int
}

// Access the generated schema
let schema = Person.openAISchema
```

### Simple Enums

```swift
@OpenAIGenerable(description: "Task priority levels")
enum Priority {
    case low
    case medium
    case high
}
```

### Enums with Associated Values

```swift
@OpenAIGenerable(description: "Result type for operations")
enum Result {
    case success(String)
    case error(code: Int, message: String)
}
```

### Nested Types

```swift
@OpenAIGenerable(description: "Work task")
struct Task {
    @OpenAIGuide(description: "Task title")
    var title: String

    @OpenAIGuide(description: "Task priority")
    var priority: Priority

    @OpenAIGuide(description: "Assigned team members")
    var assignees: [Person]
}
```

### Optional Properties

Optional properties are automatically converted to nullable union types:

```swift
@OpenAIGenerable(description: "User profile")
struct UserProfile {
    @OpenAIGuide(description: "User's unique identifier")
    var id: String

    @OpenAIGuide(description: "User's email (optional)")
    var email: String?

    @OpenAIGuide(description: "User's age (optional)")
    var age: Int?
}
```

### Using with OpenAI API

```swift
import Foundation

func makeOpenAIRequest(schema: [String: Any]) async throws {
    let url = URL(string: "https://api.openai.com/v1/responses")!

    let body: [String: Any] = [
        "model": "gpt-4.1-mini",
        "input": [
            [
                "role": "user",
                "content": [
                    [
                        "type": "input_text",
                        "text": "Generate a task"
                    ]
                ]
            ]
        ],
        "text": [
            "format": schema
        ]
    ]

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (data, _) = try await URLSession.shared.data(for: request)
    // Process response...
}

// Use it
try await makeOpenAIRequest(schema: Task.openAISchema)
```

## Macros

### `@OpenAIGenerable`

Applied to structs and enums to generate OpenAI JSON schemas.

**Parameters:**
- `description` (optional): A description of the type that helps guide the AI model

**Example:**
```swift
@OpenAIGenerable(description: "A person entity")
struct Person { ... }
```

### `@OpenAIGuide`

Applied to struct properties to add descriptions.

**Parameters:**
- `description` (required): A description of the property

**Example:**
```swift
@OpenAIGuide(description: "Full name of the person")
var name: String
```

## Generated Schema Format

The generated schemas follow OpenAI's Structured Outputs format:

```json
{
  "type": "json_schema",
  "name": "Person",
  "strict": true,
  "schema": {
    "type": "object",
    "properties": {
      "name": {
        "type": "string",
        "description": "Full name"
      },
      "age": {
        "type": "integer",
        "description": "Age in years"
      }
    },
    "required": ["name", "age"],
    "additionalProperties": false,
    "description": "A person entity"
  }
}
```

## Supported Types

### Primitive Types
- `String` → `"string"`
- `Int`, `Int8`, `Int16`, `Int32`, `Int64` → `"integer"`
- `Double`, `Float`, `CGFloat` → `"number"`
- `Bool` → `"boolean"`

### Complex Types
- Arrays: `[T]` → `{"type": "array", "items": {...}}`
- Custom structs and enums
- Nested types
- Optional types: `T?` → Union type with `null`

## Examples

See the [OpenAISwiftHelperUsageApp](Sources/OpenAISwiftHelperUsageApp/main.swift) for more comprehensive examples including:
- Simple structs with primitives
- Nested structures
- Enums with associated values
- Arrays of custom types
- Optional properties

## Requirements

- Swift 6.0+
- macOS 10.15+ / iOS 13.0+ / tvOS 13.0+ / watchOS 6.0+

## License
[wip]

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Credits

Built with [Swift Macros](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/macros/) and designed for use with [OpenAI's Structured Outputs](https://platform.openai.com/docs/guides/structured-outputs).
