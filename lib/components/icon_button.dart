import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class MyIconButton extends StatelessWidget {
  final String path;
  final int type;

  const MyIconButton({super.key, required this.path, required this.type});

  Future<void> _launchUrl() async {
    final Uri url = Uri.parse('https://t.me/d1amp0');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  void saveMail() {
    Clipboard.setData(const ClipboardData(text: "cuberubex@yandex.ru"));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          if (type == 0) {
            _launchUrl();
          } else {
            saveMail();
          }
        },
        child: Image.asset(path, width: 56, height: 56));
  }
}
