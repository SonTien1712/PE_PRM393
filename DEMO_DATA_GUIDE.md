# Dữ liệu và kịch bản trình bày Sổ Thu Chi

Chuẩn bị ngày **29/10/2026, Asia/Saigon**. Dữ liệu dưới đây đã được nạp vào SQLite của ứng dụng Windows trên máy này, không chỉ là fixture trong test. App đang mở có thể giữ tài khoản hiện tại: vào menu → Đăng xuất, rồi đăng nhập tài khoản trình bày.

## 1. Tài khoản dùng khi thuyết trình

Mật khẩu chung của ba tài khoản mới: **`Demo@2026`**.

| Username | Dữ liệu | Mục đích |
|---|---|---|
| `presenter_demo` | 35 giao dịch, 3 ngân sách, tháng 08–10/2026 | Tài khoản chính: dashboard, CRUD, search/filter/sort, tháng/danh mục, CSV và tăng ngưỡng ngân sách |
| `overbudget_demo` | 4 giao dịch, ngân sách tháng 10/2026 | Số dư âm, chi 115% ngân sách; đối chiếu cách ly với tài khoản chính |
| `empty_demo` | Chưa có giao dịch/ngân sách | Empty state, CTA thêm giao dịch, trường hợp chưa có gì để xuất |

`demo1 / Demo@123` và `demo2 / Demo@456` vẫn dùng được. Không dùng số tổng của các tài khoản cũ để đối chiếu bảng dưới.

| Tài khoản | Tổng thu toàn thời gian | Tổng chi toàn thời gian | Số dư |
|---|---:|---:|---:|
| presenter_demo | 57.500.000 ₫ | 28.300.000 ₫ | **29.200.000 ₫** |
| overbudget_demo | 5.000.000 ₫ | 5.750.000 ₫ | **−750.000 ₫** |
| empty_demo | 0 ₫ | 0 ₫ | 0 ₫ |

Số liệu này là baseline trước khi thêm/sửa/xóa trong buổi demo. DB sau khi nạp có tổng cộng 5 tài khoản, 40 giao dịch và 4 ngân sách: gồm 1 giao dịch cũ và 39 giao dịch mới.

## 2. Thống kê tháng để đối chiếu

Với `presenter_demo`:

| Tháng | Số giao dịch | Thu | Chi | Số dư tháng | Ngân sách | Đã dùng |
|---|---:|---:|---:|---:|---:|---:|
| 10/2026 | 14 | 21.000.000 | 7.900.000 | 13.100.000 | 10.000.000 | **79% — xanh** |
| 09/2026 | 11 | 20.000.000 | 9.600.000 | 10.400.000 | 10.000.000 | **96% — cảnh báo** |
| 08/2026 | 10 | 16.500.000 | 10.800.000 | 5.700.000 | 10.000.000 | **108% — vượt mức** |

Cuộn phần Tổng quan để thấy tiến độ ngân sách và chi theo danh mục. Chuyển tháng chỉ đổi phần **Theo tháng**; ba thẻ tổng toàn thời gian ở trên vẫn là 57.500.000 / 28.300.000 / 29.200.000.

Chi tháng 10 phân bổ: Nhà ở 3.000.000; Ăn uống 2.000.000; Mua sắm 900.000; Giáo dục 650.000; Sức khỏe 450.000; Đi lại 400.000; Giải trí 300.000; Khác 200.000. Tổng đúng 7.900.000. Phần trăm hiển thị được làm tròn nên không yêu cầu cộng các nhãn đã làm tròn phải bằng đúng 100%.

## 3. Kịch bản trình bày khoảng 15–20 phút

Làm bước xem baseline và CSV trước phần ghi dữ liệu. Như vậy số đối chiếu ban đầu dễ theo dõi.

