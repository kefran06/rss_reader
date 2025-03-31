import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/article_model.dart';

class ArticleScreen extends StatelessWidget {
  final Article article;

  const ArticleScreen({
    Key? key,
    required this.article,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(article.feedTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: () => _launchUrl(article.url),
          ),
        ],
      ),
      body: _buildArticleContent(context),
    );
  }

  // Helper method to format date
  String _formatDate(DateTime date) {
    return DateFormat.yMMMd().format(date);
  }

  // Launch URL helper
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      print('Error launching URL: $e');
    }
  }

  // Simpler content rendering that avoids HTML parsing issues
  Widget _buildArticleContent(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (article.imageUrl != null && article.imageUrl!.isNotEmpty)
            Hero(
              tag: 'article_image_${article.url}',
              child: SizedBox(
                width: double.infinity,
                height: 250,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Use CachedNetworkImage for better handling of network images
                    CachedNetworkImage(
                      imageUrl: article.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade200,
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade400),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) {
                        print('Error loading image: $error - URL: $url');
                        return Container(
                          color: Colors.grey.shade200,
                          child: Center(
                            child: Icon(
                              Icons.image_not_supported,
                              size: 50,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        );
                      },
                    ),
                    // Gradient overlay for better text contrast
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Title on image
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Text(
                        article.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(1, 1),
                              blurRadius: 3,
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (article.imageUrl == null || article.imageUrl!.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      article.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                Row(
                  children: [
                    const Icon(Icons.rss_feed, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      article.feedTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (article.pubDate != null) ...[
                      const Icon(Icons.access_time, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(article.pubDate!),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                if (article.author != null && article.author!.isNotEmpty) ...[
                  Text(
                    'By ${article.author}',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Simple content display - avoiding HTML rendering issues
                if (article.content != null && article.content!.isNotEmpty)
                  _buildSimpleContentDisplay(article.content!)
                else if (article.description != null && article.description!.isNotEmpty)
                  _buildSimpleContentDisplay(article.description!)
                else
                  const Text('No content available.'),
                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () => _launchUrl(article.url),
                    icon: const Icon(Icons.open_in_browser),
                    label: const Text('Read Full Article'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Simple content display without HTML parsing
  Widget _buildSimpleContentDisplay(String content) {
    // Remove HTML tags with a simple approach
    String plainText = content.replaceAll(RegExp(r'<[^>]*>'), ' ');
    plainText = plainText.replaceAll('&nbsp;', ' ');
    plainText = plainText.replaceAll('&amp;', '&');
    plainText = plainText.replaceAll('&lt;', '<');
    plainText = plainText.replaceAll('&gt;', '>');
    plainText = plainText.replaceAll('&quot;', '"');
    plainText = plainText.replaceAll('&apos;', "'");
    
    // Remove extra whitespace
    plainText = plainText.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return Text(
      plainText,
      style: const TextStyle(
        fontSize: 16.0,
        height: 1.6,
      ),
    );
  }
} 