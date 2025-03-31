# RSS Reader

A modern RSS feed reader application built with Flutter, supporting both RSS and Atom feeds. The app provides a clean and intuitive interface for reading and managing your favorite RSS feeds.

## Features

- Support for both RSS and Atom feeds
- Clean and modern Material Design UI
- Cross-platform support (Windows, Web, Mobile)
- Offline reading capability
- Feed management (add, remove, refresh)
- Article content rendering with image support
- Automatic feed title detection
- CORS proxy support for web platform

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK (latest stable version)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/rss_reader.git
```

2. Navigate to the project directory:
```bash
cd rss_reader
```

3. Install dependencies:
```bash
flutter pub get
```

4. Run the app:
```bash
flutter run
```

## Usage

1. Launch the app
2. Click the "+" button to add a new feed
3. Enter the feed URL
4. The app will automatically fetch and display the feed content
5. Tap on articles to read them in detail

## Dependencies

- provider: ^6.0.5
- shared_preferences: ^2.2.0
- http: ^1.1.0
- webfeed: ^0.7.0
- intl: ^0.18.1
- cached_network_image: ^3.2.3
- html: ^0.15.4

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details. 