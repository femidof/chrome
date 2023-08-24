// ignore_for_file: use_build_context_synchronously

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import 'simple_menu.dart';
import 'utils.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ChromeHome(),
    ),
  );
}

class ChromeHome extends StatefulWidget {
  const ChromeHome({super.key});

  @override
  State<ChromeHome> createState() => _ChromeHomeState();
}

class _ChromeHomeState extends State<ChromeHome> {
  late final WebViewController _controller;
  final _textController = TextEditingController();
  String _url = defaultUrl;
  bool isNotNull = false;
  bool _isLoadingComplete = false;
  bool _isLoading = true;
  int _loadingProgress = 0;
  bool _isBottomNavigationBarVisible = true;

  void _loadUrl(String url) {
    if (url == "") {
      setState(() {
        isNotNull = false;
      });
    } else {
      setState(() {
        isNotNull = true;
      });
      _controller.loadRequest(Uri.parse(url));
    }
  }

  String _validateURL(String input) {
    // Check if the input string is a valid URL
    Uri uri;
    try {
      // Add 'http://' as a default scheme if missing
      if (!input.startsWith('http://') && !input.startsWith('https://')) {
        input = 'http://$input';
      }
      uri = Uri.parse(input);
    } catch (e) {
      // Invalid URL, treat it as a search query
      return 'https://www.google.com/search?q=${Uri.encodeQueryComponent(input)}';
    }

    // Check if the URL has a scheme (http/https)
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      return uri.toString();
    }

