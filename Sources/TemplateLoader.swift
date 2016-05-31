import Foundation


// A class for loading a template from disk
public class TemplateLoader {
  public let paths: [String]

  public init(paths: [String]) {
    self.paths = paths
  }

  public func loadTemplate(_ templateName: String) -> Template? {
    return loadTemplate([templateName])
  }

  public func loadTemplate(_ templateNames: [String]) -> Template? {
    for path in paths {
      for templateName in templateNames {
        let templatePath = path + templateName


        if FileManager.fileAtPath(templatePath).exists {
            if let template = try? Template(URL: templatePath) {
                return template
            }
        }
      }
    }

    return nil
  }
}

class FileManager {
    enum Error: ErrorProtocol {
        case CouldNotOpenFile
        case Unreadable
    }

    static func fileAtPath(_ path: String) -> (exists: Bool, isDirectory: Bool) {
        var isDirectory = false
        var s = stat()
        if lstat(path, &s) >= 0 {
            if (s.st_mode & S_IFMT) == S_IFLNK {
                if stat(path, &s) >= 0 {
                    isDirectory = (s.st_mode & S_IFMT) == S_IFDIR
                } else {
                    return (false, isDirectory)
                }
            } else {
                isDirectory = (s.st_mode & S_IFMT) == S_IFDIR
            }

            // don't chase the link for this magic case -- we might be /Net/foo
            // which is a symlink to /private/Net/foo which is not yet mounted...
            if (s.st_mode & S_IFMT) == S_IFLNK {
                if (s.st_mode & S_ISVTX) == S_ISVTX {
                    return (true, isDirectory)
                }
                // chase the link; too bad if it is a slink to /Net/foo
                stat(path, &s) >= 0
            }
        } else {
            return (false, isDirectory)
        }
        return (true, isDirectory)
    }

    static func expandPath(_ path: String) throws -> String {
        let maybeResult = realpath(path, nil)

        guard let result = maybeResult else {
            throw Error.Unreadable
        }

        defer { free(result) }

        let cstring = String(validatingUTF8: result)

        if let expanded = cstring {
            return expanded
        } else {
            throw Error.Unreadable
        }
    }

    static func contentsOfDirectory(_ path: String) throws -> [String] {
        var gt = glob_t()
        defer { globfree(&gt) }

        let path = try self.expandPath(path).finish("/")
        let pattern = strdup(path + "{*,.*}")

        switch glob(pattern, GLOB_MARK | GLOB_NOSORT | GLOB_BRACE, nil, &gt) {
        case GLOB_NOMATCH:
            return [ ]
        case GLOB_ABORTED:
            throw Error.Unreadable
        default:
            break
        }

        var contents = [String]()
        let count: Int

        #if os(Linux)
            count = Int(gt.gl_pathc)
        #else
            count = Int(gt.gl_matchc)
        #endif

        for i in 0..<count {
            guard let utf8 = gt.gl_pathv[i] else { continue }
            let cstring = String(validatingUTF8: utf8)
            if let path = cstring {
                contents.append(path)
            }
        }
        
        return contents
    }
    
}

extension String {
    func finish(_ input: String) -> String {
        if hasSuffix(input) {
            return input
        } else {
            return self + input
        }
    }
}
