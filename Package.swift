import PackageDescription

let package = Package(
  name: "Stencil",
  dependencies: [
  ],
  testDependencies: [
    .Package(url: "https://github.com/kylef/spectre-build", majorVersion: 0),
  ]
)
