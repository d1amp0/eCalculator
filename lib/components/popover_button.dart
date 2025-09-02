import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PopoverButton extends StatefulWidget {
  final String startText;
  final TextEditingController? controller;
  final Function checkControllers;

  const PopoverButton(
      {super.key,
      required this.startText,
      required this.controller,
      required this.checkControllers});

  @override
  State<PopoverButton> createState() => _PopoverButtonState();
}

class _PopoverButtonState extends State<PopoverButton> {
  late String dropdown;
  List<String> list = ["Get it longer"];

  void getPeriods() async {
    if (widget.startText == "Учебный период") {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? period = prefs.getInt("period_type");
      if (period == null) {
        list = [
          "1 четверть",
          "2 четверть",
          "3 четверть",
          "4 четверть",
          "Учебный год"
        ];
      } else {
        if (period == 0) {
          list = [
            "1 четверть",
            "2 четверть",
            "3 четверть",
            "4 четверть",
            "Учебный год"
          ];
        } else {
          if (period == 1) {
            list = ["1 полугодие", "2 полугодие", "Учебный год"];
          } else {
            list = ["1 семестр", "2 семестр", "Учебный год"];
          }
        }
      }
      setState(() {
        list;
      });
    } else {
      list = ['2025/2026', '2024/2025', '2023/2024'];
    }
  }

  @override
  void initState() {
    super.initState();
    getPeriods();
  }

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<String>(
      onSelected: (String? value) {
        setState(() {
          dropdown = value!;
        });
        widget.checkControllers(false);
      },
      controller: widget.controller,
      dropdownMenuEntries:
          list.map<DropdownMenuEntry<String>>((String value) {
        return DropdownMenuEntry<String>(value: value, label: value, style: ButtonStyle(foregroundColor: WidgetStatePropertyAll<Color>(
            (Theme.of(context).textTheme.displayLarge?.color)!)));
      }).toList(),
      label: Text(widget.startText, style: TextStyle(fontSize: 15, color: Theme.of(context).textTheme.displayLarge?.color),),
      textStyle: TextStyle(fontSize: 15, color: Theme.of(context).textTheme.displayLarge?.color),
      menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll<Color>(
              Theme.of(context).colorScheme.secondary)),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }
}
