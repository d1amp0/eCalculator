import 'package:ecalculator/domain/calculator_scenario.dart';
import 'package:ecalculator/domain/mark_format.dart';
import 'package:ecalculator/other/mark_colors.dart';
import 'package:flutter/material.dart';

class MarkButton extends StatelessWidget {
  const MarkButton({
    super.key,
    required this.item,
    required this.onPressed,
  });

  static const tileSize = Size(92, 96);

  final ScenarioMark item;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final changed = item.isAdded || item.isEdited || item.isExcluded;
    final stateIcon = item.isAdded
        ? Icons.add_circle_outline
        : item.isExcluded
            ? Icons.remove_circle_outline
            : item.isEdited
                ? Icons.edit_outlined
                : null;
    final stateLabel = item.isAdded
        ? 'Новая'
        : item.isExcluded
            ? 'Исключена'
            : item.isEdited
                ? 'Изменена'
                : null;
    final valueColor = markValueColor(scheme, item.mark.value);

    return Semantics(
      button: true,
      label: [
        'Оценка ${formatMarkValue(item.mark.value)}',
        'коэффициент ${formatWeight(item.mark.weight)}',
        if (stateLabel != null) stateLabel.toLowerCase(),
      ].join(', '),
      child: SizedBox.fromSize(
        key: ValueKey('mark-tile-${item.mark.id}'),
        size: tileSize,
        child: Material(
          color: markTileColor(scheme, item.mark.value),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color:
                  changed ? scheme.primary : valueColor.withValues(alpha: 0.5),
              width: changed ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            key: ValueKey('mark-${item.mark.id}'),
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
              child: Column(
                children: [
                  SizedBox(
                    height: 30,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        item.isEdited
                            ? '${formatMarkValue(item.original!.value)} → ${formatMarkValue(item.mark.value)}'
                            : formatMarkValue(item.mark.value),
                        key: ValueKey('mark-value-${item.mark.id}'),
                        maxLines: 1,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: valueColor,
                              fontWeight: FontWeight.w800,
                              decoration: item.isExcluded
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: valueColor,
                              decorationThickness: 2,
                            ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 22,
                    child: Center(
                      child: Text(
                        '×${formatWeight(item.mark.weight)}',
                        key: ValueKey('mark-weight-${item.mark.id}'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 24,
                    child: Center(
                      child: stateIcon == null
                          ? const SizedBox.square(dimension: 16)
                          : Tooltip(
                              message: stateLabel!,
                              child: Icon(
                                stateIcon,
                                key: ValueKey('mark-state-${item.mark.id}'),
                                size: 17,
                                color: scheme.onSurface,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
