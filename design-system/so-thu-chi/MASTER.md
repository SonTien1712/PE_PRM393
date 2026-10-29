# Sổ Thu Chi — Hệ thiết kế mobile

Cập nhật 29/10/2026. Áp dụng trong Flutter; thay hướng desktop rộng được phác thảo trước đó. Nguồn: ui-ux-pro-max trong dự án, điều chỉnh theo yêu cầu mobile app của chủ dự án.

## Nguyên tắc

1. Số tiền và hành động chính là trọng tâm. Số dư nổi bật nhất; tổng toàn thời gian tách rõ thống kê tháng.
2. Thu xanh, chi đỏ, luôn có dấu/nhãn/icon. Số dư âm dùng đỏ.
3. Một shell mobile với hai tab, không tạo navigation desktop riêng.
4. Font và icon dùng offline; không có số liệu tăng trưởng hoặc biểu đồ trang trí chưa có nguồn.
5. Chữ lớn được đổi bố cục, không tắt text scaling để tránh overflow.

## Màu đã dùng

| Token trong AppTheme | Màu | Vai trò |
|---|---|---|
| teal | #007F78 | Primary CTA, active/icon |
| canvas | #F5F8F7 | Nền app |
| ink | #173B37 | Chữ chính, viền khung |
| muted | #526763 | Chữ phụ |
| line | #DCE7E3 | Viền card/phân cách |
| income | #15805E | Khoản thu/số dư dương |
| incomeSurface | #F4FBF7 | Bề mặt nhạt khoản thu |
| expense | #CB3F4F | Khoản chi/destructive |
| expenseSurface | #FFF8F9 | Bề mặt nhạt khoản chi |
| warning | #805500 | Cảnh báo ngân sách |
| surfaceCard / onCard | #FFFFFF / #173B37 | Nền/chữ của card |
| Input outline | #708782 | Nhận diện input trên trắng |
| Desktop surround | #E6EEEA | Nền ngoài khung mobile |

Tương phản token tính trên màu đặc: trắng/teal 4.88:1; ink/canvas 11.44:1; muted/trắng 6.04:1; income/incomeSurface 4.67:1; expense/expenseSurface 4.59:1; input outline/trắng 3.83:1. Cần kiểm tra từng cặp màu/overlay khi thêm trạng thái mới; không suy ra toàn app đạt WCAG từ bảng này.

## Chữ, khoảng cách và hình khối

- Font BeVietnamPro local: 400/500/600/700. Assets/OFL nằm trong assets/fonts; LicenseRegistry đăng ký giấy phép.
- TextTheme đầy đủ: display 48/40/36, headline 32/28/24 (700); title 20/16/14 (600), body 16/14/12 (400), label 14/12/11 (600/500). Line height 1.4. AppBar 18/700.
- Số dư 30, tổng hỗ trợ 20, input tiền giao dịch 24, ngân sách 20/600, tiền detail 32 logical px; chữ số tiền không bị FittedBox thu nhỏ.
- AppSpacing: xs=4, sm=8, md=16, lg=24, xl=32. Page padding 16 cho dashboard/list/form, 24 cho auth. Dùng khoảng bổ sung 12 khi thành phần cần.
- AppRadii: control=12, card=16, balance=20; frame ngoài 38, trong 30, viền 8.
- Button/icon target tối thiểu 48; FAB dấu cộng 56. Giữ tooltip và focus keyboard.

## Khung và bố cục

MobileAppFrame bọc toàn Navigator trong MaterialApp.builder. Trên desktop ≥600 dp rộng và ≥440 dp cao: nội dung 430 dp, cao vừa cửa sổ và tối đa 900 dp. Màn hình nhỏ/thấp hoặc Android dùng toàn viewport. ResponsiveBody vẫn giới hạn nội dung không có frame tới 640 dp.

Cấu trúc widget của frame không thay đổi khi resize qua breakpoint, giữ state Navigator/input. Copy MediaQuery size theo viewport trong frame, giữ text scaler; chỉ bỏ safe padding desktop trong khung, giữ insets thật trên điện thoại.

## Thành phần

- SummaryCard prominent cho Số dư; SummaryPair tự xếp dọc khi tiền dài/chữ lớn.
- TransactionTile có categoryIcon và nền pastel theo danh mục: Ăn uống #FFF3E0, Đi lại #E3F2FD, Nhà ở #F3E5F5, Mua sắm #FCE4EC, Giải trí #E8F5E9, Sức khỏe #FFEBEE, Giáo dục #E0F7FA; khoản thu dùng incomeSurface. Tiền dài dùng hàng riêng. Hover 150 ms hoặc 0 khi disableAnimations; có cursor/focus/splash.
- Login: logo teal, form card, lỗi chung bằng InfoBanner có live region; demo nằm riêng. Sai thông tin giữ username và xóa password.
- DashboardSkeleton tĩnh cho lần tải đầu, không dùng 0 như kết quả thật; khi refresh giữ snapshot hiện có và progress.
- FilterBar có dropdown category/sort; xếp dọc khi hẹp hoặc chữ lớn. ActiveFilterChips cho phép bỏ riêng query/type/category; xóa query không reset sort.
- AdaptiveTransactionFields chỉ đặt category/ngày cạnh nhau khi local width ≥420 và text scale ≤1.25; viewport mobile hẹp xếp dọc.
- TransactionDetails có hero danh mục/tiền/ngày, metadata co giãn và hành động Xóa tách riêng; Sửa trên AppBar luôn có tooltip.
- MonthSelector: không đi tới tương lai; query version ngăn snapshot cũ gắn vào tháng mới.
- CategoryBreakdown: category/amount/percent/progress, trạng thái rỗng đúng dữ liệu.
- BudgetProgress: dưới 80% xanh, 80–100% amber, >100% đỏ; bar clamped, text vẫn mô tả vượt hạn mức.
- FormFooter là Scaffold bottom bar, padding theo keyboard inset; Lưu/Hủy xếp dọc khi chữ lớn. SnackBar không che action.
- ConfirmDialog giữ Hủy mặc định; không thêm Undo khi chưa có nghiệp vụ khôi phục.
- Registration username lỗi trùng nằm tại field; CSV chỉ trong menu tab danh sách.

## Kiểm chứng và ảnh

120 host tests (gồm 6 test công cụ dữ liệu demo) và một Windows native integration test đã qua. Bộ layout kiểm tra sáu kích thước, chữ 1×/2×, tiền dài, resize, keyboard/feedback và date picker. Tám ảnh golden bao gồm lỗi login/detail. Form có kiểm tra labels/touch targets; Android thật và display scaling vẫn cần nghiệm thu riêng.

Ảnh hiện tại: ../../test/goldens/windows_mobile_*.png (widget + fixture) và ../../evidence/native/windows-*.png (native + SQLite tạm). visual-direction.svg/png là phác thảo desktop cũ, giữ làm lịch sử; không dùng làm thiết kế hiện tại. Chi tiết kết quả và giới hạn: ../../TEST_RESULTS.md.
