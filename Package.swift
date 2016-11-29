import PackageDescription

let package = Package(
    name: "PlusSMTP",
    targets: [],
    dependencies: [
        .Package(url: "https://github.com/matejukmar/Perfect-CURL.git", majorVersion: 2, minor: 0),
    ],
    exclude: []
)
