import 'package:flutter/material.dart';

class MyInput extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final Function onChanged;

  const MyInput(
      {super.key,
      required this.controller,
      required this.hint,
      required this.onChanged});

  @override
  State<MyInput> createState() => _MyInputState();
}

class _MyInputState extends State<MyInput> {
  bool isVisible = true;
  Icon visibility = const Icon(Icons.visibility_off);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0),
        child: TextField(
          onChanged: (value) => widget.onChanged(value),
          controller: widget.controller,
          style:
              TextStyle(color: Theme.of(context).textTheme.displayLarge?.color),
          obscureText: widget.hint == 'Логин' ? false : isVisible,
          decoration: InputDecoration(
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide:
                    BorderSide(color: Theme.of(context).colorScheme.primary),
                borderRadius: BorderRadius.circular(10),
              ),
              prefixIcon: Icon(
                widget.hint == 'Логин' ? Icons.person : Icons.lock,
                color: Theme.of(context).colorScheme.primary,
              ),
              suffixIcon: widget.hint == 'Пароль'
                  ? IconButton(
                      onPressed: () {
                        setState(() {
                          isVisible = !isVisible;
                          if (isVisible) {
                            visibility = const Icon(Icons.visibility_off);
                          } else {
                            visibility = const Icon(Icons.visibility);
                          }
                        });
                      },
                      icon: visibility,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              hintText: widget.hint,
              hintStyle: const TextStyle(
                  color: Colors.grey, fontWeight: FontWeight.w400)),
        ));
  }
}
