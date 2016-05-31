import Foundation
//import PathKit

#if os(Linux)
let NSFileNoSuchFileError = 4
#endif

/// A class representing a template
public class Template {
  struct Error: ErrorProtocol {}
  let tokens: [Token]
  
  /// Create a template with a file found at the given URL
  public convenience init(URL: String) throws {
    guard let data = NSData(contentsOfFile: URL)?.string else {
        throw Error()
    }

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

extension NSData {
    var string: String {
        return (try? String(data: byteArray)) ?? ""
    }

    public var byteArray: [UInt8] {
        let count = self.length / sizeof(UInt8)
        var bytesArray = [UInt8](repeating: 0, count: count)
        self.getBytes(&bytesArray, length:count * sizeof(UInt8))
        return bytesArray
    }
}

extension String {
    public init(data: [UInt8]) throws {
        struct Error: ErrorProtocol {}
        var string = ""
        var decoder = UTF8()
        var generator = data.makeIterator()

        loop: while true {
            switch decoder.decode(&generator) {
            case .scalarValue(let char): string.append(char)
            case .emptyInput: break loop
            case .error: throw Error()
            }
        }

        self.init(string)
    }
}
