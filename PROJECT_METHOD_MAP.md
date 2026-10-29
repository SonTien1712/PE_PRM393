# Bản đồ class, method và nơi gọi

Đối chiếu mã nguồn ngày 29/10/2026. Dùng cùng [lộ trình học](PROJECT_LEARNING_GUIDE.md). Trong tên Dart, `_` đầu tên nghĩa là private trong library. `Future<T>` là kết quả bất đồng bộ; getter đọc như thuộc tính nhưng có thể tính toán. Constructor chủ yếu nhận dependencies/giá trị; các method thực hiện xử lý được liệt kê theo nhóm dưới.

## 1. Điểm vào và lắp ghép ứng dụng

| File / symbol | Nhận → trả | Trách nhiệm / nơi gọi |
|---|---|---|
| [main.dart](lib/main.dart) — main | → void | Binding, license font, khởi tạo FFI khi desktop, runApp BootstrapApp; entry point |
| [bootstrap_app.dart](lib/bootstrap_app.dart) — BootstrapApp.createState | → _BootstrapAppState | Flutter tạo State quản lý Future khởi tạo |
| _BootstrapAppState.initState | → void | Tạo và cache Future `_initialization` |
| _initialize | → `Future<AppDatabase>` | Date formatting và AppDatabase.open; retry gọi lại |
| build | BuildContext → Widget | FutureBuilder: loading/error/retry hoặc app đã khởi tạo |
| buildInitializedApp | AppDatabase → Widget | MultiProvider: DB, ba repository, CSV service, session, auth và proxy transaction provider |
| [app.dart](lib/app.dart) — App.build | context → MaterialApp | Locale tiếng Việt, theme, builder MobileAppFrame, onGenerateRoute |
| App._route | RouteSettings → `Route<void>` | Chọn screen, kiểm tra kiểu arguments, bọc route bảo vệ bằng RequireAuth |
| _UnknownScreen.build | context → Widget | Màn route/arguments không hợp lệ và nút về Home |

Route arguments: `/transaction/detail` nhận int id; `/transaction/edit` nhận FinanceTransaction; new/home/budget không cần argument. `_route` không tự đọc SQL. App.now truyền clock tùy chọn cho form để test ngày có thể cố định; runtime mặc định dùng giờ thực.

## 2. Model và chuyển đổi dữ liệu

| File / class | Method/getter | Công dụng |
|---|---|---|
| [app_user.dart](lib/data/models/app_user.dart) — AppUser | constructor, fromMap, toMap | id/username/displayName; model này không chứa password_hash/salt |
| [finance_transaction.dart](lib/data/models/finance_transaction.dart) — TxType | enum income/expense | `.name` tương ứng giá trị TEXT trong SQL |
| FinanceTransaction | constructor | Bản ghi immutable với id tùy chọn, userId/type/amount/category/date/note/createdAt |
| FinanceTransaction.copyWith | Các field tùy chọn → FinanceTransaction mới | Provider gán ownership; form/test tạo bản cập nhật; note dùng sentinel để có thể xóa bằng null |
| FinanceTransaction.toMap / fromMap | Model ↔ `Map<String,Object?>` | Bridge giữa camelCase Dart và snake_case SQL |
| [budget.dart](lib/data/models/budget.dart) — Budget | constructor, toMap, fromMap | Ngân sách user/tháng, limitAmount và id tùy chọn |
| [summary_totals.dart](lib/data/models/summary_totals.dart) — SummaryTotals | fromMap, toMap, balance getter | Thu/chi; balance = income−expense |
| [category_total.dart](lib/data/models/category_total.dart) — CategoryTotal | fromMap, toMap | category/total từ GROUP BY |
| [save_result.dart](lib/data/models/save_result.dart) — SaveResult | constructor; ok/alert/message | Kết quả add/update; ok phản ánh commit, message có thể là warning sau commit |
| [budget_alert.dart](lib/data/models/budget_alert.dart) — BudgetAlert | constructor; level/spent/limit | Cảnh báo cụ thể cho form; BudgetAlertLevel gồm warning/exceeded |
| [session_storage.dart](lib/data/session_storage.dart) — SessionData | constructor; userId/createdAt | Dữ liệu phiên lấy từ preferences, không phải bảng DB |

