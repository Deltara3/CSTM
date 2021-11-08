// CSTM | Deltara3
// Embrace spaghetti.

import Foundation
import FoundationNetworking
import ProcessRunner
import Path

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
           \u{001B}[0;35m╰╌     \u{001B}[0;0mUninstalls a package or package(s).
        """)
}

// Grabs metadata of a package.
func metadata(name: String) -> String {
    do {
        return try String(contentsOf: URL(string: "https://raw.githubusercontent.com/Deltara3/cstm-main/main/\(name).json")!)
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

    let subcmds  = ["help", "version", "install", "uninstall"]
    let branch   = "\u{001B}[0;35m-swift-rw-dev"
    let ver      = "0.1.0\(branch)"
    do {
        let bin_path = try system(command: "\(cmd) spwn", captureOutput: true).standardOutput
    } catch {
        print("⇢ \u{001B}[0;31m✖  \u{001B}[0;0mFailed to run \u{001B}[0;36m\"\(cmd) spwn\"\u{001B}[0;0m, a required command, something went horribly wrong.")
        exit(1)
    }
    let root     = Path.home.join(".cstm")
    let cache    = Path.home.join(".cstm").join("cache")
    let temp     = Path.home.join(".cstm").join("temp")

    struct Expected: Decodable {
        let name    : String
        let id      : String
        let author  : String
        let version : String
        let source  : String
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
        print("⇢ \u{001B}[0;31m✖  \u{001B}[0;0mExpected at least \u{001B}[0;36mone \u{001B}[0;0mpackage to act on. ")
        exit(1)
    }

    // If so, get all provided.
    let pkgs = Array(CommandLine.arguments[2 ..< CommandLine.arguments.count])

    if subcmd == "install" {
        var handled     = [String]()
        var sources     = [String]()
        var versions    = [String]()
        var identifiers = [String]()
        for i in pkgs {
            if handled.contains(i) {
                print("⇢ \u{001B}[0;33m⚠  \u{001B}[0;0mPackage \u{001B}[0;36m\"\(i)\" \u{001B}[0;0malready handled, ignoring.")
            } else {
            let pkgmd = metadata(name: i)
                if pkgmd == "false" {
                    print("⇢ \u{001B}[0;33m⚠  \u{001B}[0;0mPackage \u{001B}[0;36m\"\(i)\" \u{001B}[0;0mnot found, ignoring.")
                } else {
                    print("⇢ \u{001B}[0;32m✔  \u{001B}[0;0mMetadata for package \u{001B}[0;36m\"\(i)\" \u{001B}[0;0mretrieved.")
                    let data = pkgmd.data(using: .utf8)!
                    let table: Expected = try! JSONDecoder().decode(Expected.self, from: data)
                    print("""
                    ⇢ \u{001B}[0;35m🕮  \u{001B}[0;0mPackage table built.
                       \u{001B}[0;35m│      \u{001B}[0;32mName       : \u{001B}[0;36m\"\(table.name)\"
                       \u{001B}[0;35m│      \u{001B}[0;32mIdentifier : \u{001B}[0;36m\"\(table.id)\"
                       \u{001B}[0;35m│      \u{001B}[0;32mAuthor     : \u{001B}[0;36m\"\(table.author)\"
                       \u{001B}[0;35m│      \u{001B}[0;32mVersion    : \u{001B}[0;36m\"\(table.version)\"
                       \u{001B}[0;35m╰╌     \u{001B}[0;32mSource     : \u{001B}[0;36m\"\(table.source)\"\u{001B}[0;0m
                    """)
                    handled.append(i)
                    sources.append(table.source)
                    versions.append(table.version)
                    identifiers.append(table.id)
                }
            }
        }
        print("⇢ \u{001B}[0;32m✔  \u{001B}[0;0mReady to install.")

        for i in handled {
            print("⇢ \u{001B}[0;35m🕮  \u{001B}[0;0mPackage \u{001B}[0;36m\"\(i)\" \u{001B}[0;0mstarted install.")
        }
    }
}

main()