# Nhật ký kiểm chứng

Cập nhật 29/10/2026, Windows 11 x64, Flutter 3.47.0 / Dart 3.13.0.

Các log nghiệm thu hiện tại:

- format.txt: `dart format --output=none --set-exit-if-changed lib test integration_test tool`, 90 file, 0 thay đổi ở lượt cuối.
- analyze.txt: `flutter analyze --no-pub`, không có vấn đề.
- tests.txt: `flutter test --no-pub --reporter expanded`, 120 test qua, gồm SQLite thật, provider/widget/golden tests, accessibility form và 6 test công cụ demo.
- windows-native-test.txt: integration_test/windows_smoke_test.dart trên Windows, 1 test qua; build debug và thao tác native với DB tạm riêng.
- native/: bảy ảnh native và metadata, bao gồm viewport 430 dp; login lỗi inline/nhập lại, ngân sách, thêm giao dịch, detail/action Sửa, cảnh báo 90%, CSV BOM và SQLite close-reopen đã kiểm tra.
- windows-build.txt: `flutter build windows --release --no-pub`, build thành công. Bundle có sqlite3.dll; không tải DLL thủ công.
- android-build.txt: `flutter build apk --debug --no-pub` thành công; build/app/outputs/flutter-apk/app-debug.apk. Tắt Kotlin incremental compilation để tránh lỗi cache khác ổ C:/D:. Chưa chạy APK trên thiết bị.
- demo-data-summary.json / demo-seed.txt: lần nạp thực tế ba tài khoản dành riêng, 39 giao dịch và 4 ngân sách vào DB Windows.
- demo-data-verification.json: đối chiếu backup xác nhận users/transactions/budgets cũ nguyên vẹn, password hash khớp, quick_check OK và không lỗi foreign key.
- demo-tests.txt: sáu test công cụ seed/backup/rollback/idempotence và baseline trình bày qua.
- demo-plan.txt: chạy CLI không có --apply sau khi nạp, xác nhận chế độ xem không ghi và số liệu 35/4/0 giao dịch của ba tài khoản.
- demo-docs-check.json: 73 liên kết tài liệu hợp lệ, cả 63 file lib/ được dẫn trong bản đồ method.
- local/: backup SQLite trước seed, đã được gitignore; không đưa dữ liệu cũ của người dùng vào bài nộp công khai.

m7/m8/m9/m10/ui-* lưu các lượt phát triển, có thể chứa lỗi trung gian đã được sửa. Khi đánh giá phiên bản hiện tại, dùng log nghiệm thu ở trên. Stack trace của lỗi được chủ động tạo để kiểm tra error handling không phải test failure nếu dòng cuối ghi All tests passed.

Ứng dụng runtime dùng SQLite thật. Golden dùng fixture test; Windows integration dùng DB tạm và session memory để không tác động dữ liệu người dùng. Chưa có video restart tiến trình, kiểm chứng startup Release hay ảnh Android/share sheet. Xem TEST_RESULTS/SCREENSHOTS cho các bước còn cần thu.
