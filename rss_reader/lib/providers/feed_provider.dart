import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:webfeed/webfeed.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:html/parser.dart' as htmlparser;
import '../models/feed_model.dart';
import '../models/article_model.dart';

class FeedProvider extends ChangeNotifier {
  List<Feed> _feeds = [];
  List<Article> _articles = [];
  bool _isLoading = false;
  String _error = '';

  List<Feed> get feeds => _feeds;
  List<Article> get articles => _articles;
  bool get isLoading => _isLoading;
  String get error => _error;

  FeedProvider() {
    loadFeeds();
  }

  Future<void> loadFeeds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final feedsJson = prefs.getStringList('feeds') ?? [];
      
      _feeds = feedsJson
          .map((json) => Feed.fromJson(jsonDecode(json)))
          .toList();
      
      if (_feeds.isNotEmpty) {
        await refreshAllFeeds();
      }
    } catch (e) {
      _error = 'Failed to load feeds: $e';
    }
    notifyListeners();
  }

  Future<void> saveFeeds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final feedsJson = _feeds
          .map((feed) => jsonEncode(feed.toJson()))
          .toList();
      
      await prefs.setStringList('feeds', feedsJson);
    } catch (e) {
      _error = 'Failed to save feeds: $e';
    }
  }

  // Create a URL with CORS proxy if needed
  String _createProxiedUrl(String url) {
    if (kIsWeb) {
      // Using allorigins which has good reliability
      return 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(url)}';
    }
    return url;
  }

  // Try to determine if the content is potentially an RSS/Atom feed
  bool _looksLikeFeed(String content) {
    final lowerContent = content.toLowerCase();
    return lowerContent.contains('<rss') || 
           lowerContent.contains('<feed') ||
           lowerContent.contains('<channel') ||
           lowerContent.contains('<item') ||
           lowerContent.contains('<entry');
  }

  // Helper to extract image URLs from content
  String? _extractImageFromDescription(String? description) {
    if (description == null || description.isEmpty) {
      return null;
    }

    try {
      // Try to parse HTML and extract first image
      final document = htmlparser.parse(description);
      final imgElements = document.getElementsByTagName('img');
      if (imgElements.isNotEmpty) {
        // Get the src attribute
        String? src = imgElements.first.attributes['src'];
        
        // Validate image URL
        if (src != null && (src.startsWith('http://') || src.startsWith('https://'))) {
          return src;
        }
        
        // Check for data URLs (but avoid very long ones)
        if (src != null && src.startsWith('data:image/') && src.length < 1000) {
          return src;
        }
      }
      
      // Check for OpenGraph image tags
      final metaTags = document.getElementsByTagName('meta');
      for (final meta in metaTags) {
        if (meta.attributes['property'] == 'og:image' && 
            meta.attributes['content'] != null && 
            meta.attributes['content']!.isNotEmpty) {
          return meta.attributes['content'];
        }
      }
    } catch (e) {
      // If parsing fails, try regex - using a simple pattern to avoid escaping issues
      final imgRegex = RegExp('<img.*?src="(.*?)"');
      final match = imgRegex.firstMatch(description);
      if (match != null && match.groupCount >= 1) {
        String? src = match.group(1);
        if (src != null && src.isNotEmpty && 
            (src.startsWith('http://') || src.startsWith('https://'))) {
          return src;
        }
      }
      
      // Try to find OpenGraph image with regex
      final ogRegex = RegExp('<meta[^>]*property="og:image"[^>]*content="(.*?)"');
      final ogMatch = ogRegex.firstMatch(description);
      if (ogMatch != null && ogMatch.groupCount >= 1) {
        return ogMatch.group(1);
      }
    }

    return null;
  }

  // Helper to extract simple XML values
  String? _extractSimpleXmlValue(String xml, String tag) {
    final regex = RegExp('<$tag[^>]*>(.*?)</$tag>', dotAll: true);
    final match = regex.firstMatch(xml);
    if (match != null && match.groupCount >= 1) {
      return match.group(1)?.trim();
    }
    return null;
  }

  // Helper to extract items from XML
  List<String> _extractItems(String xml) {
    final items = <String>[];
    
    // Try to extract RSS items
    final itemRegex = RegExp(r'<item[^>]*>(.*?)</item>', dotAll: true);
    final itemMatches = itemRegex.allMatches(xml);
    for (var match in itemMatches) {
      if (match.groupCount >= 1 && match.group(1) != null) {
        items.add(match.group(1)!);
      }
    }
    
    // If no RSS items found, try Atom entries
    if (items.isEmpty) {
      final entryRegex = RegExp(r'<entry[^>]*>(.*?)</entry>', dotAll: true);
      final entryMatches = entryRegex.allMatches(xml);
      for (var match in entryMatches) {
        if (match.groupCount >= 1 && match.group(1) != null) {
          items.add(match.group(1)!);
        }
      }
    }
    
    return items;
  }

  // A more robust RSS/Atom feed parser
  Future<List<Article>> _parseAnyFeed(String url, String content, Feed feed) async {
    if (content.isEmpty || !content.trim().startsWith('<')) {
      throw Exception('Invalid feed content: Not valid XML');
    }
    
    // Try to parse as RSS
    try {
      final rssFeed = RssFeed.parse(content);
      
      if (rssFeed.items != null) {
        return rssFeed.items!.map((item) {
          // Extract image from content or enclosure
          String? imageUrl = _extractImageFromRssItem(item);
          
          DateTime pubDate;
          try {
            if (item.pubDate != null) {
              // Parse the date, handling both DateTime and String
              if (item.pubDate is DateTime) {
                pubDate = item.pubDate as DateTime;
              } else {
                pubDate = DateTime.parse(item.pubDate.toString());
              }
            } else {
              pubDate = DateTime.now();
            }
          } catch (e) {
            pubDate = DateTime.now();
          }
          
          return Article(
            title: item.title?.trim() ?? 'No Title',
            url: item.link?.trim() ?? '',
            description: item.description?.trim() ?? '',
            content: item.content?.value?.trim() ?? item.description?.trim() ?? '',
            imageUrl: imageUrl,
            pubDate: pubDate,
            feedTitle: feed.title,
            feedUrl: feed.url,
          );
        }).toList()
          ..sort((a, b) {
            // Handle null pubDates by treating them as oldest
            final DateTime aPubDate = a.pubDate ?? DateTime.fromMillisecondsSinceEpoch(0);
            final DateTime bPubDate = b.pubDate ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bPubDate.compareTo(aPubDate);
          });
      }
    } catch (e) {
      print('RSS parsing error: $e');
    }
    
    // Try Atom format if RSS fails
    try {
      print('Trying to parse as Atom feed');
      final atomFeed = AtomFeed.parse(content);
      print('Successfully parsed as Atom feed: ${atomFeed.title}');
      
      final List<Article> articles = [];
      final atomFeedTitle = atomFeed.title ?? '';
      final atomFeedDescription = atomFeed.subtitle ?? '';
      String? atomFeedImageUrl;
      
      if (atomFeed.links != null) {
        for (final link in atomFeed.links!) {
          if (link != null && (link.rel == 'icon' || link.rel == 'logo')) {
            atomFeedImageUrl = link.href;
          }
        }
      }
      
      if (atomFeed.items != null) {
        for (final entry in atomFeed.items!) {
          if (entry != null) {
            // Try multiple image sources in order of preference
            String? imageUrl = null;
            String? linkUrl = null;
            
            // Check links for alternate and enclosure
            if (entry.links != null) {
              for (final link in entry.links!) {
                if (link != null) {
                  if (link.rel == 'alternate') {
                    linkUrl = link.href;
                  } else if (link.rel == 'enclosure' && 
                            link.type != null && 
                            link.type!.startsWith('image/')) {
                    imageUrl = link.href;
                  }
                }
              }
            }
            
            // Try embedded image in content
            if (imageUrl == null && entry.content != null) {
              imageUrl = _extractImageFromDescription(entry.content);
            }
            
            // Try embedded image in summary
            if (imageUrl == null && entry.summary != null) {
              imageUrl = _extractImageFromDescription(entry.summary);
            }
            
            // Handle date parsing with robust error handling
            DateTime? pubDate;
            try {
              dynamic updated = entry.updated;
              dynamic published = entry.published;
              
              if (updated != null) {
                if (updated is DateTime) {
                  pubDate = updated;
                } else if (updated is String) {
                  pubDate = DateTime.tryParse(updated);
                }
              } else if (published != null) {
                if (published is DateTime) {
                  pubDate = published;
                } else if (published is String) {
                  pubDate = DateTime.tryParse(published);
                }
              }
            } catch (e) {
              print('Error handling date: $e');
            }
            
            articles.add(Article(
              title: entry.title ?? 'No Title',
              url: linkUrl ?? url,
              feedTitle: atomFeedTitle,
              feedUrl: url,
              description: entry.summary,
              content: entry.content,
              imageUrl: imageUrl,
              author: entry.authors?.isNotEmpty == true ? entry.authors!.first.name : null,
              pubDate: pubDate,
            ));
          }
        }
      }
      
      return articles;
    } catch (e) {
      print('Error parsing as Atom feed: $e');
      // Continue to fallback parsing
    }
    
    // Manual XML parsing as a last resort
    try {
      print('Attempting manual XML parsing');
      
      // Try to extract feed title and description
      final extractedTitle = _extractSimpleXmlValue(content, 'title');
      final extractedDescription = _extractSimpleXmlValue(content, 'description') ?? 
                                 _extractSimpleXmlValue(content, 'subtitle');
      
      // Extract items/entries
      final items = _extractItems(content);
      print('Manually extracted ${items.length} items');
      
      final List<Article> manualArticles = [];
      
      // Parse each item
      for (final item in items) {
        final itemTitle = _extractSimpleXmlValue(item, 'title');
        final itemLink = _extractSimpleXmlValue(item, 'link') ?? 
                       _extractSimpleXmlValue(item, 'guid');
        final itemDescription = _extractSimpleXmlValue(item, 'description') ?? 
                             _extractSimpleXmlValue(item, 'summary') ??
                             _extractSimpleXmlValue(item, 'content');
        
        if (itemTitle != null && (itemLink != null || itemDescription != null)) {
          manualArticles.add(Article(
            title: itemTitle,
            url: itemLink ?? url,
            description: itemDescription,
            content: itemDescription,
            imageUrl: _extractImageFromDescription(itemDescription),
            pubDate: DateTime.now(), // Manual parsing of dates is complex
            feedTitle: extractedTitle ?? 'Feed',
            feedUrl: url,
          ));
        }
      }
      
      if (manualArticles.isNotEmpty) {
        print('Manually extracted ${manualArticles.length} articles');
        return manualArticles;
      }
    } catch (e) {
      print('Manual parsing failed: $e');
    }
    
    // Content doesn't appear to be a feed at all
    throw Exception('Content is not a valid RSS or Atom feed');
  }

  // Helper method to extract image URL from RSS item
  String? _extractImageFromRssItem(RssItem item) {
    // Try to get image from enclosure
    if (item.enclosure != null && 
        item.enclosure!.url != null && 
        item.enclosure!.type != null && 
        item.enclosure!.type!.startsWith('image/')) {
      return item.enclosure!.url;
    }
    
    // Try to extract image from content
    if (item.content?.value != null) {
      return _extractImageFromHtml(item.content!.value!);
    }
    
    // Try to extract from description
    if (item.description != null) {
      return _extractImageFromHtml(item.description!);
    }
    
    return null;
  }
  
  // Helper method to extract image from HTML content
  String? _extractImageFromHtml(String html) {
    // Simple regex to find the first image URL in HTML content
    final RegExp imgRegExp = RegExp(r'<img[^>]+src="([^">]+)"', caseSensitive: false);
    final match = imgRegExp.firstMatch(html);
    if (match != null && match.groupCount >= 1) {
      String src = match.group(1) ?? '';
      // Ensure the URL is absolute
      if (src.startsWith('//')) {
        src = 'https:$src';
      }
      return src;
    }
    return null;
  }

  Future<void> addFeed(Feed feed) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      // Clean up the URL
      String cleanUrl = feed.url.trim();
      if (cleanUrl.startsWith('@')) {
        cleanUrl = cleanUrl.substring(1);
      }
      
      // Extract URL from Feedly links
      final feedlyMatch = RegExp(r'feedly\.com/i/subscription/feed/(https?[^&]+)').firstMatch(cleanUrl);
      if (feedlyMatch != null && feedlyMatch.groupCount >= 1) {
        cleanUrl = Uri.decodeComponent(feedlyMatch.group(1)!);
      }
      
      // Ensure URL has http/https prefix
      if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
        cleanUrl = 'https://$cleanUrl';
      }
      
      print('Fetching feed from: $cleanUrl');
      
      // Use CORS proxy if needed
      final fetchUrl = _createProxiedUrl(cleanUrl);
      
      final client = http.Client();
      final response = await client.get(Uri.parse(fetchUrl))
          .timeout(const Duration(seconds: 30));
      
      // Check if the response is valid
      if (response.statusCode != 200) {
        throw Exception('Failed to load feed: HTTP ${response.statusCode}');
      }
      
      if (response.body.isEmpty) {
        throw Exception('Feed returned empty content');
      }
      
      // Check if content is XML and looks like a feed
      if (!_looksLikeFeed(response.body)) {
        throw Exception('URL does not appear to be a valid RSS/Atom feed');
      }
      
      // Parse the feed
      final parsedArticles = await _parseAnyFeed(cleanUrl, response.body, feed);
      
      // Create a new feed with the parsed data
      final newFeed = Feed(
        title: feed.title.isEmpty ? Uri.parse(cleanUrl).host : feed.title,
        url: cleanUrl,
        description: feed.description,
        imageUrl: feed.imageUrl,
      );
      
      // Check if this feed already exists
      final existingFeedIndex = _feeds.indexWhere((f) => f.url == cleanUrl);
      if (existingFeedIndex >= 0) {
        throw Exception('This feed is already in your list');
      }
      
      // Add the feed
      _feeds.add(newFeed);
      await saveFeeds();
      
      // Add parsed articles if any
      if (parsedArticles.isNotEmpty) {
        _articles.addAll(parsedArticles);
        
        // Update feed title if it's changed
        final parsedTitle = parsedArticles.first.feedTitle;
        
        if (parsedTitle.isNotEmpty && parsedTitle != feed.title) {
          // Find the feed in the feeds list and update with copyWith
          final index = _feeds.indexWhere((f) => f.url == feed.url);
          if (index >= 0) {
            _feeds[index] = _feeds[index].copyWith(title: parsedTitle);
            saveFeeds(); // Save the updated feeds
          }
        }
        
        print('Added ${parsedArticles.length} articles from ${newFeed.title}');
      } else {
        print('No articles found in feed: ${newFeed.title}');
      }
    } catch (e) {
      print('Error adding feed: $e');
      if (e.toString().contains('XMLHttpRequest')) {
        _error = 'CORS error: Unable to access the feed. This is a browser security restriction.';
      } else {
        _error = 'Failed to add feed: $e';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeFeed(String url) async {
    _feeds.removeWhere((feed) => feed.url == url);
    _articles.removeWhere((article) => article.feedUrl == url);
    await saveFeeds();
    notifyListeners();
  }

  Future<void> refreshAllFeeds() async {
    _isLoading = true;
    _error = '';
    _articles.clear();
    notifyListeners();
    
    try {
      for (final feed in _feeds) {
        await refreshFeed(feed);
      }
    } catch (e) {
      _error = 'Failed to refresh feeds: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchArticlesFromFeed(Feed feed) async {
    final client = http.Client();
    try {
      // Use CORS proxy if needed
      final fetchUrl = _createProxiedUrl(feed.url);
      print('Refreshing feed from: $fetchUrl');
      
      final response = await client.get(Uri.parse(fetchUrl))
          .timeout(const Duration(seconds: 30));
          
      if (response.statusCode != 200) {
        throw Exception('Failed to load feed: HTTP ${response.statusCode}');
      }

      if (response.body.isEmpty) {
        throw Exception('Feed returned empty content');
      }

      // Parse the feed using our robust parser
      final parsedArticles = await _parseAnyFeed(feed.url, response.body, feed);
      
      // Add parsed articles if any
      if (parsedArticles.isNotEmpty) {
        // Update feed title if it's changed
        final parsedTitle = parsedArticles.first.feedTitle;
        
        if (parsedTitle.isNotEmpty && parsedTitle != feed.title) {
          // Find the feed in the feeds list and update with copyWith
          final index = _feeds.indexWhere((f) => f.url == feed.url);
          if (index >= 0) {
            _feeds[index] = _feeds[index].copyWith(title: parsedTitle);
            saveFeeds(); // Save the updated feeds
          }
        }
        
        // Add the articles
        _articles.addAll(parsedArticles);
        print('Added ${parsedArticles.length} articles from ${feed.title}');
      } else {
        print('No articles found in feed: ${feed.title}');
      }
    } catch (e) {
      print('Error fetching articles from ${feed.title}: $e');
      if (e.toString().contains('XMLHttpRequest')) {
        _error = 'CORS error: Unable to access the feed. This is a browser security restriction.';
      } else {
        _error = 'Failed to fetch articles from ${feed.title}: $e';
      }
    } finally {
      client.close();
    }
  }

  Future<void> refreshFeed(Feed feed) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      final client = http.Client();
      
      // Use CORS proxy if needed
      final fetchUrl = _createProxiedUrl(feed.url);
      print('Refreshing feed from: $fetchUrl');
      
      final response = await client.get(Uri.parse(fetchUrl))
          .timeout(const Duration(seconds: 30));
          
      if (response.statusCode != 200) {
        throw Exception('Failed to load feed: HTTP ${response.statusCode}');
      }

      if (response.body.isEmpty) {
        throw Exception('Feed returned empty content');
      }

      // Parse the feed using our robust parser
      final parsedArticles = await _parseAnyFeed(feed.url, response.body, feed);
      
      // Add parsed articles if any
      if (parsedArticles.isNotEmpty) {
        // Update feed title if it's changed
        final parsedTitle = parsedArticles.first.feedTitle;
        
        if (parsedTitle.isNotEmpty && parsedTitle != feed.title) {
          // Find the feed in the feeds list and update with copyWith
          final index = _feeds.indexWhere((f) => f.url == feed.url);
          if (index >= 0) {
            _feeds[index] = _feeds[index].copyWith(title: parsedTitle);
            saveFeeds(); // Save the updated feeds
          }
        }
        
        // Add the articles
        _articles.addAll(parsedArticles);
        print('Added ${parsedArticles.length} articles from ${feed.title}');
      } else {
        print('No articles found in feed: ${feed.title}');
      }
    } catch (e) {
      print('Error refreshing feed: $e');
      if (e.toString().contains('XMLHttpRequest')) {
        _error = 'CORS error: Unable to access the feed. This is a browser security restriction.';
      } else {
        _error = 'Failed to refresh feed: $e';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 