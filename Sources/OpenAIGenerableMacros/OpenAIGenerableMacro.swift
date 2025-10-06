import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Implementation of the `stringify` macro, which takes an expression
/// of any type and produces a tuple containing the value of that expression
/// and the source code that produced the value. For example
///
///     #stringify(x + y)
///
///  will expand to
///
///     (x + y, "x + y")
public struct StringifyMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard let argument = node.arguments.first?.expression else {
            fatalError("compiler bug: the macro does not have any arguments")
        }

        return "(\(argument), \(literal: argument.description))"
    }
}

enum MacroError: Error, CustomStringConvertible {
    case notAStruct
    case associatedValuesNotSupported

    var description: String {
        switch self {
        case .notAStruct:
            return "@OpenAIScheme can only be applied to structs or enums"
        case .associatedValuesNotSupported:
            return "@OpenAIScheme does not support enums with associated values yet"
        }
    }
}

public struct OpenAISchemaMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
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
        var cases: [String] = []

        for member in members {
            guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else {
                continue
            }

            for element in caseDecl.elements {
                // Check if case has associated values
                if element.parameterClause != nil {
                    throw MacroError.associatedValuesNotSupported
                }
                cases.append(element.name.text)
            }
        }

        let enumValues = cases.map { "\"\($0)\"" }.joined(separator: ", ")

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
            let jsonType = mapSwiftTypeToJSONType(prop.type)

            if jsonType == "object" || jsonType == "enum" {
                // For custom types (structs/enums), reference their schema
                return "\"\(prop.name)\": \(prop.type).openAISchema[\"schema\"] as! [String: Any]"
            } else {
                // For primitives, use simple type
                return "\"\(prop.name)\": [\"type\": \"\(jsonType)\"]"
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
      private static func mapSwiftTypeToJSONType(_ swiftType: String) -> String {
          switch swiftType {
          case "String":
              return "string"
          case "Int", "Int8", "Int16", "Int32", "Int64":
              return "integer"
          case "Double", "Float", "CGFloat":
              return "number"
          case "Bool":
              return "boolean"
          default:
              return "object" // For custom types
          }
      }
}

@main
struct OpenAIGenerablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StringifyMacro.self,
        OpenAISchemaMacro.self
    ]
}
