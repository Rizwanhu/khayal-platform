import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// In-app Stripe Checkout. Pops with checkout [sessionId] on success URL.
class StripeCheckoutWebViewScreen extends StatefulWidget {
  const StripeCheckoutWebViewScreen({
    super.key,
    required this.checkoutUrl,
  });

  final String checkoutUrl;

  @override
  State<StripeCheckoutWebViewScreen> createState() =>
      _StripeCheckoutWebViewScreenState();
}

class _StripeCheckoutWebViewScreenState extends State<StripeCheckoutWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  static bool _isCheckoutSuccess(String url) {
    final u = url.toLowerCase();
    return u.contains('session_id=') ||
        u.contains('chat-payment-success') ||
        u.contains('checkout-success');
  }

  static String? _sessionIdFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final id = uri.queryParameters['session_id'];
    if (id != null && id.isNotEmpty) return id;
    return null;
  }

  void _maybeComplete(String url) {
    if (!_isCheckoutSuccess(url)) return;
    final sessionId = _sessionIdFromUrl(url);
    if (!mounted) return;
    Navigator.of(context).pop(sessionId ?? '');
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (url) {
            if (mounted) setState(() => _loading = false);
            _maybeComplete(url);
          },
          onNavigationRequest: (request) {
            if (_isCheckoutSuccess(request.url)) {
              _maybeComplete(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
