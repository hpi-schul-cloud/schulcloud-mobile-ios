# Make it more obvious that a PR is a work in progress and shouldn't be merged yet
warn("PR is classed as Work in Progress") if github.pr_title.include? "[WIP]"

# SwiftLint
swiftlint.config_file = '.swiftlint.yml'
swiftlint.binary_path = 'Pods/SwiftLint/swiftlint'
swiftlint.max_num_violations = 20
swiftlint.lint_files inline_mode: true
