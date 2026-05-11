import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:core_domain/core_domain.dart';
import '../theme/app_theme.dart';
import '../providers/app_providers.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

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
  @override
  List<ChatMessage> build() {
    return [
      ChatMessage(
        text:
            'Xin chào! Mình là Trợ lý Ảo Finance AI 🤖.\n Hôm nay bạn đã ăn gì, mua gì thì cứ nhắn mình ghi chép hộ nhé!',
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
        text:
            'Xin chào! Mình là Trợ lý Ảo Finance AI 🤖.\nBạn nghe được ăn gì, mua gì thì cứ nhắn mình ghi chép hộ nhé!',
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
    ref.read(chatMessagesProvider.notifier).addMessage(
          ChatMessage(text: text, isUser: true),
        );
    setState(() {
      _isLoading = true;
    });
    _scrollToBottom();

    // Lấy thông tin user hiện tại để gài vô gói gửi lên cho AI
    final user = Supabase.instance.client.auth.currentUser;

    // Rút trích lịch sử giao dịch hiện tại từ Isar Database (để phục vụ tính năng RAG - Phân tích AI)
    final transactions = ref.read(transactionsStreamProvider).value ?? [];
    // Sort mới nhất lên đầu và lấy 100 giao dịch để khỏi tràn Token LLM
    final sortedTxs = List<TransactionEntity>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    final recentTxs = sortedTxs.take(100).toList();

    final String historyString = recentTxs
        .map((t) {
          final sign = t.isExpense ? 'Chi' : 'Thu';
          // Format thủ công dd/mm/yyyy
          final dateStr =
              "${t.date.day.toString().padLeft(2, '0')}/${t.date.month.toString().padLeft(2, '0')}/${t.date.year}";
          return "[$dateStr] ${t.categoryName} ($sign): ${t.amount} (Note: ${t.note ?? 'Trống'})";
        })
        .join(" | ");

    try {
      final client = HttpClient();
      // Bắn lệnh POST lên Cổng test của Docker n8n
      final request = await client.postUrl(
        Uri.parse('http://localhost:5678/webhook/ai-chat'),
      );
      request.headers.set('Content-Type', 'application/json');
      // Bọc dán dữ liệu vào thùng JSON
      final payload = {
        'message': text,
        'user_id': user?.id,
        'history': historyString, // Điệp viên Data chìm
        'current_date': DateTime.now()
            .toIso8601String(), // Cấp ngày hiện tại cho AI biết Đường tính "Hôm nay", "Sáng nay"
      };
      request.add(utf8.encode(jsonEncode(payload)));

      // Chờ AI n8n trả kết quả về
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Bóc tách JSON do n8n (qua tay Gemini) trả về
        String resultText = responseBody.trim();

        try {
          final decoded = jsonDecode(responseBody);
          if (decoded is Map) {
            resultText = decoded['replyMessage'] ?? decoded['output'] ?? responseBody;
          }
        } catch (e) {
          // Không phải JSON thì cứ để yên là responseBody
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
        ref.read(chatMessagesProvider.notifier).addMessage(
              ChatMessage(
                text:
                    '🔴 Lỗi ngắt kết nối với não AI:\nĐảm bảo Webhook n8n đang mở cửa [Listening]. Lỗi chi tiết: $e',
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
                return _buildMessageBubble(message);
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
                    'Finance AI is thinking...',
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
          _buildTextComposer(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
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
              // ... (giữ nguyên border) ...
            ),
            // THAY THẾ Text() bằng MarkdownBody() bên dưới:
            child: isUser 
              ? Text(message.text, style: TextStyle(color: textColor, fontSize: 16))
              : MarkdownBody(
                  data: message.text,
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

  Widget _buildTextComposer() {
    // Danh sách các gợi ý nhanh
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
        child: Column( // Chuyển sang Column để chứa hàng nút bấm phía trên
          mainAxisSize: MainAxisSize.min,
          children: [
            // Hàng nút bấm Quick Replies
            SizedBox(
              height: 45,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(), // Hiệu ứng cuộn lò xo
                children: quickReplies.map((text) => Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: ActionChip(
                    label: Text(text, style: const TextStyle(fontSize: 12)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    backgroundColor: AppTheme.incomeColor.withOpacity(0.1),
                    side: BorderSide(color: AppTheme.incomeColor.withOpacity(0.3)),
                    onPressed: () => _handleSubmitted(text),
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _handleSubmitted,
                    decoration: InputDecoration(
                      hintText: 'Nhập mẩu tiền bạn vừa tiêu (vd: Đổ xăng 50k)...',
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