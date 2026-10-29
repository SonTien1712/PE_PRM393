# Kịch bản demo — Sổ Thu Chi

Đã có bộ dữ liệu trình bày gồm ba tài khoản riêng và 39 giao dịch/4 ngân sách. Nếu dùng dữ liệu đã nạp, thực hiện theo [DEMO_DATA_GUIDE.md](DEMO_DATA_GUIDE.md) để có baseline 35 giao dịch, ba trạng thái ngân sách và số đối chiếu 79→80→85→105%. Kịch bản dưới vẫn dùng cho các ca nghiệm thu tổng quát. Học cấu trúc và chuỗi method tại [PROJECT_LEARNING_GUIDE.md](PROJECT_LEARNING_GUIDE.md) và [PROJECT_METHOD_MAP.md](PROJECT_METHOD_MAP.md).

## Chuẩn bị

Hoàn tất Visual Studio/C++ và Developer Mode theo README. Chạy doctor/pub get/analyze/test; ghi kết quả thực tế. Build release và chạy cả bundle, xác nhận DB mở được. Chuẩn bị recorder và evidence/. Không xóa dữ liệu người dùng để quay; biết số dư ban đầu của tài khoản demo.

## Video 1: Đăng nhập và phiên

1. Mở exe, Login xuất hiện. Thử sai password: banner lỗi nằm trong form, username còn, password trống. Sửa input thì lỗi cũ được bỏ.
2. Login demo1 / Demo@123, Home xuất hiện.
3. Đóng cửa sổ bằng X rồi mở lại: vào Home.
4. End task một lần qua Task Manager rồi mở lại: vẫn tự đăng nhập nếu phiên hợp lệ.

## Video 2: CRUD và tổng

1. Ghi tổng ban đầu. Thêm Thu/Lương 10.000.000; thêm Chi/Ăn uống 150.000.
2. Đối chiếu tổng với TEST_RESULTS; cộng số ban đầu nếu tài khoản đã có dữ liệu.
3. Detail khoản chi → Sửa thành 200.000 → Lưu: detail và tổng đổi.
4. Đổi tiếp thành Thu: category phải reset; chọn Thưởng và lưu, đối chiếu tổng.
5. Xóa → Hủy: hàng còn. Xóa → xác nhận: chỉ đóng detail một lần, tổng đúng.
6. Giữ khoản Lương để quay persistence. Thử nhấp Lưu nhanh hai lần khi thêm: chỉ tạo một hàng.

## Video 3: Validation, search/filter

1. Thử tiền trống/0 và không chọn danh mục: inline errors, không lưu.
2. Khi ô tiền đã có giá trị, dán -5, 1,5, 1.5, chữ, 13 chữ số: giữ nguyên giá trị cũ.
3. Mở lịch: tiếng Việt, không chọn tương lai.
4. Thêm Chi/Ăn uống; tìm an uong, lọc Chi + Ăn uống; thử bốn lựa chọn trong dropdown Sắp xếp.
5. Kiểm tra số kết quả và chip điều kiện. Bỏ chip tìm kiếm không được reset sort hoặc các điều kiện còn lại. Chuyển tab rồi quay lại: filter còn; Xóa bộ lọc đưa về mặc định.
6. Đóng/mở hẳn: dữ liệu còn.

## Video 4: Logout và cách ly

1. Menu → Đăng xuất → xác nhận, thử Back/Alt+Left: không vào Home cũ.
2. Đóng app rồi mở lại: Login. Quay riêng với auto-login.
3. Login demo2 / Demo@456: không thấy dữ liệu demo1; nếu demo2 có hàng riêng, chỉ thấy hàng riêng.
4. Tạo hàng riêng demo2, logout, login demo1: dữ liệu A còn và không có hàng B.

## Video 5: M9 — Đăng ký

1. Logout → Đăng ký. Thử username `demo1`: lỗi trùng tại field, không tạo tài khoản.
2. Thử password ngắn/không có chữ hoặc số, xác nhận khác password: lỗi inline.
3. Dùng username mới 3–30 ký tự, display name hợp lệ và password có chữ/số tối thiểu 6 ký tự; ví dụ password `Demo@2026`. Đăng ký thành công tự vào Home, tài khoản mới không có giao dịch.
4. Dùng tài khoản mới cho video ngân sách để đối chiếu từ số 0. Không xóa dữ liệu của demo1/demo2.

## Video 6: M7–M8 — Tháng và ngân sách

1. Tổng quan → Đặt ngân sách (hoặc menu → Ngân sách), nhập `1000000`; kiểm tra helper `1.000.000 ₫`, banner giải thích ngưỡng 80% và Lưu.
2. Thêm Chi/Ăn uống `800000` trong tháng hiện tại: cảnh báo chạm 80%; thanh ngân sách màu cảnh báo.
3. Thêm Chi/Đi lại `50000`: tổng chi 850.000, không nhắc lại cùng mức.
4. Thêm Chi/Mua sắm `200000`: tổng chi 1.050.000, cảnh báo vượt 100%, thanh đầy và text vẫn hiển thị 105%.
5. Đối chiếu chi theo danh mục và tỷ lệ; chuyển tháng trước: phần tháng đổi, ba tổng toàn thời gian vẫn giữ. Không đi quá tháng hiện tại.
6. Sửa khoản 800.000 thành 700.000: tổng chi 950.000; cảnh báo không lặp khi mức giảm. Kiểm tra số dư/tổng và metadata trên Detail, nút Sửa ở AppBar.
7. Điều chỉnh ngân sách, Hủy không đổi; Xóa → Hủy giữ ngân sách, Xóa → xác nhận gỡ ngân sách tháng đó.

## Video 7: M10 — CSV

1. Tab Giao dịch, bật một bộ lọc để danh sách chỉ còn một phần dữ liệu.
2. Menu → Xuất CSV: Windows báo đường dẫn Downloads (Documents nếu Downloads không có). CSV chứa toàn bộ giao dịch của tài khoản, ngày tăng dần, không chỉ phần đang lọc.
3. Mở file trong Excel/text editor, kiểm tra tiếng Việt, số tiền, ghi chú có dấu phẩy/nháy/xuống dòng. Không dùng dữ liệu cá nhân khi quay.
4. Android: xuất CSV và kiểm tra bảng chia sẻ hệ thống trên thiết bị/emulator. Bước này chỉ ghi Pass sau khi thực hiện trên Android.

## Bố cục và bằng chứng

Chụp SCREENSHOTS ở 360×640 và khoảng 1280×720. Trên Windows rộng, nội dung là khung mobile 430 dp; menu/lịch/dialog cũng nằm trong khung. Resize khi đang nhập và kiểm tra dữ liệu không mất. Thử chữ 200%, bàn phím, cuộn đến action Lưu/Hủy.

Điền Pass/Fail và link thật; chưa chạy/quay vẫn Chưa chạy. Test 10 N/A theo điều kiện Firebase/REST trong REPORT. M7–M10 đã triển khai; xem TEST_RESULTS để phân biệt test tự động đã qua và các bước quay/chạy thiết bị còn thiếu.
