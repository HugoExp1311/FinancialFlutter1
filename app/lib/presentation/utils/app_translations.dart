// app/lib/presentation/utils/app_translations.dart

class AppTranslations {
  static const Map<String, Map<String, String>> translations = {
    'en': {
      'email': 'Email',
      'password': 'Password',
      'login': 'Log In',
      'signup': 'Sign Up',
      'have_account': 'Already have an account? Log In',
      'no_account': "Don't have an account? Sign Up",
      'create_account': 'Create a secure account',
      'welcome_back': 'Welcome back, login to sync your data',
      'home': 'Home',
      'statistics': 'Stats',
      'wallet': 'Wallet',
      'profile': 'Profile',
      // statistics
      'net': 'Net',
      'net_income': 'Net Income',
      'total_expense': 'Total Expense',
      'total_income': 'Total Income',
      'day': 'Day',
      'week': 'Week',
      'month': 'Month',
      'year': 'Year',
      'category_breakdown': 'Category Breakdown',
      'details_by_date': 'Details by Date',
      'search_filter_active': 'Search filter active!',
      'no_data_category': 'No data for this category.',
      'other': 'Other',
      'no_transactions_found': 'No transactions found.',
      'no_data_match': 'No data match.',
      // end statistics
      // wallet
      'my_wallets': 'My Wallets',
      'main_wallet': 'Main Wallet',
      'savings': 'Savings',
      'total_balance': 'Total Balance',
      'add_new_wallet': 'Add New Wallet',
      // end wallet
      // add transaction
      'new_transaction': 'New Transaction',
      'enter_amount': 'Enter Amount',
      'category': 'Category',
      'date': 'Date',
      'note': 'Note',
      'what_was_this_for': 'What was this for?',
      'save_transaction': 'Save Transaction',
      'please_enter_amount': 'Please enter an amount',
      'transaction_saved': 'Transaction saved successfully!',
      // dịch UI cho Category
      'food': 'Food',
      'transport': 'Transport',
      'shopping': 'Shopping',
      'bills': 'Bills',
      'salary': 'Salary',
      'invest': 'Invest',
      'rent': 'Rent',
      // end add transaction
      // chatbot
      'intro_message':
          'Hello! I am Finance AI 🤖.\nJust message me your expenses or income, and I will log them for you!',
      'image_attached': '📸 [Invoice image attached]',
      'scan_invoice_prompt':
          'Please scan this invoice image, calculate the total in USD and log it for me.',
      'image_error': 'Image selection error: ',
      'finance_ai_thinking': 'Finance AI is thinking...',
      'send_invoice': 'Send invoice',
      'chat_hint': 'Enter your expense (e.g., Gas 50k)...',
      'parse_error': 'Could not extract answer!',
      'ai_incompatible': 'AI returned incompatible result:\n',
      'ai_disconnected':
          '🔴 AI disconnection error:\nEnsure n8n Webhook is listening. Details: ',
      // end chatbot
      // home
      'welcome': 'Welcome,',
      'see_all': 'See All',
      'no_transactions_yet': 'No transactions yet. Add some!',
      'error': 'Error',
      'recent_transactions': 'Recent Transactions',
      // end home
      // profile
      'unknown_user': 'Unknown User',
      'premium_member': 'Premium Member ✦',
      'account_settings': 'Account Settings',
      'language': 'Language',
      'security_faceid': 'Security & FaceID',
      'notifications': 'Notifications',
      'help_support': 'Help & Support',
      'logout': 'Log Out',
      // end profile
      'income': 'Income',
      'expense': 'Expense',
      'sync_data': 'Sync Data',
      'syncing_with_cloud': 'Syncing with Cloud...',
      // chi tiết còn lại
      'edit_transaction': 'Edit Transaction',
      'delete_transaction': 'Delete Transaction',
      'transaction_deleted': 'Transaction deleted',
      'failed_to_delete': 'Failed to delete',
      'amount': 'Amount',
      'cancel': 'Cancel',
      'save': 'Save',
      'transaction_updated': 'Transaction updated',
      'failed_to_update': 'Failed to update',
      // end chi tiết
    },

    // Từ điển tiếng việt
    'vi': {
      'email': 'Email',
      'password': 'Mật khẩu',
      'login': 'Đăng nhập',
      'signup': 'Đăng ký',
      'have_account': 'Đã có tài khoản? Đăng nhập',
      'no_account': 'Chưa có tài khoản? Đăng ký',
      'create_account': 'Tạo tài khoản mới',
      'welcome_back': 'Chào mừng trở lại',
      'home': 'Trang chủ',
      'statistics': 'Thống kê',
      'wallet': 'Ví',
      'profile': 'Hồ sơ',
      // statistics
      'net': 'Tích lũy',
      'net_income': 'Thu nhập ròng',
      'total_expense': 'Tổng chi tiêu',
      'total_income': 'Tổng thu nhập',
      'day': 'Ngày',
      'week': 'Tuần',
      'month': 'Tháng',
      'year': 'Năm',
      'category_breakdown': 'Phân bổ theo danh mục',
      'details_by_date': 'Chi tiết theo ngày',
      'search_filter_active': 'Đã bật bộ lọc tìm kiếm!',
      'no_data_category': 'Không có dữ liệu danh mục này.',
      'other': 'Khác',
      'no_transactions_found': 'Không tìm thấy giao dịch nào.',
      'no_data_match': 'Không có dữ liệu nào.',
      // end statistics
      // wallet
      'my_wallets': 'Ví của tôi',
      'main_wallet': 'Ví chính',
      'savings': 'Tiết kiệm',
      'total_balance': 'Tổng số dư',
      'add_new_wallet': 'Thêm ví mới',
      // end wallet
      // add transaction
      'new_transaction': 'Giao dịch mới',
      'enter_amount': 'Nhập số tiền',
      'category': 'Danh mục',
      'date': 'Ngày',
      'note': 'Ghi chú',
      'what_was_this_for': 'Giao dịch này dùng để làm gì?',
      'save_transaction': 'Lưu giao dịch',
      'please_enter_amount': 'Vui lòng nhập số tiền',
      'transaction_saved': 'Đã lưu giao dịch thành công!',
      // dịch UI cho Category
      'food': 'Ăn uống',
      'transport': 'Di chuyển',
      'shopping': 'Mua sắm',
      'bills': 'Hóa đơn',
      'salary': 'Lương',
      'invest': 'Đầu tư',
      'rent': 'Tiền cho thuê',
      // end add transaction
      // chatbot
      'intro_message':
          'Xin chào! Mình là Trợ lý Ảo Finance AI 🤖.\nBạn vừa có chi tiêu hay thu nhập gì thì cứ nhắn mình ghi chép hộ nhé!',
      'image_attached': '📸 [Đã đính kèm ảnh hóa đơn]',
      'scan_invoice_prompt':
          'Hãy quét hình ảnh hóa đơn này, tính tổng tiền quy ra USD và ghi chép lại giúp tôi.',
      'image_error': 'Lỗi chọn ảnh: ',
      'finance_ai_thinking': 'Finance AI đang suy nghĩ...',
      'send_invoice': 'Gửi hóa đơn',
      'chat_hint': 'Nhập số tiền bạn vừa tiêu (vd: Đổ xăng 50k)...',
      'parse_error': 'Chưa bóc tách được câu trả lời!',
      'ai_incompatible': 'AI n8n trả về kết quả không tương thích:\n',
      'ai_disconnected':
          '🔴 Lỗi ngắt kết nối với não AI:\nĐảm bảo Webhook n8n đang mở cửa [Listening]. Lỗi chi tiết: ',
      // end chatbot
      // home
      'welcome': 'Chào mừng trở lại,',
      'recent_transactions': 'Giao dịch gần đây',
      'see_all': 'Xem tất cả',
      'no_transactions_yet': 'Chưa có giao dịch. Hãy thêm mới!',
      'error': 'Lỗi',
      // end home
      // profile
      'unknown_user': 'Người dùng ẩn danh',
      'premium_member': 'Thành viên Premium ✦',
      'account_settings': 'Cài đặt tài khoản',
      'language': 'Ngôn ngữ',
      'security_faceid': 'Bảo mật & FaceID',
      'notifications': 'Thông báo',
      'help_support': 'Trợ giúp & Hỗ trợ',
      'logout': 'Đăng xuất',
      // end profile
      'income': 'Thu nhập',
      'expense': 'Chi tiêu',
      'sync_data': 'Đồng bộ dữ liệu',
      'syncing_with_cloud': 'Đang đồng bộ dữ liệu...',
      // chi tiết còn lại
      'edit_transaction': 'Sửa giao dịch',
      'delete_transaction': 'Xóa giao dịch',
      'transaction_deleted': 'Đã xóa giao dịch',
      'failed_to_delete': 'Xóa thất bại',
      'amount': 'Số tiền',
      'cancel': 'Hủy',
      'save': 'Lưu',
      'transaction_updated': 'Cập nhật thành công',
      'failed_to_update': 'Cập nhật thất bại',
      // end chi tiết
    },
  };

  static String getText(String lang, String key) {
    return translations[lang]?[key] ?? key;
  }
}