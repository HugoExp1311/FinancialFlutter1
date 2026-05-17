import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../providers/app_providers.dart';
import 'package:image_picker/image_picker.dart'; // Chụp ảnh từ nhánh bạn
import 'package:flutter_markdown/flutter_markdown.dart'; // Markdown từ nhánh Thu
import '../providers/language_provider.dart';
import '../utils/app_translations.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final List<String> quickReplies = [
    "🎯 Tư vấn tài chính",
    "📊 Thống kê tháng này",
    "💸 Mẹo tiết kiệm",
  ];

  ChatMessage({required this.text, required this.isUser});
}

class ChatMessagesNotifier extends Notifier<List<ChatMessage>> {
  static const String introKey = 'intro_message_key';

  @override
  List<ChatMessage> build() {
    return [
      ChatMessage(
        text: introKey, // Lưu dưới dạng key để dịch tin nhắn đa ngôn ngữ
        isUser: false,
      ),
    ];
  }

  void addMessage(ChatMessage message) {
    state = [...state, message];
  }

  void clear() {
    state = [ChatMessage(text: introKey, isUser: false)];
  }
}

final chatMessagesProvider =
    NotifierProvider<ChatMessagesNotifier, List<ChatMessage>>(() {
      return ChatMessagesNotifier();
    });

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key});

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();
  String? _base64Image;

  // Tính năng chụp ảnh hóa đơn từ nhánh Bạn
  Future<void> _pickImage() async {
    final lang = ref.read(languageProvider);
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        imageQuality: 50,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        _base64Image = base64Encode(bytes);

        // Hiển thị tin nhắn người dùng gửi ảnh
        ref
            .read(chatMessagesProvider.notifier)
            .addMessage(
              ChatMessage(
                text: AppTranslations.getText(lang, 'image_attached'),
                isUser: true,
              ),
            );

        _handleSubmitted(AppTranslations.getText(lang, 'scan_invoice_prompt'));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppTranslations.getText(lang, 'image_error')}$e'),
          ),
        );
      }
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

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    _textController.clear();
    final lang = ref.read(languageProvider);
    final scanPrompt = AppTranslations.getText(lang, 'scan_invoice_prompt');

    // Chỉ in tin nhắn nếu không phải prompt quét ảnh ẩn
    if (text != scanPrompt) {
      ref
          .read(chatMessagesProvider.notifier)
          .addMessage(ChatMessage(text: text, isUser: true));
    }

    setState(() {
      _isLoading = true;
    });
    _scrollToBottom();

    final user = Supabase.instance.client.auth.currentUser;

    try {
      final client = HttpClient();
      final request = await client.postUrl(
        Uri.parse('http://localhost:5678/webhook/ai-chat'),
      );
      request.headers.set('Content-Type', 'application/json');

      final payload = {
        'message': text,
        'user_id': user?.id,
        'current_date': DateTime.now().toIso8601String(),
        if (_base64Image != null) 'image_base64': _base64Image,
      };

      _base64Image = null;

      request.add(utf8.encode(jsonEncode(payload)));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Bóc tách JSON an toàn (Kết hợp cả 2 nhánh)
        String resultText = responseBody.trim();

        try {
          final decoded = jsonDecode(responseBody);
          if (decoded is Map) {
            resultText = decoded['replyMessage'] ?? decoded['output'] ?? decoded['bot_text'] ?? AppTranslations.getText(lang, 'parse_error');
            
            // Nếu AI ghi chép thành công thì bắt app tự đồng bộ dữ liệu
            if (decoded['replyMessage'] != null || decoded['output'] != null) {
              ref.read(syncTransactionsUseCaseProvider).execute();
            }
          }
        } catch (e) {
          // Nếu không phải JSON thì bắt lỗi incompatible
          if (resultText.isEmpty) {
            resultText = '${AppTranslations.getText(lang, 'ai_incompatible')}$responseBody';
          }
        }

        if (resultText.isNotEmpty) {
          ref.read(chatMessagesProvider.notifier).addMessage(
                ChatMessage(text: resultText, isUser: false),
          );
        }
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ref
            .read(chatMessagesProvider.notifier)
            .addMessage(
              ChatMessage(
                text: '${AppTranslations.getText(lang, 'ai_disconnected')}$e',
                isUser: false,
              ),
            );
        _scrollToBottom();
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);
    final lang = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.smart_toy_rounded, color: AppTheme.incomeColor),
            SizedBox(width: 8),
            Text('Finance AI', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
        elevation: 1,
        backgroundColor: Theme.of(context).cardTheme.color,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return _buildMessageBubble(message, lang);
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.incomeColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppTranslations.getText(lang, 'finance_ai_thinking'),
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          _buildTextComposer(lang),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, String lang) {
    final isUser = message.isUser;
    final alignment = isUser
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    final bgColor = isUser
        ? AppTheme.primaryColor
        : Theme.of(context).cardTheme.color;
    final textColor = isUser
        ? Colors.white
        : Theme.of(context).colorScheme.onSurface;
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(isUser ? 20 : 0),
      bottomRight: Radius.circular(isUser ? 0 : 20),
    );

    String displayText = message.text;
    if (message.text == ChatMessagesNotifier.introKey) {
      displayText = AppTranslations.getText(lang, 'intro_message');
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8, // Giới hạn chiều rộng
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: borderRadius,
              border: isUser
                  ? null
                  : Border.all(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                    ),
            ),
            // SỬ DỤNG MARKDOWN CỦA THU NẾU LÀ BOT TRẢ LỜI
            child: isUser 
              ? Text(displayText, style: TextStyle(color: textColor, fontSize: 16))
              : MarkdownBody(
                  data: displayText,
                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                    p: TextStyle(color: textColor, fontSize: 16, height: 1.5),
                    strong: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                    listBullet: TextStyle(color: textColor, fontSize: 16),
                    blockSpacing: 10,
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextComposer(String lang) {
    // Danh sách các gợi ý nhanh (Của Thu)
    final List<String> quickReplies = [
      "🎯 Tư vấn tài chính",
      "📊 Thống kê tháng này",
      "💸 Mẹo tiết kiệm",
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 16,
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // HÀNG NÚT BẤM GỢI Ý NHANH (CỦA THU)
            SizedBox(
              height: 45,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: quickReplies.map((text) => Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: ActionChip(
                    label: Text(text, style: const TextStyle(fontSize: 12)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    backgroundColor: AppTheme.incomeColor.withValues(alpha: 0.1),
                    side: BorderSide(color: AppTheme.incomeColor.withValues(alpha: 0.3)),
                    onPressed: () => _handleSubmitted(text),
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: 8),

            // Ô NHẬP LIỆU & NÚT GỬI ẢNH (CỦA BẠN)
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.add_a_photo_rounded,
                    color: AppTheme.textSubDark,
                  ),
                  onPressed: _pickImage,
                  tooltip: AppTranslations.getText(lang, 'send_invoice'),
                ),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _handleSubmitted,
                    decoration: InputDecoration(
                      hintText: AppTranslations.getText(lang, 'chat_hint'),
                      hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.incomeColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    onPressed: () => _handleSubmitted(_textController.text),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}