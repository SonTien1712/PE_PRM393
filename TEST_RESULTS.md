# Kết quả kiểm thử

Ngày chạy tự động: **28/10/2026** (Asia/Saigon), Flutter 3.47.0 stable / Dart 3.13.0 / Windows 11 x64. Pass chỉ dùng sau thực thi; Chưa chạy là chưa có evidence; N/A cần lý do. Host test không thay video UI/restart tiến trình.

## Tự động và môi trường

| Kiểm tra | Result | Evidence/ghi chú |
|---|---|---|
| flutter test --reporter expanded | Pass — 63 tests | [Log đầy đủ](evidence/tests.txt): `00:19 +63: All tests passed!` |
| flutter analyze | Pass | [Log](evidence/analyze.txt): `No issues found!` |
| dart format . | Pass | [Log](evidence/format.txt): 58 files, 0 changed |
| Widget layout/locale/navigation/CRUD | Pass | 360×640 và 1280×720, fake repositories; chưa thay bằng chứng Windows native |
| Windows release build | Fail | [Log](evidence/windows-build.txt): `Unable to find suitable Visual Studio toolchain` — blocker môi trường |
| Windows native UI/restart | Chưa chạy | Chưa có bundle chạy thật |
| Android UI/restart | Chưa chạy | Chưa có thiết bị/emulator, license SDK còn thiếu |

| File test | Nội dung ở lần chạy cuối | Result |
|---|---|---|
| password_hasher_test.dart | Salt 16 byte, khác salt khác hash, verify đúng/sai | Pass |
| text_utils_test.dart | Việt dựng sẵn/tổ hợp, hoa thường, nguyên âm và đ | Pass |
| validators_test.dart | Tiền, category/type, ngày thật, note, budget, auth rules | Pass |
| amount_input_formatter_test.dart | Invalid paste giữ nguyên text/selection/composing | Pass |
| transaction_repository_test.dart | CRUD, SQL totals/tháng, bounds, trường bất biến, seed | Pass |
| user_isolation_test.dart | Read/update/delete/totals/budget per-user, FK cascade | Pass |
| transaction_provider_test.dart | Silent reset, epoch, commit/read failure, mutation guard, filter/sort | Pass |
| session_storage_test.dart | Save/read/clear, thiếu từng key xóa phiên dở dang | Pass |
| auth_provider_test.dart | Tương lai/đúng 7 ngày bị loại, dưới 7 ngày hợp lệ, lỗi đọc không xóa phiên | Pass |
| database_error_test.dart | Lỗi write SQLite thật qua query_only, thông báo Việt và không thêm hàng | Pass |
| database_persistence_test.dart | Đóng/mở lại DB trên đĩa, giữ hàng/totals/seed và cách ly user | Pass |
| transaction_form_test.dart | Enter login, layout/locale, Lưu lặp, warning/retry, logout/direct guard, edit/delete | Pass |

## Manual theo đề

| # | Scenario | Expected | Result | Evidence link/file |
|---|---|---|---|---|
| 1 | Login demo1 / Demo@123 | Home hiện | Chưa chạy | Cần screenshot Windows |
| 2 | Sai thông tin đăng nhập | Lỗi chung, giữ username, xóa password | Chưa chạy | Screenshot |
| 3 | Login, đóng hoàn toàn, mở lại; End task một lần | Tự vào Home | Chưa chạy | Video riêng; không hot restart |
| 4 | Logout, đóng, mở lại | Login hiện | Chưa chạy | Video riêng |
| 5 | Thêm/sửa/xóa; Hủy rồi xác nhận xóa | CRUD đúng, delete có confirm | Chưa chạy | Video/screenshots |
| 6 | Tổng sau mỗi CRUD | Khớp bảng số liệu dưới | Chưa chạy | Ảnh trước/sau |
| 7 | Thêm dữ liệu, đóng, mở lại | Dữ liệu còn | Chưa chạy | Video |
| 8 | A có dữ liệu, login B rồi trở lại A | Cách ly hai chiều | Chưa chạy | Video; repo isolation đã test riêng |
| 9 | Trống/0/thiếu category, dán -5/1,5/1.5/chữ/13 số | Inline error hoặc giữ nguyên giá trị cũ | Chưa chạy | Screenshot; utility tests đã qua |
| 10 | Connection failure Firebase/REST | Không áp dụng SQLite theo điều kiện đề | N/A | Chủ dự án đối chiếu; REPORT |
| Extra | Search an uong + loại/category/sort | Tìm thấy Ăn uống, kết quả đúng | Chưa chạy | Screenshot |
| Extra | Logout rồi Back/Alt+Left | Không vào Home cũ | Chưa chạy | Video |
| Extra | Nhấp Lưu nhanh hai lần | Một hàng | Chưa chạy | Video/widget test |
| Extra | Release exe mở DB ở cwd khác | Đường dẫn/dữ liệu ổn định | Chưa chạy | Screenshot; thiếu VS |
| Extra | Date picker khi Windows tiếng Anh | Nút/nhãn tiếng Việt | Chưa chạy | Screenshot |
| Extra | 360×640 và 1280×720 | Không overflow, cuộn được | Chưa chạy | Screenshot |
| Extra | DB write error; refresh fail sau commit | Báo tiếng Việt, không insert trùng | Chưa chạy | Các test DB fault/provider/widget đã Pass ở bảng tự động; chưa gây lỗi trên app native |
| Optional | Tháng/budget/register/CSV | Chỉ chạy khi triển khai | N/A | Tier C chưa triển khai |

## Bộ số liệu đối chiếu tổng

Dùng tài khoản rỗng hoặc cộng số dư ban đầu khi tính. Giữ lại một hàng để quay persistence.

| Bước | Thao tác | Tổng thu | Tổng chi | Số dư | Result |
|---|---|---:|---:|---:|---|
| 0 | Rỗng | 0 | 0 | 0 | Chưa chạy |
| 1 | Thu Lương 10.000.000 | 10.000.000 | 0 | 10.000.000 | Chưa chạy |
| 2 | Chi Ăn uống 150.000 | 10.000.000 | 150.000 | 9.850.000 | Chưa chạy |
| 3 | Sửa chi thành 200.000 | 10.000.000 | 200.000 | 9.800.000 | Chưa chạy |
| 4 | Đổi thành Thu/Thưởng 200.000 | 10.200.000 | 0 | 10.200.000 | Chưa chạy |
| 5 | Xóa khoản Thưởng | 10.000.000 | 0 | 10.000.000 | Chưa chạy |

Ngày mặc định hôm nay nên thiếu ngày được test ở validator. Lưu ảnh/video thật dưới evidence/ và cập nhật từng dòng khi đã thực hiện.
