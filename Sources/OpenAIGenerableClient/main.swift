import OpenAIGenerable
import Foundation

// Example 1: Simple struct with primitives
@OpenAIScheme
struct Person {
    var name: String
    var age: Int
}

// Example 2: Simple enum
@OpenAIScheme
enum Priority {
    case low
    case medium
    case high
}

// Example 3: Enum with associated values
@OpenAIScheme
enum Result {
    case success(String)
    case error(code: Int, message: String)
}

// Example 4: Arrays
@OpenAIScheme
struct Team {
    var name: String
    var members: [Person]
    var priorities: [Priority]
}

// Example 5: Complex nested structure
@OpenAIScheme
enum Status {
    case pending
    case completed(Result)
}

@OpenAIScheme
struct Task {
    var title: String
    var assignees: [String]
    var status: Status
}

// Helper function to convert schema to pretty JSON string
func printSchema(name: String, schema: [String: Any]) {
    print("=== \(name) Schema ===")
    if let jsonData = try? JSONSerialization.data(withJSONObject: schema, options: [.prettyPrinted, .sortedKeys]),
       let jsonString = String(data: jsonData, encoding: .utf8) {
        print(jsonString)
    } else {
        print("Failed to convert schema to JSON")
    }
    print()
}

// Print the schemas
printSchema(name: "Person", schema: Person.openAISchema)
printSchema(name: "Priority", schema: Priority.openAISchema)
printSchema(name: "Result", schema: Result.openAISchema)
printSchema(name: "Team", schema: Team.openAISchema)
printSchema(name: "Task", schema: Task.openAISchema)