    // Invalid URL with an unsupported scheme, treat it as a search query
    return 'https://www.google.com/search?q=${Uri.encodeQueryComponent(input)}';
  }

  void _handleSubmitted(String urlString) {
    String url = _validateURL(urlString.trim());
    _textController.text = url;
    setState(() {
      _url = url;
    });
    _loadUrl(url);
  }

  Future<void> _web(String url) async {
    late final PlatformWebViewControllerCreationParams params;

    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }
    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (int progress) {
          setState(() {
            _loadingProgress = progress;
          });
          debugPrint("Loading: $progress%");
        },
        onPageStarted: (String url) {
          setState(() {
            _isLoading = true;
          });
          debugPrint("Page started loading: $url");
        },
        onPageFinished: (String url) {
          setState(() {
            _isLoading = false;
            _isLoadingComplete = true;
          });
          debugPrint("Page finished loading: $url");
        },
        onWebResourceError: (WebResourceError error) {
          debugPrint('''
            Page resource error:
            code: ${error.errorCode}
            description: ${error.description}
            errorType: ${error.errorType}
            isForMainFrame: ${error.isForMainFrame}
 ''');
        },
        onNavigationRequest: (NavigationRequest request) {
          debugPrint('allowing navigation to ${request.url}');
          return NavigationDecision.navigate;
        },
        onUrlChange: (UrlChange change) {
          debugPrint('url change to ${change.url}');
          // probably setstate here to change url too
        },
      ))
      ..addJavaScriptChannel(
        "Toaster",
        onMessageReceived: (JavaScriptMessage message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message.message)),
          );
        },
      )
      ..loadRequest(Uri.parse(url));
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }
    _controller = controller;
  }

  @override
  void initState() {
    super.initState();
    _web(_url);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollNotification) {
          setState(() {
            _isBottomNavigationBarVisible = false;
          });
        } else if (notification is ScrollNotification ||
            notification is OverscrollNotification) {
          setState(() {
            _isBottomNavigationBarVisible = true;
          });
        }
        return false;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        extendBody: true,
        backgroundColor: Colors.white,
        appBar: isNotNull == false
            ? null
            : AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                toolbarHeight: 30,
                centerTitle: true,
                flexibleSpace: Container(
                  padding: const EdgeInsets.only(left: 10, top: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      NavigationControls(webViewController: _controller),
                    ],
                  ),
                ),
              ),
        bottomNavigationBar: _isBottomNavigationBarVisible
            ? isNotNull == false
                ? Container()
                : FadeInUp(
                    child: Hero(
                        tag: "tag",
                        child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(40),
                              topRight: Radius.circular(40),
                            ),
                            child: Container(
                                color: Colors.white,
                                height: 90,
                                width: MediaQuery.of(context).size.width,
                                padding: const EdgeInsets.all(23),
                                child: TextField(
                                    keyboardAppearance: MediaQuery.of(context)
                                                .platformBrightness ==
                                            Brightness.dark
                                        ? Brightness.dark
                                        : Brightness.light,
                                    style: const TextStyle(color: Colors.black),
                                    controller: _textController,
                                    onSubmitted: (String value) async {
                                      if (value.isEmpty) {
                                        setState(() {
                                          isNotNull = true;
                                        });
                                      }
                                      _handleSubmitted(value);
                                    },
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(
                                        Iconsax.search_normal,
                                        size: 18,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                            color: Color.fromARGB(
                                                255, 213, 213, 213),
                                            width: 0.7),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                              color: Color.fromARGB(
                                                255,
                                                213,
                                                213,
                                                213,
                                              ),
                                              width: 0.7),
                                          borderRadius:
                                              BorderRadius.circular(10.0)),
                                      fillColor: const Color.fromARGB(
                                          255, 213, 213, 213),
                                      filled: true,
                                      contentPadding: const EdgeInsets.only(
                                          left: 15, top: 5),
                                      alignLabelWithHint: true,
                                      suffixIcon: GestureDetector(
                                        onTap: () async {
                                          final String? url =
                                              await _controller.currentUrl();
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content:
                                                    Text('Favorited $url')),
                                          );
                                        },
                                        child: const Icon(
                                          Iconsax.heart_add,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      hintText: "Search on Address",
                                      hintStyle: const TextStyle(
                                          color: Color.fromARGB(
                                              255, 118, 118, 118),
                                          fontFamily: "arial"),
                                    ))))),
                  )
            : null,
        body: isNotNull == false
            ? Stack(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height,
                    width: MediaQuery.of(context).size.width,
                    child: Image.asset(
                      "assets/background.jpg",
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                      alignment: Alignment.bottomRight,
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FadeInDown(
                          child: ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: Container(
                                  height: 100,
                                  width: 100,
                                  padding: const EdgeInsets.all(10),
                                  color: Colors.white,
                                  child: Image.asset(
                                    "assets/chrome-logo.png",
                                    height: 100,
                                  )))),
                      Container(
                        height: 20,
                      ),
                      FadeInDown(
                          child: const Text(
                        "Chrome",
                        style: TextStyle(
                            fontSize: 40, fontWeight: FontWeight.bold),
                      )),
                      Container(
                        height: 20,
                      ),
                      FadeIn(
                        child: Hero(
                          tag: "tag",
                          child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(40),
                                  topRight: Radius.circular(40)),
                              child: Container(
                                  color: Colors.transparent,
                                  height: 90,
                                  width: MediaQuery.of(context).size.width,
                                  padding: const EdgeInsets.all(23),
                                  child: TextField(
                                      keyboardAppearance: MediaQuery.of(context)
                                                  .platformBrightness ==
                                              Brightness.dark
                                          ? Brightness.dark
                                          : Brightness.light,
                                      style:
                                          const TextStyle(color: Colors.black),
                                      controller: _textController,
                                      onSubmitted: (val) async {
                                        if (val.isEmpty) {
                                          setState(() {
                                            isNotNull = true;
                                          });
                                        }
                                        _handleSubmitted(val);
                                      },
                                      decoration: InputDecoration(
                                        prefixIcon: const Icon(
                                          Iconsax.search_normal,
                                          size: 18,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                              color: Color.fromARGB(
                                                  255, 213, 213, 213),
                                              width: 0.7),
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                              color: Color.fromARGB(
                                                  255, 213, 213, 213),
                                              width: 0.7),
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                        ),
                                        fillColor: const Color.fromARGB(
                                            255, 213, 213, 213),
                                        filled: true,
                                        contentPadding: const EdgeInsets.only(
                                            left: 15, top: 5),
                                        alignLabelWithHint: true,
                                        hintText: 'Search on Address',
                                        hintStyle: const TextStyle(
                                            color: Color.fromARGB(
                                                255, 118, 118, 118),
                                            fontFamily: "arial"),
                                      )))),
                        ),
                      ),
                      _isLoadingComplete
                          ? ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  isNotNull = !isNotNull;
                                });
                              },
                              child: const Text(
                                "Load Google",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 20),
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                    value: _loadingProgress / 100),
                                const SizedBox(height: 16),
                                Text('Loading: $_loadingProgress%'),
                              ],
                            ),
                    ],
                  ),
                ],
              )
            : WebViewWidget(controller: _controller),
      ),
    );
  }
}

class NavigationControls extends StatelessWidget {
  const NavigationControls({super.key, required this.webViewController});

  final WebViewController webViewController;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.blue,
          ),
          onPressed: () async {
            if (await webViewController.canGoBack()) {
              await webViewController.goBack();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No back history item')),
              );
            }
          },
        ),
        // TODO: If Item cant go forward, change the icon behavior
        IconButton(
          icon: const Icon(
            Icons.arrow_forward_ios,
            color: Colors.blue,
          ),
          onPressed: () async {
            if (await webViewController.canGoForward()) {
              await webViewController.goForward();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No forward history item')),
              );
            }
          },
        ),
        Container(
          width: MediaQuery.of(context).size.width / 2.3,
        ),
        SimpleMenu(webViewController: webViewController),
      ],
    );
  }
}
