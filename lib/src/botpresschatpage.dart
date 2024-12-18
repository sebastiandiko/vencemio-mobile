import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class BotpressChat extends StatelessWidget {
  const BotpressChat({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Consultas"),
        backgroundColor: Colors.green,
      ),
      body: const BotpressWebView(),
    );
  }
}

class BotpressWebView extends StatefulWidget {
  const BotpressWebView({Key? key}) : super(key: key);

  @override
  State<BotpressWebView> createState() => _BotpressWebViewState();
}

class _BotpressWebViewState extends State<BotpressWebView> {
  final String botpressUrl =
      "https://cdn.botpress.cloud/webchat/v2.2/shareable.html?configUrl=https://files.bpcontent.cloud/2024/12/11/17/20241211171207-DTORZGDI.json";

  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(botpressUrl));
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
