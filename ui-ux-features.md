# Nhật Ký Phát Triển Giao Diện (UI/UX Features Log)

Tài liệu này tổng hợp các chức năng giao diện, thành phần UI (Components) và các cập nhật kiến trúc đã được triển khai cho ứng dụng Quản lý tài chính cá nhân (Finance App).

## 1. Cấu Trúc Giao Diện Hiện Tại (Presentation Layer)
Các file được xây dựng trong thư mục `lib/presentation/`:

* **`theme/app_theme.dart`**: Trái tim thiết kế của ứng dụng.
  * **Chức năng**: Định nghĩa các bảng màu cao cấp (Premium Color Palette) và cấu hình giao diện `Dark Mode` / `Light Mode`.
  * **Highlight**: Gán màu riêng biệt cho Thu nhập (Xanh Ngọc - Emerald Green) và Chi tiêu (Đỏ San Hô - Coral Red). Tự động lấy cấu hình hệ thống nhờ `ThemeMode.system`.
  
* **`screens/home_screen.dart`**: Bảng điều khiển chính (Dashboard).
  * **Chức năng**: Trang chính của người dùng khi vừa mở ứng dụng.
  * **Thành phần**:
    1. **Custom AppBar**: Chứa lời chào cá nhân hóa "Good Morning, Alex!" và hình đại diện (Avatar).
    2. **Khu vực số dư**: Hiển thị thẻ tổng quan tài chính.
    3. **Danh sách (List View)**: Khu vực cuộn hiển thị dữ liệu lịch sử các giao dịch gần nhất (Recent Transactions).
    4. **Floating Action Button (FAB)**: Nút nổi "New Transaction" bắt mắt ngay giữa dưới cùng để thao tác nhanh.

* **`widgets/balance_card.dart`**: Thẻ Số Dư (Component Độc lập).
  * **Chức năng**: Hiển thị tổng số dư hiện tại ($12,450.00), và phân bổ Tổng Thu - Tổng Chi trong tháng.
  * **Thiết kế**: 
    - Hiệu ứng Gradient 3 lớp (Đen huyền - Xanh xám - Xanh đại dương).
    - Tạo hiệu ứng đổ bóng mượt (Soft Drop Shadow) làm nổi thẻ trên nền giao diện tối, mang lại cảm giác phần mềm cao cấp.

* **`widgets/transaction_item.dart`**: Khối Lịch sử Giao dịch (Reusable Component).
  * **Chức năng**: Component tái sử dụng cao, dùng để bọc dữ liệu của 1 giao dịch đơn lẻ thành một thanh danh sách đẹp mắt.
  * **Thiết kế**: 
    - Nền Icon mờ (Opacity 15%) tiệp màu với chính Icon đó.
    - Tự động thay đổi màu chữ của Số Tiền (Amount) dựa vào việc đó là Tiêu Tiền (màu đỏ dấu `-`) hay Nhận Tiền (màu xanh dấu `+`).

## 2. Tiêu Chuẩn Kỹ Thuật UI (UI/UX Engineering Standards)
- 🎨 **Glassmorphism & Opacity**: Ứng dụng nhiều lớp mờ (Opacity màu nền) thay vì viền thô cứng để tạo cảm giác sang trọng.
- 📱 **Responsive & SafeArea**: Tích hợp `SafeArea` bao bọc ngoài cùng màn hình, đảm bảo UI tự động tránh "Tai thỏ" (Notch), Dynamic Island trên iOS, hoặc thanh điều hướng trên các loại màn hình Android có tỷ lệ mép dị biệt.
- 🧩 **Component-Based**: Tách hoàn toàn Card và Item ra file riêng lẻ (`widgets/...`). Cực kỳ thân thiện khi cần tái sử dụng ở các màn hình Thống Kê (Chart) sau này.

## 3. Hệ Thống Đa Tính Năng (Multi-Screen Architecture)
Ứng dụng đã được nâng cấp từ một màn hình duy nhất thành hệ thống Super App điều hướng toàn diện (đạt chuẩn Expert CV).

* **`screens/main_navigation_screen.dart`**: Khung xương điều hướng của toàn bộ hệ thống.
  * **Chức năng**: Chứa `IndexedStack` giúp người dùng chuyển tab nhanh mà màn hình không bị tải lại từ đầu (Giữ nguyên State).
  * **Thiết kế Navigation Bar**: Thanh BottomAppBar tuỳ chỉnh, vát mượt mà ôm lấy nút Thêm Giao Dịch lơ lửng. Đặc biệt đã được viết đè lớp `surfaceTintColor: Colors.transparent` để khắc phục vệt ám trắng của Material 3. Các Icon tab được gắn hiệu ứng Scale chậm tạo cảm giác ấn nảy tinh tế.

* **`screens/statistics_screen.dart`**: Bảng điều khiển Thống kê Sinh học (Dashboard).
  * **Thiết kế**: Vẽ song song 2 biểu đồ hoàn toàn bằng thuật toán Toán học nguyên thuỷ (`CustomPainter`), loại bỏ hoàn toàn việc phụ thuộc thư viện rác:
    - **Biểu đồ Đường (Line Chart)** với hiệu ứng đổ bóng Gradient cong vút mềm mại diễn tả sức khỏe thu nhập (Net Income).
    - **Biểu đồ Tròn (Pie Chart)** sử dụng StrokeCap.round chừa khoảng hở (Gap) nghệ thuật dành riêng cho việc chia tỷ trọng danh mục.
  * **Chức năng bổ trợ**: Nút lọc thời gian (Week/Month/Year) và danh sách lịch sử băm nhỏ theo từng Cụm Ngày (Today, Yesterday...).

