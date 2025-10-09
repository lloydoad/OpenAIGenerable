import OpenAIGenerable
import Foundation

// Example 1: Simple struct with primitives
@OpenAIScheme(description: "A person entity")
struct Person {
    @OpenAIProperty(description: "Full name")
    var name: String
    @OpenAIProperty(description: "Age in years")
    var age: Int
}

// Example 2: Simple enum
@OpenAIScheme(description: "Task priority levels")
enum Priority {
    case low
    case medium
    case high
}

// Example 3: Enum with associated values
@OpenAIScheme(description: "Result type for operations")
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
@OpenAIScheme(description: "used to represent the state of a task")
enum Status {
    case pending
    case completed(Result)
}

@OpenAIScheme(description: "Work task. usually the smallest unit of work")
struct Task {
    @OpenAIProperty(description: "summary title, should be less that 10 words")
    var title: String
    @OpenAIProperty(description: "name of developer(s) working on task")
    var assignees: [String]
    @OpenAIProperty(description: "state of task")
    var status: Status
}

@OpenAIScheme(description: "Work task. usually the smallest unit of work")
struct ComplexTask {
    @OpenAIProperty(description: "summary title, should be less that 10 words")
    var title: String
    @OpenAIProperty(description: "developer(s) working on task")
    var assignees: [Person]
    @OpenAIProperty(description: "state of task")
    var status: Status
}

// Example 6: Optional properties
@OpenAIScheme(description: "User profile with optional fields")
struct UserProfile {
    @OpenAIProperty(description: "User's unique identifier")
    var id: String
    @OpenAIProperty(description: "User's full name")
    var name: String
    @OpenAIProperty(description: "User's email address (optional)")
    var email: String?
    @OpenAIProperty(description: "User's age (optional)")
    var age: Int?
    @OpenAIProperty(description: "User's bio (optional)")
    var bio: String?
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
printSchema(name: "ComplexTask", schema: ComplexTask.openAISchema)
printSchema(name: "UserProfile", schema: UserProfile.openAISchema)