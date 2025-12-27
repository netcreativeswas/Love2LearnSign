import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CaptchaChallenge extends StatefulWidget {
  final String siteKey;
  final Duration timeout;

  const CaptchaChallenge({
    super.key, 
    required this.siteKey,
    this.timeout = const Duration(minutes: 3), // 3 minute timeout by default
  });

  @override
  State<CaptchaChallenge> createState() => _CaptchaChallengeState();
}

class _CaptchaChallengeState extends State<CaptchaChallenge> {
  late final WebViewController _webViewController;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  Timer? _timeoutTimer;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    
    // Set up timeout timer
    _timeoutTimer = Timer(widget.timeout, () {
      if (!_isDisposed && mounted) {
        debugPrint('⚠️ reCAPTCHA timeout - closing dialog');
        Navigator.of(context).pop(); // Return null on timeout
      }
    });

    final params = PlatformWebViewControllerCreationParams();
    _webViewController = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'RecaptchaBridge',
        onMessageReceived: (message) {
          debugPrint('✅ reCAPTCHA token received');
          _timeoutTimer?.cancel();
          if (!_isDisposed && mounted) {
            Navigator.of(context).pop(message.message);
          }
        },
      )
      ..addJavaScriptChannel(
        'RecaptchaError',
        onMessageReceived: (message) {
          debugPrint('❌ reCAPTCHA error: ${message.message}');
          _timeoutTimer?.cancel();
          if (!_isDisposed && mounted) {
            setState(() {
              _hasError = true;
              _errorMessage = message.message;
              _isLoading = false;
            });
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (!_isDisposed && mounted) {
              setState(() => _isLoading = false);
              debugPrint('📄 reCAPTCHA page loaded');
            }
          },
          onWebResourceError: (error) {
            debugPrint('❌ WebView resource error: ${error.description}');
            if (!_isDisposed && mounted) {
              setState(() {
                _hasError = true;
                _errorMessage = 'Failed to load reCAPTCHA. Please check your internet connection.';
                _isLoading = false;
              });
            }
          },
        ),
      )
      ..loadHtmlString(_buildHtml(widget.siteKey), baseUrl: 'https://localhost/');
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Security Check',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 1.0, // Use 100% of screen width
        height: 500, // Increase height to fit image challenge comfortably
        child: _hasError
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'reCAPTCHA Error',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage ?? 'Failed to load reCAPTCHA',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _hasError = false;
                          _isLoading = true;
                        });
                        _webViewController.reload();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : Stack(
                children: [
                  WebViewWidget(controller: _webViewController),
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            _timeoutTimer?.cancel();
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  String _buildHtml(String siteKey) {
    return '''
<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
      body {
        margin: 0;
        padding: 0;
        display: flex;
        align-items: center;
        justify-content: center;
        height: 100vh;
        background-color: #fafafa;
        font-family: Arial, sans-serif;
      }
      #captcha-container {
        padding: 8px;
      }
      #error-message {
        display: none;
        padding: 16px;
        background-color: #ffebee;
        color: #c62828;
        border-radius: 4px;
        text-align: center;
      }
    </style>
    <script>
      // Global error handler
      window.onerror = function(message, source, lineno, colno, error) {
        console.error('JavaScript error:', message, error);
        if (window.RecaptchaError) {
          RecaptchaError.postMessage('JavaScript error: ' + message);
        }
        return true;
      };

      // Timeout to detect if reCAPTCHA doesn't load
      var loadTimeout = setTimeout(function() {
        if (!window.grecaptcha) {
          console.error('reCAPTCHA script failed to load');
          if (window.RecaptchaError) {
            RecaptchaError.postMessage('reCAPTCHA script failed to load. Please check your internet connection.');
          }
        }
      }, 15000); // 15 second timeout for script load

      function onSubmit(token) {
        console.log('reCAPTCHA token received');
        clearTimeout(loadTimeout);
        if (window.RecaptchaBridge) {
          RecaptchaBridge.postMessage(token);
        }
      }

      function onExpired() {
        console.log('reCAPTCHA expired');
        if (window.RecaptchaError) {
          RecaptchaError.postMessage('reCAPTCHA expired. Please try again.');
        }
      }

      function onError() {
        console.error('reCAPTCHA error occurred');
        clearTimeout(loadTimeout);
        if (window.RecaptchaError) {
          RecaptchaError.postMessage('reCAPTCHA error occurred. Please check your internet connection.');
        }
      }

      // Verify reCAPTCHA loaded successfully
      window.addEventListener('load', function() {
        setTimeout(function() {
          if (window.grecaptcha) {
            console.log('reCAPTCHA API loaded successfully');
            clearTimeout(loadTimeout);
          }
        }, 2000);
      });
    </script>
    <script src="https://www.google.com/recaptcha/api.js" async defer onerror="onError()"></script>
  </head>
  <body>
    <div id="captcha-container">
      <div class="g-recaptcha" 
           data-sitekey="$siteKey" 
           data-callback="onSubmit"
           data-expired-callback="onExpired"
           data-error-callback="onError"></div>
    </div>
    <div id="error-message"></div>
  </body>
</html>
''';
  }
}
