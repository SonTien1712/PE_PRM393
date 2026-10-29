# Báo cáo — Sổ Thu Chi

## Phạm vi và nền tảng

Mã nguồn M0–M10 và tài liệu M6-DOC theo PROJECT_SPEC_1.md đã được triển khai. Đây là ứng dụng mobile được phát triển/demo trên Windows qua sqflite_common_ffi; Android dùng cùng nghiệp vụ với sqflite mặc định. Không hỗ trợ web. Chủ dự án yêu cầu triển khai M7–M10 trong khi tiếp tục hoàn thiện bằng chứng baseline; các bước thủ công chưa chạy vẫn giữ trạng thái chưa nghiệm thu.

Sau bản nền/tài liệu đã bổ sung Tier B: retry bootstrap, needsRefresh/banner tải lại chỉ đọc, test phiên thiếu key/hết hạn/tương lai/lỗi đọc, lỗi SQLite thật và widget tests. Các mục này đã được triển khai; nghiệm thu native vẫn là phần riêng chưa hoàn tất.

Chức năng: login/restore/logout, CRUD có xác nhận xóa, tổng thu/chi/số dư, search tiếng Việt không dấu, bộ lọc kết hợp và bốn sort; thống kê theo tháng/danh mục, ngân sách/cảnh báo, đăng ký và xuất CSV.

Giao diện mobile dùng Be Vietnam Pro bundle offline và màu teal/xanh thu/đỏ chi. Windows rộng dùng khung 430 dp bao toàn bộ Navigator, điện thoại/cửa sổ hẹp dùng toàn chiều rộng. Giữ hai tab dưới cùng; resize không tạo lại Navigator. Số dư nổi bật; tiền dài/chữ lớn chuyển bố cục thay vì FittedBox thu nhỏ vô hạn. Footer Lưu/Hủy nằm trên bàn phím và dưới vùng SnackBar; date picker/menu nằm trong khung.

Đã áp dụng bản `ui-upgrade-plan.md` mới: TextTheme/spacing/radius thống nhất, login có lỗi inline và demo riêng, skeleton lần tải đầu, dropdown sắp xếp và chip bỏ từng điều kiện, nền icon theo danh mục, detail chia khối và Sửa trên AppBar, nhắc ngân sách 80%. Category/ngày dùng local constraints để xếp cạnh nhau hoặc dọc; không dựa vào chiều rộng cửa sổ bên ngoài khung. Đề xuất NavigationRail/desktop 1120 dp được thay bằng khung 430 dp theo yêu cầu trực tiếp trước đó của chủ dự án. Đối chiếu tại UI_UX_IMPROVEMENT_PLAN.md.

## Kiến trúc và dữ liệu

- core: theme/routes, pure validators, VND, normalize tiếng Việt, salt/hash, formatter kiểm tra cả lần nhập/dán, month ranges, hàm CSV và hàm tính chuyển ngưỡng ngân sách thuần.
- data: một file SQLite, models, repositories SQL có tham số, session preferences; CsvExportService điều phối thư mục/file/chia sẻ theo nền tảng và kiểm tra phiên.
- providers: AuthProvider quản lý phiên/đăng ký; TransactionProvider quản lý snapshot/tổng SQL/filter/sort/CRUD, tháng/ngân sách và đọc CSV theo user.
- screens/widgets: giao diện, named routes, loading/empty/error và widget dùng lại.

SQLite phù hợp bài PE vì offline, không cần máy chủ và lưu bền. Windows dùng application support directory, độc lập cwd; Android dùng databases directory. Tiền INTEGER dương tối đa 999999999999; type phân biệt income/expense. Ngày yyyy-MM-dd thật và không vượt hôm nay; note tối đa 200 ký tự. DB CHECK kiểm soát tiền/type/budget, bật foreign_keys mỗi lần mở. Repository kiểm tra category thuộc type; update giữ nguyên user_id/created_at/id.

Tổng dùng SQL SUM/COALESCE, không phụ thuộc search/filter. Upsert budget UPDATE rồi INSERT nếu 0 hàng trong một transaction; giữ id và không phụ thuộc cú pháp UPSERT mới.

M7 dùng khoảng ngày [đầu tháng, đầu tháng kế tiếp); tổng chính luôn toàn thời gian. Version riêng cho truy vấn tháng chặn kết quả trả về sai thứ tự. Snapshot của tháng cũ không được gắn nhãn tháng mới khi đang tải hoặc lỗi.

M8 chỉ cảnh báo khi tăng cấp: dưới 80% → từ 80%, hoặc từ không cảnh báo/cảnh báo → trên 100%; đúng 100% vẫn là cảnh báo. Tính cho tháng của giao dịch, kể cả khi đang xem tháng khác. Sửa giao dịch trừ khoản chi cũ trong cùng tháng trước khi cộng giá trị mới. Lỗi đọc tùy chọn để tính cảnh báo không chặn ghi hợp lệ. Ngân sách ghi thành công rồi refresh lỗi vẫn hoàn tất và chỉ yêu cầu thử đọc lại.

M9 tạo user với username lowercase và hash/salt, rồi lưu phiên để tự đăng nhập. Trùng tên là lỗi tại field username. Nếu tạo tài khoản xong nhưng lưu phiên lỗi, UI chỉ dẫn đăng nhập, không gửi đăng ký lần nữa.

