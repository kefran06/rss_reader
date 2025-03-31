class Article {
  final String title;
  final String? description;
  final String? content;
  final String? imageUrl;
  final String url;
  final DateTime? pubDate;
  final String feedTitle;
  final String feedUrl;
  final String? author;

  Article({
    required this.title,
    this.description,
    this.content,
    this.imageUrl,
    required this.url,
    this.pubDate,
    required this.feedTitle,
    required this.feedUrl,
    this.author,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'content': content,
      'imageUrl': imageUrl,
      'url': url,
      'pubDate': pubDate?.toIso8601String(),
      'feedTitle': feedTitle,
      'feedUrl': feedUrl,
      'author': author,
    };
  }

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: json['title'] as String,
      description: json['description'] as String?,
      content: json['content'] as String?,
      imageUrl: json['imageUrl'] as String?,
      url: json['url'] as String? ?? json['link'] as String, // Backward compatibility with old 'link' field
      pubDate: json['pubDate'] != null ? DateTime.parse(json['pubDate'] as String) : null,
      feedTitle: json['feedTitle'] as String,
      feedUrl: json['feedUrl'] as String,
      author: json['author'] as String?,
    );
  }
} 