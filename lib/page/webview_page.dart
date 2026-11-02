import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

enum MenuOptions { clearCache, clearCookies }

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final WebViewController controller;
  final cookieManager = WebViewCookieManager();

  double progress = 0;
  bool showProgress = true;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            log('Новая страница: $url');

            if (!mounted) return;
            setState(() => progress = 0);
          },

          onProgress: (value) {
            if (!mounted) return;

            setState(() {
              progress = value / 100;
            });
          },

          onPageFinished: (url) async {
            log('Страница полностью загружена: $url');

            if (mounted) {
              setState(() => progress = 1);
            }

            if (url.contains('m.facebook.com') && isSubmitting) {
              isSubmitting = false;
              log('Форма Facebook отправлена');
            }
          },

          onWebResourceError: (error) {
            log('Ошибка WebView: ${error.description}');
          },

          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            final host = uri?.host.toLowerCase();

            if (host == 'm.youtube.com') {
              log('Навигация заблокирована: ${request.url}');
              return NavigationDecision.prevent;
            }

            log('Навигация разрешена: ${request.url}');
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse('https://flutter.dev'));
  }

  Future<void> goBack() async {
    if (await controller.canGoBack()) {
      await controller.goBack();
    } else {
      showMessage('Нет предыдущей страницы в истории');
    }
  }

  Future<void> goForward() async {
    if (await controller.canGoForward()) {
      await controller.goForward();
    } else {
      showMessage('Нет следующей страницы в истории');
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> handleMenu(MenuOptions option) async {
    try {
      switch (option) {
        case MenuOptions.clearCache:
          await controller.clearCache();
          showMessage('Кеш очищен');
          break;

        case MenuOptions.clearCookies:
          final hadCookies = await cookieManager.clearCookies();

          showMessage(
            hadCookies ? 'Cookies очищены' : 'Cookies уже были очищены',
          );
          break;
      }
    } catch (error) {
      log('Тазалау қатесі: $error');
      showMessage('Не удалось выполнить очистку');
    }
  }

  Future<void> hideFooter() async {
    try {
      await controller.runJavaScript('''
        const footer = document.querySelector('footer');
        if (footer) {
          footer.style.display = 'none';
        }
      ''');

      log('Footer скрыт');
    } catch (error) {
      log('Ошибка JavaScript: $error');
    }
  }

  Future<void> submitFacebookLogin(String email, String password) async {
    final currentUrl = await controller.currentUrl();
    final uri = Uri.tryParse(currentUrl ?? '');
    final host = uri?.host.toLowerCase();

    if (host != 'm.facebook.com' &&
        host != 'www.facebook.com' &&
        host != 'facebook.com') {
      showMessage('Сначала откройте Facebook');
      return;
    }

    if (email.isEmpty || password.isEmpty) {
      showMessage('Введите email и пароль');
      return;
    }

    try {
      final result = await controller.runJavaScriptReturningResult('''
        (() => {
          const emailField =
              document.getElementById('m_login_email');

          const passwordField =
              document.getElementById('m_login_password');

          const form = emailField?.form;

          if (!emailField || !passwordField || !form) {
            return false;
          }

          emailField.value = ${jsonEncode(email)};
          passwordField.value = ${jsonEncode(password)};

          emailField.dispatchEvent(
            new Event('input', { bubbles: true })
          );

          passwordField.dispatchEvent(
            new Event('input', { bubbles: true })
          );

          form.submit();
          return true;
        })()
      ''');

      if (result == true) {
        isSubmitting = true;
        log('Форма Facebook отправлена');
      } else {
        showMessage('Форма Facebook не найдена');
      }
    } catch (error) {
      isSubmitting = false;
      log('Ошибка Facebook: $error');
      showMessage('Не удалось отправить форму');
    }
  }

  Future<void> showFacebookLoginDialog() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    final credentials = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Вход в Facebook'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, [
                  emailController.text,
                  passwordController.text,
                ]);
              },
              child: const Text('Отправить'),
            ),
          ],
        );
      },
    );

    emailController.dispose();
    passwordController.dispose();

    if (credentials != null) {
      await submitFacebookLogin(credentials[0], credentials[1]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (await controller.canGoBack()) {
          await controller.goBack();
          return false;
        }

        return true;
      },

      child: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              tooltip: 'Назад',
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: goBack,
            ),

            IconButton(
              tooltip: 'Вперёд',
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: goForward,
            ),

            IconButton(
              tooltip: 'Обновить',
              icon: const Icon(Icons.replay),
              onPressed: () {
                setState(() {
                  showProgress = false;
                });

                controller.reload();
              },
            ),

            IconButton(
              tooltip: 'Скрыть Footer',
              icon: const Icon(Icons.code),
              onPressed: hideFooter,
            ),

            IconButton(
              tooltip: 'Вход в Facebook',
              icon: const Icon(Icons.login),
              onPressed: showFacebookLoginDialog,
            ),

            PopupMenuButton<MenuOptions>(
              onSelected: handleMenu,
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: MenuOptions.clearCache,
                  child: Text('Очистить кеш'),
                ),
                PopupMenuItem(
                  value: MenuOptions.clearCookies,
                  child: Text('Очистить Cookies'),
                ),
              ],
            ),
          ],
        ),

        body: SafeArea(
          child: Column(
            children: [
              if (showProgress)
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  color: Colors.red,
                  backgroundColor: Colors.grey,
                ),

              Expanded(child: WebViewWidget(controller: controller)),
            ],
          ),
        ),

        floatingActionButton: FloatingActionButton(
          tooltip: 'Открыть YouTube',
          onPressed: () async {
            await controller.loadRequest(Uri.parse('https://www.youtube.com'));
          },
          child: const Icon(Icons.next_plan, size: 32),
        ),
      ),
    );
  }
}
