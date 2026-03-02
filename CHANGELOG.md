## 1.0.0 – Initial Release
- Updated codebase for Flutter 3.35.2
- Improved stability and structure
- Modernized library under MIT License

## 1.0.1

- Fix handling of broken image URLs causing infinite loading
- Improve media and markdown image error handling

## 1.0.2

- Add `hostConfigMap` support for `AdaptiveCard.network`, `AdaptiveCard.asset`, and `AdaptiveCard.memory`
- Improve async adaptive card loading with clearer failure fallback/error visibility
- Fix adaptive image/media sizing issues that could cause gray or unbounded layouts in release builds
- Add host config usage guidance for asset paths vs in-memory map configuration
