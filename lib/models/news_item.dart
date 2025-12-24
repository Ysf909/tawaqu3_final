class NewsItem {
  final String title;
  final String category;  // "Crypto", "Forex", "Metals"
  final String summary;
  final Duration age;     // still useful for "x h ago"
  final DateTime? publishedAt; // real time from API

  NewsItem({
    required this.title,
    required this.category,
    required this.summary,
    required this.age,
    this.publishedAt,
  });
}
