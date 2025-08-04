import 'package:flutter/material.dart';

void showError(context) {
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Подождите", style: TextStyle(fontSize: 18, color: Colors.white),),
                      Text("Данные загружаются", style: TextStyle(fontSize: 14),)
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
