import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MyApp(),
  ));
}

Future<void> _saveLoginStatusAndPassword(bool isLoggedIn, String password) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isLoggedIn', isLoggedIn);
  await prefs.setString('password', password);
}

Future<bool> _getLoginStatus() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool('isLoggedIn') ?? false;
}

Future<String?> _getPassword() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('password');
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final Completer<InAppWebViewController> _controller =
      Completer<InAppWebViewController>();
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebView'),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              _controller.future.then((controller) async {
                if (await controller.canGoBack()) {
                  controller.goBack();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () {
              _controller.future.then((controller) async {
                if (await controller.canGoForward()) {
                  controller.goForward();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _controller.future.then((controller) {
                controller.reload();
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(
              url: Uri.parse('https://webportal.juit.ac.in:6011/studentportal/#/.php'),
            ),
            initialOptions: InAppWebViewGroupOptions(
              crossPlatform: InAppWebViewOptions(
                useShouldOverrideUrlLoading: true,
                mediaPlaybackRequiresUserGesture: false,
              ),
              android: AndroidInAppWebViewOptions(
                useShouldInterceptRequest: true,
              ),
              ios: IOSInAppWebViewOptions(
                allowsInlineMediaPlayback: true,
              ),
            ),
            onWebViewCreated: (InAppWebViewController controller) {
              _controller.complete(controller);
            },
            onLoadStart: (InAppWebViewController controller, Uri? url) async {
              if (url != null) {
                setState(() {
                  _isLoading = true;
                });
                if (url.toString().startsWith('https://webportal.juit.ac.in:6011/studentportal/#/login')) {
                  // If the user is on the login page, save the password
                  controller.evaluateJavascript(source: 'document.querySelector(\'#password\').value;')
                      .then((password) async {
                    await _saveLoginStatusAndPassword(true, password);
                  });
                }
              }
            },
            onLoadStop: (InAppWebViewController controller, Uri? url) async {
              if (url != null) {
                bool isLoggedIn = await _getLoginStatus();
                if (isLoggedIn) {
                  String? password = await _getPassword();
                  if (password != null) {
                    // Fill in the username and password fields with the saved values
                    // and submit the form to log in the user automatically.
                    // You may need to modify this code based on the HTML structure
                    // of the login page.
                    controller.evaluateJavascript(source: '''
                      document.querySelector('#username').value = 'your_username';
                      document.querySelector('#password').value = '$password';
                      document.querySelector('#login_button').click();
                    ''');
                  }
                }
                setState(() {
                  _isLoading = false;
                });
              }
            },
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}