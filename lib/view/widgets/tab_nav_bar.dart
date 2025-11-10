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
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.newspaper), label: 'News'),
        BottomNavigationBarItem(icon: Icon(Icons.auto_graph), label: 'Trade'),
      ],
    );
  }
}

