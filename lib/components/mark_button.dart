import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MarkButton extends StatefulWidget {
  final List markList;
  final Function getScore;
  final Function getCoefficient;
  final Function update;

  const MarkButton(
      {super.key,
      required this.markList,
      required this.getScore,
      required this.getCoefficient,
      required this.update});

  @override
  State<MarkButton> createState() => _MarkButtonState();
}

class _MarkButtonState extends State<MarkButton> {
  int? modeSliding = 0;
  int colorMode = 0;
  String resultScore = "", changedValue = "";
  bool isDisabled = false, isPressed = false;
  TextEditingController main = TextEditingController();
  double scoreNew = 0, coefficientNew = 0, score = 0, coefficient = 0;

  bool check() {
    if (main.text.isNotEmpty) {
      if (widget.markList[0].round() != int.parse(main.text) &&
          int.parse(main.text) >= 1 &&
          int.parse(main.text) <= 5) return true;
    }
    return false;
  }

  String markSign(double value) {
    double sign = value - value.round();
    if (sign > 0) return "+";
    if (sign < 0) return "-";
    return "";
  }

  void selfClear() {
    setState(() {
      modeSliding = 0;
      colorMode = 0;
      resultScore = "";
      changedValue = "";
      isDisabled = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        score = widget.getScore();
        scoreNew = score;
        coefficient = widget.getCoefficient();
        coefficientNew = coefficient;
        List<String> finish = await showDialog(
            barrierDismissible: false,
            context: context,
            builder: (context) => StatefulBuilder(builder: (context, setState) {
                  return AlertDialog(
                    title: Text(
                      "Информация об оценке",
                      style: TextStyle(
                          color:
                              Theme.of(context).textTheme.displayLarge?.color),
                    ),
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Оценка: ${widget.markList[0]}",
                          style: TextStyle(
                              fontSize: 18,
                              color: Theme.of(context)
                                  .textTheme
                                  .displayLarge
                                  ?.color),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          "Дата: ${widget.markList[2]}",
                          style: TextStyle(
                              fontSize: 18,
                              color: Theme.of(context)
                                  .textTheme
                                  .displayLarge
                                  ?.color),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          "Коэффициент: ${(widget.markList[1] * 100).round() / 100}",
                          style: TextStyle(
                              fontSize: 18,
                              color: Theme.of(context)
                                  .textTheme
                                  .displayLarge
                                  ?.color),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          "Выбрать действие:",
                          style: TextStyle(
                              fontSize: 18,
                              color: Theme.of(context)
                                  .textTheme
                                  .displayLarge
                                  ?.color),
                        ),
                        CupertinoSlidingSegmentedControl(
                          children: {
                            0: Text("Удалить",
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .displayLarge
                                        ?.color,
                                    fontSize: 18)),
                            1: Text("Заменить",
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .displayLarge
                                        ?.color,
                                    fontSize: 18)),
                          },
                          groupValue: modeSliding,
                          onValueChanged: (int? index) {
                            setState(() {
                              modeSliding = index;
                            });
                          },
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          thumbColor: Theme.of(context).colorScheme.secondary,
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 4),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              double value = 0.0;
                              if (modeSliding == 0) {
                                scoreNew = score -
                                    widget.markList[0] * widget.markList[1];
                                coefficientNew =
                                    coefficient - widget.markList[1];
                                value =
                                    (scoreNew / coefficientNew * 100).round() /
                                        100;
                                resultScore =
                                    "${(score / coefficient * 100).round() / 100}   →   $value";
                                isDisabled = true;
                                isPressed = true;
                              } else {
                                if (check()) {
                                  scoreNew = score -
                                      widget.markList[0] * widget.markList[1] +
                                      double.parse(main.text) *
                                          widget.markList[1];
                                  coefficientNew = coefficient;
                                  value = (scoreNew / coefficientNew * 100)
                                          .round() /
                                      100;
                                  resultScore =
                                      "${(score / coefficient * 100).round() / 100}   →   $value";
                                  isDisabled = true;
                                  isPressed = true;
                                }
                              }
                            });
                            FocusManager.instance.primaryFocus?.unfocus();
                          },
                          child: Container(
                              height: 48,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 25.0),
                              decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(10.0)),
                              child: Center(
                                child: Text(
                                  'Применить',
                                  style: TextStyle(
                                      fontSize: 18,
                                      color: Theme.of(context)
                                          .textTheme
                                          .displaySmall
                                          ?.color),
                                ),
                              )),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Padding(
                            padding: modeSliding == 1
                                ? const EdgeInsets.only(
                                    top: 5, bottom: 5, right: 60, left: 60)
                                : const EdgeInsets.all(0),
                            child: modeSliding == 1
                                ? TextField(
                                    controller: main,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .textTheme
                                            .displayLarge
                                            ?.color,
                                        fontSize: 28),
                                    decoration: InputDecoration(
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                            color: Colors.grey),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      hintText: "Заменить на",
                                      hintStyle: const TextStyle(
                                          color: Colors.grey,
                                          fontWeight: FontWeight.w400,
                                          fontSize: 18),
                                    ),
                                  )
                                : const SizedBox(
                                    height: 0,
                                  )),
                        Text(
                          isDisabled ? "Результат:" : "",
                          style: TextStyle(
                              fontSize: 18,
                              color: Theme.of(context)
                                  .textTheme
                                  .displayLarge
                                  ?.color),
                        ),
                        Text(
                          resultScore,
                          style: TextStyle(
                              fontSize: 32,
                              color: Theme.of(context)
                                  .textTheme
                                  .displayLarge
                                  ?.color),
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (colorMode == 0) {
                                  selfClear();
                                }
                                Navigator.pop(context,
                                    [score.toString(), coefficient.toString()]);
                              },
                              child: Text(
                                "Отмена",
                                style: TextStyle(
                                    fontSize: 18,
                                    color: Theme.of(context)
                                        .textTheme
                                        .displayLarge
                                        ?.color),
                              ),
                            ),
                            const SizedBox(
                              width: 20,
                            ),
                            GestureDetector(
                              onTap: () {
                                if (isDisabled) {
                                  if (modeSliding == 0) {
                                    colorMode = 1;
                                  } else {
                                    colorMode = 2;
                                    changedValue =
                                        "${widget.markList[0].round()}→${main.text}";
                                  }
                                }
                                Navigator.pop(
                                    context,
                                    isPressed
                                        ? [
                                            scoreNew.toString(),
                                            coefficientNew.toString()
                                          ]
                                        : [
                                            score.toString(),
                                            coefficient.toString()
                                          ]);
                              },
                              child: Text(
                                "Ок",
                                style: TextStyle(
                                    fontSize: 18,
                                    color: Theme.of(context)
                                        .textTheme
                                        .displayLarge
                                        ?.color),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    insetPadding: const EdgeInsets.symmetric(vertical: 70),
                  );
                }));
        setState(() {
          colorMode;
          widget.update(finish[0], finish[1]);
        });
      },
      child: Column(
        children: [
          Text(
            colorMode == 2 && isPressed
                ? changedValue
                : "${widget.markList[0].round()}${markSign(widget.markList[0])}",
            style: TextStyle(
                fontSize: 36,
                color: colorMode == 0
                    ? Theme.of(context).textTheme.displayLarge?.color
                    : colorMode == 1 && isPressed
                        ? Colors.red
                        : Colors.blue,
                decoration: colorMode == 1 ? TextDecoration.lineThrough : null),
          ),
          Text(
            "${widget.markList[1]}",
            style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).textTheme.displayLarge?.color),
          ),
        ],
      ),
    );
  }
}
