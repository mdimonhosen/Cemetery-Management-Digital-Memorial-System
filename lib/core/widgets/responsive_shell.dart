import 'package:flutter/material.dart';

class ResponsiveDashboardShell extends StatefulWidget {
  final Widget child;
  final List<NavigationDestination> destinations;
  final List<NavigationRailDestination> railDestinations;
  final int selectedIndex;
  final Function(int) onDestinationSelected;

  const ResponsiveDashboardShell({
    super.key,
    required this.child,
    required this.destinations,
    required this.railDestinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  State<ResponsiveDashboardShell> createState() => _ResponsiveDashboardShellState();
}

class _ResponsiveDashboardShellState extends State<ResponsiveDashboardShell> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 600;

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: widget.selectedIndex,
              onDestinationSelected: widget.onDestinationSelected,
              labelType: NavigationRailLabelType.all,
              destinations: widget.railDestinations,
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: widget.child),
          ],
        ),
      );
    } else {
      return Scaffold(
        body: widget.child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: widget.selectedIndex,
          onDestinationSelected: widget.onDestinationSelected,
          destinations: widget.destinations,
        ),
      );
    }
  }
}
