import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../providers/feed_provider.dart';
import '../models/feed_model.dart';
import '../models/article_model.dart';
import 'article_screen.dart';
import 'add_feed_screen.dart';
import '../widgets/article_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showFeedsList = false;

  @override
  Widget build(BuildContext context) {
    return kIsWeb 
        ? _buildMaterialHomeScreen() 
        : _buildCupertinoHomeScreen();
  }

  Widget _buildMaterialHomeScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RSS Reader'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final provider = Provider.of<FeedProvider>(context, listen: false);
              provider.refreshAllFeeds();
            },
          ),
          IconButton(
            icon: Icon(_showFeedsList ? Icons.article : Icons.rss_feed),
            onPressed: () {
              setState(() {
                _showFeedsList = !_showFeedsList;
              });
            },
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddFeed(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCupertinoHomeScreen() {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('RSS Reader'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.refresh),
              onPressed: () {
                final provider = Provider.of<FeedProvider>(context, listen: false);
                provider.refreshAllFeeds();
              },
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: Icon(_showFeedsList 
                  ? CupertinoIcons.doc_text 
                  : CupertinoIcons.antenna_radiowaves_left_right),
              onPressed: () {
                setState(() {
                  _showFeedsList = !_showFeedsList;
                });
              },
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            _buildBody(),
            Positioned(
              right: 16,
              bottom: 16,
              child: CupertinoButton(
                padding: const EdgeInsets.all(16),
                color: CupertinoColors.systemBlue,
                borderRadius: BorderRadius.circular(30),
                child: const Icon(
                  CupertinoIcons.add,
                  color: CupertinoColors.white,
                ),
                onPressed: () => _navigateToAddFeed(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<FeedProvider>(
      builder: (context, feedProvider, child) {
        if (feedProvider.isLoading) {
          return Center(
            child: kIsWeb 
                ? const CircularProgressIndicator() 
                : const CupertinoActivityIndicator(radius: 16),
          );
        }

        if (feedProvider.error.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Error: ${feedProvider.error}',
                  style: TextStyle(
                    color: kIsWeb ? Colors.red : CupertinoColors.systemRed,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                kIsWeb
                    ? ElevatedButton(
                        onPressed: () {
                          feedProvider.refreshAllFeeds();
                        },
                        child: const Text('Retry'),
                      )
                    : CupertinoButton(
                        color: CupertinoColors.systemBlue,
                        onPressed: () {
                          feedProvider.refreshAllFeeds();
                        },
                        child: const Text('Retry'),
                      ),
              ],
            ),
          );
        }

        if (feedProvider.feeds.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'No feeds added yet',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 16),
                kIsWeb
                    ? ElevatedButton(
                        onPressed: () => _navigateToAddFeed(),
                        child: const Text('Add Feed'),
                      )
                    : CupertinoButton(
                        color: CupertinoColors.systemBlue,
                        onPressed: () => _navigateToAddFeed(),
                        child: const Text('Add Feed'),
                      ),
              ],
            ),
          );
        }

        if (_showFeedsList) {
          return _buildFeedsList(feedProvider);
        } else {
          return _buildArticlesList(feedProvider);
        }
      },
    );
  }

  Widget _buildFeedsList(FeedProvider feedProvider) {
    return kIsWeb
        ? ListView.builder(
            itemCount: feedProvider.feeds.length,
            itemBuilder: (context, index) {
              final feed = feedProvider.feeds[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (feed.imageUrl != null)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        child: Image.network(
                          feed.imageUrl!,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const SizedBox(
                            height: 0,
                          ),
                        ),
                      ),
                    ListTile(
                      title: Text(feed.title),
                      subtitle: Text(feed.url),
                      leading: feed.imageUrl != null
                          ? null // We're already showing the image above
                          : const CircleAvatar(
                              child: Icon(Icons.rss_feed),
                            ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          _showDeleteConfirmationDialog(context, feed);
                        },
                      ),
                    ),
                    if (feed.description != null && feed.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          feed.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                  ],
                ),
              );
            },
          )
        : CupertinoScrollbar(
            child: ListView.builder(
              itemCount: feedProvider.feeds.length,
              itemBuilder: (context, index) {
                final feed = feedProvider.feeds[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBackground,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.systemGrey4.withOpacity(0.2),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (feed.imageUrl != null)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                          child: Image.network(
                            feed.imageUrl!,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const SizedBox(
                              height: 0,
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    feed.title,
                                    style: CupertinoTheme.of(context)
                                        .textTheme
                                        .textStyle
                                        .copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    feed.url,
                                    style: CupertinoTheme.of(context)
                                        .textTheme
                                        .textStyle
                                        .copyWith(
                                          fontSize: 14, 
                                          color: CupertinoColors.systemGrey,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (feed.description != null && feed.description!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        feed.description!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: CupertinoTheme.of(context)
                                            .textTheme
                                            .textStyle
                                            .copyWith(
                                              fontSize: 14,
                                              color: CupertinoColors.secondaryLabel,
                                            ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              child: const Icon(
                                CupertinoIcons.delete,
                                color: CupertinoColors.systemRed,
                              ),
                              onPressed: () {
                                _showCupertinoDeleteConfirmationDialog(context, feed);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
  }

  Widget _buildArticlesList(FeedProvider feedProvider) {
    // Group articles by date
    final now = DateTime.now();
    final last24Hours = now.subtract(const Duration(hours: 24));
    final lastWeek = now.subtract(const Duration(days: 7));
    
    // Sort articles into groups
    final List<Article> today = [];
    final List<Article> thisWeek = [];
    final List<Article> older = [];
    
    for (final article in feedProvider.articles) {
      if (article.pubDate == null) {
        older.add(article);
      } else if (article.pubDate!.isAfter(last24Hours)) {
        today.add(article);
      } else if (article.pubDate!.isAfter(lastWeek)) {
        thisWeek.add(article);
      } else {
        older.add(article);
      }
    }

    // Get localized date headers
    final locale = Localizations.localeOf(context).languageCode;
    final todayText = _getLocalizedDateHeader('Today', locale);
    final thisWeekText = _getLocalizedDateHeader('This Week', locale);
    final olderText = _getLocalizedDateHeader('Older', locale);
    
    return kIsWeb
        ? RefreshIndicator(
            onRefresh: () => feedProvider.refreshAllFeeds(),
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                if (today.isNotEmpty) ...[
                  _buildDateHeader(context, todayText),
                  ...today.map((article) => _buildArticleItem(article)),
                ],
                if (thisWeek.isNotEmpty) ...[
                  _buildDateHeader(context, thisWeekText),
                  ...thisWeek.map((article) => _buildArticleItem(article)),
                ],
                if (older.isNotEmpty) ...[
                  _buildDateHeader(context, olderText),
                  ...older.map((article) => _buildArticleItem(article)),
                ],
                if (feedProvider.articles.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Text('No articles found. Pull to refresh or add more feeds.'),
                    ),
                  ),
                // Add extra space at the bottom
                const SizedBox(height: 80),
              ],
            ),
          )
        : CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: () => feedProvider.refreshAllFeeds(),
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  if (today.isNotEmpty) ...[
                    _buildDateHeader(context, todayText, isCupertino: true),
                    ...today.map((article) => _buildArticleItem(article)),
                  ],
                  if (thisWeek.isNotEmpty) ...[
                    _buildDateHeader(context, thisWeekText, isCupertino: true),
                    ...thisWeek.map((article) => _buildArticleItem(article)),
                  ],
                  if (older.isNotEmpty) ...[
                    _buildDateHeader(context, olderText, isCupertino: true),
                    ...older.map((article) => _buildArticleItem(article)),
                  ],
                  if (feedProvider.articles.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: Text('No articles found. Pull to refresh or add more feeds.'),
                      ),
                    ),
                  // Add extra space at the bottom for floating button
                  const SizedBox(height: 80),
                ]),
              ),
            ],
          );
  }
  
  Widget _buildDateHeader(BuildContext context, String title, {bool isCupertino = false}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: isCupertino 
            ? CupertinoTheme.of(context).textTheme.navTitleTextStyle.copyWith(
                fontSize: 18,
                color: CupertinoColors.systemGrey,
              )
            : Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
      ),
    );
  }
  
  Widget _buildArticleItem(Article article) {
    return ArticleCard(
      article: article,
      onTap: () => _navigateToArticleScreen(article),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, Feed feed) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Feed'),
        content: Text('Are you sure you want to delete "${feed.title}"?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final provider = Provider.of<FeedProvider>(context, listen: false);
              provider.removeFeed(feed.url);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCupertinoDeleteConfirmationDialog(BuildContext context, Feed feed) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Feed'),
        content: Text('Are you sure you want to delete "${feed.title}"?'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              final provider = Provider.of<FeedProvider>(context, listen: false);
              provider.removeFeed(feed.url);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToAddFeed() async {
    final result = await Navigator.push(
      context,
      kIsWeb
          ? MaterialPageRoute(
              builder: (context) => const AddFeedScreen(),
            )
          : CupertinoPageRoute(
              builder: (context) => const AddFeedScreen(),
            ),
    );
    
    if (result == true) {
      setState(() {
        _showFeedsList = true;
      });
    }
  }

  void _navigateToArticleScreen(Article article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArticleScreen(article: article),
      ),
    );
  }

  // Returns localized date header based on the user's locale
  String _getLocalizedDateHeader(String englishText, String localeCode) {
    // Basic localization for common languages
    final Map<String, Map<String, String>> translations = {
      'es': {
        'Today': 'Hoy',
        'This Week': 'Esta Semana',
        'Older': 'Anteriores',
      },
      'fr': {
        'Today': 'Aujourd\'hui',
        'This Week': 'Cette Semaine',
        'Older': 'Plus Anciens',
      },
      'de': {
        'Today': 'Heute',
        'This Week': 'Diese Woche',
        'Older': 'Älter',
      },
      'it': {
        'Today': 'Oggi',
        'This Week': 'Questa Settimana',
        'Older': 'Più Vecchi',
      },
      'pt': {
        'Today': 'Hoje',
        'This Week': 'Esta Semana',
        'Older': 'Mais Antigos',
      },
      'ja': {
        'Today': '今日',
        'This Week': '今週',
        'Older': '過去',
      },
      'zh': {
        'Today': '今天',
        'This Week': '本周',
        'Older': '更早',
      },
      'ru': {
        'Today': 'Сегодня',
        'This Week': 'На этой неделе',
        'Older': 'Ранее',
      },
    };
    
    // Return translated text if available, otherwise use English
    if (translations.containsKey(localeCode) && 
        translations[localeCode]!.containsKey(englishText)) {
      return translations[localeCode]![englishText]!;
    }
    return englishText;
  }
} 