## 3. Database và repository

| File / method | Input → output | Bên gọi / điều đáng chú ý |
|---|---|---|
| [app_database.dart](lib/data/app_database.dart) — AppDatabase.defaultPath | DatabaseFactory → `Future<String>` | open gọi khi không truyền path; desktop app support directory, mobile database directory |
| AppDatabase.open | path/factory tùy chọn → `Future<AppDatabase>` | Bootstrap hoặc test; bật foreign key, gắn schema version/callback |
| AppDatabase._onCreate | Database, version → `Future<void>` | SQLite chỉ gọi khi tạo DB; tạo 3 bảng/index, hash/salt demo1/demo2, batch commit |
| AppDatabase._onUpgrade | DB, oldVersion, newVersion → `Future<void>` | Migration hook, hiện v1 chưa có bước nâng version |
| AppDatabase.close | → `Future<void>` | Đóng connection; được dùng khi test/đóng DB có chủ đích |
| [repository_support.dart](lib/data/repositories/repository_support.dart) — `runDatabaseOperation<T>` | `Future<T>` Function() → `Future<T>` | Các repository dùng chung; chuyển DatabaseException thành AppException sau debug log |
| [user_repository.dart](lib/data/repositories/user_repository.dart) — findById | int id → `Future<AppUser?>` | Auth restore; chỉ chọn các cột public |
| UserRepository.authenticate | username/password → `Future<AppUser?>` | Auth login; username chuẩn hóa, verify hash; sai trả null |
| UserRepository.register | username/password/displayName → `Future<AppUser>` | Auth register; validate, salt/hash, INSERT, đổi lỗi UNIQUE thành thông báo tên trùng |
| [transaction_repository.dart](lib/data/repositories/transaction_repository.dart) — getAll | userId → `Future<List<FinanceTransaction>>` | refresh/CSV; WHERE user_id, ngày/id giảm dần |
| getById | userId, id → `Future<FinanceTransaction?>` | Tính cảnh báo khi edit; ownership theo hai khóa |
| insert | FinanceTransaction → `Future<int>` id | _save khi add; _validate, không dùng id do caller gửi |
| update | FinanceTransaction → `Future<int>` số hàng | _save khi edit; không sửa user_id/created_at/id; 0 hàng là lỗi |
| delete | userId, id → `Future<int>` số hàng | Provider.delete; 0 hàng là lỗi, không xóa nhầm user khác |
| getTotals | userId, fromDate?/toExclusive? → `Future<SummaryTotals>` | refresh/tháng/cảnh báo; SUM/CASE/COALESCE, khoảng ngày tùy chọn |
| getExpenseByCategory | userId, fromDate, toExclusive → `Future<List<CategoryTotal>>` | _readMonth; chỉ expense, GROUP BY và sort tổng giảm dần |
| _validate | FinanceTransaction → void hoặc throw | insert/update dùng chung: amount/category/date/note |
| [budget_repository.dart](lib/data/repositories/budget_repository.dart) — getForMonth | userId, yyyy-MM → `Future<Budget?>` | Month snapshot và tính cảnh báo |
| upsert | Budget → `Future<void>` | saveBudget; validate và transaction UPDATE→INSERT nếu chưa có |
| delete | userId, month → `Future<void>` | removeBudget; chỉ xóa hạn mức, không xóa giao dịch |

## 4. AuthProvider

File [auth_provider.dart](lib/providers/auth_provider.dart). Constructor nhận UserRepository, SessionStorage và clock tùy chọn. AuthProvider extends ChangeNotifier, không điều hướng trực tiếp.

