import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CardPayment extends StatefulWidget {
  final double amount;

  const CardPayment({Key? key, required this.amount}) : super(key: key);

  @override
  State<CardPayment> createState() => _CardPaymentState();
}

class _CardPaymentState extends State<CardPayment> {
  late WebViewController _controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializePayment();
  }

  Future<void> _initializePayment() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = {
      'email': prefs.getString('email'),
      'phone': prefs.getString('phone'),
      'name': prefs.getString('name'),
    };

    final flutterwaveHtml = '''
      <!DOCTYPE html>
      <html>
      <head>
        <script src="https://checkout.flutterwave.com/v3.js"></script>
      </head>
      <body>
        <script>
          FlutterwaveCheckout({
            public_key: "${prefs.getString('FLW_PUBLIC_KEY')}",
            tx_ref: "titanic-${DateTime.now().millisecondsSinceEpoch}",
            amount: ${widget.amount},
            currency: "NGN",
            payment_options: "card, mobilemoneyghana, ussd",
            redirect_url: "https://vtubiz.com/payment/callback",
            customer: {
              email: "${userData['email']}",
              phone_number: "${userData['phone']}",
              name: "${userData['name']}",
            },
            customizations: {
              title: "VTUBIZ Checkout",
              description: "Fast and Easy Payment",
              logo: "https://vtubiz.com/assets/img/logo/vtulogo.png",
            },
            callback: function(response) {
              window.flutter_inappwebview.callHandler('paymentComplete', response);
            },
          });
        </script>
      </body>
      </html>
    ''';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              isLoading = false;
            });
          },
        ),
      )
      ..loadHtmlString(flutterwaveHtml);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Payment'),
        backgroundColor: const Color(0xFF383D41),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}