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
            return "@OpenAIScheme can only be applied to structs or enums"
        }
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
public struct OpenAISchemaMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Check if it's an enum
        if let enumDecl = declaration.as(EnumDeclSyntax.self) {
            return try expandEnum(enumDecl: enumDecl)
        }

        // Check if it's a struct
        if let structDecl = declaration.as(StructDeclSyntax.self) {
            return try expandStruct(structDecl: structDecl)
        }

        throw MacroError.notAStruct
    }

    private static func expandEnum(enumDecl: EnumDeclSyntax) throws -> [DeclSyntax] {
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

            let schemaCode = """
                static var openAISchema: [String: Any] {
                [
                    "type": "json_schema",
                    "name": "\(enumName)",
                    "strict": true,
                    "schema": [
                        "type": "string",
                        "enum": [\(enumValues)]
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
                            "additionalProperties": false
                        ]
                    ],
                    "required": ["\(caseName)"],
                    "additionalProperties": false
                ]
            """
        }.joined(separator: ",\n\t\t")

        let schemaCode = """
            static var openAISchema: [String: Any] {
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

    private static func expandStruct(structDecl: StructDeclSyntax) throws -> [DeclSyntax] {
        // 2. Get the struct name
        let structName = structDecl.name.text

        // 3. Extract all stored properties
        let members = structDecl.memberBlock.members
        var properties: [(name: String, type: String)] = []

        for member in members {
              guard let varDecl = member.decl.as(VariableDeclSyntax.self) else {
                  continue
              }

              // Get property name and type
              for binding in varDecl.bindings {
                  guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self),
                        let typeAnnotation = binding.typeAnnotation else {
                      continue
                  }

                  let propertyName = identifier.identifier.text
                  let propertyType = typeAnnotation.type.description//.trimmingCharacters(in: .whitespaces)

                  properties.append((name: propertyName, type: propertyType))
              }
        }

        // 4. Generate the schema properties dictionary
        let propertiesEntries = properties.map { prop in
            let typeInfo = mapSwiftTypeToJSONType(prop.type)

            if typeInfo.isArray {
                // Handle array types
                guard let elementType = typeInfo.elementType else {
                    return "\"\(prop.name)\": [\"type\": \"array\", \"items\": [:]]"
                }

                let elementTypeInfo = mapSwiftTypeToJSONType(elementType)

                if elementTypeInfo.jsonType == "object" || elementTypeInfo.jsonType == "enum" {
                    // Array of custom types
                    return "\"\(prop.name)\": [\"type\": \"array\", \"items\": \(elementType).openAISchema[\"schema\"] as! [String: Any]]"
                } else {
                    // Array of primitives
                    return "\"\(prop.name)\": [\"type\": \"array\", \"items\": [\"type\": \"\(elementTypeInfo.jsonType)\"]]"
                }
            } else if typeInfo.jsonType == "object" || typeInfo.jsonType == "enum" {
                // For custom types (structs/enums), reference their schema
                return "\"\(prop.name)\": \(prop.type).openAISchema[\"schema\"] as! [String: Any]"
            } else {
                // For primitives, use simple type
                return "\"\(prop.name)\": [\"type\": \"\(typeInfo.jsonType)\"]"
            }
        }.joined(separator: ",\n\t\t")

         // 5. Generate the required array
        let requiredFields = properties.map { "\"\($0.name)\"" }.joined(separator: ", ")

        // 6. Generate the complete schema code
        let schemaCode =
        """
            static var openAISchema: [String: Any] {
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
                    "additionalProperties": false
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
        OpenAISchemaMacro.self
    ]
}
