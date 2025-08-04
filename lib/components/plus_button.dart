import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlusButton extends StatefulWidget {
  final Function getScore;
  final Function getCoefficient;
  final Function add;
  final Function update;

  const PlusButton(
      {super.key,
      required this.getScore,
      required this.getCoefficient,
      required this.add,
      required this.update});

  @override
  State<PlusButton> createState() => _PlusButtonState();
}

class _PlusButtonState extends State<PlusButton> {
  String resultScore = "";
  bool isDisabled = false, isPressed = false, withPM = false;
  double score = 0, coefficient = 0, scoreNew = 0, coefficientNew = 0;
  int? markSliding = 0;
  TextEditingController mainMark = TextEditingController(),
      mainCoefficient = TextEditingController();

  bool check() {
    if (mainCoefficient.text.isNotEmpty && mainMark.text.isNotEmpty) {
      if (double.parse(mainMark.text) >= 1 &&
          double.parse(mainMark.text) <= 5 &&
          double.parse(mainCoefficient.text) >= 0) {
        return true;
      }
    }
    return false;
  }

  void clear() {
    setState(() {
      resultScore = "";
      isDisabled = false;
      scoreNew = score;
      coefficientNew = coefficient;
    });
  }

  void getPM() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? mark = prefs.getBool("mark_type");
    mark != null ? withPM = mark : withPM = false;
    setState(() {
      withPM;
    });
  }

  @override
  void initState() {
    super.initState();
    getPM();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        score = widget.getScore();
        scoreNew = score;
        coefficient = widget.getCoefficient();
        coefficientNew = coefficient;
        List<double> waiting = await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => StatefulBuilder(builder: (context, setState) {
                  return AlertDialog(
                    title: Text(
                      "Добавить оценку",
                      style: TextStyle(
                          color:
                              Theme.of(context).textTheme.displayLarge?.color),
                    ),
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                            padding: const EdgeInsets.only(
                                top: 5, bottom: 5, right: 60, left: 60),
                            child: TextField(
                              controller: mainMark,
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
                                  borderSide:
                                      const BorderSide(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                hintText: "Оценка",
                                hintStyle: const TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 18),
                              ),
                            )),
                        Padding(
                            padding: const EdgeInsets.only(
                                top: 5, bottom: 5, right: 60, left: 60),
                            child: TextField(
                              controller: mainCoefficient,
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
                                  borderSide:
                                      const BorderSide(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                hintText: "Коэффициент",
                                hintStyle: const TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 18),
                              ),
                            )),
                        Center(
                          child: withPM ? Text(
                            "Какой знак?",
                            style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .displayLarge
                                    ?.color,
                                fontSize: 18),
                          ) : null,
                        ),
                        Center(
                          child: withPM
                              ? CupertinoSlidingSegmentedControl(
                                  children: {
                                    0: Text("Ничего",
                                        style: TextStyle(
                                            color: markSliding == 0
                                                ? Theme.of(context)
                                                    .textTheme
                                                    .displayLarge
                                                    ?.color
                                                : Theme.of(context)
                                                    .textTheme
                                                    .displaySmall
                                                    ?.color,
                                            fontSize: 18)),
                                    1: Text("+",
                                        style: TextStyle(
                                            color: markSliding == 1
                                                ? Theme.of(context)
                                                    .textTheme
                                                    .displayLarge
                                                    ?.color
                                                : Theme.of(context)
                                                    .textTheme
                                                    .displaySmall
                                                    ?.color,
                                            fontSize: 18)),
                                    2: Text("-",
                                        style: TextStyle(
                                            color: markSliding == 2
                                                ? Theme.of(context)
                                                    .textTheme
                                                    .displayLarge
                                                    ?.color
                                                : Theme.of(context)
                                                    .textTheme
                                                    .displaySmall
                                                    ?.color,
                                            fontSize: 18)),
                                  },
                                  groupValue: markSliding,
                                  onValueChanged: (int? index) {
                                    setState(() {
                                      markSliding = index;
                                    });
                                  },
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  thumbColor:
                                      Theme.of(context).colorScheme.secondary,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 3, horizontal: 3),
                                )
                              : null,
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              double value = 0.0;
                              if (check()) {
                                scoreNew = score +
                                    double.parse(mainMark.text) *
                                        double.parse(mainCoefficient.text);
                                if (withPM) {
                                  if (markSliding == 1) {
                                    scoreNew += 0.2 * double.parse(mainCoefficient.text);
                                  }
                                  if (markSliding == 2) {
                                    scoreNew -= 0.2 * double.parse(mainCoefficient.text);
                                  }
                                }
                                coefficientNew = coefficient +
                                    double.parse(mainCoefficient.text);
                                value =
                                    (scoreNew / coefficientNew * 100).round() /
                                        100;
                                resultScore =
                                    "${(score / coefficient * 100).round() / 100}   ->   $value";
                                isDisabled = true;
                                isPressed = true;
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
                                  'Добавить',
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
                                clear();
                                Navigator.pop(context, [0.0]);
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
                                Navigator.pop(
                                    context,
                                    isPressed
                                        ? [scoreNew, coefficientNew]
                                        : [0.0]);
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
                    insetPadding: const EdgeInsets.symmetric(vertical: 100),
                  );
                }));
        if (scoreNew != score) {
          widget.add([
            (scoreNew - score) / (coefficientNew - coefficient),
            coefficientNew - coefficient
          ]);
          widget.update(scoreNew.toString(), coefficientNew.toString());
        }
      },
      child: Icon(
        Icons.add,
        size: 50,
        color: Theme.of(context).textTheme.displayLarge?.color
      ),
    );
  }
}
