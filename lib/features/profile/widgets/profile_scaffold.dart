import 'package:flutter/material.dart';
import 'package:mentz/widgets/app_background.dart';
import 'package:mentz/widgets/fade_slide_in.dart';

class ProfileTabSpec {
  final IconData icon;
  final String label;

  const ProfileTabSpec(this.icon, this.label);
}

/// Estrutura comum: AppBar + cabeçalho que rola + abas fixas no topo.
class ProfileScaffold extends StatelessWidget {
  final String title;
  final Widget header;
  final List<ProfileTabSpec> tabs;
  final List<Widget> pages;
  final Widget? floatingActionButton;

  const ProfileScaffold({
    super.key,
    required this.title,
    required this.header,
    required this.tabs,
    required this.pages,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            title,
            style: TextStyle(color: cs.primary, fontWeight: FontWeight.w800),
          ),
          scrolledUnderElevation: 0,
        ),
        floatingActionButton: floatingActionButton,
        body: AppBackground(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: NestedScrollView(
                headerSliverBuilder: (context, innerScrolled) => [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: FadeSlideIn(child: header),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _PinnedBarDelegate(
                      height: 58,
                      color: cs.surface,
                      child: _ProfileTabBar(tabs),
                    ),
                  ),
                ],
                body: TabBarView(children: pages),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileTabBar extends StatelessWidget {
  final List<ProfileTabSpec> tabs;

  const _ProfileTabBar(this.tabs);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return TabBar(
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      dividerColor: Colors.transparent,
      indicatorSize: TabBarIndicatorSize.tab,
      indicator: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      labelColor: cs.onPrimary,
      unselectedLabelColor: cs.onSurfaceVariant,
      splashBorderRadius: BorderRadius.circular(14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      labelPadding: const EdgeInsets.symmetric(horizontal: 14),
      labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      unselectedLabelStyle:
          const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      tabs: [
        for (final t in tabs)
          Tab(
            height: 40,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(t.icon, size: 18),
                const SizedBox(width: 6),
                Text(t.label),
              ],
            ),
          ),
      ],
    );
  }
}

class _PinnedBarDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Color color;
  final Widget child;

  _PinnedBarDelegate({
    required this.height,
    required this.color,
    required this.child,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: color,
      elevation: overlapsContent ? 2 : 0,
      child: Align(alignment: Alignment.centerLeft, child: child),
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedBarDelegate old) =>
      old.child != child || old.color != color || old.height != height;
}