| Method | Input → output | Ý nghĩa |
|---|---|---|
| _begin | → int operation | Busy=true, xóa lỗi, tăng operation, reset registrationCreated, notify |
| _isCurrent | operation → bool | Đối chiếu operation và disposed để bỏ kết quả cũ |
| _finish | operation → void | Nếu còn current: busy=false và notify |
| clearError | → void | Xóa lỗi đã được UI nhận |
| restoreSession | → `Future<bool>` | Đọc session; kiểm tra tương lai/hết hạn/user còn; gán currentUser hoặc thông báo lỗi |
| login | username,password → `Future<bool>` | Authenticate, lưu phiên, gán currentUser; bắt lỗi và finish |
| register | username,password,displayName → `Future<bool>` | Tạo user rồi lưu phiên; phân biệt tài khoản đã tạo nhưng session lỗi |
| logout | → `Future<void>` | Clear session; thành công mới currentUser=null; RequireAuth lo redirect |
| dispose | → void | Đánh dấu disposed, vô hiệu operation cũ, gọi super.dispose |

Getter: currentUser (AppUser?), isBusy (bool), errorMessage (String?), registrationCreated (bool). UI dùng các getter này để vẽ/disable/đọc lỗi; không sửa field nội bộ.

## 5. TransactionProvider

File [transaction_provider.dart](lib/providers/transaction_provider.dart). Constructor nhận TransactionRepository, BudgetRepository và clock; tháng mặc định là tháng hiện tại.

### Snapshot, vòng đời và truy vấn

| Method | Input → output | Được dùng thế nào |
|---|---|---|
| setUser | int? userId → void | Proxy gọi khi auth đổi. Nếu user khác: tăng epoch, reset rows/tổng/tháng/filter/cờ im lặng; microtask notify và refresh |
| _isCurrent | epoch → bool | Cùng user epoch và chưa dispose |
| _isCurrentRead | epoch,version → bool | Cùng epoch và lượt refresh mới nhất |
| clearError | → void | UI đã nhận thông báo thì clear/notify |
| refresh | → `Future<bool>` | Đọc rows, tổng all-time và tháng; chỉ publish khi vẫn current và đọc đủ; lỗi giữ snapshot trước, needsRefresh |
| _readMonth | userId,DateTime → `Future<(totals,breakdown,budget)>` | Tính monthRange, gọi SQL totals/GROUP BY/budget |
| _publishMonth | month,tuple → void | Cập nhật các field tháng và monthDataKey cùng nhau |
| changeMonth | int deltaMonths → `Future<void>` | Chặn vượt giới hạn/đang mutation; đổi tháng, chống kết quả cũ bằng version; không đổi tổng all-time |
| byId | int id → FinanceTransaction? | Detail tìm trong snapshot `_all`; không chạy SQL mỗi build |
| dispose | → void | Vô hiệu epoch/readVersion và giải phóng ChangeNotifier |

### Mutation và CSV

| Method | Input → output | Được dùng thế nào |
|---|---|---|
| add / update | FinanceTransaction → `Future<SaveResult>` | Hai wrapper gọi chung _save với updating=false/true |
| _save | transaction, updating → `Future<SaveResult>` | Guard mutation, gán ownership, chuẩn bị alert, write, refresh; committed quyết định ok |
| delete | int id → `Future<bool>` | Guard/write/refresh; khi đã xóa mà refresh lỗi vẫn trả true và loại row khỏi snapshot |
| _prepareBudgetAlert | transaction,updating → `Future<BudgetAlert?>` | Đọc budget/spent/old row; tính afterSpent; lỗi đọc tùy chọn thì bỏ alert và vẫn cho ghi |
| saveBudget | int limit → `Future<void>` | Wrapper _writeBudget(limit) |
| removeBudget | → `Future<void>` | Wrapper _writeBudget(null) |
| _writeBudget | int? limit → `Future<void>` | Upsert/delete theo user/tháng; lỗi write throw, warning sau commit giữ trong errorMessage |
| buildCsv | → `Future<String>` | Đọc mọi hàng của user capture, kiểm tra epoch; rỗng/lỗi thành AppException; gọi hàm CSV thuần |
| _messageFor | Object error → String | AppException dùng message, lỗi khác dùng thông báo DB chung |

