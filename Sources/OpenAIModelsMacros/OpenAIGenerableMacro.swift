import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import Foundation

/// An enumeration representing errors that can occur during macro processing.
enum MacroError: Error, CustomStringConvertible {
    /// Error indicating that the macro was applied to a declaration that is not a struct or enum.
    case notAStruct

    /// A textual description of the error.
    var description: String {
        switch self {
        case .notAStruct:
            return "@OpenAIGenerable can only be applied to structs or enums"
        }
    }
}

/// A peer macro that adds description metadata to properties.
///
/// This macro doesn't generate any code itself, but the `@OpenAISchemaMacro`
/// reads these attributes during expansion to include property descriptions.
public struct OpenAIPropertyMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // This macro doesn't generate code, it just attaches metadata
        return []
    }
}

/// A macro that generates a JSON schema representation for a struct or enum.
///
/// The `OpenAISchemaMacro` is responsible for expanding the `@OpenAIScheme` attribute
/// into a static `openAISchema` property. This property provides a JSON schema
/// that describes the structure and types of the fields within the struct or enum.
///
/// - Note: This macro currently supports:
///     - structs
///     - enums (string enums + associated values)
public struct OpenAISchemaMacro: MemberMacro, ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        // Create an extension that adds OpenAISchemaProviding conformance
        let extensionDecl: DeclSyntax =
            """
            extension \(type.trimmed): OpenAISchemaProviding {}
            """

        return [extensionDecl.cast(ExtensionDeclSyntax.self)]
    }

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Extract description from @OpenAIScheme(description: "...")
        let typeDescription = extractDescription(from: node)

        // Check if it's an enum
        if let enumDecl = declaration.as(EnumDeclSyntax.self) {
            return try expandEnum(enumDecl: enumDecl, typeDescription: typeDescription)
        }

        // Check if it's a struct
        if let structDecl = declaration.as(StructDeclSyntax.self) {
            return try expandStruct(structDecl: structDecl, typeDescription: typeDescription)
        }

        throw MacroError.notAStruct
    }

    /// Extract the description parameter from the @OpenAIScheme attribute
    private static func extractDescription(from node: AttributeSyntax) -> String? {
        guard let arguments = node.arguments,
              let labeledArguments = arguments.as(LabeledExprListSyntax.self) else {
            return nil
        }

        for argument in labeledArguments {
            if argument.label?.text == "description",
               let stringLiteral = argument.expression.as(StringLiteralExprSyntax.self),
               let segment = stringLiteral.segments.first,
               let stringSegment = segment.as(StringSegmentSyntax.self) {
                return stringSegment.content.text
            }
        }

        return nil
    }

    /// Extract description from @OpenAIGuide attribute on a variable
    private static func extractPropertyDescription(from varDecl: VariableDeclSyntax) -> String? {
        for attribute in varDecl.attributes {
            guard let customAttribute = attribute.as(AttributeSyntax.self),
                  let identifier = customAttribute.attributeName.as(IdentifierTypeSyntax.self),
                  identifier.name.text == "OpenAIGuide",
                  let arguments = customAttribute.arguments,
                  let labeledArguments = arguments.as(LabeledExprListSyntax.self) else {
                continue
            }

            for argument in labeledArguments {
                if argument.label?.text == "description",
                   let stringLiteral = argument.expression.as(StringLiteralExprSyntax.self),
                   let segment = stringLiteral.segments.first,
                   let stringSegment = segment.as(StringSegmentSyntax.self) {
                    return stringSegment.content.text
                }
            }
        }

        return nil
    }

    private static func expandEnum(enumDecl: EnumDeclSyntax, typeDescription: String?) throws -> [DeclSyntax] {
        let enumName = enumDecl.name.text

        // Extract enum cases
        let members = enumDecl.memberBlock.members
        var simpleCases: [String] = []
        var associatedCases: [(name: String, params: [(label: String, type: String)])] = []

        for member in members {
            guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else {
                continue
            }

            for element in caseDecl.elements {
                let caseName = element.name.text

                // Check if case has associated values
                if let paramClause = element.parameterClause {
                    var params: [(label: String, type: String)] = []

                    for (index, param) in paramClause.parameters.enumerated() {
                        let label = param.firstName?.text ?? "_\(index)"
                        let type = param.type.description.trimmingCharacters(in: .whitespaces)
                        params.append((label: label, type: type))
                    }

                    associatedCases.append((name: caseName, params: params))
                } else {
                    simpleCases.append(caseName)
                }
            }
        }

        // If all cases are simple, generate string enum
        if associatedCases.isEmpty {
            let enumValues = simpleCases.map { "\"\($0)\"" }.joined(separator: ", ")

            // Add description if provided
            let descriptionField = typeDescription.map { ",\n\t\t\t\"description\": \"\($0)\"" } ?? ""

            let schemaCode = """
                nonisolated public static var openAISchema: [String: Any] {
                [
                    "type": "json_schema",
                    "name": "\(enumName)",
                    "strict": true,
                    "schema": [
                        "type": "string",
                        "enum": [\(enumValues)]\(descriptionField)
                    ]
                ]
            }
            """

            return [DeclSyntax(stringLiteral: schemaCode)]
        }

        // Generate anyOf structure for associated values
        let anyOfCases = associatedCases.map { caseName, params in
            let properties = params.map { label, type in
                let typeInfo = mapSwiftTypeToJSONType(type)
                if typeInfo.jsonType == "object" || typeInfo.jsonType == "enum" {
                    return "\"\(label)\": \(type).openAISchema[\"schema\"] as! [String: Any]"
                } else {
                    return "\"\(label)\": [\"type\": \"\(typeInfo.jsonType)\"]"
                }
            }.joined(separator: ",\n\t\t\t\t\t")

            let requiredFields = params.map { "\"\($0.label)\"" }.joined(separator: ", ")

            // Add type description to the case property if provided
            let caseDescriptionField = typeDescription.map { ",\n\t\t\t\t\t\t\"description\": \"\($0)\"" } ?? ""

            return """
            [
                    "type": "object",
                    "properties": [
                        "\(caseName)": [
                            "type": "object",
                            "properties": [
                            \(properties)
                            ],
                            "required": [\(requiredFields)],
                            "additionalProperties": false\(caseDescriptionField)
                        ]
                    ],
                    "required": ["\(caseName)"],
                    "additionalProperties": false
                ]
            """
        }.joined(separator: ",\n\t\t")

        let schemaCode = """
            nonisolated public static var openAISchema: [String: Any] {
            [
                "type": "json_schema",
                "name": "\(enumName)",
                "strict": true,
                "schema": [
                    "anyOf": [
                    \(anyOfCases)
                    ]
                ]
            ]
        }
        """

        return [DeclSyntax(stringLiteral: schemaCode)]
    }

    private static func expandStruct(structDecl: StructDeclSyntax, typeDescription: String?) throws -> [DeclSyntax] {
        // 2. Get the struct name
        let structName = structDecl.name.text

        // 3. Extract all stored properties with descriptions
        let members = structDecl.memberBlock.members
        var properties: [(name: String, type: String, description: String?, isOptional: Bool)] = []

        for member in members {
              guard let varDecl = member.decl.as(VariableDeclSyntax.self) else {
                  continue
              }

              // Extract property description from @OpenAIProperty attribute
              let propertyDescription = extractPropertyDescription(from: varDecl)

              // Get property name and type
              for binding in varDecl.bindings {
                  guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self),
                        let typeAnnotation = binding.typeAnnotation else {
                      continue
                  }

                  let propertyName = identifier.identifier.text
                  var propertyType = typeAnnotation.type.description.trimmingCharacters(in: .whitespaces)

                  // Check if the type is Optional (wrapped in Optional<T> or T?)
                  let isOptional = propertyType.hasSuffix("?") || propertyType.hasPrefix("Optional<")

                  // Unwrap optional type to get the base type
                  if propertyType.hasSuffix("?") {
                      propertyType = String(propertyType.dropLast()).trimmingCharacters(in: .whitespaces)
                  } else if propertyType.hasPrefix("Optional<") && propertyType.hasSuffix(">") {
                      propertyType = String(propertyType.dropFirst(9).dropLast()).trimmingCharacters(in: .whitespaces)
                  }

                  properties.append((name: propertyName, type: propertyType, description: propertyDescription, isOptional: isOptional))
              }
        }

        // 4. Generate the schema properties dictionary
        let propertiesEntries = properties.map { prop in
            let typeInfo = mapSwiftTypeToJSONType(prop.type)
            let descriptionField = prop.description.map { ", \"description\": \"\($0)\"" } ?? ""

            if typeInfo.isArray {
                // Handle array types
                guard let elementType = typeInfo.elementType else {
                    let typeField = prop.isOptional ? "[\"array\", \"null\"]" : "\"array\""
                    return "\"\(prop.name)\": [\"type\": \(typeField), \"items\": [:]\(descriptionField)]"
                }

                let elementTypeInfo = mapSwiftTypeToJSONType(elementType)

                if elementTypeInfo.jsonType == "object" || elementTypeInfo.jsonType == "enum" {
                    // Array of custom types - need to build the array schema properly
                    let typeField = prop.isOptional ? "[\"array\", \"null\"]" : "\"array\""
                    if let desc = prop.description {
                        return "\"\(prop.name)\": [\"type\": \(typeField), \"items\": \(elementType).openAISchema[\"schema\"] as! [String: Any], \"description\": \"\(desc)\"]"
                    } else {
                        return "\"\(prop.name)\": [\"type\": \(typeField), \"items\": \(elementType).openAISchema[\"schema\"] as! [String: Any]]"
                    }
                } else {
                    // Array of primitives
                    let typeField = prop.isOptional ? "[\"array\", \"null\"]" : "\"array\""
                    return "\"\(prop.name)\": [\"type\": \(typeField), \"items\": [\"type\": \"\(elementTypeInfo.jsonType)\"]\(descriptionField)]"
                }
            } else if typeInfo.jsonType == "object" || typeInfo.jsonType == "enum" {
                // For custom types (structs/enums), reference their schema
                if prop.isOptional {
                    // For optional custom types, we need to add null to the anyOf or wrap in anyOf
                    let baseSchema = "\(prop.type).openAISchema[\"schema\"] as! [String: Any]"
                    if let desc = prop.description {
                        return "\"\(prop.name)\": ([\"description\": \"\(desc)\", \"anyOf\": [\(baseSchema), [\"type\": \"null\"]]] as [String: Any])"
                    } else {
                        return "\"\(prop.name)\": [\"anyOf\": [\(baseSchema), [\"type\": \"null\"]]]"
                    }
                } else {
                    // Non-optional custom types
                    if let desc = prop.description {
                        return "\"\(prop.name)\": ([\"description\": \"\(desc)\"] as [String: Any]).merging(\(prop.type).openAISchema[\"schema\"] as! [String: Any]) { current, _ in current }"
                    } else {
                        return "\"\(prop.name)\": \(prop.type).openAISchema[\"schema\"] as! [String: Any]"
                    }
                }
            } else {
                // For primitives, use simple type
                let typeField = prop.isOptional ? "[\"\(typeInfo.jsonType)\", \"null\"]" : "\"\(typeInfo.jsonType)\""
                return "\"\(prop.name)\": [\"type\": \(typeField)\(descriptionField)]"
            }
        }.joined(separator: ",\n\t\t")

         // 5. Generate the required array
        let requiredFields = properties.map { "\"\($0.name)\"" }.joined(separator: ", ")

        // 6. Add type description if provided
        let descriptionField = typeDescription.map { ",\n\t\t\t\"description\": \"\($0)\"" } ?? ""

        // 7. Generate the complete schema code
        let schemaCode =
        """
            nonisolated public static var openAISchema: [String: Any] {
            [
                "type": "json_schema",
                "name": "\(structName)",
                "strict": true,
                "schema": [
                    "type": "object",
                    "properties": [
                    \(propertiesEntries)
                    ],
                    "required": [\(requiredFields)],
                    "additionalProperties": false\(descriptionField)
                ]
            ]
        }
        """

        return [DeclSyntax(stringLiteral: schemaCode)]
    }

      // Helper: Map Swift types to JSON Schema types
      private static func mapSwiftTypeToJSONType(_ swiftType: String) -> (jsonType: String, isArray: Bool, elementType: String?) {
          // Check if it's an array
          if swiftType.hasPrefix("[") && swiftType.hasSuffix("]") {
              let elementType = String(swiftType.dropFirst().dropLast()).trimmingCharacters(in: .whitespaces)
              return ("array", true, elementType)
          }

          // Handle primitives
          switch swiftType {
          case "String":
              return ("string", false, nil)
          case "Int", "Int8", "Int16", "Int32", "Int64":
              return ("integer", false, nil)
          case "Double", "Float", "CGFloat":
              return ("number", false, nil)
          case "Bool":
              return ("boolean", false, nil)
          default:
              return ("object", false, nil) // For custom types
          }
      }
}

@main
struct OpenAIGenerablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        OpenAISchemaMacro.self,
        OpenAIPropertyMacro.self
    ]
}
