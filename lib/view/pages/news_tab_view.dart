import 'package:flutter/material.dart';
import 'package:tawaqu3_final/view/widgets/card_container.dart';
import 'package:tawaqu3_final/view/widgets/section_title.dart';
import '../../models/news_item.dart';

class NewsTabView extends StatelessWidget {
  final List<NewsItem> news;

  const NewsTabView({
    super.key,
    required this.news,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle('Market News'),
          ...news.map(
            (n) => CardContainer(
              child: ListTile(
                title: Text(n.title),
                subtitle: Text(
                  """
${n.category} • ${n.age.inHours}h ago
${n.summary}
""",
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
