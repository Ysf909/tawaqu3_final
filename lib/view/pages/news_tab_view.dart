import 'package:flutter/material.dart';
import 'package:tawaqu3_final/models/news_item.dart';
import 'package:tawaqu3_final/services/api_service.dart';

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
        // sort newest first (smaller age = newer)
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => _onFilterChanged(filter),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final news = _currentNews();

    return Column(
      children: [
        // 🔹 Filter bar
        SizedBox(
          height: 56,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
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

        // 🔹 Content
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text('Error: $_error'))
                  : news.isEmpty
                      ? const Center(child: Text('No news found.'))
                      : RefreshIndicator(
                          onRefresh: _loadAllNews,
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: news.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = news[index];
                              return ListTile(
                                title: Text(item.title),
                                subtitle: Text(
                                  item.summary,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Text(
                                  item.category,
                                  style:
                                      Theme.of(context).textTheme.labelSmall,
                                ),
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }
}
