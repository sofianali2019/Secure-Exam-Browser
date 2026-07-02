import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:webview_flutter/webview_flutter.dart';
import '../models/exam_config.dart';

class WebviewService {
  WebViewController? _controller;
  final StreamController<Map<String, dynamic>> _moodleEvents =
      StreamController<Map<String, dynamic>>.broadcast();
  static const _moodleUserAgent = 'MoodleMobile';

  Stream<Map<String, dynamic>> get moodleEvents => _moodleEvents.stream;
  WebViewController? get controller => _controller;

  bool _isDomainAllowed(String url, List<String> allowedDomains) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return allowedDomains.any((domain) => uri.host == domain);
  }

  WebViewController buildController({
    required ExamConfig config,
  }) {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(_moodleUserAgent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            _moodleEvents.add({'event': 'page_started', 'url': url});
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri != null &&
                !_isDomainAllowed(request.url, config.effectiveAllowedDomains)) {
              _moodleEvents.add({
                'event': 'navigation_blocked',
                'url': request.url,
              });
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageFinished: (url) {
            _injectMoodleBridge();
            _moodleEvents.add({'event': 'page_finished', 'url': url});
          },
          onWebResourceError: (error) {
            _moodleEvents.add({
              'event': 'resource_error',
              'code': error.errorCode,
              'description': error.description,
            });
          },
        ),
      )
      ..addJavaScriptChannel(
        'MoodleBridge',
        onMessageReceived: (message) {
          try {
            final data = jsonDecode(message.message) as Map<String, dynamic>;
            _moodleEvents.add(data);
          } catch (_) {
            _moodleEvents.add({'event': 'raw', 'data': message.message});
          }
        },
      );

    return _controller!;
  }

  Future<void> loadExam(String url) async {
    debugPrint('WebviewService.loadExam: loading $url');
    await _controller?.loadRequest(Uri.parse(url));
  }

  Future<void> _injectMoodleBridge() async {
    const bridge = '''
      (function() {
        if (window.__sebBridgeInjected) return;
        window.__sebBridgeInjected = true;

        // Redirect popups (like Moodle quiz attempts) into the same WebView
        var _origWindowOpen = window.open;
        window.open = function(url) {
          if (url) window.location.href = url;
          return _origWindowOpen ? _origWindowOpen.call(window, '') : window;
        };

        function sendToFlutter(data) {
          if (window.MoodleBridge) {
            window.MoodleBridge.postMessage(JSON.stringify(data));
          }
        }

        var origPushState = history.pushState;
        history.pushState = function() {
          sendToFlutter({ event: 'navigation', state: 'push' });
          return origPushState.apply(this, arguments);
        };

        var origReplaceState = history.replaceState;
        history.replaceState = function() {
          sendToFlutter({ event: 'navigation', state: 'replace' });
          return origReplaceState.apply(this, arguments);
        };

        var quizObserver = new MutationObserver(function(mutations) {
          mutations.forEach(function(mutation) {
            if (mutation.target.id && mutation.target.id.includes('quiz')) {
              sendToFlutter({ event: 'quiz_mutation' });
            }
          });
        });
        quizObserver.observe(document.body, { childList: true, subtree: true });

        // Monitor quiz submit button clicks
        document.addEventListener('click', function(e) {
          var target = e.target;
          var btn = target.closest(
            '#id_submitbutton, ' +
            'input[name="submitbutton"], ' +
            'button[name="submitbutton"], ' +
            '.submitbtns input[type="submit"], ' +
            '[data-action="submit"]'
          );
          if (btn) {
            sendToFlutter({ event: 'quiz_submit_clicked' });
          }
        }, true);

        // Monitor Moodle timer warnings
        var timeObserver = new MutationObserver(function(mutations) {
          mutations.forEach(function(mutation) {
            if (mutation.type === 'childList' && mutation.addedNodes) {
              for (var i = 0; i < mutation.addedNodes.length; i++) {
                var node = mutation.addedNodes[i];
                if (node.nodeType === 1) {
                  var el = node;
                  if ((el.classList && el.classList.contains('timewarning')) ||
                      (el.id && (el.id.indexOf('timer') !== -1 || el.id.indexOf('countdown') !== -1)) ||
                      (el.querySelector && (el.querySelector('.timewarning') !== null))) {
                    sendToFlutter({ event: 'timer_warning', source: el.id || 'unknown' });
                  }
                }
              }
            }
            if (mutation.type === 'attributes' && mutation.target) {
              var el = mutation.target;
              if (el.classList && el.classList.contains('timewarning')) {
                sendToFlutter({ event: 'timer_warning', source: 'class_added' });
              }
            }
          });
        });
        timeObserver.observe(document.body, {
          childList: true,
          subtree: true,
          attributes: true,
          attributeFilter: ['class', 'style'],
        });

        // Detect page visibility changes (navigating away)
        document.addEventListener('visibilitychange', function() {
          sendToFlutter({
            event: 'visibility_change',
            visible: !document.hidden,
          });
        });

        // Monitor beforeunload (attempting to close/leave page)
        window.addEventListener('beforeunload', function() {
          sendToFlutter({ event: 'page_unload_attempted' });
        });

        sendToFlutter({ event: 'bridge_ready' });
      })();
    ''';
    await _controller?.runJavaScript(bridge);
  }

  /// Attempts to find and click the Moodle quiz submit button via JavaScript.
  /// Returns true if a submit button was found and clicked.
  Future<bool> submitQuiz() async {
    if (_controller == null) return false;
    try {
      final result = await _controller!.runJavaScriptReturningResult('''
        (function() {
          var selectors = [
            '#id_submitbutton',
            'input[name="submitbutton"]',
            'button[name="submitbutton"]',
            '.submitbtns input[type="submit"]',
            '[data-action="submit"]',
            'button[data-action="submit"]',
          ];
          for (var i = 0; i < selectors.length; i++) {
            var btn = document.querySelector(selectors[i]);
            if (btn) {
              btn.click();
              return "submitted";
            }
          }
          var allButtons = document.querySelectorAll(
            'button, input[type="submit"], input[type="button"]'
          );
          var keywords = ["submit", "finish", "complete", "hand in", "handin", "turn in"];
          for (var i = 0; i < allButtons.length; i++) {
            var el = allButtons[i];
            var text = (el.textContent || el.value || el.getAttribute("aria-label") || "").toLowerCase().trim();
            for (var j = 0; j < keywords.length; j++) {
              if (text.indexOf(keywords[j]) !== -1) {
                el.click();
                return "submitted";
              }
            }
          }
          var form = document.querySelector("#responseform");
          if (form) {
            form.submit();
            return "form_submitted";
          }
          return "not_found";
        })();
      ''');
      return result == 'submitted' || result == 'form_submitted';
    } catch (_) {
      return false;
    }
  }

  Future<void> setSebConfig(String configJson) async {
    // Parse and re-encode to prevent template injection.
    // jsonEncode on the parsed map ensures all strings are properly escaped
    // for JavaScript interpolation, preventing XSS and script injection.
    try {
      final parsed = jsonDecode(configJson) as Map<String, dynamic>;
      final safeJson = jsonEncode(parsed);
      final js = '''
        (function() {
          if (window.__sebConfig !== undefined) return;
          window.__sebConfig = $safeJson;
          var event = new CustomEvent('seb-config-ready', { detail: $safeJson });
          document.dispatchEvent(event);
        })();
      ''';
      await _controller?.runJavaScript(js);
    } catch (e) {
      debugPrint('setSebConfig: invalid JSON, not injecting: $e');
    }
  }

  void dispose() {
    _moodleEvents.close();
  }
}
