# Sổ Thu Chi

Ứng dụng mobile quản lý thu chi bằng Flutter, Provider và SQLite, phát triển/demo trên Windows và hỗ trợ Android bằng cùng mã nguồn. UI tiếng Việt, Material 3, font Be Vietnam Pro dùng offline. Không hỗ trợ web.

Trên Windows rộng từ 600 dp và cao từ 440 dp, toàn bộ ứng dụng nằm trong khung điện thoại **430 dp**: AppBar, điều hướng dưới, màn hình, menu và hộp thoại đều thuộc khung. Khung vừa chiều cao cửa sổ, tối đa 900 dp nội dung. Cửa sổ nhỏ/điện thoại dùng toàn chiều rộng, giữ SafeArea và khoảng tránh bàn phím. Đổi kích thước không làm mất route hoặc dữ liệu form. Không dùng NavigationRail hoặc dashboard desktop mở rộng.

Bản nâng cấp UI áp dụng hệ chữ/khoảng cách thống nhất, login có lỗi trong form, skeleton dashboard lần tải đầu, danh sách có nhãn sắp xếp và chip bỏ từng bộ lọc, icon danh mục pastel, detail có nút Sửa trên AppBar và banner ngân sách 80%. [Kế hoạch và đối chiếu triển khai](UI_UX_IMPROVEMENT_PLAN.md) ghi cách áp dụng bản `ui-upgrade-plan.md` mới vào yêu cầu mobile.

## Chức năng

- Đăng nhập, khôi phục phiên tối đa 7 ngày, đăng xuất và bảo vệ mọi route nội bộ.
- Thêm/list/detail/sửa/xóa có xác nhận; tiền VND số nguyên, ngày không vượt hôm nay, validation cả form và repository.
- Tổng thu/chi/số dư toàn thời gian lấy từ SQL, cập nhật sau CRUD.
- Search ghi chú/danh mục không phân biệt hoa thường/dấu tiếng Việt, cả Unicode tổ hợp.
- Bộ lọc loại/danh mục kết hợp, bốn cách sort; giữ bộ lọc khi chuyển tab, reset khi đổi tài khoản.
- SQLite có ràng buộc, foreign keys và điều kiện user_id. Epoch chặn tác vụ phiên cũ; nhấp Lưu lặp bị chặn.
- SaveResult phân biệt lỗi ghi với lỗi refresh sau commit, tránh insert lại vì thông báo sai.
- Hardening Tier B: bootstrap có Thử lại, cảnh báo dữ liệu cũ có Thử tải lại (chỉ đọc), kiểm thử phiên/lỗi DB và luồng giao diện.

Đã triển khai M0–M10 theo PROJECT_SPEC_1.md và hướng mobile do chủ dự án cập nhật:

| Mốc | Chức năng | Cách dùng |
|---|---|---|
| M7 | Thống kê tháng, chi tiêu theo danh mục và tỷ lệ | Tổng quan → Theo tháng; mũi tên chuyển tháng, không chọn tương lai |
| M8 | Ngân sách theo tháng/tài khoản, tiến độ và cảnh báo | Tổng quan → Đặt/Điều chỉnh ngân sách hoặc menu → Ngân sách |
| M9 | Đăng ký, kiểm tra tên trùng, tự đăng nhập | Đăng nhập → Chưa có tài khoản? Đăng ký |
| M10 | Xuất toàn bộ giao dịch của tài khoản hiện tại | Tab Giao dịch → menu → Xuất CSV |

Ba tổng chính luôn là **toàn thời gian**; bộ chọn tháng chỉ đổi phần Theo tháng. Cảnh báo xuất hiện khi khoản chi làm mức sử dụng tăng lên ngưỡng 80% hoặc vượt 100%; không lặp khi vẫn ở cùng mức. Sửa khoản chi trừ giá trị cũ trước khi tính ngưỡng.

CSV có UTF-8 BOM, giữ tiếng Việt, escape dấu phẩy/nháy/xuống dòng và bảo vệ các tiền tố công thức theo đặc tả. Xuất toàn bộ giao dịch, không chỉ kết quả đang lọc. Windows lưu vào Downloads (fallback Documents), Android tạo file tạm và mở bảng chia sẻ hệ thống. Tên `finance_export_yyyyMMdd_HHmmss.csv`, thêm hậu tố khi trùng tên. Tác vụ thuộc phiên cũ bị hủy và không mở bảng chia sẻ cho phiên mới.

## Tài khoản demo

| Username | Password |
|---|---|
| demo1 | Demo@123 |
| demo2 | Demo@456 |

Ứng dụng chỉ tự seed hai tài khoản trên khi tạo DB lần đầu, không tự thêm giao dịch. Mỗi tài khoản có dữ liệu riêng.

## Dữ liệu trình bày và tài liệu đọc mã nguồn

Theo yêu cầu chuẩn bị thuyết trình ngày 29/10/2026, đã nạp vào DB Windows ba tài khoản riêng: `presenter_demo`, `overbudget_demo`, `empty_demo`; mật khẩu chung `Demo@2026`. Có 39 giao dịch và 4 ngân sách mới, dữ liệu cũ được giữ và đã có backup trước khi nạp. Tài khoản chính có 35 giao dịch qua ba tháng, số dư 29.200.000 ₫ và ngân sách tháng hiện tại ở mức 79% để demo tăng ngưỡng.