### Filter và getter

| Getter/method | Trả về / thay đổi |
|---|---|
| all, transactions | Cùng snapshot danh sách không cho mutate trực tiếp |
| totals, monthTotals, monthBreakdown | Tổng all-time; tổng/breakdown của snapshot tháng |
| userId, userEpoch | Ownership và mã phiên hiện tại |
| isLoading, isSaving, mutationBusy | Cờ loading/write; mutationBusy tương ứng isSaving |
| hasLoaded, lastRefreshSucceeded | Đã từng có snapshot và lượt refresh gần nhất có xác nhận thành công |
| needsRefresh | Cần tải lại snapshot tổng hoặc tháng |
| errorMessage | Thông báo lỗi đọc hoặc warning sau commit |
| selectedMonth, selectedMonthKey, _currentMonth | DateTime chọn, yyyy-MM chọn, tháng của clock |
| hasMonthData | monthDataKey có khớp tháng đang chọn không |
| isMonthLoading, monthBudget, canGoNextMonth | Loading tháng; budget chỉ khi dữ liệu đúng tháng; có được next không |
| searchQuery, typeFilter, categoryFilter, sort | State query/type/category/SortOption |
| categoryOptions | Danh mục hợp lệ với type đang chọn |
| hasActiveFilters | Query/type/category hoặc sort khác mặc định |
| visible | Lọc AND và sort trên bản sao `_all`; không thay rows gốc hoặc totals |
| setSearch(String) | Đổi query và notify nếu khác |
| setTypeFilter(TxType?) | Đổi type; bỏ category nếu không còn hợp lệ |
| setCategoryFilter(String?) | Chỉ giữ category nằm trong options |
| setSort(SortOption) | Đổi thứ tự; enum newest/oldest/amountDesc/amountAsc |
| clearFilters() | Reset query/type/category/sort và notify |

## 6. Session và file export

| File / method | Input → output | Trách nhiệm |
|---|---|---|
| [session_storage.dart](lib/data/session_storage.dart) — _getPreferences | → `Future<SharedPreferences>` | Lấy preferences inject trong test hoặc instance thật |
| save | userId → `Future<void>` | Ghi hai int userId/timestamp; giá trị set trả false thì throw |
| read | → `Future<SessionData?>` | Thiếu cả hai key thì null; thiếu một key thì clear; đủ thì tạo SessionData. AuthProvider kiểm tra tuổi phiên |
| clear | → `Future<void>` | Xóa cả hai key; không xóa được thì throw |
| [csv_export_service.dart](lib/data/csv_export_service.dart) — _write | File,csv → `Future<void>` | Ghi chuỗi UTF-8, flush; callback có thể inject để test lỗi |
| _share | path → `Future<void>` | SharePlus.instance.share với XFile text/csv; chỉ service mobile gọi |
| _defaultDirectory | → `Future<Directory>` | Desktop Downloads/Documents, mobile temp |
| export | csv,isCurrent callback → `Future<String?>` | Tạo filename, tránh trùng, ghi/chia sẻ, kiểm tra phiên; null nếu bị hủy |
| _discard | File → `Future<void>` | Dọn file export dở; log lỗi dọn, không đè lỗi chính |

Constructor CsvExportService cho inject desktop/directory/shareFile/writeFile/now. Những điểm inject dùng cho kiểm thử file, callback chia sẻ và lỗi; không phải backend giả trong runtime.

## 7. Core: các hàm thuần và token

