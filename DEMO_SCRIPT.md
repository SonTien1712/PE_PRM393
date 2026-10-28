# Kịch bản demo — Sổ Thu Chi

## Chuẩn bị

Hoàn tất Visual Studio/C++ và Developer Mode theo README. Chạy doctor/pub get/analyze/test; ghi kết quả thực tế. Build release và chạy cả bundle, xác nhận DB mở được. Chuẩn bị recorder và evidence/. Không xóa dữ liệu người dùng để quay; biết số dư ban đầu của tài khoản demo.

## Video 1: Đăng nhập và phiên

1. Mở exe, Login xuất hiện. Thử sai password: lỗi chung, username còn, password trống.
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
4. Thêm Chi/Ăn uống; tìm an uong, lọc Chi + Ăn uống; thử bốn sort.
5. Chuyển tab rồi quay lại: filter còn; Xóa bộ lọc đưa về mặc định.
6. Đóng/mở hẳn: dữ liệu còn.

## Video 4: Logout và cách ly

1. Menu → Đăng xuất → xác nhận, thử Back/Alt+Left: không vào Home cũ.
2. Đóng app rồi mở lại: Login. Quay riêng với auto-login.
3. Login demo2 / Demo@456: không thấy dữ liệu demo1; nếu demo2 có hàng riêng, chỉ thấy hàng riêng.
4. Tạo hàng riêng demo2, logout, login demo1: dữ liệu A còn và không có hàng B.

Chụp SCREENSHOTS ở 360×640 và khoảng 1280×720. Điền Pass/Fail và link thật; chưa chạy/quay vẫn Chưa chạy. Test 10 N/A theo điều kiện Firebase/REST trong REPORT. Không demo Tier C chưa triển khai.
