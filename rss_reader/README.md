# RSS Reader App

A Flutter application that allows you to follow and read articles from multiple RSS feeds.

## Features

- Add multiple RSS feeds by URL
- View a combined feed of all articles
- Read article content within the app
- Open articles in browser for full reading experience
- Manage your RSS feed subscriptions
- Support for both RSS and Atom feed formats
- Caching of images for better performance
- Example feeds to get started quickly

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version recommended)
- An Android or iOS device/emulator

### Installation

1. Clone this repository
2. Navigate to the project directory
3. Run `flutter pub get` to install dependencies
4. Run `flutter run` to start the app

## Usage

1. When you first open the app, you'll see an empty feed screen
2. Press the "+" button to add a new RSS feed
3. Enter a title and URL for the feed (or choose from examples)
4. View all articles in the main feed
5. Tap on article cards to read full content
6. Toggle between articles view and feeds management using the icon in the top right
7. Pull down to refresh feeds

## Dependencies

- Flutter
- Provider (for state management)
- http (for network requests)
- webfeed (for RSS/Atom parsing)
- shared_preferences (for storing feeds)
- cached_network_image (for image caching)
- flutter_html (for rendering HTML content)
- url_launcher (for opening links)
- intl (for date formatting)

## Example Feeds

The app includes several example RSS feeds to get you started:

- NASA Breaking News
- BBC World News
- CNN Top Stories

Feel free to add your own favorite RSS feeds! 