- [DEMO_DATA_GUIDE.md](DEMO_DATA_GUIDE.md): tài khoản, số tổng đối chiếu, kịch bản 15–20 phút, nhập 80%/85%/105%, CSV và cách dọn các dòng tự thêm.
- [PROJECT_LEARNING_GUIDE.md](PROJECT_LEARNING_GUIDE.md): bảy buổi học cấu trúc/SQL/auth/CRUD/async/UI/test, sơ đồ luồng và câu hỏi bảo vệ.
- [PROJECT_METHOD_MAP.md](PROJECT_METHOD_MAP.md): tra từng file, class, method/getter, input/output và chuỗi gọi.

Mở app → đăng xuất tài khoản cũ → đăng nhập `presenter_demo`. Công cụ `dart run tool/seed_demo_data.dart` chỉ xem kế hoạch; thêm `--apply` để backup rồi nạp các tài khoản còn thiếu trên máy khác. Chạy lại không nhân đôi hoặc reset dữ liệu đã có; không tự nạp sang Android. Xem hướng dẫn chi tiết trước khi đổi file DB.

## Windows

1. Cài Flutter stable tương thích pubspec (môi trường kiểm tra: Flutter 3.47.0 / Dart 3.13.0).
2. Cài Visual Studio với workload **Desktop development with C++**, gồm MSVC/CMake/Windows SDK tương thích Flutter. VS Code không thay thế bộ công cụ này. Môi trường hiện tại đã build và chạy được integration test Windows native.
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

Giữ cả bundle Release, gồm data/plugin/DLL, không chép riêng exe. sqflite_common_ffi là dependency runtime. Nếu một bản package cũ báo không tải được sqlite3.dll, lấy DLL Windows x64 phù hợp từ [SQLite](https://www.sqlite.org/download.html), đặt cạnh exe, chạy lại và ghi bước đó. Chưa cần áp dụng fallback này trong lượt kiểm thử native hiện tại. Trạng thái build Release nằm trong TEST_RESULTS.md.

Windows lưu finance_tracker.db trong getApplicationSupportDirectory(), thường dưới `%APPDATA%\<company>\<app>\`; Android dùng databases directory chuẩn. Đường dẫn desktop độc lập cwd, nên flutter run và exe dùng cùng DB. Metadata app nằm trong windows/runner/Runner.rc.

Reset dữ liệu phát triển: đóng app hoàn toàn, xác định đúng finance_tracker.db của app rồi xóa riêng file đó và journal/WAL đi kèm nếu có. Thao tác này mất dữ liệu; lần mở sau tạo schema và seed lại. Không cần reset cho chạy thông thường.

## Android

Hoàn tất Android SDK và `flutter doctor --android-licenses`, mở emulator hoặc kết nối thiết bị USB debugging:

```powershell
flutter devices
flutter run -d <android-device-id>
flutter build apk --debug
```

Android dùng sqflite mặc định; chỉ desktop khởi tạo FFI. Không chạy bằng Chrome/web.

APK debug đã build tại `build/app/outputs/flutter-apk/app-debug.apk`; xem evidence/android-build.txt. Trên môi trường project ở D: và Pub Cache ở C:, Kotlin incremental cache gây lỗi khác ổ đĩa; android/gradle.properties dùng `kotlin.incremental=false` theo [tài liệu Kotlin](https://kotlinlang.org/docs/gradle-compilation-and-caches.html). Build APK chưa thay thế kiểm tra UI/bàn phím/share sheet trên thiết bị.

## Kiểm tra và tài liệu

```powershell
dart format lib test integration_test tool
flutter analyze
flutter test --reporter expanded
flutter test integration_test/windows_smoke_test.dart -d windows --dart-define=EVIDENCE_DIR=D:/FPt/SemesterVIII/PRM393/PE/evidence/native
```

Repository tests dùng SQLite thật qua FFI in-memory. Provider/widget tests được phép dùng fake để điều khiển async; runtime ứng dụng luôn là SQLite. Xem TEST_RESULTS.md cho số test/log thực tế và các ca cần chụp/quay; không coi host tests là bằng chứng restart tiến trình.

Kết quả nghiệm thu ngày 29/10/2026 và số test thực tế ghi tại [TEST_RESULTS.md](TEST_RESULTS.md). [Ảnh golden](test/goldens/) được render từ widget thật với font bundle và fixture test; [ảnh Windows native](evidence/native/) được chụp trong integration test chạy SQLite thật ở thư mục tạm riêng. Không thêm giao dịch mẫu vào DB của người dùng. Test native dùng phiên trong bộ nhớ để không ghi đè phiên thật; không thay thế video đóng/mở lại tiến trình và kiểm chứng shared_preferences.

Bộ responsive kiểm tra 360×640, 412×915, 768×1024, 1280×720, 1440×900, landscape 844×390; chữ 1×/2×, số tiền dài, giữ state khi resize, lịch trong khung, footer Lưu không bị bàn phím/thông báo che. Golden chỉ cập nhật có chủ đích: `flutter test test/mobile_layout_test.dart --update-goldens`.

lib/main.dart khởi tạo FFI; bootstrap_app.dart mở DB; app.dart cấu hình locale/routes; core chứa tiện ích/validation/theme; data chứa models/DB/repositories/session; providers quản lý auth/snapshot; screens/widgets chứa UI. test/ chứa kiểm thử. REPORT.md giải thích thiết kế/giới hạn, SCREENSHOTS.md và DEMO_SCRIPT.md hướng dẫn thu evidence.

Theo yêu cầu chủ dự án, M7–M10 đã được mở và kiểm thử, đồng thời tiếp tục ghi đúng các bằng chứng native/thủ công còn thiếu. Android share sheet, kiểm thử thiết bị và video restart phiên/dữ liệu vẫn cần nghiệm thu riêng; không ghi Pass thay cho các bước chưa chạy.
