// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "cstm",
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.4.0")),
        .package(url: "https://github.com/mxcl/path.swift.git", from: "1.4.0"),
        .package(url: "https://github.com/eneko/ProcessRunner.git", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "cstm",
            dependencies: [
                .product(name: "Alamofire", package: "Alamofire"),
                .product(name: "Path", package: "path.swift"),
                .product(name: "ProcessRunner", package: "ProcessRunner")
            ]),
    ]
)
