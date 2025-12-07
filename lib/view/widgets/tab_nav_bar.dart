import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_model/navigation_view_model.dart';

class TabNavBar extends StatelessWidget {
  const TabNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationViewModel>();
    return BottomNavigationBar(
  currentIndex: nav.currentIndex,
  onTap: nav.setIndex,
  type: BottomNavigationBarType.fixed,
  items: const [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_rounded),
      label: 'Home',   // 0
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.article_rounded),
      label: 'News',   // 1
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.swap_horiz_rounded),
      label: 'Trade',  // 2
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.leaderboard_rounded),
      label: 'Top',    // 3
    ),
  ],
);

  }
}

