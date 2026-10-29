# Kết quả kiểm thử

Cập nhật **29/10/2026** (Asia/Saigon). Flutter 3.47.0 / Dart 3.13.0 / Windows 11 x64. Chỉ ghi Pass khi đã chạy; ảnh golden không thay bằng chứng native hoặc video restart tiến trình.

## Kết quả tự động gần nhất

| Kiểm tra | Kết quả | Bằng chứng và giới hạn |
|---|---|---|
| Unit/repository/provider/widget/golden/tool | **Pass — 120 tests** | [tests.txt](evidence/tests.txt), kết thúc `+120: All tests passed!` |
| Analyzer | **Pass** | [analyze.txt](evidence/analyze.txt): `No issues found!` |
| Format | **Pass** | [format.txt](evidence/format.txt): 90 file (lib/test/integration_test/tool), 0 thay đổi ở lượt cuối |
| Windows native integration | **Pass — 1 test** | [Log](evidence/windows-native-test.txt), [metadata](evidence/native/windows-smoke.json), [ảnh](evidence/native/); DB tạm riêng và session memory |
| Windows Release build | **Pass** | [windows-build.txt](evidence/windows-build.txt); bundle tại build/windows/x64/runner/Release/ |
| Release exe khởi động DB và restart phiên | **Chưa chạy** | Build thành công chưa xác nhận chạy tiến trình Release hoặc video restart |
| Android debug APK build | **Pass** | [android-build.txt](evidence/android-build.txt); APK tại build/app/outputs/flutter-apk/app-debug.apk. Tắt Kotlin incremental compilation để tránh lỗi cache giữa project D: và Pub Cache C: |
| Android UI/share sheet/restart | **Chưa chạy** | Chưa có bằng chứng emulator/thiết bị |
| Nạp dữ liệu thuyết trình Windows | **Pass — đã ghi SQLite thật** | [Summary](evidence/demo-data-summary.json), [đối chiếu](evidence/demo-data-verification.json); thêm 3 tài khoản, 39 giao dịch, 4 ngân sách. Bản ghi cũ giữ nguyên; backup tại evidence/local/ được gitignore |

Native integration đã thực thi: login sai với banner inline, giữ username/xóa password rồi đăng nhập lại bằng Enter; viewport 430 dp; lưu ngân sách 1000; thêm khoản chi 900, cảnh báo 90%, tổng tháng/tổng chi 900; detail có action Sửa nhìn thấy được; xuất file CSV BOM trong thư mục tạm và đóng/mở lại file SQLite giữ dữ liệu. Có bảy ảnh native. Test không đụng DB/phiên người dùng thật; không kiểm chứng persistence shared_preferences qua restart tiến trình. Gõ/phím được điều khiển bởi Flutter test API, không thay thế kiểm tra bàn phím/IME thủ công.

Bundle Release đã có exe, flutter_windows.dll, sqlite3.dll và plugin/data đi kèm. Không chép riêng exe; chưa áp dụng fallback tải sqlite3.dll thủ công.

## Phạm vi bộ test

| Nhóm | Nội dung đã qua |
|---|---|
| Password/validation/formatter | Salt/hash, tiền/category/date/note/auth rules, dán sai giữ nguyên input |
| Text/CSV | Việt dựng sẵn/tổ hợp, BOM byte thật, quote/comma/newline, tiền tố công thức, thứ tự ngày tăng dần |
| SQLite repositories | CRUD/totals/month range, CHECK bounds, FK cascade, user isolation, trường update bất biến, đóng/mở lại file DB |
| Session/auth | Thiếu key, tương lai, đúng 7 ngày, lỗi đọc không xóa phiên, registration/hash/login/duplicate, tạo user rồi lỗi lưu phiên |
| TransactionProvider | Epoch, silent reset, atomic snapshot, commit vs refresh, mutation guard, filter AND/sort |
| Month dashboard | Chuyển tháng giữ tổng toàn thời gian/filter, range qua năm/nhuận, bỏ kết quả/lỗi tháng cũ |
| Budget | 80%/100%/>100%, chỉ tăng cấp mới cảnh báo, edit trừ giá trị cũ, đổi tháng/type, upsert giữ ID, bounds/isolation |
| Budget form | Lưu lặp chỉ một write, commit + refresh lỗi vẫn đóng một lần, retry chỉ đọc, Hủy/Xóa xác nhận |
| CSV service | Ghi file UTF-8 thật, tránh ghi đè tên, desktop không share, mobile gọi callback share, hủy/dọn file khi đổi epoch, lỗi file tiếng Việt |
| Navigation/forms | Login Enter, CRUD, logout xóa stack, direct route guard gồm budget, password/username field errors |
| Mobile layout/accessibility | Sáu kích thước, chữ 1×/2×, tiền dài, route/input giữ khi resize; calendar trong frame, keyboard/feedback tránh footer; label và Android tap targets trên form |
| UI nâng cấp | Login lỗi inline/nhập lại; skeleton không hiển thị tổng 0 giả; dropdown sort/chip bỏ bộ lọc; category/ngày đổi row/column theo local width và text scale; detail có tiền/ghi chú dài và action Sửa |
| Golden | Tám trạng thái với font Be Vietnam Pro bundle và fixture/ngày cố định: login, login lỗi, dashboard, list, form, budget, detail, register; so sánh ảnh trong test/goldens |
| Công cụ demo | 6 test: ngày qua năm/nhuận, tổng/ownership/password qua repo thật và giữ dữ liệu cũ, chạy lại giữ bản sửa, collision rollback, mở backup trước seed, baseline 79→80→85→105% |

