// ARQUIVO NOVO — crie em lib/screens/profile/profile_widgets.dart. Não altera nenhum arquivo existente por si só.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../auth_widgets.dart';

// ───────────────────────── Estrutura da tela ─────────────────────────

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

    final tabBar = TabBar(
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

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            title,
            style: TextStyle(
              color: cs.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          scrolledUnderElevation: 0,
        ),
        floatingActionButton: floatingActionButton,
        body: AuthBackground(
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
                      child: tabBar,
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

/// Lista rolável padrão de cada aba.
class ProfileTabPage extends StatelessWidget {
  final List<Widget> children;
  const ProfileTabPage({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: children,
    );
  }
}

// ───────────────────────── Cabeçalho ─────────────────────────

class ProfileHeader extends StatelessWidget {
  final String name;
  final String subtitle;
  final String? photoUrl;
  final List<Widget> chips;
  final VoidCallback? onEditPhoto;

  const ProfileHeader({
    super.key,
    required this.name,
    required this.subtitle,
    this.photoUrl,
    this.chips = const [],
    this.onEditPhoto,
  });

  String get _initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return AuthCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: cs.primary,
                    backgroundImage:
                        photoUrl != null ? NetworkImage(photoUrl!) : null,
                    child: photoUrl == null
                        ? Text(
                            _initials,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: cs.onPrimary,
                            ),
                          )
                        : null,
                  ),
                  if (onEditPhoto != null)
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: Material(
                        color: cs.secondaryContainer,
                        shape: CircleBorder(
                          side: BorderSide(color: cs.surface, width: 2),
                        ),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onEditPhoto,
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              Icons.photo_camera_outlined,
                              size: 16,
                              color: cs.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, children: chips),
          ],
        ],
      ),
    );
  }
}

// ───────────────────────── Blocos de conteúdo ─────────────────────────

class SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const SectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface.withAlpha(235),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.primaryContainer,
                ),
                child: Icon(icon, size: 18, color: cs.onPrimaryContainer),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? valueWidget;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueWidget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                valueWidget ??
                    Text(
                      value,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const StatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(110),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: cs.primary, size: 22),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color; // null = neutro

  const StatusChip({super.key, required this.label, this.icon, this.color});

  factory StatusChip.active(bool active, {String? activeLabel, String? inactiveLabel}) {
    return StatusChip(
      label: active ? (activeLabel ?? 'Ativa') : (inactiveLabel ?? 'Inativa'),
      icon: active ? Icons.check_circle : Icons.pause_circle,
      color: active ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = color ?? cs.onSecondaryContainer;
    final bg = color != null ? color!.withAlpha(30) : cs.secondaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Aviso de privacidade para dados sensíveis.
class PrivacyBanner extends StatelessWidget {
  final String text;
  final bool hidden;
  final VoidCallback? onToggle;

  const PrivacyBanner({
    super.key,
    required this.text,
    this.hidden = false,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer.withAlpha(200),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, color: cs.onTertiaryContainer, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: cs.onTertiaryContainer,
                fontSize: 12.5,
                height: 1.3,
              ),
            ),
          ),
          if (onToggle != null)
            IconButton(
              tooltip: hidden ? 'Mostrar valores' : 'Ocultar valores',
              onPressed: onToggle,
              icon: Icon(
                hidden
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: cs.onTertiaryContainer,
              ),
            ),
        ],
      ),
    );
  }
}

class EmptyHint extends StatelessWidget {
  final String text;
  const EmptyHint(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(text, style: TextStyle(color: cs.onSurfaceVariant)),
      ),
    );
  }
}

// ───────────────────────── Gráficos (sem dependências) ─────────────────────────

class SimpleLineChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final String unit;
  final double height;

  const SimpleLineChart({
    super.key,
    required this.values,
    required this.labels,
    this.unit = '',
    this.height = 150,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _LinePainter(
              values: values,
              unit: unit,
              lineColor: cs.primary,
              gridColor: cs.outlineVariant,
              textColor: cs.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final l in labels)
              Text(
                l,
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
          ],
        ),
      ],
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<double> values;
  final String unit;
  final Color lineColor;
  final Color gridColor;
  final Color textColor;

  _LinePainter({
    required this.values,
    required this.unit,
    required this.lineColor,
    required this.gridColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    const padX = 14.0;
    const padTop = 18.0;
    const padBottom = 8.0;

    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final range = (maxV - minV) == 0 ? 1.0 : (maxV - minV);

    final w = size.width - padX * 2;
    final h = size.height - padTop - padBottom;

    Offset point(int i) {
      final x = padX + (w * i / (values.length - 1));
      final y = padTop + h - ((values[i] - minV) / range) * h;
      return Offset(x, y);
    }

    // linhas de grade
    final grid = Paint()
      ..color = gridColor.withAlpha(120)
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final y = padTop + h * i / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final pts = [for (var i = 0; i < values.length; i++) point(i)];

    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      line.lineTo(p.dx, p.dy);
    }

    final fill = Path.from(line)
      ..lineTo(pts.last.dx, size.height)
      ..lineTo(pts.first.dx, size.height)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [lineColor.withAlpha(70), lineColor.withAlpha(0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      line,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    for (final p in pts) {
      canvas.drawCircle(p, 5, Paint()..color = Colors.white);
      canvas.drawCircle(p, 3.5, Paint()..color = lineColor);
    }

    // rótulo do último valor
    final tp = TextPainter(
      text: TextSpan(
        text: '${values.last.toStringAsFixed(1)}$unit',
        style: TextStyle(
          color: lineColor,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final last = pts.last;
    final dx = math.min(last.dx - tp.width / 2, size.width - tp.width);
    tp.paint(canvas, Offset(math.max(0, dx), math.max(0, last.dy - 22)));
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) =>
      old.values != values || old.lineColor != lineColor;
}

class SimpleBarChart extends StatelessWidget {
  final List<num> values;
  final List<String> labels;
  final double height;

  const SimpleBarChart({
    super.key,
    required this.values,
    required this.labels,
    this.height = 130,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final maxV = values.isEmpty ? 1 : values.reduce(math.max);

    return SizedBox(
      height: height + 36,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${values[i]}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TweenAnimationBuilder<double>(
                      tween: Tween(
                        begin: 0,
                        end: maxV == 0 ? 0.0 : values[i] / maxV,
                      ),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) => Container(
                        height: math.max(4.0, height * v),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: i == values.length - 1
                              ? cs.primary
                              : cs.primary.withAlpha(110),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}