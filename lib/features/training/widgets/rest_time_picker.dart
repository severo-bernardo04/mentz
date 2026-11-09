import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Seletor do tempo de descanso em carrossel, com minutos e segundos.
/// Devolve o total em segundos em [onChanged].
class RestTimePicker extends StatefulWidget {
  final int initialSeconds;
  final ValueChanged<int> onChanged;

  const RestTimePicker({
    super.key,
    required this.initialSeconds,
    required this.onChanged,
  });

  @override
  State<RestTimePicker> createState() => _RestTimePickerState();
}

class _RestTimePickerState extends State<RestTimePicker> {
  static const _maxMinutes = 15;
  static const _itemExtent = 40.0;

  late int _minutes = (widget.initialSeconds ~/ 60).clamp(0, _maxMinutes);
  late int _seconds = widget.initialSeconds % 60;

  late final _minutesCtrl = FixedExtentScrollController(initialItem: _minutes);
  late final _secondsCtrl = FixedExtentScrollController(initialItem: _seconds);

  @override
  void dispose() {
    _minutesCtrl.dispose();
    _secondsCtrl.dispose();
    super.dispose();
  }

  void _notify() => widget.onChanged(_minutes * 60 + _seconds);

  /// Uma coluna do carrossel, com números de 0 até [count] - 1.
  Widget _buildWheel({
    required Key key,
    required FixedExtentScrollController controller,
    required int count,
    required ValueChanged<int> onSelected,
  }) {
    final cs = Theme.of(context).colorScheme;

    return CupertinoPicker(
      key: key,
      scrollController: controller,
      itemExtent: _itemExtent,
      selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
        background: cs.primary.withAlpha(25),
      ),
      onSelectedItemChanged: onSelected,
      children: [
        for (var i = 0; i < count; i++)
          Center(
            child: Text(
              i.toString().padLeft(2, '0'),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.titleSmall;

    return SizedBox(
      height: 150,
      child: Row(
        children: [
          Expanded(
            child: _buildWheel(
              key: const Key('rest_minutes_picker'),
              controller: _minutesCtrl,
              count: _maxMinutes + 1,
              onSelected: (value) {
                _minutes = value;
                _notify();
              },
            ),
          ),
          Text('min', style: labelStyle),
          const SizedBox(width: 12),
          Expanded(
            child: _buildWheel(
              key: const Key('rest_seconds_picker'),
              controller: _secondsCtrl,
              count: 60,
              onSelected: (value) {
                _seconds = value;
                _notify();
              },
            ),
          ),
          Text('s', style: labelStyle),
        ],
      ),
    );
  }
}