## Theo đề và bằng chứng cần bổ sung

| # | Tình huống | Mong đợi | Kết quả | Bằng chứng/ghi chú |
|---|---|---|---|---|
| 1 | Login demo1 / Demo@123 | Home hiện | Pass — native tự động | Integration test + evidence/native/windows-dashboard.png |
| 2 | Sai thông tin login | Lỗi chung, giữ username, xóa password | Pass — native tự động | Integration test + evidence/native/windows-login-error.png |
| 3 | Login, đóng hoàn toàn/End task, mở lại | Tự vào Home | Chưa chạy | Video riêng, không hot restart |
| 4 | Logout, đóng, mở lại | Login xuất hiện | Chưa chạy | Video riêng |
| 5 | Thêm/sửa/xóa; Hủy/xác nhận | CRUD đúng, xác nhận xóa | Chưa nghiệm thu đủ native | Native đã thêm; edit/delete qua widget và SQLite tests |
| 6 | Tổng sau mọi CRUD | Khớp tính tay | Chưa nghiệm thu đủ native | Native đã đối chiếu khoản chi 900; đầy đủ CRUD qua host tests |
| 7 | Thêm dữ liệu, kết thúc tiến trình, mở lại | Dữ liệu còn | Chưa chạy | Đã đóng/mở file DB trong tests, chưa restart app |
| 8 | A có dữ liệu, login B rồi trở lại A | Cách ly hai chiều | Chưa nghiệm thu native | Repo/provider tests đã qua |
| 9 | Input trống/0/thiếu category; dán sai | Inline error/giữ input cũ | Chưa nghiệm thu native | Formatter/validator/widget tests đã qua |
| 10 | Connection failure Firebase/REST | Không áp dụng SQLite | N/A | Điều kiện đề đã được chủ dự án đối chiếu; lỗi DB test riêng |
| Extra | Search/filter/sort, giữ khi đổi tab | Kết quả đúng, state giữ | Chưa nghiệm thu thủ công | Provider tests đã qua |
| Extra | Logout rồi Back/Alt+Left | Không mở Home cũ | Chưa nghiệm thu native | Widget guard/logout đã qua |
| Extra | Release chạy ở cwd khác | Cùng DB/session, DLL đầy đủ | Chưa chạy | Cần chạy bundle Release |
| Extra | Windows display scale 100/125/150% | Khung/input không lỗi | Chưa chạy đầy đủ | Có ảnh native ở scale môi trường hiện tại; text scale đã test riêng |
| M7 | Chuyển tháng, tỷ lệ danh mục | Chỉ đổi thống kê tháng | Pass — host tests | Native đã kiểm tra tháng hiện tại, chưa quay thao tác chuyển tháng |
| M8 | Ngân sách, cảnh báo 80%/>100% | Theo user/tháng, không lặp cùng cấp | Pass — tự động | Native đã cảnh báo 90%; các ngưỡng/edit/commit-warning có tests |
| M9 | Register/duplicate/tự login | User mới rỗng, lỗi field đúng | Pass — host tests | SQLite thật + widget form; cần capture native nếu nộp evidence |
| M10 | CSV Việt, escaping, user/epoch | File đúng, chỉ dữ liệu user hiện tại | Pass — tự động | Native ghi file tạm + unit/file service tests; Excel/Downloads và Android share sheet cần kiểm tra thủ công |

## Bộ số liệu demo đối chiếu tổng

Dùng tài khoản rỗng hoặc cộng tổng ban đầu; không xóa dữ liệu thật chỉ để quay.

| Bước | Thao tác | Tổng thu | Tổng chi | Số dư | Kết quả video |
|---|---|---:|---:|---:|---|
| 0 | Rỗng | 0 | 0 | 0 | Chưa quay |
| 1 | Thu Lương 10.000.000 | 10.000.000 | 0 | 10.000.000 | Chưa quay |
| 2 | Chi Ăn uống 150.000 | 10.000.000 | 150.000 | 9.850.000 | Chưa quay |
| 3 | Sửa chi thành 200.000 | 10.000.000 | 200.000 | 9.800.000 | Chưa quay |
| 4 | Đổi thành Thu/Thưởng 200.000 | 10.200.000 | 0 | 10.200.000 | Chưa quay |
| 5 | Xóa khoản Thưởng | 10.000.000 | 0 | 10.000.000 | Chưa quay |

Log m7/m8/m9/m10/ui-* là nhật ký trong quá trình phát triển, có thể chứa lỗi của lượt trước đã sửa. Ba log format.txt/analyze.txt/tests.txt và windows-native-test.txt/windows-build.txt là kết quả nghiệm thu hiện tại. Stack trace từ fault injection là dự kiến nếu dòng cuối vẫn ghi All tests passed.
