// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "cstm",
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.4.0")),
        .package(url: "http://github.com/dduan/Pathos", from: "0.4.2")
    ],
    targets: [
        .executableTarget(
            name: "cstm",
            dependencies: [
                .product(name: "Alamofire", package: "Alamofire"),
                .product(name: "Pathos", package: "Pathos"),
            ]),
    ]
)
