import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewLocalPage extends StatefulWidget {
  const WebViewLocalPage({super.key});

  @override
  State<WebViewLocalPage> createState() => _WebViewLocalPageState();
}

class _WebViewLocalPageState extends State<WebViewLocalPage> {
  late final WebViewController _webController;

  @override
  void initState() {
    super.initState();

    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'MyJSChannel',
        onMessageReceived: (JavaScriptMessage message) {
          log('JavaScript: ${message.message}');

          if (!mounted) return;

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Сообщение JavaScript'),
              content: Text(
                message.message,
                style: const TextStyle(fontSize: 20),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Закрыть'),
                ),
              ],
            ),
          );
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            log('Загрузка страницы: $url');
          },
          onPageFinished: (url) {
            log('Страница полностью загружена: $url');
          },
          onWebResourceError: (error) {
            log('Ошибка: ${error.description}');
          },
        ),
      )
      ..loadFlutterAsset('assets/index.html');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WebView Local')),
      body: WebViewWidget(controller: _webController),
    );
  }
}


  // void loadLocalHTML() async {
  //   final html = await rootBundle.loadString('assets/index.html');
  //   final url = Uri.dataFromString(
  //     html,
  //     mimeType: 'text/html',
  //     encoding: Encoding.getByName('utf-8'),
  //   ).toString();

  //   _webController.loadUrl(url);
  // }

  // final html = '''<!DOCTYPE html>
  // <html>
  // <body>

  // <h1>This is heading 1</h1>
  // <h2>This is heading 2</h2>
  // <h3>This is heading 3</h3>
  // <h4>This is heading 4</h4>
  // <h5>This is heading 5</h5>
  // <h6>This is heading 6</h6>

  // </body>
  // </html>''';
