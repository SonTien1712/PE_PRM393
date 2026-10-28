# Báo cáo — Sổ Thu Chi

## Phạm vi và nền tảng

Mã nguồn chức năng bắt buộc M0–M6 và tài liệu M6-DOC theo PROJECT_SPEC_1.md đã được triển khai. Windows desktop là nền tảng chính qua sqflite_common_ffi; Android dùng cùng nghiệp vụ với sqflite mặc định. Không hỗ trợ web.

Sau bản nền/tài liệu đã bổ sung Tier B: retry bootstrap, needsRefresh/banner tải lại chỉ đọc, test phiên thiếu key/hết hạn/tương lai/lỗi đọc, lỗi SQLite thật và widget tests. Các mục này đã được triển khai; nghiệm thu native vẫn là phần riêng chưa hoàn tất.

Chức năng: login/restore/logout, CRUD có xác nhận xóa, tổng thu/chi/số dư, search tiếng Việt không dấu, bộ lọc kết hợp và bốn sort. UI tiếng Việt, Material 3, responsive max-width 640. Tháng/ngân sách UI, đăng ký và CSV chưa triển khai/hiển thị; schema/repository ngân sách có sẵn theo DB v1.

## Kiến trúc và dữ liệu

- core: theme/routes, pure validators, VND, normalize tiếng Việt, salt/hash, formatter kiểm tra cả lần nhập/dán.
- data: một file SQLite, models, repositories SQL có tham số, session preferences.
- providers: AuthProvider quản lý phiên; TransactionProvider quản lý snapshot/tổng SQL/filter/sort/CRUD.
- screens/widgets: giao diện, named routes, loading/empty/error và widget dùng lại.

SQLite phù hợp bài PE vì offline, không cần máy chủ và lưu bền. Windows dùng application support directory, độc lập cwd; Android dùng databases directory. Tiền INTEGER dương tối đa 999999999999; type phân biệt income/expense. Ngày yyyy-MM-dd thật và không vượt hôm nay; note tối đa 200 ký tự. DB CHECK kiểm soát tiền/type/budget, bật foreign_keys mỗi lần mở. Repository kiểm tra category thuộc type; update giữ nguyên user_id/created_at/id.

Tổng dùng SQL SUM/COALESCE, không phụ thuộc search/filter. Upsert budget UPDATE rồi INSERT nếu 0 hàng trong một transaction; giữ id và không phụ thuộc cú pháp UPSERT mới.

## Auth, cách ly và bất đồng bộ

Preferences chỉ lưu userId/timestamp, không lưu mật khẩu. Restore loại phiên thiếu key, timestamp tương lai, tuổi >= 7 ngày hoặc user không còn. Lỗi đọc preferences đi Login với thông báo riêng, không tự xóa key.

SELECT/UPDATE/DELETE transactions/budgets giới hạn user_id. Provider gán quyền sở hữu từ phiên đã capture trước await. Đổi user tăng epoch, xóa state im lặng trong proxy update và defer notify/refresh bằng microtask để tránh notify khi build. Kết quả/catch/finally phiên cũ không chạm state mới; version đọc còn chặn refresh cùng user hoàn tất sai thứ tự.

Mọi protected route dùng RequireAuth; chỉ guard của route hiện tại chuyển về Login sau logout và xóa stack. Handler logout không điều hướng thêm. Form dùng mounted/epoch sau await, chặn nhấp Lưu lặp trước await; detail chỉ tự đóng sau một snapshot mới đọc thành công xác nhận hàng không tồn tại.

## Xử lý lỗi

DatabaseException được đổi thành thông báo tiếng Việt, lỗi nghiệp vụ giữ thông báo cụ thể, raw exception chỉ vào debug log. SaveResult.ok phản ánh DB commit: refresh lỗi sau ghi vẫn ok, form đóng một lần và hiện cảnh báo tải lại, không hướng người dùng insert trùng. Đọc lỗi giữ snapshot trước. Bootstrap cache Future mở DB, loading/error có MaterialApp riêng, không tự reset dữ liệu.

## Kiểm chứng

Lượt cuối **63 tests đều qua**, flutter analyze không có vấn đề và format 58 file không thay đổi. Log đầy đủ tại evidence/tests.txt, evidence/analyze.txt và evidence/format.txt. Repository tests dùng SQLite FFI thật; provider/widget tests dùng fake điều khiển async, không thay backend runtime. Widget tests xác nhận login/Enter, thêm/sửa/xóa, hủy/xác nhận xóa, logout với nhiều protected route, Lưu lặp, refresh warning và layout/lịch tiếng Việt ở 360×640/1280×720. Test đóng/mở file SQLite trên đĩa giữ dữ liệu/seed; PRAGMA query_only tạo lỗi write thật và xác nhận không thêm hàng.

Môi trường: Flutter 3.47.0 / Dart 3.13.0 / Windows 11, Developer Mode bật. Doctor báo chưa có Visual Studio C++; chưa nghiệm thu Windows release, UI native hay đóng/mở lại tiến trình. Android chưa kiểm thử trên thiết bị, SDK còn license chưa chấp nhận. Không ghi Pass cho bằng chứng thủ công chưa có và không bắt đầu Tier C khi baseline chưa nghiệm thu.

## Test 10 và giới hạn

Chủ dự án xác nhận đề ghi “For Firebase or RESTful API implementations, test connection failures...”. Ứng dụng chỉ SQLite nên test 10 là N/A; lỗi SQLite được kiểm tra riêng cho mục error handling.

SHA-256 kèm salt giữ theo phạm vi PE, không lưu plaintext trong DB/preferences. Đây là hash nhanh, không phải giải pháp mật khẩu cho sản phẩm thực tế; không thêm PBKDF2/package hashing trong phạm vi này. Demo credentials công khai phục vụ chấm bài. Lọc user_id và session local không bảo vệ dữ liệu khi DB/preferences/thiết bị bị can thiệp.

Local-only, không đồng bộ/khôi phục/đổi mật khẩu. Xóa DB hoặc gỡ app có thể mất dữ liệu. Hết hạn phiên kiểm tra khi restore, không có bộ hẹn giờ nền.
