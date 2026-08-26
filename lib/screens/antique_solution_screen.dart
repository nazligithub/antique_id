import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../constants/app_constants.dart';
import '../services/collection_service.dart';
import '../widgets/collection_selection_bottom_sheet.dart';
import 'antique_collection/collection_viewmodel.dart';

class AntiqueSolutionScreen extends StatefulWidget {
  final Map<String, dynamic> analysisResult;
  final String imagePath;

  const AntiqueSolutionScreen({
    super.key,
    required this.analysisResult,
    required this.imagePath,
  });

  @override
  State<AntiqueSolutionScreen> createState() => _AntiqueSolutionScreenState();
}

class _AntiqueSolutionScreenState extends State<AntiqueSolutionScreen> {
  late WebViewController _webViewController;
  bool isLoading = true;
  double webViewHeight = 1000;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              isLoading = true;
            });
          },
          onPageFinished: (String url) async {
            setState(() {
              isLoading = false;
            });

            // Wait a bit for content to fully render
            await Future.delayed(const Duration(milliseconds: 500));

            // Get the actual content height with multiple attempts
            try {
              for (int i = 0; i < 3; i++) {
                await Future.delayed(const Duration(milliseconds: 200));

                final heightResult = await _webViewController.runJavaScriptReturningResult(
                  'Math.max(document.body.scrollHeight, document.body.offsetHeight, document.documentElement.clientHeight, document.documentElement.scrollHeight, document.documentElement.offsetHeight);'
                );

                if (heightResult is num && heightResult > 0) {
                  final calculatedHeight = heightResult.toDouble() + 200; // More padding
                  setState(() {
                    webViewHeight = calculatedHeight < 1000 ? 1000 : calculatedHeight; // Minimum 1000
                  });
                  debugPrint('WebView height set to: $webViewHeight');
                  break;
                }
              }
            } catch (e) {
              debugPrint('Error getting WebView height: $e');
              setState(() {
                webViewHeight = 2000; // Larger fallback height
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              isLoading = false;
            });
          },
        ),
      );

    _loadHtmlContent();
  }

  void _loadHtmlContent() {
    // API response'ındaki data field'ından HTML content'i al
    String htmlContent = widget.analysisResult['data']?['html_content'] ??
        widget.analysisResult['html_content'] ??
        widget.analysisResult['htmlContent'] ??
        _generateDefaultHtml();

    // API'den gelen HTML'i tam HTML dokument haline getir (görsel olmadan)
    if (!htmlContent.contains('<html>')) {
      htmlContent = '''
<!DOCTYPE html>
<html>
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta charset="UTF-8">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        body {
            margin: 0;
            padding: 16px;
            background-color: #ffffff;
            font-family: 'Playfair Display', serif;
            line-height: 1.6;
            color: #333;
        }
        * {
            box-sizing: border-box;
        }
        h1, h2, h3 {
            color: #2D1810;
            margin-top: 24px;
            margin-bottom: 16px;
        }
        h1 {
            font-size: 24px;
            font-weight: bold;
        }
        h2 {
            font-size: 20px;
            font-weight: 600;
        }
        h3 {
            font-size: 18px;
            font-weight: 500;
        }
        p {
            margin: 12px 0;
            font-size: 16px;
        }
        .value-estimate {
            background: linear-gradient(135deg, #8B4513, #D4AF37);
            color: white;
            padding: 16px;
            border-radius: 12px;
            text-align: center;
            font-size: 18px;
            font-weight: bold;
            margin: 20px 0;
        }
        .info-box {
            background: #f5f1e8;
            padding: 16px;
            border-radius: 8px;
            border-left: 4px solid #8B4513;
            margin: 16px 0;
        }
        ul {
            padding-left: 20px;
        }
        li {
            margin: 8px 0;
            font-size: 16px;
        }
        strong {
            color: #8B4513;
        }
    </style>
</head>
<body>
    $htmlContent
</body>
</html>''';
    }

    _webViewController.loadHtmlString(htmlContent);
  }

  String _generateDefaultHtml() {
    final result = widget.analysisResult;
    final data = result['data'] ?? result;
    final name = data['antique_name'] ?? data['name'] ?? result['name'] ?? result['result']?['name'] ?? 'Unknown Antique';
    final description = data['description'] ?? result['description'] ?? result['result']?['description'] ?? 'No description available';
    final era = data['era'] ?? data['period'] ?? result['era'] ?? result['result']?['era'] ?? result['result']?['estimatedAge'] ?? 'Unknown era';
    final origin = data['origin'] ?? result['origin'] ?? result['result']?['origin'] ?? 'Unknown origin';
    final value = data['antique_price'] ?? data['reference_price'] ?? result['estimatedValue'] ?? result['result']?['estimatedValue'] ?? 'Value not determined';
    final confidence = data['confidence'] ?? result['confidence'] ?? result['result']?['confidence'] ?? 0;

    return '''
        <h1>$name</h1>

        <h2>Description</h2>
        <p>$description</p>

        <div class="value-estimate">
            Estimated Value: \$$value
        </div>

        <h2>Details</h2>
        <div class="info-box">
            <strong>Era:</strong> $era<br>
            <strong>Origin:</strong> $origin<br>
            <strong>Confidence Level:</strong> ${(confidence * 100).toInt()}%
        </div>

        <h2>Key Features</h2>
        <ul>
            <li>Carefully examine the craftsmanship and materials used</li>
            <li>Look for maker's marks or signatures</li>
            <li>Consider the item's provenance and history</li>
            <li>Consult with professional appraisers for accurate valuation</li>
        </ul>

        <h2>Care Instructions</h2>
        <div class="info-box">
            <p>To preserve your antique's value:</p>
            <ul>
                <li>Keep in a stable environment away from direct sunlight</li>
                <li>Maintain consistent temperature and humidity</li>
                <li>Clean gently with appropriate materials</li>
                <li>Avoid restoration unless absolutely necessary</li>
            </ul>
        </div>
    ''';
  }

  void _saveToCollection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CollectionSelectionBottomSheet(
        onCollectionSelected: (collectionName) async {
          try {
            await CollectionService().saveToCollection(
              widget.analysisResult,
              widget.imagePath,
              collectionName: collectionName,
            );

            if (mounted) {
              // Collection view model'ı force refresh et
              Provider.of<CollectionViewModel>(context, listen: false).loadCollection(forceRefresh: true);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Added to "$collectionName" collection!'),
                  backgroundColor: const Color(0xFF8B4513),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to save: ${e.toString()}'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _shareResult() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sharing functionality coming soon!'),
        backgroundColor: Color(0xFF8B4513),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.analysisResult['data']?['image_url'] ??
                     widget.analysisResult['imageUrl'];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F1E8),
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  // Image section - full width, covers status bar
                  if (imageUrl != null && imageUrl.toString().isNotEmpty)
                    Container(
                      height: 350.h,
                      width: double.infinity,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.image_not_supported,
                              size: 50.sp,
                              color: Colors.grey[400],
                            ),
                          );
                        },
                      ),
                    ),
                  // WebView Content - unlimited height
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20.r),
                        topRight: Radius.circular(20.r),
                      ),
                    ),
                    child: isLoading
                        ? Container(
                            height: 400.h,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF8B4513),
                              ),
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20.r),
                              topRight: Radius.circular(20.r),
                            ),
                            child: Container(
                              height: webViewHeight, // Dynamic height based on content
                              child: WebViewWidget(controller: _webViewController),
                            ),
                          ),
                  ),
                  // Extra space for save button
                  SizedBox(height: 100.h),
                ],
              ),
            ),
            // Back button - positioned over image
            Positioned(
              top: MediaQuery.of(context).padding.top + 10.h,
              left: 20.w,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // Fixed Save to Collection Button
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  left: 20.w,
                  right: 20.w,
                  top: 20.h,
                  bottom: MediaQuery.of(context).padding.bottom + 20.h,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20.r),
                    topRight: Radius.circular(20.r),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _saveToCollection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B4513),
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    minimumSize: Size(double.infinity, 50.h),
                  ),
                  child: Text(
                    'Save to Collection',
                    style: GoogleFonts.lora(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}