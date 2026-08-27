import 'package:ecalculator/domain/calculator_scenario.dart';
import 'package:ecalculator/domain/mark_format.dart';
import 'package:flutter/material.dart';

class MarkButton extends StatelessWidget {
  const MarkButton({
    super.key,
    required this.item,
    required this.onPressed,
  });

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

    return Semantics(
      button: true,
      label: [
        'Оценка ${formatMarkValue(item.mark.value)}',
        'коэффициент ${formatWeight(item.mark.weight)}',
        if (stateLabel != null) stateLabel,
      ].join(', '),
      child: Opacity(
        opacity: item.isExcluded ? 0.55 : 1,
        child: Material(
          color: changed
              ? scheme.primaryContainer.withValues(alpha: 0.55)
              : scheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: changed ? scheme.primary : scheme.outlineVariant,
            ),
          ),
          child: InkWell(
            key: ValueKey('mark-${item.mark.id}'),
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 76, minHeight: 76),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.isEdited
                          ? '${formatMarkValue(item.original!.value)} → ${formatMarkValue(item.mark.value)}'
                          : formatMarkValue(item.mark.value),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            decoration: item.isExcluded
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '×${formatWeight(item.mark.weight)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (stateIcon != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(stateIcon, size: 13),
                          const SizedBox(width: 3),
                          Text(
                            stateLabel!,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
