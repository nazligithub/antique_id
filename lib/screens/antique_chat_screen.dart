import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../services/api_service.dart';
import '../providers/app_provider.dart';
import 'antique_premium/antique_premium_view.dart';

class AntiqueChatScreen extends StatefulWidget {
  final String? initialMessage;

  const AntiqueChatScreen({
    super.key,
    this.initialMessage,
  });

  @override
  State<AntiqueChatScreen> createState() => _AntiqueChatScreenState();
}

class _AntiqueChatScreenState extends State<AntiqueChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Hoş geldin mesajı
    _messages.add(ChatMessage(
      text: "Hello! I'm your antique expert. Ask me anything about antiques, their history, valuation, or identification.",
      isUser: false,
      timestamp: DateTime.now(),
    ));

    // Eğer initial message varsa gönder
    if (widget.initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _messageController.text = widget.initialMessage!;
        _sendMessage();
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final appProvider = Provider.of<AppProvider>(context, listen: false);

    // Check if user is premium
    if (!appProvider.isPremiumUser) {
      // Show premium paywall
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AntiquePremiumView(fromOnboarding: false),
        ),
      );
      return;
    }

    setState(() {
      _messages.add(ChatMessage(
        text: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      await _sendChatRequest(message); // Bu artık response'u kendisi handle ediyor
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: "Sorry, I'm having trouble responding right now. Please try again later.",
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  Future<String> _sendChatRequest(String message) async {
    try {
      final result = await ApiService().chatWithExpert(message);

      // API'den gelen response'u parse et ve HTML içerip içermediğini kontrol et
      String responseText;
      bool isHtmlContent = false;

      debugPrint('Chat API Response: $result');

      if (result['data'] != null && result['data']['html_content'] != null) {
        responseText = result['data']['html_content'];
        isHtmlContent = true;
      } else if (result['html_content'] != null) {
        responseText = result['html_content'];
        isHtmlContent = true;
      } else if (result['data'] != null && result['data']['message'] != null) {
        var messageData = result['data']['message'];
        // Eğer message string ise ve JSON formatında ise parse et
        if (messageData is String && messageData.startsWith('{')) {
          try {
            var parsedMessage = jsonDecode(messageData);
            responseText = parsedMessage['message'] ?? parsedMessage['response'] ?? messageData;
          } catch (e) {
            responseText = messageData;
          }
        } else {
          responseText = messageData.toString();
        }
      } else if (result['data'] != null && result['data']['response'] != null) {
        responseText = result['data']['response'].toString();
      } else if (result['message'] != null) {
        var messageData = result['message'];
        // Eğer message string ise ve JSON formatında ise parse et
        if (messageData is String && messageData.startsWith('{')) {
          try {
            var parsedMessage = jsonDecode(messageData);
            responseText = parsedMessage['message'] ?? parsedMessage['response'] ?? messageData;
          } catch (e) {
            responseText = messageData;
          }
        } else {
          responseText = messageData.toString();
        }
      } else if (result['response'] != null) {
        responseText = result['response'].toString();
      } else {
        // Parse edilemeyen JSON response için fallback
        responseText = 'I apologize, but I couldn\'t generate a proper response.';
      }

      // HTML içeriği varsa, ChatMessage'a HTML flag'i ile ekle
      setState(() {
        _messages.add(ChatMessage(
          text: responseText,
          isUser: false,
          timestamp: DateTime.now(),
          isHtml: isHtmlContent,
        ));
        _isLoading = false;
      });

      _scrollToBottom();
      return responseText; // Bu artık kullanılmayacak, sadece eski kod uyumluluğu için
    } catch (e) {
      debugPrint('Chat API Error: $e');
      return "I'm sorry, but I'm having technical difficulties. Please try asking your question again.";
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatHtmlContent(String htmlContent) {
    // HTML content'i tam HTML dokument haline getir
    if (!htmlContent.contains('<html>')) {
      return '''
<!DOCTYPE html>
<html>
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta charset="UTF-8">
    <style>
        body {
            margin: 8px;
            padding: 0;
            background-color: transparent;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            font-size: 14px;
            color: #2D1810;
        }
        * {
            box-sizing: border-box;
        }
        h1, h2, h3, h4, h5, h6 {
            margin-top: 0;
            margin-bottom: 8px;
        }
        p {
            margin-top: 0;
            margin-bottom: 8px;
        }
        ul, ol {
            margin-top: 0;
            margin-bottom: 8px;
            padding-left: 16px;
        }
    </style>
</head>
<body>
    $htmlContent
</body>
</html>''';
    }
    return htmlContent;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F1E8),
        body: Container(
          decoration: AppDecorations.antiqueBackground,
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _buildChatList(),
                ),
                _buildInputArea(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20.w),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40.w,
              height: 40.w,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Color(0xFF8B4513),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          ClipOval(
            child: Image.asset(
              'assets/antique_float.png',
              width: 40.w,
              height: 40.h,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Antique Expert',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D1810),
                  ),
                ),
                Text(
                  'Online',
                  style: GoogleFonts.lora(
                    fontSize: 12.sp,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isLoading && index == _messages.length) {
          return _buildTypingIndicator();
        }

        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            ClipOval(
              child: Image.asset(
                'assets/antique_float.png',
                width: 32.w,
                height: 32.h,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: 8.w),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: message.isUser
                    ? const Color(0xFF8B4513)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(16.r).copyWith(
                  bottomLeft: message.isUser
                      ? Radius.circular(16.r)
                      : Radius.circular(4.r),
                  bottomRight: message.isUser
                      ? Radius.circular(4.r)
                      : Radius.circular(16.r),
                ),
              ),
              child: message.isHtml && !message.isUser
                  ? Container(
                      height: 200.h, // HTML content için sabit yükseklik
                      child: WebViewWidget(
                        controller: WebViewController()
                          ..setJavaScriptMode(JavaScriptMode.unrestricted)
                          ..loadHtmlString(_formatHtmlContent(message.text)),
                      ),
                    )
                  : Text(
                      message.text,
                      style: GoogleFonts.lora(
                        fontSize: 14.sp,
                        color: message.isUser
                            ? Colors.white
                            : const Color(0xFF2D1810),
                        height: 1.4,
                      ),
                    ),
            ),
          ),
          if (message.isUser) ...[
            SizedBox(width: 8.w),
            CircleAvatar(
              radius: 16.r,
              backgroundColor: const Color(0xFF2D1810),
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: 16.sp,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Row(
        children: [
          ClipOval(
            child: Image.asset(
              'assets/antique_float.png',
              width: 32.w,
              height: 32.h,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16.r).copyWith(
                bottomLeft: Radius.circular(4.r),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                SizedBox(width: 4.w),
                _buildTypingDot(1),
                SizedBox(width: 4.w),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.5 + (value * 0.5),
          child: Container(
            width: 6.w,
            height: 6.h,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(25.r),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Ask about antiques...',
                        hintStyle: GoogleFonts.lora(
                          color: Colors.grey[500],
                          fontSize: 14.sp,
                        ),
                        border: InputBorder.none,
                      ),
                      style: GoogleFonts.lora(
                        fontSize: 14.sp,
                        color: const Color(0xFF2D1810),
                      ),
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                      onChanged: (text) => setState(() {}), // Trigger rebuild to update button color
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: _isLoading ? null : _sendMessage,
            child: Container(
              width: 48.w,
              height: 48.h,
              decoration: BoxDecoration(
                color: _isLoading
                    ? Colors.grey[400]
                    : _messageController.text.trim().isEmpty
                        ? Colors.grey[400]
                        : const Color(0xFF8B4513),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.send,
                color: Colors.white,
                size: 20.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isHtml;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isHtml = false,
  });
}