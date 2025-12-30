import 'package:flutter/material.dart';
import 'package:tawaqu3_final/models/news_item.dart';
import 'package:tawaqu3_final/services/api_service.dart';
import 'package:tawaqu3_final/view/widgets/card_container.dart';

enum NewsFilter { all, forex, crypto, metals }

class NewsView extends StatefulWidget {
  const NewsView({super.key}); 

  @override
  State<NewsView> createState() => _NewsViewState();
}

class _NewsViewState extends State<NewsView> {
  final ApiService _api = ApiService();

  NewsFilter _selected = NewsFilter.all;

  bool _loading = true;
  String? _error;

  List<NewsItem> _crypto = [];
  List<NewsItem> _forex = [];
  List<NewsItem> _metals = [];

  @override
  void initState() {
    super.initState();
    _loadAllNews();
  }

  Future<void> _loadAllNews() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait<List<NewsItem>>([
        _api.fetchCryptoNews(),
        _api.fetchForexNews(),
        _api.fetchMetalsNews(),
      ]);

      _crypto = results[0];
      _forex = results[1];
      _metals = results[2];

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<NewsItem> _currentNews() {
    switch (_selected) {
      case NewsFilter.crypto:
        return _crypto;
      case NewsFilter.forex:
        return _forex;
      case NewsFilter.metals:
        return _metals;
      case NewsFilter.all:
      default:
        final all = [..._crypto, ..._forex, ..._metals];
        // newest first (age is Duration since publish)
        all.sort((a, b) => a.age.compareTo(b.age));
        return all;
    }
  }

  void _onFilterChanged(NewsFilter filter) {
    setState(() {
      _selected = filter;
    });
  }

  Widget _buildFilterChip(String label, NewsFilter filter) {
    final isSelected = _selected == filter;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        labelStyle: TextStyle(
          color: isSelected
              ? theme.colorScheme.onPrimary
              : theme.textTheme.bodyMedium?.color,
        ),
        selectedColor: theme.colorScheme.primary,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        onSelected: (_) => _onFilterChanged(filter),
      ),
    );
  }

  String _formatAge(Duration age) {
    if (age.inMinutes < 1) return 'Just now';
    if (age.inMinutes < 60) return '${age.inMinutes}m ago';
    if (age.inHours < 24) return '${age.inHours}h ago';
    return '${age.inDays}d ago';
  }

  String _formatPublished(DateTime dt) {
    final local = dt.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d  $h:$min';
  }

  Color _categoryColor(String category, BuildContext context) {
    final theme = Theme.of(context);
    switch (category.toLowerCase()) {
      case 'crypto':
        return Colors.orangeAccent;
      case 'forex':
        return Colors.blueAccent;
      case 'metals':
        return Colors.amber;
      default:
        return theme.colorScheme.primary;
    }
  }

  void _showNewsDetails(NewsItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        final catColor = _categoryColor(item.category, context);

        final pubText = item.publishedAt != null
            ? _formatPublished(item.publishedAt!)
            : 'Unknown time';

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: catColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          item.category,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: catColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            pubText,
                            style: theme.textTheme.labelSmall,
                          ),
                          Text(
                            _formatAge(item.age),
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    item.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.summary.isNotEmpty
                        ? item.summary
                        : 'No additional details available.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNewsCard(NewsItem item) {
    final theme = Theme.of(context);
    final catColor = _categoryColor(item.category, context);

    final pubText = item.publishedAt != null
        ? _formatPublished(item.publishedAt!)
        : _formatAge(item.age); // fallback

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showNewsDetails(item),
        child: CardContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // top row: category pill + time
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: catColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      item.category,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: catColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    pubText,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.summary.isNotEmpty
                    ? item.summary
                    : 'No summary available.',
                maxLines: 3, // 👈 only preview
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final news = _currentNews();
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Text(
                  'Market News',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: _loadAllNews,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),

          // Filter bar
          SizedBox(
            height: 56,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Row(
                children: [
                  _buildFilterChip("All", NewsFilter.all),
                  _buildFilterChip("Forex", NewsFilter.forex),
                  _buildFilterChip("Crypto", NewsFilter.crypto),
                  _buildFilterChip("Metals", NewsFilter.metals),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Error loading news.\n$_error',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      )
                    : news.isEmpty
                        ? const Center(
                            child: Text(
                              'No news found.\nTry refreshing in a moment.',
                              textAlign: TextAlign.center,
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadAllNews,
                            child: ListView.builder(
                              physics:
                                  const AlwaysScrollableScrollPhysics(),
                              itemCount: news.length,
                              itemBuilder: (context, index) {
                                final item = news[index];
                                return _buildNewsCard(item);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
