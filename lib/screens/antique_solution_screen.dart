import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/collection_service.dart';
import '../widgets/collection_selection_bottom_sheet.dart';

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
          onPageFinished: (String url) {
            setState(() {
              isLoading = false;
            });
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
    // Debug: API response'ını kontrol et
    debugPrint('Analysis Result Keys: ${widget.analysisResult.keys.toList()}');
    debugPrint('Analysis Result: ${widget.analysisResult.toString().substring(0, 500)}...');

    // API response'ındaki data field'ından HTML content'i al
    String htmlContent = widget.analysisResult['data']?['html_content'] ??
        widget.analysisResult['html_content'] ??
        widget.analysisResult['htmlContent'] ??
        _generateDefaultHtml();

    debugPrint('Using HTML Content: ${htmlContent.substring(0, 200)}...');

    // API'den gelen HTML'i tam HTML dokument haline getir
    if (!htmlContent.contains('<html>')) {
      htmlContent = '''
<!DOCTYPE html>
<html>
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta charset="UTF-8">
    <style>
        body {
            margin: 0;
            padding: 16px;
            background-color: #f5f1e8;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        }
        * {
            box-sizing: border-box;
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
    final name = result['name'] ?? result['result']?['name'] ?? 'Unknown Antique';
    final description = result['description'] ?? result['result']?['description'] ?? 'No description available';
    final era = result['era'] ?? result['result']?['era'] ?? result['result']?['estimatedAge'] ?? 'Unknown era';
    final origin = result['origin'] ?? result['result']?['origin'] ?? 'Unknown origin';
    final value = result['estimatedValue'] ?? result['result']?['estimatedValue'] ?? 'Value not determined';
    final confidence = result['confidence'] ?? result['result']?['confidence'] ?? 0;

    return '''
        <h1>$name</h1>

        <h2>Description</h2>
        <p>$description</p>

        <div class="value-estimate">
            Estimated Value: $value
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
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F1E8),
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 300.h,
                  pinned: false,
                  stretch: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: Container(
                    margin: EdgeInsets.only(left: 20.w, top: 10.h),
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
                  flexibleSpace: FlexibleSpaceBar(
                    background: imageUrl != null
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey,
                                    size: 50,
                                  ),
                                ),
                              );
                            },
                          )
                        : Image.file(
                            File(widget.imagePath),
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                ),
              ),
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 200.h,
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20.r),
                      topRight: Radius.circular(20.r),
                    ),
                    child: Container(
                      height: MediaQuery.of(context).size.height - 200.h,
                      child: WebViewWidget(controller: _webViewController),
                    ),
                  ),
                  if (isLoading)
                    Container(
                      height: MediaQuery.of(context).size.height - 200.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20.r),
                          topRight: Radius.circular(20.r),
                        ),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF8B4513),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.all(20.w),
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
    );
  }
}