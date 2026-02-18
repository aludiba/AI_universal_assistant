import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// 展示用户协议、隐私政策等 HTML 页面（复用 iOS 的 用户协议.html、隐私政策.html）
/// 使用 rootBundle 加载 HTML 后通过 loadHtmlString 渲染，避免 loadFlutterAsset 的 key 问题
class PolicyWebViewScreen extends StatefulWidget {
  const PolicyWebViewScreen({
    super.key,
    required this.title,
    required this.assetPath,
  });

  final String title;
  final String assetPath;

  @override
  State<PolicyWebViewScreen> createState() => _PolicyWebViewScreenState();
}

class _PolicyWebViewScreenState extends State<PolicyWebViewScreen> {
  WebViewController? _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAndShowHtml();
  }

  Future<void> _loadAndShowHtml() async {
    try {
      final html = await rootBundle.loadString(widget.assetPath);
      if (!mounted) return;
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (_) {
              if (mounted) setState(() => _loading = false);
            },
          ),
        )
        ..loadHtmlString(html);
      setState(() {});
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
            )
          : Stack(
              children: [
                if (_controller != null)
                  WebViewWidget(controller: _controller!),
                if (_loading)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
    );
  }
}