* **`screens/wallet_screen.dart`**: Quản lý Ví điện tử & Thẻ.
  * **Thiết kế**: Gọn gàng và đẳng cấp, giả lập ngoại hình các thẻ thanh toán. Bo tròn mạnh (Radius 24), Gradient mờ trải dài góc chéo, tích hợp icon Chip Wifi mang lại tính hiện thực.

* **`screens/profile_screen.dart`**: Màn hình Thiết lập & Người dùng.
  * **Thiết kế**: Thay vì cố định, màn hình được bọc trong bộ `SingleChildScrollView`. Nó ngăn ngừa mọi lỗi "Overflow" khó chịu khi xem trên điện thoại lùn, cho phép người dùng lướt trơn tru qua danh sách Setting. Các thẻ Setting được bao viền nhẹ (Opacity 0.05) tinh giản mà không kém phần sang trọng.

* **`screens/add_transaction_screen.dart`**: Cửa sổ thêm giao dịch (Fullscreen Modal Dialog).
  * **Chức năng**: Hiện lên mượt mà theo chiều dọc (slide from bottom) khi bấm nút (+) từ Main Navigation. Cho phép chọn Thu nhập/Chi tiêu, Category, nhập số tiền lớn và ghi chú. 
  * **Thiết kế UI**: 
    - Bộ công tắc Trượt ngang (Income/Expense Custom Toggle) bọc màu viền tinh khiết của Theme.
    - Cụm nhập số tiền Khổng lồ (`fontSize: 48`) thiết kế kiểu mờ 0.00 chuyên nghiệp với biểu tượng `$`.
    - Component chọn Danh mục (`CategoryItem`) nằm ngang (Horizontal Scroll) bảo vệ State, tự động ngắt mảng chia thành riêng biệt Nhóm Thu Nhập (Salary, Invest, Rent...) và Nhóm Chi Tiêu (Food, Transport, Bills).
    - Tích hợp Date Picker tiêm cấu trúc Theme tối của ứng dụng, tránh bị chói mắt.

## 4. Nhật Ký Lỗi & Sửa Chữa Đáng Chú Ý (Expert Debugging)
- **Lỗi Deprecated `.withOpacity()`**: Cập nhật toàn bộ file lên chuẩn `.withValues(alpha: x)` để tương thích với Engine Render mới nhất của Dart 3 (Impeller Engine).

### 💡 Bài Học Điển Hình: Lỗi Tràn Viền (Yellow Strip "Overflowed by X pixels")
Lỗi dải sọc caro vàng đen là hung thần gây nhức nhối bậc nhất khi làm di động (đặc biệt khi co màn hình). Qua quá trình phát triển, dự án đã rút ra quy tắc vàng (Expert Rules) để đối phó:
1. **Lỗi Tràn dọc đáy (Bottom Overflow)**: 
   - Nguyên nhân: Các thành phần UI bên trong cột (`Column`) chiếm chiều cao lớn hơn màn hình thực tế (Ví dụ trên màn hình Profile).
   - Cách phòng tránh: Không bao giờ nhốt lượng lớn thẻ giao diện vào `Column` tĩnh. Mặc định mọi màn hình dạng List đều phải được bọc trong bộ khung `SingleChildScrollView`.
2. **Lỗi Tràn ngang chữ (Right Overflow)**: 
   - Nguyên nhân: Việc xuất một đoạn String/Text nội suy quá dài (Như chuỗi `Ngày/Tháng/Năm`), sau đó lại dùng các thẻ ép cứng như `Spacer()` tạo lực đẩy tàn phá bố cục ngang.
   - Cách phòng tránh: Khi đặt một Text kế bên một Icon ở khu vực hẹp, TẤT YẾU phải bọc `Text(...)` đó vào trong một chiếc bao `Expanded(child: ...)` nhằm nhắc Widget đó tự động thu mình nhỏ lại, co dãn tuỳ theo dung lượng máy!

## 5. Tầng Cơ Sở Dữ Liệu (Data Layer)
Toàn bộ hệ thống UI tĩnh đã kết nối thành công với bộ não NoSQL `Isar Database` siêu tốc:
- **`models/app_transaction.dart` (Schema)**: Cấu trúc lõi lưu trữ giao dịch.
- **Kỹ thuật Tối ưu (Database Optimizer)**: 
  - Đánh Index dạng giá trị (`IndexType.value`) trên cột `date` mang lại tốc độ Search/Sort siêu nhanh O(log N).
  - Triển khai **Kiến trúc phẳng (Flat Architecture/Embedding)** bằng việc nhồi trực tiếp Icon/Màu sắc của `Category` vào Schema `Transaction`, loại trừ triệt để lỗi trì trệ do Joins (IsarLink) gây ra.

---
*Dự án hiện tại: Sẵn sàng đấu nối Business Logic (Riverpod) để kích nạp Dữ liệu sống vào các màn hình UI!*
