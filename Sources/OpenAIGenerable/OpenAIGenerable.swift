// The Swift Programming Language
// https://docs.swift.org/swift-book

/// A protocol that types must conform to when they provide an OpenAI JSON schema.
public protocol OpenAISchemaProviding {
    /// The OpenAI-compliant JSON schema for this type.
    nonisolated static var openAISchema: [String: Any] { get }
}

/// A macro that generates a JSON schema representation for a struct or enum.
///
/// The `@OpenAIScheme` macro can be applied to structs or enums to automatically
/// generate a static `openAISchema` property. This property provides a JSON schema
/// that describes the structure and types of the fields within the struct or enum.
///
/// The macro also makes the type conform to `OpenAISchemaProviding`.
///
/// - Parameter description: An optional description of the type
///
/// - Note: This macro currently supports:
///     - structs
///     - enums (string enums + associated values)
@attached(member, names: named(openAISchema))
@attached(extension, conformances: OpenAISchemaProviding)
public macro OpenAIScheme(description: String? = nil) = #externalMacro(module: "OpenAIGenerableMacros", type: "OpenAISchemaMacro")

/// A macro that adds a description to a property for OpenAI schema generation.
///
/// The `@OpenAIProperty` macro is a peer macro that attaches metadata to properties.
/// It works in conjunction with `@OpenAIScheme` to include property descriptions
/// in the generated JSON schema.
///
/// - Parameter description: A description of the property
@attached(peer)
public macro OpenAIProperty(description: String) = #externalMacro(module: "OpenAIGenerableMacros", type: "OpenAIPropertyMacro")

public extension Array where Element: OpenAISchemaProviding {
    nonisolated static var openAISchema: [String: Any] {
        return [
            "type": "array",
            "items": Element.openAISchema
        ]
    }
}