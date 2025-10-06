// The Swift Programming Language
// https://docs.swift.org/swift-book

/// A macro that generates a JSON schema representation for a struct or enum.
/// 
/// The `@OpenAIScheme` macro can be applied to structs or enums to automatically
/// generate a static `openAISchema` property. This property provides a JSON schema
/// that describes the structure and types of the fields within the struct or enum.
/// 
/// - Note: This macro currently supports:
///     - structs
///     - enums (string enums + associated values)
@attached(member, names: named(openAISchema))
public macro OpenAIScheme() = #externalMacro(module: "OpenAIGenerableMacros", type: "OpenAISchemaMacro")