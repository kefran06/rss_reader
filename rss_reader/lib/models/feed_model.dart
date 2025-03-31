class Feed {
  final String title;
  final String url;
  final String? description;
  final String? imageUrl;

  Feed({
    required this.title,
    required this.url,
    this.description,
    this.imageUrl,
  });

  Feed copyWith({
    String? title,
    String? url,
    String? description,
    String? imageUrl,
  }) {
    return Feed(
      title: title ?? this.title,
      url: url ?? this.url,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'description': description,
      'imageUrl': imageUrl,
    };
  }

  factory Feed.fromJson(Map<String, dynamic> json) {
    return Feed(
      title: json['title'] as String,
      url: json['url'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }
} 