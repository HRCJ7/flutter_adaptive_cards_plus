[![pub package](https://img.shields.io/pub/v/flutter_adaptive_cards_plus.svg)](https://pub.dev/packages/flutter_adaptive_cards_plus)
[![](https://tokei.rs/b1/github/HRCJ7/flutter_adaptive_cards_plus?category=code)](https://github.com/HRCJ7/flutter_adaptive_cards_plus)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](https://github.com/HRCJ7/flutter_adaptive_cards_plus/blob/main/LICENSE)

# Flutter Adaptive Cards Plus

A Flutter library for rendering **Adaptive Cards**, updated and maintained to support the latest **Flutter SDK 3.35.2**.

This version modernizes the codebase, improves stability, and ensures compatibility with the current Flutter ecosystem while preserving the simplicity and flexibility of adaptive card rendering.

---

## ✨ Features

* Compatible with Flutter **3.35.2+**
* Render adaptive cards using Flutter widgets
* Supports text, media, inputs, and actions
* Load card definitions from network, assets, or memory
* Improved dark mode color adaptation
* Clean and minimal API for developers

---

## 📦 Installation

Add the package to your `pubspec.yaml`:

```
dependencies:
  flutter_adaptive_cards_plus:
    git:
      url: https://github.com/HRCJ7/flutter_adaptive_cards_plus
```

Then run:

```
flutter pub get
```

---

## 🚀 Usage Example

```
AdaptiveCard.network(
  placeholder: Text("Loading, please wait..."),
  url: "https://example.com/sample.json",
  hostConfigPath: "assets/host_config.json",
  onSubmit: (data) {
    // Handle form submission
  },
  onOpenUrl: (url) {
    // Handle URL click
  },
  showDebugJson: true,
  approximateDarkThemeColors: true,
);
```

Other constructors:

* `AdaptiveCard.asset` → Load card from a local asset
* `AdaptiveCard.memory` → Load from an in-memory JSON map

---

## 🧪 Running Tests

```
flutter test
```

---

## 💡 About

This project continues the development of an earlier open-source Adaptive Cards library for Flutter, now updated to meet the requirements of the latest Flutter SDK and community standards.

Special thanks to the open-source community for the inspiration and foundation that made this project possible.

---

## 👤 Maintainer

**Rajitha Perera**
GitHub: [@HRCJ7](https://github.com/HRCJ7)

---

## 📄 License

Licensed under the [MIT License](LICENSE).
Use freely in commercial or personal projects.
