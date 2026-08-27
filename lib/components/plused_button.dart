import 'package:flutter/material.dart';

class PlusedButton extends StatefulWidget {
  final List<double> markList;
  final Function getScore;
  final Function getCoefficient;
  final Function update;
  final Function delete;

  const PlusedButton({
    super.key,
    required this.getScore,
    required this.getCoefficient,
    required this.markList,
    required this.update,
    required this.delete,
  });

  @override
  State<PlusedButton> createState() => _PlusedButtonState();
}

class _PlusedButtonState extends State<PlusedButton> {
  String markSign(double value) {
    double sign = value - value.round();
    if (sign > 0) return "+";
    if (sign < 0) return "-";
    return "";
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        bool delete = await showDialog(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                content: SizedBox(
                  height: 90,
                  child: Column(
                    children: [
                      Text(
                        'Вы уверены, что хотите удалить оценку?',
                        style: TextStyle(
                          fontSize: 16,
                          color:
                              Theme.of(context).textTheme.displayLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context, true);
                            },
                            child: Text(
                              'Удалить',
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context)
                                    .textTheme
                                    .displayLarge
                                    ?.color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context, false);
                            },
                            child: Text(
                              'Отмена',
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context)
                                    .textTheme
                                    .displayLarge
                                    ?.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
        if (delete) {
          widget.update(
            (widget.getScore() - widget.markList[0] * widget.markList[1])
                .toString(),
            (widget.getCoefficient() - widget.markList[1]).toString(),
          );
          widget.delete(widget.markList);
        }
      },
      child: Column(
        children: [
          Text(
            "${widget.markList[0].round()}${markSign((widget.markList[0] * 100).round() / 100)}",
            style: const TextStyle(fontSize: 36, color: Colors.green),
          ),
          Text(
            ((widget.markList[1] * 100).round() / 100).toString(),
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(context).textTheme.displayLarge?.color,
            ),
          ),
        ],
      ),
    );
  }
}