| File / symbol | Input → output | Quy tắc |
|---|---|---|
| [validators.dart](lib/core/validators.dart) — validateLoginUsername / validateLoginPassword | String? → String? | Kiểm tra không trống; null nghĩa hợp lệ |
| validateUsername | String? → String? | Trim/lowercase, 3–30 ký tự a–z/0–9/_ |
| validatePassword | String? → String? | Tối thiểu 6, có chữ ASCII và số |
| validateConfirmPassword | value,password → String? | Khớp password |
| validateDisplayName | String? → String? | Không trống, tối đa 40 |
| validateAmount / validateBudgetLimit | String? → String? | Số nguyên >0, tối đa 999999999999; budget dùng quy tắc amount |
| validateCategory | String?,TxType → String? | Category phải thuộc đúng type |
| validateDate | DateTime?,today? → String? | Không null, không vượt ngày hôm nay |
| parseStorageDate | String → DateTime? | Chỉ chấp nhận canonical yyyy-MM-dd và ngày có thật |
| validateNote | String? → String? | Tối đa 200 ký tự |
| [amount_input_formatter.dart](lib/core/amount_input_formatter.dart) — amountInputFormatter | oldValue,newValue → TextEditingValue | Toàn edit phải khớp 0–12 chữ số ASCII; dán sai giữ nguyên oldValue |
| [password_hasher.dart](lib/core/password_hasher.dart) — generateSalt | length=16 → String | Random.secure, base64url |
| hash | password,salt → String | SHA-256 của `salt:password` UTF-8 |
| verify | password,salt,hash → bool | So hash vừa tính với hash đã lưu |
| [money_format.dart](lib/core/money_format.dart) — formatVnd | int → String | intl Việt, phân nhóm và ₫ |
| parseAmountOrNull | String → int? | Tiện ích parse có sẵn; không thay validateAmount |
| [text_utils.dart](lib/core/text_utils.dart) — normalizeVi | String → String | Lowercase/trim, bỏ dấu Việt và U+0300–U+036F |
| csvEscape | String → String | Chặn tiền tố =+-@, escape nháy kép và quote khi có dấu phẩy/newline |
| [csv_export.dart](lib/core/csv_export.dart) — buildTransactionsCsv | `Iterable<FinanceTransaction>` → String | BOM/header, date/id tăng dần, escape category/note; caller bảo đảm user scope |
| [month_utils.dart](lib/core/month_utils.dart) — monthKey | DateTime → yyyy-MM | Chuỗi tháng có zero padding |
| monthRange | DateTime → (String,String) | Đầu tháng và đầu tháng kế, cuối khoảng loại trừ |
| [budget_alert_calculator.dart](lib/core/budget_alert_calculator.dart) — budgetLevel | spent,limit → BudgetAlertLevel? | <80% null, 80–100 warning, >100 exceeded; limit≤0 null |
| calculateBudgetAlert | beforeSpent,afterSpent,limit → BudgetAlert? | Hàm cục bộ rank xếp cấp; chỉ trả alert khi cấp tăng |
| [categories.dart](lib/core/categories.dart) — categoriesFor | TxType → `List<String>` | Chọn incomeCategories/expenseCategories |
| [category_appearance.dart](lib/core/category_appearance.dart) — categoryIcon / categorySurface | category / category,type → IconData / Color | Icon và nền pastel; khoản thu có surface chung |
| [platform_utils.dart](lib/core/platform_utils.dart) — isDesktop | → bool | Desktop factory/frame/directory; app nhắm Windows/Android |
| [app_theme.dart](lib/core/app_theme.dart) — _type, _textTheme, light | Font params → TextStyle; getters → TextTheme/ThemeData | Font local, màu, style thành phần; không có nghiệp vụ tài chính |
| [app_exception.dart](lib/core/app_exception.dart) — AppException.toString | → String | Message nghiệp vụ để log/hiển thị |
| [constants.dart](lib/core/constants.dart) | Hằng số | maxAmount, sessionMaxAge, databaseErrorMessage, seedAccounts |
| [app_routes.dart](lib/core/app_routes.dart) | Hằng route | splash/login/register/home/new/edit/detail/budget |
| [app_spacing.dart](lib/core/app_spacing.dart) | Hằng spacing/radius | AppSpacing và AppRadii, không có method nghiệp vụ |