M10 đọc toàn bộ giao dịch của user đã capture, không phụ thuộc filter hiện tại; CSV sắp ngày tăng dần, có BOM và escaping. Windows lưu Downloads/fallback Documents; Android ghi file tạm rồi dùng share_plus 13.3.1. Kiểm tra epoch trước/sau các await; file export dở của phiên cũ được dọn, không chia sẻ sang phiên mới. Test service dùng thư mục tạm và callback share, không tự gửi dữ liệu đến ứng dụng khác.

## Auth, cách ly và bất đồng bộ

Preferences chỉ lưu userId/timestamp, không lưu mật khẩu. Restore loại phiên thiếu key, timestamp tương lai, tuổi >= 7 ngày hoặc user không còn. Lỗi đọc preferences đi Login với thông báo riêng, không tự xóa key.

SELECT/UPDATE/DELETE transactions/budgets giới hạn user_id. Provider gán quyền sở hữu từ phiên đã capture trước await. Đổi user tăng epoch, xóa state im lặng trong proxy update và defer notify/refresh bằng microtask để tránh notify khi build. Kết quả/catch/finally phiên cũ không chạm state mới; version đọc còn chặn refresh cùng user hoàn tất sai thứ tự.

Mọi protected route dùng RequireAuth; chỉ guard của route hiện tại chuyển về Login sau logout và xóa stack. Handler logout không điều hướng thêm. Form dùng mounted/epoch sau await, chặn nhấp Lưu lặp trước await; detail chỉ tự đóng sau một snapshot mới đọc thành công xác nhận hàng không tồn tại.

## Xử lý lỗi

DatabaseException được đổi thành thông báo tiếng Việt, lỗi nghiệp vụ giữ thông báo cụ thể, raw exception chỉ vào debug log. SaveResult.ok phản ánh DB commit: refresh lỗi sau ghi vẫn ok, form đóng một lần và hiện cảnh báo tải lại, không hướng người dùng insert trùng. Đọc lỗi giữ snapshot trước. Bootstrap cache Future mở DB, loading/error có MaterialApp riêng, không tự reset dữ liệu.

## Kiểm chứng

Theo yêu cầu chuẩn bị thuyết trình ngày 29/10/2026, đã thêm công cụ Dart CLI trong tool/: dataset ba tháng và ba tài khoản riêng; validate schema/rules, snapshot SQLite bằng VACUUM INTO, seed trong transaction, bỏ qua tài khoản đã có để không trùng/ghi đè. Đã nạp thực tế 39 giao dịch/4 ngân sách vào DB Windows, đối chiếu bản backup xác nhận dữ liệu cũ nguyên vẹn. App không tự chạy công cụ này khi mở; schema và logic runtime không đổi. Có sáu test riêng cho dữ liệu/ngày, authenticate qua repository, idempotence, rollback collision, backup và ngưỡng trình bày. Tài liệu học/kịch bản ở PROJECT_LEARNING_GUIDE.md, PROJECT_METHOD_MAP.md, DEMO_DATA_GUIDE.md.

Kết quả/số test cuối ở TEST_RESULTS.md; log đầy đủ tại evidence/tests.txt, evidence/analyze.txt và evidence/format.txt. Repository tests dùng SQLite FFI thật; provider/widget tests dùng fake điều khiển async, không thay backend runtime. Bộ test bao phủ CRUD, route guard, phiên, Unicode, post-commit warning, race truy vấn tháng, giới hạn/upsert ngân sách, ngưỡng cảnh báo, đăng ký và CSV/BOM/epoch. UI kiểm tra sáu kích thước, chữ 1×/2×, bàn phím, menu/date picker, state khi resize và ảnh golden với font thật.

Ngày 29/10/2026, integration test Windows native đã build/chạy thành công: đăng nhập lỗi inline/nhập lại, khung 430 dp, lưu ngân sách, thêm khoản chi 900/1000, detail/action Sửa, cảnh báo 90%, tổng SQL theo tháng, ghi CSV BOM và đóng/mở lại file SQLite. Bảy ảnh thật/metadata ở evidence/native/, log evidence/windows-native-test.txt. Test dùng DB tạm riêng và session memory để không ảnh hưởng dữ liệu/phiên thật; không chứng minh restart tiến trình/shared_preferences. APK Android debug cũng đã build thành công sau khi tắt Kotlin incremental compilation để xử lý cache khác ổ C:/D:; chưa chạy Android trên thiết bị. Trạng thái Release cập nhật riêng trong TEST_RESULTS.md. Video restart/cách ly tài khoản và Android share sheet chưa được thay bằng ảnh golden.

## Test 10 và giới hạn

Chủ dự án xác nhận đề ghi “For Firebase or RESTful API implementations, test connection failures...”. Ứng dụng chỉ SQLite nên test 10 là N/A; lỗi SQLite được kiểm tra riêng cho mục error handling.

SHA-256 kèm salt giữ theo phạm vi PE, không lưu plaintext trong DB/preferences. Đây là hash nhanh, không phải giải pháp mật khẩu cho sản phẩm thực tế; không thêm PBKDF2/package hashing trong phạm vi này. Demo credentials công khai phục vụ chấm bài. Lọc user_id và session local không bảo vệ dữ liệu khi DB/preferences/thiết bị bị can thiệp.

Local-only, không đồng bộ/khôi phục/đổi mật khẩu. Xóa DB hoặc gỡ app có thể mất dữ liệu. Hết hạn phiên kiểm tra khi restore, không có bộ hẹn giờ nền.
