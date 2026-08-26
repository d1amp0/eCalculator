import 'package:flutter/material.dart';

void showErrorLogin(context) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Center(
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            height: 90,
            width: 300,
            decoration: const BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.all(Radius.circular(20))),
            child: const Row(
              children: [
                Icon(
                  Icons.lock_rounded,
                  color: Colors.white,
                  size: 48,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Ошибка!",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                      Text(
                        "Неверный логин или пароль",
                        style: TextStyle(fontSize: 14),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    behavior: SnackBarBehavior.floating,
    backgroundColor: Colors.transparent,
    elevation: 0,
  ));
}

void showErrorPeriod(context) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Center(
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            height: 100,
            width: 300,
            decoration: const BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.all(Radius.circular(20))),
            child: const Row(
              children: [
                Icon(
                  Icons.error_outline_sharp,
                  color: Colors.white,
                  size: 48,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Ошибка!",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                      Text(
                        "Учебный период/учебный год не найден",
                        style: TextStyle(fontSize: 14),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    behavior: SnackBarBehavior.floating,
    backgroundColor: Colors.transparent,
    elevation: 0,
  ));
}
