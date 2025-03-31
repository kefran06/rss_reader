import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/article_model.dart';

class ArticleCard extends StatelessWidget {
  final Article article;
  final VoidCallback onTap;

  const ArticleCard({
    super.key,
    required this.article,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Always use material design for Windows
    return _buildMaterialArticleCard(context);
  }

  Widget _buildMaterialArticleCard(BuildContext context) {
    final hasImage = article.imageUrl != null && article.imageUrl!.isNotEmpty;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        child: hasImage 
            ? _buildCardWithMainImage(context)
            : _buildCardWithThumbnail(context),
      ),
    );
  }
  
  Widget _buildCardWithMainImage(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Hero(
          tag: 'article_image_${article.url}',
          child: SizedBox(
            height: 180,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              child: CachedNetworkImage(
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
                        size: 40,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        _buildArticleDetails(context),
      ],
    );
  }
  
  Widget _buildCardWithThumbnail(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show a thumbnail icon or a generated color based on feed
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _getColorForFeed(article.feedTitle),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                _getIconForFeed(article.feedTitle),
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    article.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    article.feedTitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        article.pubDate != null
                            ? _formatDateTime(article.pubDate!)
                            : 'Unknown date',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildArticleDetails(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            article.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            article.feedTitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 8),
          if (article.description != null)
            Text(
              _stripHtml(article.description!),
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.access_time,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                article.pubDate != null
                    ? _formatDateTime(article.pubDate!)
                    : 'Unknown date',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Generate a consistent color based on the feed title
  Color _getColorForFeed(String feedTitle) {
    // Use a simple hash of the title to generate a consistent color
    final int hash = feedTitle.hashCode.abs();
    final int colorValue = hash % 0xFFFFFF; // Use the hash to get a color value
    return Color(0xFF000000 + colorValue); // Ensure it's not too light by adding base color
  }
  
  // Select an icon based on the feed title
  IconData _getIconForFeed(String feedTitle) {
    final feedLower = feedTitle.toLowerCase();
    
    if (feedLower.contains('tech') || feedLower.contains('technology')) {
      return Icons.computer;
    } else if (feedLower.contains('news')) {
      return Icons.newspaper;
    } else if (feedLower.contains('sport')) {
      return Icons.sports;
    } else if (feedLower.contains('food') || feedLower.contains('recipe')) {
      return Icons.restaurant;
    } else if (feedLower.contains('travel')) {
      return Icons.travel_explore;
    } else if (feedLower.contains('science')) {
      return Icons.science;
    } else if (feedLower.contains('health')) {
      return Icons.health_and_safety;
    } else if (feedLower.contains('finance') || feedLower.contains('money')) {
      return Icons.attach_money;
    } else {
      return Icons.rss_feed;
    }
  }

  Widget _buildCupertinoArticleCard(BuildContext context) {
    final hasImage = article.imageUrl != null && article.imageUrl!.isNotEmpty;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey4.withOpacity(0.3),
              offset: const Offset(0, 2),
              blurRadius: 6,
              spreadRadius: 0,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: hasImage
            ? _buildCupertinoCardWithMainImage(context)
            : _buildCupertinoCardWithThumbnail(context),
      ),
    );
  }
  
  Widget _buildCupertinoCardWithMainImage(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Hero(
          tag: 'article_image_${article.url}',
          child: SizedBox(
            height: 180,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              child: CachedNetworkImage(
                imageUrl: article.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: CupertinoColors.systemGrey6,
                  child: const Center(
                    child: Icon(
                      CupertinoIcons.photo,
                      size: 40,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) {
                  print('Error loading image: $error - URL: $url');
                  return Container(
                    color: CupertinoColors.systemGrey6,
                    child: const Center(
                      child: Icon(
                        CupertinoIcons.photo,
                        size: 40,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        _buildCupertinoArticleDetails(context),
      ],
    );
  }
  
  Widget _buildCupertinoCardWithThumbnail(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show a thumbnail icon or a generated color based on feed
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _getColorForFeed(article.feedTitle),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                _getCupertinoIconForFeed(article.feedTitle),
                size: 40,
                color: CupertinoColors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    article.title,
                    style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    article.feedTitle,
                    style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                          fontSize: 15,
                          color: CupertinoTheme.of(context).primaryColor,
                        ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(
                        CupertinoIcons.time,
                        size: 14,
                        color: CupertinoColors.systemGrey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        article.pubDate != null
                            ? _formatDateTime(article.pubDate!)
                            : 'Unknown date',
                        style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                              fontSize: 13,
                              color: CupertinoColors.systemGrey,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCupertinoArticleDetails(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            article.title,
            style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            article.feedTitle,
            style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  fontSize: 15,
                  color: CupertinoTheme.of(context).primaryColor,
                ),
          ),
          const SizedBox(height: 8),
          if (article.description != null)
            Text(
              _stripHtml(article.description!),
              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                    fontSize: 14,
                    color: CupertinoColors.secondaryLabel,
                  ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                CupertinoIcons.time,
                size: 14,
                color: CupertinoColors.systemGrey,
              ),
              const SizedBox(width: 4),
              Text(
                article.pubDate != null
                    ? _formatDateTime(article.pubDate!)
                    : 'Unknown date',
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                      fontSize: 13,
                      color: CupertinoColors.systemGrey,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // Select a Cupertino icon based on the feed title
  IconData _getCupertinoIconForFeed(String feedTitle) {
    final feedLower = feedTitle.toLowerCase();
    
    if (feedLower.contains('tech') || feedLower.contains('technology')) {
      return CupertinoIcons.device_laptop;
    } else if (feedLower.contains('news')) {
      return CupertinoIcons.news;
    } else if (feedLower.contains('sport')) {
      return CupertinoIcons.sportscourt;
    } else if (feedLower.contains('food') || feedLower.contains('recipe')) {
      return CupertinoIcons.shopping_cart;
    } else if (feedLower.contains('travel')) {
      return CupertinoIcons.airplane;
    } else if (feedLower.contains('science')) {
      return CupertinoIcons.lab_flask_solid;
    } else if (feedLower.contains('health')) {
      return CupertinoIcons.heart;
    } else if (feedLower.contains('finance') || feedLower.contains('money')) {
      return CupertinoIcons.money_dollar;
    } else {
      return CupertinoIcons.antenna_radiowaves_left_right;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat.yMMMd().format(dateTime);
  }

  String _stripHtml(String htmlString) {
    String result = htmlString.replaceAll(RegExp(r'<[^>]*>'), ' ');
    result = result.replaceAll('&nbsp;', ' ');
    result = result.replaceAll('&amp;', '&');
    result = result.replaceAll('&lt;', '<');
    result = result.replaceAll('&gt;', '>');
    result = result.replaceAll('&quot;', '"');
    result = result.replaceAll('&apos;', "'");
    return result.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  // Helper to create a properly formatted image URL
  String _getProxiedImageUrl(String url) {
    // For web, just use direct URLs but add a crossorigin attribute in the HTML
    // The Image widget will handle this properly
    return url;
  }
} 