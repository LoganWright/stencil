import Foundation
//import PathKit

#if os(Linux)
let NSFileNoSuchFileError = 4
#endif

/// A class representing a template
public class Template {
  let tokens: [Token]
  
  /// Create a template with a file found at the given URL
  public convenience init(URL: String) throws {
    let data = try String(contentsOfFile: URL)
    self.init(templateString: data)
  }
  
  /// Create a template with a template string
  public init(templateString:String) {
    let lexer = Lexer(templateString: templateString)
    tokens = lexer.tokenize()
  }
  
  /// Render the given template
  public func render(_ context: Context? = nil) throws -> String {
    let context = context ?? Context()
    let parser = TokenParser(tokens: tokens, namespace: context.namespace)
    let nodes = try parser.parse()
    return try renderNodes(nodes, context)
  }
}
