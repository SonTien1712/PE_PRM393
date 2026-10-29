# Ảnh và bằng chứng

Cập nhật 29/10/2026. Phân biệt ảnh từ widget với ảnh tiến trình native; không dùng ảnh golden làm bằng chứng đã chạy Android hay restart app.

## Ảnh Windows native đã có

Integration test chạy tiến trình Windows thật, SQLite ở thư mục tạm riêng và session memory, viewport nội dung 430 dp. Ảnh phản ánh test data, không phải dữ liệu cá nhân được seed vào app runtime.

| Ảnh | Nội dung |
|---|---|
| [Đăng nhập](evidence/native/windows-login.png) | Form native trước login |
| [Lỗi đăng nhập](evidence/native/windows-login-error.png) | Banner inline, giữ username, xóa password; sau đó test đăng nhập lại thành công |
| [Dashboard](evidence/native/windows-dashboard.png) | Khoản chi 900 đồng, tổng/số dư đúng, khung mobile |
| [Danh sách](evidence/native/windows-list.png) | Khoản Ăn uống đã lưu trong SQLite |
| [Thêm giao dịch](evidence/native/windows-form.png) | Tiền 900, danh mục và ngày, footer Lưu/Hủy |
| [Chi tiết](evidence/native/windows-detail.png) | Hero giao dịch, metadata, action Sửa trên AppBar; nội dung dưới có thể cuộn |
| [Ngân sách](evidence/native/windows-budget.png) | Tiền 1000, helper VND và nhắc ngưỡng 80% |
| [Metadata](evidence/native/windows-smoke.json) | Kết quả, viewport và giới hạn của integration test |

## Ảnh golden từ widget thật

Font bundle Be Vietnam Pro, fixture cố định: tổng thu 10.000.000, chi 3.800.000, dư 6.200.000 và ngân sách 4.000.000. Đây là kiểm tra layout tự động, không phải capture Android.

| Màn hình | Ảnh |
|---|---|
| Login | [Xem](test/goldens/windows_mobile_login.png) |
| Login lỗi | [Xem](test/goldens/windows_mobile_login_error.png) |
| Dashboard/tháng/ngân sách | [Xem](test/goldens/windows_mobile_dashboard.png) |
| List/filter | [Xem](test/goldens/windows_mobile_list.png) |
| Thêm giao dịch/footer | [Xem](test/goldens/windows_mobile_form.png) |
| Chi tiết/Sửa/Xóa | [Xem](test/goldens/windows_mobile_detail.png) |
| Budget | [Xem](test/goldens/windows_mobile_budget.png) |
| Register | [Xem](test/goldens/windows_mobile_register.png) |

## Bằng chứng thủ công còn cần

- Native edit/validation, delete confirm, tìm kiếm tiếng Việt, chuyển tháng và category breakdown khi cuộn.
- Register mới/tên trùng, xuất CSV vào Downloads và mở trong Excel giữ tiếng Việt; Android share sheet trên thiết bị/emulator.
- Điện thoại 360×640/412×915: safe area, bàn phím thật, xoay màn hình; Windows display scale 100/125/150%.
- Bundle Release khởi động/mở DB ở cwd khác. Build thành công chưa chứng minh startup Release.
- Video riêng: auto-login sau kết thúc tiến trình; logout rồi đóng/mở cần login; CRUD/tổng; persistence; đổi demo1/demo2 hai chiều; Back sau logout. Quay một lần End task, không dùng hot restart.

Gắn ảnh/video thật vào TEST_RESULTS khi đã thực hiện. Phác thảo visual-direction.svg/png trước đây là hướng desktop cũ, không dùng làm evidence hiện tại.