| Bước | Thao tác trực tiếp | Kết quả cần chỉ ra | Mã cần giải thích |
|---|---|---|---|
| 1 — 1 phút | Đăng nhập sai, sau đó login presenter_demo | Lỗi nằm trong form; username còn, password trống; login đúng vào Home | LoginScreen._login → AuthProvider.login → UserRepository.authenticate |
| 2 — 2 phút | Xem Số dư/Tổng thu/Tổng chi; chuyển tháng 10 → 9 → 8 → 10 | Tổng toàn thời gian không đổi; ngân sách có đủ ba trạng thái; category breakdown đúng tháng | refresh, changeMonth, getTotals, getExpenseByCategory |
| 3 — 2 phút | Tab Giao dịch; tìm `an uong`, `ca phe`, `FLUTTER`; kết hợp loại Chi + danh mục Ăn uống; thử bốn sort | Không phân biệt hoa thường/dấu; ghi chú Unicode tổ hợp tìm được; điều kiện kết hợp AND; số kết quả/chip đổi | _onSearch, normalizeVi, visible, setTypeFilter/setCategoryFilter/setSort |
| 4 — 1 phút | Bỏ riêng chip tìm kiếm; chuyển tab rồi quay lại; Xóa bộ lọc | Bỏ một điều kiện không xóa các điều kiện độc lập; tab giữ state; nút Xóa đưa về mặc định | IndexedStack, ActiveFilterChips, clearFilters |
| 5 — 2 phút | Bật lọc Chi/Ăn uống; menu → Xuất CSV; mở file | Baseline CSV có **35 dòng dữ liệu**, dù UI đang lọc ít hơn; giữ tiếng Việt và nhiều dòng ghi chú | HomeShell._exportCsv → buildCsv → buildTransactionsCsv → export |
| 6 — 4 phút | Dùng các giao dịch ở mục 4 để đi 79% → 80% → 85% → 105%; mở Detail, Sửa và thử Xóa/Hủy | Cảnh báo chỉ khi tăng cấp, tổng đổi đúng, Sửa ở AppBar, Xóa có xác nhận | TransactionFormScreen._save, TransactionProvider._save/_prepareBudgetAlert, calculateBudgetAlert, _delete |
| 7 — 1 phút | Mở Ngân sách, nhập thử 12.000.000 rồi Hủy; sau đó Lưu 12.000.000 và đặt lại 10.000.000 | Hủy không ghi; Lưu cập nhật đúng user/tháng; có helper tiền VND | BudgetScreen._submit → saveBudget → BudgetRepository.upsert |
| 8 — 2 phút | Logout → overbudget_demo → presenter_demo | Tài khoản thứ hai có đúng 4 hàng, số dư −750.000, ngân sách 115%; quay lại vẫn thấy dữ liệu riêng của presenter | logout, RequireAuth, setUser, điều kiện user_id trong repository |
| 9 — 1 phút | Login empty_demo | Tổng 0 là dữ liệu thật; danh sách trống có CTA; xuất CSV báo chưa có dữ liệu | EmptyState, hasLoaded, buildCsv |
| 10 — 2 phút | Logout → Đăng ký: thử trùng presenter_demo, sau đó username mới như `sinhvien_demo_01` | Tên trùng tại field; tài khoản mới tự login và trống | RegisterScreen._register → AuthProvider.register → UserRepository.register |
| 11 — video riêng | Login rồi đóng hẳn app/mở lại; logout rồi đóng/mở lại; Back sau logout | Có phiên thì vào Home, logout thì cần Login và không Back vào Home cũ | restoreSession, SessionStorage, RequireAuth |

Các ca trống/0/thiếu category, dán `-5`/`1,5`/13 chữ số, ngày tương lai có thể trình bày ngay khi mở form ở bước 6. Lưu giao dịch hợp lệ sau cùng; các dữ liệu không hợp lệ không được ghi vào DB.

Muốn CSV vẫn có 35 dòng, thực hiện bước 5 trước bước 6 hoặc dọn các dòng tự thêm theo hướng dẫn dưới. Phân biệt dòng CSV logic với số dòng vật lý: ghi chú có newline có thể chiếm nhiều dòng trong text editor.

## 4. Bộ thao tác CRUD và cảnh báo có số đối chiếu

Trở về tháng **10/2026**, ngân sách **10.000.000**, user **presenter_demo**. Chọn ngày trong tháng 10 và không vượt hôm nay. Dùng ghi chú rõ ràng để dễ dọn sau buổi diễn:

| Thao tác | Ghi chú | Chi tháng | Đã dùng | Thông báo mong đợi | Chi toàn thời gian | Số dư toàn thời gian |
|---|---|---:|---:|---|---:|---:|
| Baseline | — | 7.900.000 | 79% | Không có cảnh báo khi chỉ mở app | 28.300.000 | 29.200.000 |
| Thêm Chi/Ăn uống 100.000 | DEMO80 | 8.000.000 | 80% | Sắp vượt ngân sách tháng (80%) | 28.400.000 | 29.100.000 |
| Thêm Chi/Đi lại 500.000 | DEMO85 | 8.500.000 | 85% | Thông báo thêm thành công, không lặp cảnh báo ngân sách cùng cấp | 28.900.000 | 28.600.000 |
| Thêm Chi/Mua sắm 2.000.000 | DEMO105 | 10.500.000 | 105% | Đã vượt ngân sách tháng! | 30.900.000 | 26.600.000 |
| Sửa dòng DEMO105 thành 1.500.000 | Giữ DEMO105 | 10.000.000 | 100% | Cập nhật thành công; 100% vẫn là mức cảnh báo, không phải vượt mức | 30.400.000 | 27.100.000 |
| Xóa ba dòng DEMO80/85/105 sau khi đã thử Hủy | — | 7.900.000 | 79% | Từng lần xóa cần xác nhận | 28.300.000 | 29.200.000 |

Để minh họa đổi loại Thu/Chi và category reset, tạo riêng dòng ghi chú `DEMOCRUD`, sửa thành Thu/Thưởng rồi xóa chính dòng đó. Không dùng một trong 35 giao dịch baseline nếu muốn giữ nguyên bảng đối chiếu.

