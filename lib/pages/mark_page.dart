import 'package:flutter/material.dart';
import 'package:ecalculator/components/mark_button.dart';
import 'package:ecalculator/components/more_menu.dart';
import 'package:ecalculator/components/plus_button.dart';
import 'package:ecalculator/components/plused_button.dart';
import 'package:ecalculator/server/functions.dart';

class MarkPage extends StatefulWidget {
  final String name;
  final List<List>? markList;

  const MarkPage({super.key, required this.name, required this.markList});

  @override
  State<MarkPage> createState() => _MarkPageState();
}

class _MarkPageState extends State<MarkPage> {
  late final double scoreStart, coefficientStart;
  double score = 0, coefficient = 0;
  List<List<double>> extraMarkList = [], changes = [];

  @override
  void initState() {
    super.initState();
    score = getScore(widget.markList);
    scoreStart = score;
    coefficient = getCoefficient(widget.markList);
    coefficientStart = coefficient;
  }

  void update(String scoreNew, String coefficientNew) {
    setState(() {
      score = double.parse(scoreNew);
      coefficient = double.parse(coefficientNew);
    });
  }

  String getChanges() {
    double value = -scoreStart / coefficientStart + score / coefficient;
    if (value == 0) {
      return "Изменение: 0.00";
    }
    if (value > 0) {
      return "Изменение: +${(value * 100).round() / 100}";
    }
    return "Изменение: ${(value * 100).round() / 100}";
  }

  Color? getChangesColor() {
    double value = -scoreStart / coefficientStart + score / coefficient;
    if (value == 0) {
      return Theme.of(context).textTheme.displaySmall!.color;
    }
    if (value > 0) {
      return const Color.fromARGB(255, 3, 192, 60);
    }
    return const Color.fromARGB(255, 220, 20, 60);
  }

  void addExtraMarkList(List<double> mark) {
    setState(() {
      extraMarkList.add(mark);
    });
  }

  void deleteExtraMarkList(List<double> mark) {
    setState(() {
      extraMarkList.remove(mark);
    });
  }

  double getScoreCurrent() {
    return score;
  }

  double getCoefficientCurrent() {
    return coefficient;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              children: [
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Icon(
                    Icons.arrow_back_sharp,
                    color: Theme.of(context).textTheme.displaySmall?.color,
                    size: 30,
                  ),
                ),
                Flexible(
                  child: Center(
                    child: Text(
                      widget.name,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.displaySmall?.color,
                        fontSize: 32,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const MoreMenu(canLeave: true),
              ],
            ),
            Divider(
              height: 5,
              thickness: 1,
              color: Theme.of(context).textTheme.displaySmall?.color,
            ),
            Text(
              "Балл: ${(score / coefficient * 100).round() / 100}",
              style: TextStyle(
                color: Theme.of(context).textTheme.displaySmall?.color,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              "Коэффициент: ${(coefficient * 100).round() / 100}",
              style: TextStyle(
                color: Theme.of(context).textTheme.displaySmall?.color,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              getChanges(),
              style: TextStyle(color: getChangesColor(), fontSize: 24),
            ),
            const SizedBox(height: 5),
            Container(
              height: 450,
              width: 340,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                shape: BoxShape.rectangle,
                color: Theme.of(context).colorScheme.secondary,
              ),
              child: GridView.count(
                crossAxisCount: 4,
                children: List.generate(
                  widget.markList!.length + 1 + extraMarkList.length,
                  (index) {
                    if (index < widget.markList!.length) {
                      return Center(
                        child: MarkButton(
                          markList: widget.markList![index],
                          getScore: getScoreCurrent,
                          getCoefficient: getCoefficientCurrent,
                          update: update,
                        ),
                      );
                    }
                    if (index ==
                        widget.markList!.length + extraMarkList.length) {
                      return Center(
                        child: PlusButton(
                          getScore: getScoreCurrent,
                          getCoefficient: getCoefficientCurrent,
                          add: addExtraMarkList,
                          update: update,
                        ),
                      );
                    }
                    //return const Center(child: Added(),)
                    return Center(
                      child: PlusedButton(
                        markList:
                            extraMarkList[index - widget.markList!.length],
                        getScore: getScoreCurrent,
                        getCoefficient: getCoefficientCurrent,
                        update: update,
                        delete: deleteExtraMarkList,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