## 8. Screen: nơi nhận tương tác

Mọi StatefulWidget có `createState()` để Flutter tạo State; `build(context)` tạo cây UI từ state; `dispose()` giải phóng controller/listener/Timer. Bảng dưới liệt kê callback và điểm lifecycle riêng, bên cạnh build/createState/dispose chuẩn.

| File / State | Method/getter | Trách nhiệm / gọi tiếp |
|---|---|---|
| [splash_screen.dart](lib/screens/splash_screen.dart) | initState, _restore | Sau frame gọi auth.restoreSession rồi pushReplacement Home/Login nếu mounted |
| [login_screen.dart](lib/screens/login_screen.dart) | initState | Nhận lỗi restore một lần sau frame, clear lỗi provider |
| _LoginScreenState | _clearError | Input đổi thì bỏ banner cũ |
| _LoginScreenState | _login | Validate/busy/unfocus; auth.login; thành công clear stack vào Home; thất bại clear password/banner |
| [register_screen.dart](lib/screens/register_screen.dart) | _register | Validate/busy; auth.register; lỗi username inline; xử lý đã tạo nhưng session lỗi |
| [home_shell.dart](lib/screens/home_shell.dart) | _exportCsv | Busy/epoch, provider.buildCsv → exporter.export, hiển thị saved path hoặc đã mở share sheet |
| _HomeShellState | _logout | ConfirmDialog → auth.logout, hiển thị lỗi nếu vẫn còn user; không tự điều hướng |
| _HomeShellState.build | build | AppBar/menu, IndexedStack hai tab, FAB, NavigationBar; callback đổi tab bằng setState |
| [dashboard_screen.dart](lib/screens/dashboard_screen.dart) | build | Consumer: skeleton/lỗi/stale/tổng all-time/tháng/recent; refresh gọi provider, Xem tất cả gọi callback HomeShell |
| [transaction_list_screen.dart](lib/screens/transaction_list_screen.dart) | didChangeDependencies | Gắn listener provider và đồng bộ controller query lúc đầu |
| _TransactionListScreenState | _syncSearch | Khi đổi epoch thì hủy debounce; đồng bộ query nếu không đang gõ chờ debounce |
| _TransactionListScreenState | _onSearch | Timer 300 ms, capture epoch rồi setSearch |
| _TransactionListScreenState | _clearFilters / _clearSearch | Hủy Timer, clear controller; reset tất cả hoặc chỉ query |
| _TransactionListScreenState | dispose | Hủy Timer, tháo listener, dispose controller |
| [transaction_form_screen.dart](lib/screens/transaction_form_screen.dart) | initState | Tạo controllers từ initial hoặc giá trị mặc định |
| _TransactionFormScreenState | _editing, _now, _today | Có initial không; clock inject/thực; ngày hiện tại không có giờ |
| _TransactionFormScreenState | _updateDateText | Format ngày đã chọn cho controller readonly |
| _TransactionFormScreenState | _pickDate | Calendar Việt, lastDate=today, chỉ nhận kết quả nếu cùng epoch và mounted |
| _TransactionFormScreenState | _save | Validate/guard/capture; build transaction → add/update → xử lý SaveResult/pop/feedback |
| [transaction_detail_screen.dart](lib/screens/transaction_detail_screen.dart) | _scheduleMissingClose | Chỉ schedule một pop sau snapshot thành công xác nhận thiếu row, route phải hiện tại |
| _TransactionDetailScreenState | _edit | Push edit với transaction, sau quay về rebuild nếu cùng epoch |
| _TransactionDetailScreenState | _delete | Guard/confirm/capture → provider.delete; pop và success/warning đúng một lần |
| [budget_screen.dart](lib/screens/budget_screen.dart) | didChangeDependencies | Khởi tạo input hạn mức một lần khi đã có data đúng tháng |
| _BudgetScreenState | _submit(remove=false) | Save validate hoặc confirm delete; capture epoch/tháng; gọi saveBudget/removeBudget, xử lý warning/lỗi và pop |

