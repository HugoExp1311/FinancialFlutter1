import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:core_domain/core_domain.dart';
import '../theme/app_theme.dart';
import '../providers/app_providers.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/language_provider.dart'; 
import '../utils/app_translations.dart'; 

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class ChatMessagesNotifier extends Notifier<List<ChatMessage>> {
  static const String introKey = 'intro_message_key';

  @override
  List<ChatMessage> build() {
    return [
      ChatMessage(
        text: introKey, // Lưu dưới dạng Key để dịch ở UI
        isUser: false,
      ),
    ];
  }

  void addMessage(ChatMessage message) {
    state = [...state, message];
  }

  void clear() {
    state = [
      ChatMessage(
        text: introKey,
        isUser: false,
      ),
    ];
  }
}

// Global Provider không có .autoDispose để lưu vào RAM trên toàn phiên chạy App
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

  Future<void> _pickImage() async {
    final lang = ref.read(languageProvider); // Đọc ngôn ngữ hiện tại
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery, 
        maxWidth: 1000, 
        imageQuality: 50, 
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        _base64Image = base64Encode(bytes);

        // Hiển thị tin nhắn người dùng "gửi ảnh" lên màn hình chat
        ref.read(chatMessagesProvider.notifier).addMessage(
              ChatMessage(text: AppTranslations.getText(lang, 'image_attached'), isUser: true),
            );

        // Tự động gọi hàm gửi API lên n8n
        _handleSubmitted(AppTranslations.getText(lang, 'scan_invoice_prompt'));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppTranslations.getText(lang, 'image_error')}$e')),
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
    final lang = ref.read(languageProvider); // Đọc ngôn ngữ hiện tại
    final scanPrompt = AppTranslations.getText(lang, 'scan_invoice_prompt');
    
    // Chỉ in tin nhắn ra màn hình NẾU nó KHÔNG PHẢI là câu lệnh quét ảnh tự động
    if (text != scanPrompt) {
      ref.read(chatMessagesProvider.notifier).addMessage(
            ChatMessage(text: text, isUser: true),
          );
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

        try {
          final responseJson = jsonDecode(responseBody);
          final replyText =
              responseJson['replyMessage'] ??
              responseJson['bot_text'] ??
              AppTranslations.getText(lang, 'parse_error');

          ref.read(chatMessagesProvider.notifier).addMessage(
                ChatMessage(text: replyText, isUser: false),
              );

          if (responseJson['replyMessage'] != null) {
            ref.read(syncTransactionsUseCaseProvider).execute();
          }
        } catch (e) {
          ref.read(chatMessagesProvider.notifier).addMessage(
                ChatMessage(
                  text: '${AppTranslations.getText(lang, 'ai_incompatible')}$responseBody',
                  isUser: false,
                ),
              );
        }
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ref.read(chatMessagesProvider.notifier).addMessage(
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
    final lang = ref.watch(languageProvider); // THEO DÕI NGÔN NGỮ ĐỂ VẼ GIAO DIỆN

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
          _buildTextComposer(lang), // TRUYỀN LANG XUỐNG
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

    // XỬ LÝ DỊCH CÂU CHÀO MẶC ĐỊNH
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
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: borderRadius,
              border: isUser
                  ? null
                  : Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.1),
                    ),
            ),
            child: Text(
              displayText, // HIỂN THỊ TEXT ĐÃ DỊCH HOẶC TEXT TỪ AI
              style: TextStyle(color: textColor, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextComposer(String lang) {
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
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add_a_photo_rounded, color: AppTheme.textSubDark),
              onPressed: _pickImage,
              tooltip: AppTranslations.getText(lang, 'send_invoice'),
            ),
            const SizedBox(width: 8), 

            Expanded(
              child: TextField(
                controller: _textController,
                textInputAction: TextInputAction.send,
                onSubmitted: _handleSubmitted,
                decoration: InputDecoration(
                  hintText: AppTranslations.getText(lang, 'chat_hint'),
                  hintStyle: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.4),
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
      ),
    );
  }
}