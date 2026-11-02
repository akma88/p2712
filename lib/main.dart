import 'package:flutter/material.dart';
import 'package:p2712/page/webview_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "WebView Page",
      theme: ThemeData.dark(),
      home: WebViewPage(),
    );
  }
}
