// CSTM | Deltara3
// Embrace spaghetti.
// Wow packages suck!!!!


import Foundation
import FoundationNetworking
import ProcessRunner
import Path

// Base64
extension String {
    func b64encode() -> String? {
        return data(using: .utf8)?.base64EncodedString()
    }

    func b64decode() -> String? {
        var st = self;
        if (self.count % 4 <= 2) {
            st += String(repeating: "=", count: (self.count % 4))
        }
        guard let data = Data(base64Encoded: st) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}

// The opposite of eye candy.
func help() {
        print("""
        ⇢ \u{001B}[0;35m🕮  \u{001B}[0;0mUsage: \u{001B}[0;32mcstm \u{001B}[0;31m[subcommand] \u{001B}[0;36m{package(s)}
           \u{001B}[0;35m│
           \u{001B}[0;35m│ \u{001B}[0;0mSubcommands:
           \u{001B}[0;35m│      \u{001B}[0;32mhelp
           \u{001B}[0;35m│      \u{001B}[0;0mDisplays this message.
           \u{001B}[0;35m│
           \u{001B}[0;35m│      \u{001B}[0;32mversion
           \u{001B}[0;35m│      \u{001B}[0;0mDisplays the version number.
           \u{001B}[0;35m│
           \u{001B}[0;35m│      \u{001B}[0;32minstall \u{001B}[0;31m[package(s)]
           \u{001B}[0;35m│      \u{001B}[0;0mInstalls a package or package(s).
           \u{001B}[0;35m│
           \u{001B}[0;35m│      \u{001B}[0;32muninstall \u{001B}[0;31m[package(s)]
           \u{001B}[0;35m│      \u{001B}[0;0mUninstalls a package or package(s).
           \u{001B}[0;35m│
           \u{001B}[0;35m│      \u{001B}[0;32mbuild \u{001B}[0;31m[package]
           \u{001B}[0;35m╰╌     \u{001B}[0;0mBuilds a package.
        """)
}

// Grabs metadata of a package.
func metadata(name: String) -> String {
    do {
        return try String(contentsOf: URL(string: "https://raw.githubusercontent.com/Deltara3/cstm-main/main/packages/\(name).csp")!)
    } catch {
        return "false"
    }
}

func main() {
    // Constants
    #if os(Windows)
        let cmd  = "where"
    #endif
    #if os(Linux) || os(macOS)
        let cmd  = "which"
    #endif

    #if os(Windows)
        let read_cmd = "type"
    #endif
    #if os(Linux) || os(macOS)
        let read_cmd = "cat"
    #endif

    let subcmds  = ["help", "version", "install", "uninstall", "build"]
    let deny     = ["gamescene", "std"]
    let branch   = "\u{001B}[0;35m-swift-rw-dev"
    let ver      = "0.1.0\(branch)"

    var bin_path: String

    do {
        bin_path = try system(command: "\(cmd) spwn", captureOutput: true).standardOutput
    } catch {
        print("⇢ \u{001B}[0;31m✖  \u{001B}[0;0mFailed to run \u{001B}[0;36m\"\(cmd) spwn\"\u{001B}[0;0m, a required command, something went horribly wrong.")
        exit(1)
    }

    var library_path: Path

    do {
        library_path = try Path(bin_path)!.readlink().parent.join("libraries")
    } catch {
        library_path = Path("~")!
        print("⇢ \u{001B}[0;31m✖  \u{001B}[0;0mFailed to locate library path, something went horribly wrong.")
        exit(1)
    }

    let root     = Path.home.join(".cstm")
    let cache    = Path.home.join(".cstm").join("cache")
    let temp     = Path.home.join(".cstm").join("temp")

    struct Expected: Decodable {
        let name      : String
        let id        : String
        let author    : String
        let version   : String
        let source    : String
        let depends   : String
    }

    // Create folders, if required.
    let is_setup = Path.home.join(".cstm").join(".setup")
    if is_setup.isFile == false {
        do {
            try root.mkdir()
            try cache.mkdir()
            try temp.mkdir()
            try root.join(".setup").touch()
            print("⇢ \u{001B}[0;32m✔  \u{001B}[0;0m Successfully initialized folder structure.")
        } catch {
            print("⇢ \u{001B}[0;31m✖  \u{001B}[0;0mFailed to initialize folder structure, something went horribly wrong.")
            exit(1)
        }
    }

    // Determine if there was no subcommand provided.
    if CommandLine.arguments.count == 1 {
        help()
        exit(0)
    }

    // If there was, check if it's valid.
    let subcmd = CommandLine.arguments[1]
    if subcmds.contains(subcmd) == false {
        print("⇢ \u{001B}[0;31m✖  \u{001B}[0;0mSubcommand \u{001B}[0;36m\"\(subcmd)\" \u{001B}[0;0mis not valid.")
        exit(1)
    }

    // Version.
    if subcmd == "version" {
        print("⇢ \u{001B}[0;35m🕮  \u{001B}[0;36mv\(ver)\u{001B}[0;0m")
        exit(0)
    }

    // Help.
    if subcmd == "help" {
        help()
        exit(0)
    }

    // Check if at least one package name was provided.
    if CommandLine.arguments.count == 2 {
        print("⇢ \u{001B}[0;31m✖  \u{001B}[0;0mExpected at least \u{001B}[0;36mone \u{001B}[0;0mpackage to act on.")
        exit(1)
    }

    // If so, get all provided.
    let pkgs = Array(CommandLine.arguments[2 ..< CommandLine.arguments.count])

    if subcmd == "install" {
        var handled     = [String]()
        var sources     = [String]()
        var versions    = [String]()
        var identifiers = [String]()
        var deps        = [String]()
        for i in pkgs {
            print("⇢ \u{001B}[0;35m🕮  \u{001B}[0;0mStarting retrieval of package \u{001B}[0;36m\"\(i)\" \u{001B}[0;0mnow.")
            if handled.contains(i) {
                print("⇢ \u{001B}[0;33m⚠  \u{001B}[0;0mPackage \u{001B}[0;36m\"\(i)\" \u{001B}[0;0malready handled, ignoring.")
            } else {
            let pkgmd = metadata(name: i)
                if pkgmd == "false" {
                    print("⇢ \u{001B}[0;33m⚠  \u{001B}[0;0mPackage \u{001B}[0;36m\"\(i)\" \u{001B}[0;0mnot found, ignoring.")
                } else {
                    print("⇢ \u{001B}[0;32m✔  \u{001B}[0;0mPackage \u{001B}[0;36m\"\(i)\" \u{001B}[0;0mretrieved.")
                    let data = pkgmd.data(using: .utf8)!
                    let table: Expected = try! JSONDecoder().decode(Expected.self, from: data)
                    print("""
                    ⇢ \u{001B}[0;35m🕮  \u{001B}[0;0mPackage table built.
                       \u{001B}[0;35m│      \u{001B}[0;32mName       : \u{001B}[0;36m\"\(table.name)\"
                       \u{001B}[0;35m│      \u{001B}[0;32mIdentifier : \u{001B}[0;36m\"\(table.id)\"
                       \u{001B}[0;35m│      \u{001B}[0;32mAuthor     : \u{001B}[0;36m\"\(table.author)\"
                       \u{001B}[0;35m╰╌     \u{001B}[0;32mVersion    : \u{001B}[0;36m\"\(table.version)\"\u{001B}[0;0m
                    """)
                    handled.append(i)
                    sources.append(table.source)
                    versions.append(table.version)
                    identifiers.append(table.id)

                    if table.depends == "" {
                        print("⇢ \u{001B}[0;35m🕮  \u{001B}[0;0mNo dependencies.")
                    } else {
                        let req_deps = table.depends.components(separatedBy: ";")
                        print("⇢ \u{001B}[0;35m🕮  \u{001B}[0;0mDependencies.")
                        for i in req_deps {
                            if i == req_deps.first {
                                print("   \u{001B}[0;35m│      \u{001B}[0;36m\"\(i)\"\u{001B}[0;0m")
                            } else {
                                print("   \u{001B}[0;35m╰╌     \u{001B}[0;36m\"\(i)\"\u{001B}[0;0m")
                            }
                            if deps.contains(i) == false {
                                deps.append(i)
                            }
                        }
                    }
                }
            }
        }

        var iter = 0
        for i in handled {
            print("⇢ \u{001B}[0;35m🕮  \u{001B}[0;0mInstalling package \u{001B}[0;36m\"\(i)\" \u{001B}[0;0mnow.")
            let splitsrc = sources[iter].components(separatedBy: "|")
            let files = splitsrc[1].components(separatedBy: ";")

            do {
                try library_path.join(splitsrc[0]).mkdir()
            } catch {
                print("⇢ \u{001B}[0;31m✖  \u{001B}[0;0mPackage \u{001B}[0;36m\"\(handled[iter])\" \u{001B}[0;0mcould not be installed, try running with elevated permissions.")
                exit(1)
            }

            for i in files {
                let file = i.components(separatedBy: ":")
                do {
                    try file[0].write(to: library_path.join(file[1].b64decode()!))
                } catch {
                    print("⇢ \u{001B}[0;31m✖  \u{001B}[0;0mPackage \u{001B}[0;36m\"\(handled[iter])\" \u{001B}[0;0mcould not be installed, try running with elevated permissions.")
                    exit(1)
                }
            }

            iter = iter + 1
        }
    }

    if subcmd == "uninstall" {
        for i in pkgs {
            if deny.contains(i) {
                print("⇢ \u{001B}[0;31m✖  \u{001B}[0;0mPackage \u{001B}[0;36m\"\(i)\" \u{001B}[0;0mis a core library, refusing to uninstall.")
            } else {
                if library_path.join(i).exists {
                    do {
                        try library_path.join(i).delete()
                        print("⇢ \u{001B}[0;32m✔  \u{001B}[0;0mPackage \u{001B}[0;36m\"\(i)\" \u{001B}[0;0muninstalled.")
                    } catch {
                        print("⇢ \u{001B}[0;31m✖  \u{001B}[0;0mPackage \u{001B}[0;36m\"\(i)\" \u{001B}[0;0mcould not be uninstalled, try running with elevated permissions.")
                    }
                } else {
                    print("⇢ \u{001B}[0;33m⚠  \u{001B}[0;0mPackage \u{001B}[0;36m\"\(i)\" \u{001B}[0;0mcould not be found, ignoring.")
                }
            }
        }
    }

    if subcmd == "build" {
        print("⇢ \u{001B}[0;35m🕮  \u{001B}[0;0mBuilding package \u{001B}[0;36m\"\(pkgs[0])\" \u{001B}[0;0mnow.")
        let base = Path(pkgs[0]) ?? Path.cwd.join(pkgs[0])

        let files = base.ls().files

        var built_files = [String]()

        for i in files {
            var content: String

            do {
                content       = try system(command: "\(read_cmd) \(i)", captureOutput: true).standardOutput
                let splitpath = "\(i)".components(separatedBy: "/")
                built_files.append("\(pkgs[0])/\(splitpath.last!):\(content.b64encode()!)")
                print("⇢ \u{001B}[0;32m✔  \u{001B}[0;0mFile \u{001B}[0;36m\"\(splitpath.last!)\" \u{001B}[0;0madded.")
            } catch {
                print("⇢ \u{001B}[0;31m✖  \u{001B}[0;0mPackage \u{001B}[0;36m\"\(pkgs[0])\"\u{001B}[0;0m, failed to build.")
                exit(1)
            }
        }

        let joined_files = built_files.joined(separator: ";")
        let pkgdata = "\(pkgs[0])|\(joined_files)"

        print("⇢ \u{001B}[0;32m✔  \u{001B}[0;0mPackage data built.")
        print("⇢ \u{001B}[0;35m🕮  \u{001B}[0;0mFinalization.")

        print("⇢ \u{001B}[0;35m🕮  \u{001B}[0;0mName.")
        let pkgname    = readLine()

        print("⇢ \u{001B}[0;35m🕮  \u{001B}[0;0mAuthor.")
        let pkgauthor  = readLine()

        print("⇢ \u{001B}[0;35m🕮  \u{001B}[0;0mVersion.")
        let pkgversion = readLine()

        print("⇢ \u{001B}[0;35m🕮  \u{001B}[0;0mDependencies, separated by a semicolon, leave blank for none.")
        let pkgdeps    = readLine()

        print("⇢ \u{001B}[0;35m🕮  \u{001B}[0;0mFinalizating package.")

        let finalpkg = """
        {
            "name": "\(pkgname!)",
            "id": "\(pkgs[0])",
            "author": "\(pkgauthor!)",
            "version": "\(pkgversion!)",
            "source": "\(pkgdata)",
            "depends": "\(pkgdeps!)"
        }
        """

        print("⇢ \u{001B}[0;32m✔  \u{001B}[0;0mPackage finalized.")

        do {
            try finalpkg.write(to: Path.cwd.join("\(pkgs[0]).csp"))
        } catch {
            print("⇢ \u{001B}[0;31m✖  \u{001B}[0;0mPackage \u{001B}[0;36m\"\(pkgs[0])\"\u{001B}[0;0m, failed to write.")
            exit(1)
        }

        print("""
        ⇢ \u{001B}[0;32m✔  \u{001B}[0;0mPackage \u{001B}[0;36m\"\(pkgs[0])\" \u{001B}[0;0mbuilt successfully.
        ⇢ \u{001B}[0;35m🕮  \u{001B}[0;0mSubmit \u{001B}[0;36m\"\(pkgs[0]).csp\" \u{001B}[0;0min a pull request to \u{001B}[0;36m\"Deltara3/cstm-main\"\u{001B}[0;0m, because I'm too broke for servers.
        """)
    }
}

main()
