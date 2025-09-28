import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ghar360/core/utils/app_colors.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TourView extends StatefulWidget {
  const TourView({super.key});

  @override
  State<TourView> createState() => _TourViewState();
}

class _TourViewState extends State<TourView> {
  late final WebViewController controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    final String tourUrl = Get.arguments as String;
    const consoleSilencer = '''
      if (window && window.console) {
        window.console.log = function() {};
        window.console.warn = function() {};
        window.console.error = function() {};
        window.console.info = function() {};
        window.console.debug = function() {};
      }
    ''';

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              isLoading = true;
            });
            controller.runJavaScript(consoleSilencer);
          },
          onPageFinished: (String url) {
            setState(() {
              isLoading = false;
            });
            controller.runJavaScript(consoleSilencer);
            controller.runJavaScript('''
              document.body.style.margin = '0';
              document.body.style.padding = '0';
              var iframes = document.getElementsByTagName('iframe');
              for (var i = 0; i < iframes.length; i++) {
                iframes[i].style.width = '100%';
                iframes[i].style.height = '100vh';
                iframes[i].style.border = 'none';
              }
            ''');
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              isLoading = false;
            });
            Get.snackbar(
              'error_loading_tour'.tr,
              'check_internet_connection'.tr,
              snackPosition: SnackPosition.TOP,
              backgroundColor: AppColors.errorRed,
              colorText: AppColors.snackbarText,
            );
          },
        ),
      );

    if (tourUrl.contains('kuula.co')) {
      final htmlContent =
          '''
        <!DOCTYPE html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <style>
            body { margin: 0; padding: 0; background: #000; }
            iframe { width: 100vw; height: 100vh; border: none; }
          </style>
          <script type="text/javascript">
            $consoleSilencer
          </script>
        </head>
        <body>
          <iframe class="ku-embed" frameborder="0"
                  allow="xr-spatial-tracking; gyroscope; accelerometer"
                  allowfullscreen scrolling="no"
                  src="$tourUrl">
          </iframe>
        </body>
        </html>
      ''';
      controller.loadHtmlString(htmlContent);
    } else {
      controller.loadRequest(Uri.parse(tourUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.appBarBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.appBarIcon),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'virtual_tour_title'.tr,
          style: TextStyle(color: AppColors.appBarText, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.fullscreen, color: AppColors.appBarIcon),
            onPressed: () {
              Get.snackbar(
                'fullscreen_mode'.tr,
                'rotate_device_better_experience'.tr,
                snackPosition: SnackPosition.TOP,
                backgroundColor: AppColors.snackbarBackground,
                colorText: AppColors.snackbarText,
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.share, color: AppColors.appBarIcon),
            onPressed: () {
              Get.snackbar(
                'share_tour'.tr,
                'tour_link_copied'.tr,
                snackPosition: SnackPosition.TOP,
                backgroundColor: AppColors.snackbarBackground,
                colorText: AppColors.snackbarText,
              );
            },
          ),
        ],
      ),
      body: Container(
        color: AppColors.scaffoldBackground,
        child: Stack(
          children: [
            // WebView with enhanced iframe support
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppColors.getCardShadow(),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: WebViewWidget(controller: controller),
              ),
            ),
            // Loading indicator
            if (isLoading)
              Container(
                color: AppColors.scaffoldBackground,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        color: AppColors.primaryYellow,
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'loading_virtual_tour'.tr,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
