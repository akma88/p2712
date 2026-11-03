import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebviewLocalPage extends StatefulWidget {
  const WebviewLocalPage({super.key});

  @override
  State<WebviewLocalPage> createState() => _WebviewLocalPageState();
}

class _WebviewLocalPageState extends State<WebviewLocalPage> {
  late final WebViewController _webController;

  @override
  void initState() {
    super.initState();

    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadFlutterAsset('assets/index.html');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WebView Local')),
      body: WebViewWidget(controller: _webController),
    );
  }

  void loadLocalHTML() async {
    final html = await rootBundle.loadString("assets/index.html");
    final url = Uri.dataFromString(
      html,
      mimeType: 'text/html',
      encoding: Encoding.getByName("utf-8"),
    ).toString();

    _webController.loadHtmlString(url);
  }

  //   final html = '''
  // <!DOCTYPE html>
  // <html>
  // <head>
  //   <meta charset="utf-8">
  //   <meta name="viewport" content="width=device-width, initial-scale=1.0">
  // </head>
  // <body>
  //   <h1>This is heading 1</h1>
  //   <h2>This is heading 2</h2>
  //   <h3>This is heading 3</h3>
  //   <h4>This is heading 4</h4>
  //   <h5>This is heading 5</h5>
  //   <h6>This is heading 6</h6>
  // </body>
  // </html>
  // ''';
}
