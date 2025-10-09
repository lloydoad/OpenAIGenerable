// The Swift Programming Language
// https://docs.swift.org/swift-book

/// A protocol that types must conform to when they provide an OpenAI JSON schema.
public protocol OpenAISchemaProviding {
    /// The OpenAI-compliant JSON schema for this type.
    nonisolated static var openAISchema: [String: Any] { get }
}

/// A macro that generates a JSON schema representation for a struct or enum.
///
/// The `@OpenAIGenerable` macro can be applied to structs or enums to automatically
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
public macro OpenAIGenerable(description: String? = nil) = #externalMacro(module: "OpenAIModelsMacros", type: "OpenAISchemaMacro")

/// A macro that adds a description to a property for OpenAI schema generation.
///
/// The `@OpenAIGuide` macro is a peer macro that attaches metadata to properties.
/// It works in conjunction with `@OpenAIGenerable` to include property descriptions
/// in the generated JSON schema.
///
/// - Parameter description: A description of the property
@attached(peer)
public macro OpenAIGuide(description: String) = #externalMacro(module: "OpenAIModelsMacros", type: "OpenAIPropertyMacro")