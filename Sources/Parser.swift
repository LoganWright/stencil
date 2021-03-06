public func until(_ tags: [String]) -> ((TokenParser, Token) -> Bool) {
  return { parser, token in
    if let name = token.components().first {
      for tag in tags {
        if name == tag {
          return true
        }
      }
    }
    
    return false
  }
}

public typealias Filter = Any? throws -> Any?

/// A class for parsing an array of tokens and converts them into a collection of Node's
public class TokenParser {
  public typealias TagParser = (TokenParser, Token) throws -> NodeType
  
  private var tokens: [Token]
  private let namespace: Namespace
  
  public init(tokens: [Token], namespace: Namespace) {
    self.tokens = tokens
    self.namespace = namespace
  }
  
  /// Parse the given tokens into nodes
  public func parse() throws -> [NodeType] {
    return try parse(nil)
  }
  
  public func parse(_ parse_until:((parser:TokenParser, token:Token) -> (Bool))?) throws -> [NodeType] {
    var nodes = [NodeType]()
    
    while tokens.count > 0 {
      let token = nextToken()!
      
      switch token {
      case .Text(let text):
        nodes.append(TextNode(text: text))
      case .Variable:
        nodes.append(VariableNode(variable: try compileFilter(token.contents)))
      case .Block:
        let tag = token.components().first
        
        if let parse_until = parse_until where parse_until(parser: self, token: token) {
          prependToken(token)
          return nodes
        }
        
        if let tag = tag {
          if let parser = namespace.tags[tag] {
            nodes.append(try parser(self, token))
          } else {
            throw TemplateSyntaxError("Unknown template tag '\(tag)'")
          }
        }
      case .Comment:
        continue
      }
    }
    
    return nodes
  }
  
  public func nextToken() -> Token? {
    if tokens.count > 0 {
      #if !swift(>=3.0)
        return tokens.removeAtIndex(0)
      #else
        return tokens.remove(at:0)
      #endif
    }
    
    return nil
  }
  
  public func prependToken(_ token:Token) {
    #if !swift(>=3.0)
      tokens.insert(token, atIndex: 0)
    #else
      tokens.insert(token, at: 0)
    #endif
    
  }
  
  public func findFilter(_ name: String) throws -> Filter {
    if let filter = namespace.filters[name] {
      return filter
    }
    
    throw TemplateSyntaxError("Invalid filter '\(name)'")
  }
  
  func compileFilter(_ token: String) throws -> Resolvable {
    return try FilterExpression(token: token, parser: self)
  }
}