Banner ngân sách trên dashboard thể hiện mức hiện tại. SnackBar cảnh báo được phát khi một lần add/update làm **tăng cấp**, không phát lại chỉ vì đăng nhập, chuyển tháng hoặc kéo refresh. Việc seed trực tiếp SQL không phát SnackBar.

## 5. Dữ liệu kiểm tra CSV và tìm kiếm

Trong tháng 10 có sẵn các ghi chú sau:

- `Ăn sáng, cà phê cùng nhóm`: dấu phẩy, tìm `ca phe`.
- `Bữa trưa "nhóm Flutter"`: dấu nháy kép, tìm `flutter`.
- `Khóa Flutter` rồi xuống dòng `Tài liệu SQLite`: ghi chú nhiều dòng trong một ô CSV.
- Dòng 1.250.000 Ăn uống có ký tự dấu tổ hợp trong phần `Cà phê...`: tìm `ca phe` vẫn khớp.
- `=SUM(1,2) — ghi chú kiểm tra CSV`: CSV phải thêm dấu nháy đơn trước `=` và quote ô có dấu phẩy, để nội dung được xử lý như text.

Toàn bộ số tiền là số nguyên VND. CSV không có currency symbol trong cột amount. File baseline của presenter_demo gồm 35 bản ghi theo ngày tăng dần, một header 6 cột, UTF-8 BOM; ô note được escape. Bộ lọc trên UI không quyết định dữ liệu xuất.

## 6. Nạp lại trên máy khác và xem tình trạng hiện tại

Công cụ dùng Dart và dependency đã có, không cần Python hoặc thêm package. Mở app Windows ít nhất một lần để schema v1 và DB được tạo, rồi chạy ở thư mục dự án:

```powershell
# Chỉ xem kế hoạch và số liệu; chưa nạp vào DB.
dart run tool/seed_demo_data.dart

# Tạo backup rồi thêm ba tài khoản còn thiếu.
dart run tool/seed_demo_data.dart --apply --report evidence/demo-data-summary.json

# Chọn file DB/ngày rõ ràng nếu cần.
dart run tool/seed_demo_data.dart --apply --database "$env:APPDATA\com.example\pe_prm393_de190630\finance_tracker.db" --as-of 2026-10-29
```

Nếu `dart` chưa có trong PATH trên máy hiện tại, dùng `D:\Flutter\flutter_windows_3.47.0-stable\flutter\bin\dart.bat` thay cho `dart`. Mặc định lấy ngày hiện tại theo UTC+7; dữ liệu nằm ở tháng đó và hai tháng trước, ngày trong tháng hiện tại được giới hạn tới hôm nay.

Chạy lại **không reset** các tài khoản đã có: không nhân đôi hàng, không ghi đè những gì bạn đã sửa khi tập demo. Nếu một username dành riêng đã tồn tại với mật khẩu khác, toàn bộ lần seed bị rollback. Khi đã sang tháng mới, dữ liệu đã tạo vẫn thuộc các tháng cũ; công cụ không tự dịch chuyển lịch sử. Chọn tháng đã chuẩn bị hoặc chuẩn bị lại trên một bản DB demo riêng.

Windows và Android có DB riêng. Công cụ hiện nạp DB Windows, không tự đồng bộ sang điện thoại/emulator. Lệnh `--database` phải trỏ đúng một file SQLite v1 đã tạo, không phải đường dẫn CSV hay file không tồn tại.

## 7. Backup và bằng chứng

DB đang dùng: `%APPDATA%\com.example\pe_prm393_de190630\finance_tracker.db`. Công cụ không thay đổi shared_preferences; nếu app đang login tài khoản cũ, bạn cần logout để chọn tài khoản mới.

- [Kết quả nạp](evidence/demo-data-summary.json): tài khoản mới, số lượng và tổng theo tháng, đường dẫn backup.
- [Đối chiếu sau khi nạp](evidence/demo-data-verification.json): dữ liệu cũ giữ nguyên, mật khẩu khớp cơ chế của app, quick_check OK, không lỗi foreign key.
- [Log 6 kiểm thử của công cụ](evidence/demo-tests.txt).
- Backup SQLite nhất quán ở `evidence/local/before_demo_*.sqlite`, thư mục đã được gitignore vì có thể chứa dữ liệu cũ của người dùng. Không đưa backup này vào bài nộp công khai.

Để trở về baseline sau khi tập, ưu tiên xóa đúng các dòng DEMO vừa tạo bằng UI và đặt lại ngân sách 10.000.000. Backup là ảnh trước khi có ba tài khoản mới; phục hồi toàn file sẽ đưa cả DB về thời điểm trước khi seed. Không chép đè DB khi ứng dụng đang chạy.

Nạp dữ liệu và test tự động không thay cho video đóng/mở tiến trình hoặc kiểm tra share sheet Android. Ghi kết quả thực tế khi đã thao tác.