Những callback ngắn nằm trực tiếp trong build (đổi Thu/Chi, ẩn/hiện password, mở route, onDestinationSelected...) không có tên method riêng. Chúng thay state cục bộ hoặc gọi method đã liệt kê, không có SQL ẩn trong callback UI.

## 9. Widget dùng lại

| File / class | Method chính | Vai trò và input/callback |
|---|---|---|
| [mobile_app_frame.dart](lib/widgets/mobile_app_frame.dart) — MobileAppFrame | build | child Navigator; tính viewport/frame theo constraints/platform, copy MediaQuery, giữ subtree khi resize |
| [responsive_body.dart](lib/widgets/responsive_body.dart) — ResponsiveBody | build | child trong SafeArea/Center/ConstrainedBox |
| [summary_card.dart](lib/widgets/summary_card.dart) — SummaryCard | build | title/amount/color/icon/prominent; thẻ tiền được format |
| SummaryPair | build | income/expense/labels; hàng hoặc cột theo width/độ dài tiền/text scale |
| [transaction_tile.dart](lib/widgets/transaction_tile.dart) — TransactionTile | build | tx,onTap; icon/note/date/amount, layout tiền dài và hover/focus |
| [filter_bar.dart](lib/widgets/filter_bar.dart) — FilterBar | build | provider,onClear; ChoiceChip, category dropdown, sortLabels/dropdown |
| ActiveFilterChips | build | provider,onClearSearch; InputChip bỏ riêng query/type/category |
| [transaction_fields.dart](lib/widgets/transaction_fields.dart) — AdaptiveTransactionFields | build | Category/date controller/validators/callbacks; local width≥420 và chữ vừa mới đặt cạnh nhau |
| [transaction_details.dart](lib/widgets/transaction_details.dart) — TransactionDetails | build | tx/deleting/onDelete; hero/metadata/delete action |
| _DetailField | build | label/value/secondary; label/value nằm ngang hoặc dọc, value selectable |
| [form_footer.dart](lib/widgets/form_footer.dart) — FormFooter | build | onSave/onCancel/label/busy; safe area/keyboard inset, nút xếp dọc khi chữ lớn |
| [month_selector.dart](lib/widgets/month_selector.dart) — MonthSelector | build | month/canGoNext/enabled/onChanged; phát delta −1 hoặc +1 |
| [month_overview.dart](lib/widgets/month_overview.dart) — MonthOverview | build | Provider tháng; selector/tổng/budget/breakdown hoặc loading/error đúng tháng |
| [category_breakdown.dart](lib/widgets/category_breakdown.dart) — CategoryBreakdown | build | `List<CategoryTotal>`, tổng expense; amount/ratio/percent và empty |
| [budget_progress.dart](lib/widgets/budget_progress.dart) — BudgetProgress | build | budget/spent/enabled/onEdit; chưa có thì CTA, có thì màu/progress/text; bar clamp nhưng text giữ tỷ lệ thật |
| [empty_state.dart](lib/widgets/empty_state.dart) — EmptyState | build | icon/message/actionLabel/onAction; thông điệp và CTA tùy chọn |
| [info_banner.dart](lib/widgets/info_banner.dart) — InfoBanner | build | message/icon/foreground/background/liveRegion; thông báo inline có semantics |
| [stale_data_banner.dart](lib/widgets/stale_data_banner.dart) — StaleDataBanner | build | Provider.needsRefresh; nút Thử tải lại chỉ gọi refresh |
| [dashboard_skeleton.dart](lib/widgets/dashboard_skeleton.dart) — DashboardSkeleton, _Placeholder | build | Placeholder tĩnh lần tải đầu; semantics loading, không phát số 0 giả |
| [confirm_dialog.dart](lib/widgets/confirm_dialog.dart) — ConfirmDialog.show | context/title/message/confirmLabel/destructive → `Future<bool>` | Hủy autofocus; đóng ngoài/back tương đương false; dùng cho delete/logout |
| [require_auth.dart](lib/widgets/require_auth.dart) — RequireAuth | createState, _RequireAuthState.build | CurrentUser có thì child; không có thì schedule redirect sau frame trên route hiện tại |
| [provider_error_listener.dart](lib/widgets/provider_error_listener.dart) — ProviderErrorListener | createState, didChangeDependencies, _onChanged, dispose, build | Gắn/tháo listener; chụp epoch/message; SnackBar một lần sau frame khi route hiện tại và enabled; child không bị thay nội dung |

