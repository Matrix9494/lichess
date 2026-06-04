import 'dart:math';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lichess_mobile/src/model/common/chess960.dart';
import 'package:lichess_mobile/src/styles/styles.dart';
import 'package:lichess_mobile/src/utils/l10n_context.dart';
import 'package:lichess_mobile/src/widgets/adaptive_bottom_sheet.dart';
import 'package:lichess_mobile/src/widgets/board_preview.dart';

({int index, String fen}) chess960PositionResult(int index) {
  final position = chess960Position(index);
  return (index: index, fen: position.fen);
}

Future<({int index, String fen})?> showChess960PositionPicker(
  BuildContext context, {
  int initialIndex = 518,
}) {
  return showModalBottomSheet<({int index, String fen})>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _Chess960PositionPicker(initialIndex: initialIndex),
  );
}

class _Chess960PositionPicker extends StatefulWidget {
  const _Chess960PositionPicker({required this.initialIndex});

  final int initialIndex;

  @override
  State<_Chess960PositionPicker> createState() => _Chess960PositionPickerState();
}

class _Chess960PositionPickerState extends State<_Chess960PositionPicker> {
  final _random = Random.secure();
  late int _index;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, 959);
    _controller = TextEditingController(text: _index.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setIndex(int value) {
    final next = value.clamp(0, 959);
    setState(() {
      _index = next;
      _controller.text = next.toString();
      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final fen = chess960Position(_index).fen;

    return BottomSheetScrollableContainer(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      children: [
        Text(
          context.l10n.chess960StartPosition(_index.toString()),
          style: Styles.sectionTitle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        SmallBoardPreview(
          orientation: Side.white,
          fen: fen,
          padding: EdgeInsets.zero,
          description: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _Chess960PositionFormatter(),
                ],
                decoration: InputDecoration(
                  labelText: context.l10n.startPosition,
                  helperText: '0 - 959',
                  suffixIcon: IconButton(
                    tooltip: context.l10n.randomChess960Position,
                    icon: const Icon(Icons.casino_outlined),
                    onPressed: () => _setIndex(_random.nextInt(960)),
                  ),
                ),
                onChanged: (value) {
                  final next = int.tryParse(value);
                  if (next != null && next != _index) {
                    setState(() => _index = next.clamp(0, 959));
                  }
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    tooltip: '-1',
                    onPressed: _index > 0 ? () => _setIndex(_index - 1) : null,
                    icon: const Icon(Icons.remove),
                  ),
                  IconButton(
                    tooltip: '+1',
                    onPressed: _index < 959 ? () => _setIndex(_index + 1) : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(context.l10n.cancel),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop((index: _index, fen: fen)),
                child: Text(context.l10n.loadPosition),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Chess960PositionFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final value = int.tryParse(newValue.text);
    if (value == null || value > 959) return oldValue;
    return newValue;
  }
}
