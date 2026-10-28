# Sổ Thu Chi

Ứng dụng quản lý thu chi bằng Flutter, Provider và SQLite. Windows desktop là nền tảng chính; cùng mã nguồn hỗ trợ Android. UI tiếng Việt, Material 3, nội dung căn giữa rộng tối đa 640 px. Không hỗ trợ web.

## Chức năng

- Đăng nhập, khôi phục phiên tối đa 7 ngày, đăng xuất và bảo vệ mọi route nội bộ.
- Thêm/list/detail/sửa/xóa có xác nhận; tiền VND số nguyên, ngày không vượt hôm nay, validation cả form và repository.
- Tổng thu/chi/số dư toàn thời gian lấy từ SQL, cập nhật sau CRUD.
- Search ghi chú/danh mục không phân biệt hoa thường/dấu tiếng Việt, cả Unicode tổ hợp.
- Bộ lọc loại/danh mục kết hợp, bốn cách sort; giữ bộ lọc khi chuyển tab, reset khi đổi tài khoản.
- SQLite có ràng buộc, foreign keys và điều kiện user_id. Epoch chặn tác vụ phiên cũ; nhấp Lưu lặp bị chặn.
- SaveResult phân biệt lỗi ghi với lỗi refresh sau commit, tránh insert lại vì thông báo sai.
- Hardening Tier B: bootstrap có Thử lại, cảnh báo dữ liệu cũ có Thử tải lại (chỉ đọc), kiểm thử phiên/lỗi DB và luồng giao diện.

Bản nguồn hiện thực chức năng bắt buộc M0–M6 theo PROJECT_SPEC_1.md. Tháng/ngân sách UI, đăng ký và CSV chưa được mở. Bảng/repository ngân sách được chuẩn bị từ schema v1 theo đặc tả.

## Tài khoản demo

| Username | Password |
|---|---|
| demo1 | Demo@123 |
| demo2 | Demo@456 |

Chỉ seed tài khoản khi tạo DB lần đầu; không thêm giao dịch giả. Mỗi tài khoản có dữ liệu riêng.

## Windows

1. Cài Flutter stable tương thích pubspec (môi trường kiểm tra: Flutter 3.47.0 / Dart 3.13.0).
2. Cài Visual Studio 2022 với workload **Desktop development with C++**, gồm MSVC/CMake/Windows SDK mặc định. VS Code không thay thế bộ công cụ này.
3. Bật Windows Developer Mode trong Settings → For developers để plugin tạo symlink.
4. Chạy:

```powershell
flutter doctor -v
flutter pub get
flutter run -d windows
flutter build windows --release
.\build\windows\x64\runner\Release\pe_prm393_de190630.exe
```

windows/ và android/ đã có. Nếu một bản sao thiếu chúng, sao lưu thay đổi riêng rồi dùng `flutter create --platforms=windows,android .`.

Giữ cả bundle Release, gồm data/plugin/DLL, không chép riêng exe. sqflite_common_ffi là dependency runtime. Kiểm tra sớm release cũng mở DB; nếu phiên bản package cũ báo không tải được sqlite3.dll, lấy DLL Windows x64 phù hợp từ [SQLite](https://www.sqlite.org/download.html), đặt cạnh exe, chạy lại và ghi bước đó. Fallback này chưa áp dụng: máy hiện chưa có Visual Studio để build release.

Windows lưu finance_tracker.db trong getApplicationSupportDirectory(), thường dưới `%APPDATA%\<company>\<app>\`; Android dùng databases directory chuẩn. Đường dẫn desktop độc lập cwd, nên flutter run và exe dùng cùng DB. Metadata app nằm trong windows/runner/Runner.rc.

Reset dữ liệu phát triển: đóng app hoàn toàn, xác định đúng finance_tracker.db của app rồi xóa riêng file đó và journal/WAL đi kèm nếu có. Thao tác này mất dữ liệu; lần mở sau tạo schema và seed lại. Không cần reset cho chạy thông thường.

## Android

Hoàn tất Android SDK và `flutter doctor --android-licenses`, mở emulator hoặc kết nối thiết bị USB debugging:

```powershell
flutter devices
flutter run -d <android-device-id>
```

Android dùng sqflite mặc định; chỉ desktop khởi tạo FFI. Không chạy bằng Chrome/web.

## Kiểm tra và tài liệu

```powershell
dart format .
flutter analyze
flutter test --reporter expanded
```

Repository tests dùng SQLite thật qua FFI in-memory. Provider/widget tests được phép dùng fake để điều khiển async; runtime ứng dụng luôn là SQLite. Xem TEST_RESULTS.md cho số test/log thực tế và các ca cần chụp/quay; không coi host tests là bằng chứng restart tiến trình.

Lượt cuối ngày 28/10/2026: **63 tests qua**, analyzer không có vấn đề, format 58 file không thay đổi. Log đầy đủ trong evidence/. Widget tests đã chạy login/Enter, thêm/sửa/xóa, route guard/logout, Lưu lặp, refresh lỗi sau commit, lịch tiếng Việt và layout 360×640/1280×720. SQLite thật trên đĩa cũng đã được đóng/mở lại trong test. Đây chưa phải kiểm thử tiến trình Windows native.

lib/main.dart khởi tạo FFI; bootstrap_app.dart mở DB; app.dart cấu hình locale/routes; core chứa tiện ích/validation/theme; data chứa models/DB/repositories/session; providers quản lý auth/snapshot; screens/widgets chứa UI. test/ chứa kiểm thử. REPORT.md giải thích thiết kế/giới hạn, SCREENSHOTS.md và DEMO_SCRIPT.md hướng dẫn thu evidence.

Máy triển khai Windows 11 đã bật Developer Mode nhưng thiếu Visual Studio C++; Android còn license chưa chấp nhận và chưa có thiết bị kết nối. Chưa xác nhận app Windows release hoặc Android thật; các DoD thủ công tương ứng chưa nghiệm thu. Hoàn thiện và nghiệm thu bản bắt buộc trước Tier C.
