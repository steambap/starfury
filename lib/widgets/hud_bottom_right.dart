import 'package:flutter/material.dart';
import 'package:starflame/cell.dart';
import 'package:watch_it/watch_it.dart';

import 'package:starflame/styles.dart';
import 'package:starflame/scifi_game.dart';
import 'package:starflame/hud_state.dart';

class HudBottomRight extends StatelessWidget with WatchItMixin {
  const HudBottomRight(this.game, {super.key});

  static const id = 'hud_bottom_right';

  final ScifiGame game;

  @override
  Widget build(BuildContext context) {
    final cell = watchValue((HudState hudState) => hudState.cell);

    return SafeArea(
      minimum: const EdgeInsets.all(8),
      child: Align(
        alignment: Alignment.bottomRight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.panelBackground,
                border: Border.all(color: AppTheme.panelBorder, width: 1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: _cellPanel(cell),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                if (game.watchMode) {
                  return;
                }
                game.cycle.endTurn();
              },
              style: AppTheme.primaryButton,
              child: const Text('Next Turn'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cellPanel(Cell cell) {
    final planetStr = cell.planet?.name ?? '-';
    final ownerStr = cell.planet?.ownerName() ?? '-';
    String cellStr = '-';
    if (cell.isValid()) {
      cellStr = cell.toShortString();
    }

    return Table(
      columnWidths: const {0: FixedColumnWidth(100), 1: FixedColumnWidth(144)},
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          children: [
            const Text('Planet:', style: AppTheme.label12),
            Text(planetStr, style: AppTheme.label12),
          ],
        ),
        TableRow(
          children: [
            const Text('Owned By:', style: AppTheme.label12),
            Text(ownerStr, style: AppTheme.label12),
          ],
        ),
        TableRow(
          children: [
            const Text('Coordinates:', style: AppTheme.label12),
            Text(cellStr, style: AppTheme.label12),
          ],
        ),
      ],
    );
  }
}