## 10. Công cụ dữ liệu trình bày

Các file tool không được import vào lib và không tự chạy khi mở ứng dụng.

| File / symbol | Input → output | Vai trò |
|---|---|---|
| [demo_dataset.dart](tool/demo_dataset.dart) — buildDemoDataset | asOf → `List<DemoAccount>` | 35/4/0 giao dịch, 3/1/0 ngân sách; clamp ngày; helpers day/row/add xây dataset |
| DemoAccount | constructor + fields | username/displayName/transactions/budgets; Password công khai riêng cho demo |
| [demo_seed_support.dart](tool/demo_seed_support.dart) — validateDemoDatabase | Database → `Future<void>` | Kiểm tra version/columns/quick_check/foreign keys trước seed |
| backupDemoDatabase | Database,Directory → `Future<String>` | VACUUM INTO tạo snapshot SQLite nhất quán trước ghi |
| seedDemoData | Database,asOf → `Future<List<Map>>` | Validate bằng core; transaction tạo tài khoản còn thiếu; existing skip, khác mật khẩu thì rollback |
| demoDatabaseSummary | Database → `Future<List<Map>>` | Chỉ aggregate ba user dành riêng, gồm counts/totals/month; không xuất hash/salt |
| [seed_demo_data.dart](tool/seed_demo_data.dart) — main / run | `List<String>` args → `Future<void>` | Parse CLI; kiểm tra file DB có thật; dry run hoặc backup/seed/report; đóng DB trong finally |

## 11. Chuỗi gọi để tập đọc code

```text
Mở app: main → _initialize → AppDatabase.open → buildInitializedApp → App → Splash._restore
Login: _login → AuthProvider.login → authenticate → verify → SessionStorage.save → Home
Đổi user: AuthProvider.currentUser → Proxy.update → setUser → refresh → notifyListeners
Thêm/sửa: form._save → add/update → provider._save → _prepareBudgetAlert → insert/update → refresh → SaveResult
Xóa: detail._delete → ConfirmDialog.show → provider.delete → repository.delete → refresh → pop
Tìm: _onSearch → Timer → setSearch → visible → normalizeVi → list build
Tháng: MonthSelector.onChanged → changeMonth → _readMonth → monthRange / SQL totals / category / budget
Budget: _submit → saveBudget/removeBudget → _writeBudget → upsert/delete → refresh → đóng form
CSV: _exportCsv → buildCsv → getAll → buildTransactionsCsv/csvEscape → export → write/share
Logout: _logout → auth.logout → SessionStorage.clear → currentUser=null → setUser(null) → RequireAuth redirect
```

Khi học một method, ghi 5 dòng: ai gọi; input/return; field nào thay đổi; có await/side effect nào; test nào chứng minh. Bắt đầu với `_save`, `refresh`, `restoreSession`, `changeMonth` và `calculateBudgetAlert`, rồi dùng bảng này để truy tiếp các method con.
