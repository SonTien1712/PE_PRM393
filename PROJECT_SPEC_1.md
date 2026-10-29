# PROJECT_SPEC.md — Personal Finance Tracker (Flutter + SQLite, Windows Desktop primary)

> **Audience:** an AI coding assistant (any IDE: Cursor, Copilot, Windsurf, Claude Code, ...).
> **Goal:** implement the complete app described here, end to end, without asking questions.
> **Language of UI text:** Vietnamese. **Language of code/comments:** English.
> **If anything is ambiguous, follow Section 3 (Locked Decisions). Do not invent alternatives.**
> **Primary platform:** Windows desktop (via `sqflite_common_ffi`). Android stays supported by the same code. See Sections 2.2 and 3.

> **Owner update — 28/10/2026:** This is a mobile-app course project developed on Windows. Use a phone-like viewport on wide Windows windows (430 dp content, a thin device frame), and full-width responsive UI on phones/narrow windows. Keep bottom navigation on all widths; the earlier Desktop v2 rail/wide-dashboard proposal is superseded. The owner explicitly requests M7–M10 now; implement and test them while continuing to mark any missing native/manual baseline evidence as unverified.

---

## 0. How you (the AI) must work

1. Read this whole file before writing code.
2. Implement **milestone by milestone** in the order of Section 17. After each milestone:
   - run `dart format .` and `flutter analyze` (must be clean),
   - run `flutter test` once tests exist,
   - verify the milestone's **Definition of Done (DoD)**,
   - then continue to the next milestone.
3. Never use in-memory mock data in place of SQLite.
4. Never add Firebase, REST, or any second storage backend. **Exactly one** primary storage: SQLite.
5. Never store a password (plain or hashed) in `shared_preferences`. Session stores only `userId` + timestamp.
6. Every database call that touches `transactions` or `budgets` **must** include `user_id` in its `WHERE` clause (SELECT, UPDATE and DELETE).
7. Never name a class `Transaction` (it collides with `sqflite`'s `Transaction`). Use `FinanceTransaction`.
8. Prefer small, reusable widgets; no screen file over ~350 lines.
9. When a package API differs from the snippets here (versions change), adapt to the installed version, keep behavior identical.
10. At the end, produce the deliverables listed in Section 18.
11. Deliver the mandatory app and submission documents at M6-DOC before starting optional features. Keep unfinished optional entry points hidden.
12. **Respect the tiers in Section 17.1.** Tier A is required inside M0–M6. Tier B items are hardening extras: do them only after M6-DOC and only if time remains. Never let Tier B work delay Tier A.
13. Only `core/platform_utils.dart` may import `dart:io` `Platform`. Everything else asks `isDesktop`.

---

## 1. Project summary

A personal income and expense tracking app (Flutter/Dart). Users log in, the login state survives app restarts, and each user only sees their own transactions, stored in a local SQLite database. The app runs on Windows desktop (primary development/demo target) and on Android with the same code.

### 1.1 Grading map (10 points) — drives priorities

| Criterion | Pts | Delivered by |
|---|---|---|
| UI and navigation | 1.0 | Section 11 |
| Login, session restoration, logout | 2.0 | F1 |
| Transaction CRUD | 2.0 | F2 |
| Income/expense calculations | 1.0 | F3 |
| Search and filtering | 1.0 | F4 |
| SQLite integration (+ per-user data) | 2.0 | F5 |
| Code organization, validation, error handling | 1.0 | F6, Sections 9, 10 |

Optional features (Section 12) **never** replace mandatory ones. Mandatory functionality is complete after M6; the submission-ready baseline includes M6-DOC immediately afterward, before M7. Sorting belongs to mandatory milestone M5.

### 1.2 Hard requirements from the assignment (do not violate)

- Login screen; app content reachable only after authentication.
- Persist auth state across restarts (`shared_preferences`); no plain-text password to maintain the session.
- Logout clears/invalidates the state; after logout the user cannot reach authenticated screens (including via Back).
- Transaction fields: id, type (income/expense), amount (> 0), category, date, note (optional). Required fields validated before save.
- Home shows total income, total expenses, balance (`Balance = Income − Expense`), updated after every add/edit/delete.
- Add, list, detail, edit, delete (after confirmation), search by note or category, filter by type or category.
- Data persists after restart; each user sees only their own data; a different account must not see previous data.
- Handle login failure, invalid input, storage errors.
- Required screens: Login, Home/Dashboard, Transaction List, Add/Edit, Transaction Detail.

---

## 2. Tech stack

- Flutter (stable) + Dart 3.x, Material 3.
- State management: `provider`. Do **not** use Riverpod, Bloc, GetX, or `go_router`. Use `Navigator` + named routes.
- **Platforms:** Windows desktop (primary) and Android (kept compatible). Flutter web is **not** supported (`sqflite` does not run on web).

### 2.1 Packages

Run (let pub resolve the latest compatible versions; do not hand-pin old versions):

```
flutter pub add sqflite sqflite_common_ffi path path_provider shared_preferences provider crypto
flutter pub add intl:any
flutter pub add dev:flutter_lints
```

- `sqflite_common_ffi` is a **regular dependency** (not dev): it is needed at runtime on Windows. It is also used by tests.
- `intl:any` lets pub choose the version required by `flutter_localizations`.
- Add `flutter_localizations` from the Flutter SDK (not a hosted package):

```yaml
dependencies:
  flutter_localizations:
    sdk: flutter
```

- **`share_plus` is added only at M10** and used only on Android (Windows uses a save-to-file path, Section 12.5). Do not add it earlier, to avoid unnecessary Windows plugin build issues.

### 2.2 Windows desktop setup (one time)

1. Install **Visual Studio 2022** with the workload **Desktop development with C++**. Run `flutter doctor` and fix every Windows item.
2. Enable **Windows Developer Mode** (Settings → For developers). Without it, building with plugins fails with a symlink error.
3. In the existing project folder, add platform folders if missing: `flutter create --platforms=windows,android .` (keeps existing `lib/` and `pubspec.yaml`).
4. Run with `flutter run -d windows`.
5. **SQLite DLL.** With a current `sqflite_common_ffi`, `sqlite3.dll` is bundled/built automatically. Older versions bundle it only for debug mode. **Verify early (at M1)** that a release build also opens the database: `flutter build windows --release`, then run the `.exe` from `build\windows\x64\runner\Release\`. If you see `Failed to load dynamic library 'sqlite3.dll'`, download the latest 64-bit `sqlite3.dll` from sqlite.org and copy it **next to the .exe**, then record this step in README.
6. Database location on desktop is the application support directory (Section 5.2), e.g. `C:\Users\<you>\AppData\Roaming\<company>\<app>\finance_tracker.db`. To reset data during development, close the app and delete that file (this replaces "uninstall the app" from the Android workflow).

### 2.3 Platform initialization (`main.dart`)

```dart
import 'package:sqflite_common_ffi/sqflite_common_ffi.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (isDesktop) {                       // Windows, Linux, macOS
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi; // must be set before any database is opened
  }
  runApp(const BootstrapApp());
}
```

```dart
// core/platform_utils.dart — the ONLY file that imports dart:io Platform
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

bool get isDesktop =>
    !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
```

All repository/SQL code stays identical on every platform because `databaseFactoryFfi` implements the full `sqflite` interface. Android uses the default `sqflite` factory (no initialization needed).

---

## 3. Locked decisions (do not change)

| Topic | Decision |
|---|---|
| Platforms | Windows desktop is the primary dev/demo target; Android remains supported. No web |
| Storage | SQLite via `sqflite` (+ `sqflite_common_ffi` on desktop), one DB file `finance_tracker.db`, DB version 1 |
| DB location | Desktop: `getApplicationSupportDirectory()` + `finance_tracker.db` (directory created if missing). Android: `getDatabasesPath()` |
| Money | VND, stored as `INTEGER` (đồng, no decimals). Max amount 999,999,999,999 (12 digits) |
| Amount sign | Always positive. `type` distinguishes income/expense. Never store negative amounts |
| Date | Stored as `TEXT` `yyyy-MM-dd` (date only, no time, no timezone). Future dates are **not** allowed (`lastDate` = today) |
| Session | `shared_preferences` keys: `session_user_id` (int), `session_created_at_ms` (int). On restoration, missing keys, future timestamps, or age **>= 7 days** invalidate the session |
| Passwords | `sha256("$salt:$password")` with a random per-user salt (16 random bytes, base64url). Hash and salt stored in `users`. Retain this PE implementation; document its limitations in REPORT, without adding a password-hashing package |
| Usernames | Stored lowercase; matched case-insensitively; regex `^[a-z0-9_]{3,30}$` |
| Seed accounts | `demo1 / Demo@123` and `demo2 / Demo@456` (created in `onCreate`, hashed at creation) |
| Presentation data | At the owner's request on 2026-10-29, an explicit Dart CLI tool may back up the existing DB and add three reserved presentation accounts with demo transactions/budgets. No automatic transaction seeding at app startup. See DEMO_DATA_GUIDE.md |
| Categories | Fixed lists per type (Section 7.3). Changing type in the form resets category |
| Summary cards | The three main cards (Income, Expense, Balance) are **all-time totals for the current user** and are never affected by search/filter or the month selector |
| Month section | A separate "Theo tháng" section on the dashboard with its own month selector, visible from M7; budget controls appear from M8 |
| Filter state | Search/filter/sort state lives in the provider: it **persists across tab switches** and is **reset on login/logout/user change** |
| Search | Done in Dart (not SQL `LIKE`/`LOWER`), case-insensitive and diacritic-insensitive for Vietnamese, including combining marks U+0300–U+036F |
| Sorting | Mandatory in M5: newest, oldest, amount descending, amount ascending |
| Save result | `add`/`update` return `SaveResult`; `ok` means the DB write committed. A later refresh failure keeps `ok = true` (Tier A: set `errorMessage`; Tier B: stale flag + read retry) and never offers to repeat the save |
| Async isolation | Increment `_epoch` on every actual user change; stale async completions must not change current state or emit UI effects |
| `setUser` timing | `setUser` runs inside a provider `update:` callback, i.e. **during build**. It must clear state **silently** and defer `notifyListeners()`/`refresh()` with `scheduleMicrotask` (Section 7.1) |
| Logout navigation | Only `RequireAuth` navigates after logout. The logout handler calls `auth.logout()` and does **not** navigate itself |
| Localization | `flutter_localizations`, `locale: Locale('vi')`, Vietnamese supported locale and Material/Widgets/Cupertino delegates; retain `vi_VN` for explicit number/date formatting |
| Layout | `MobileAppFrame` wraps the entire Navigator using MaterialApp.builder: Windows windows >=600 dp wide and >=440 dp high show a centered 430 dp mobile viewport with a frame; height fits the available window up to 900 dp. Narrow windows/phones fill the viewport, preserving real safe areas and keyboard insets. Keep bottom NavigationBar; ResponsiveBody still limits protected content to 640 dp on larger unframed devices |
| Optional entry points | Hide month UI until M7, budget UI until M8, registration until M9, and CSV export until M10 |
| Error display | `SnackBar` for transient errors; inline `errorText` for form fields; Login uses a single inline banner above the submit button |
| Mandatory test 10 | Applies to Firebase/REST only. Not applicable to SQLite. State this in the report |
| Theme | Material 3, seed color teal; income = green, expense = red; full Be Vietnam Pro TextTheme, spacing 4/8/16/24/32 and control/card/balance radii 12/16/20. Updated UI decisions are recorded in UI_UX_IMPROVEMENT_PLAN.md |

---

## 4. Folder structure and responsibilities

```
lib/
  main.dart                       # bindings, desktop FFI init, runApp(BootstrapApp)
  bootstrap_app.dart              # cached init Future; minimal MaterialApp for loading/error; then providers + App
  app.dart                        # MaterialApp, Vietnamese localization, theme, guarded named routes
  core/
    platform_utils.dart           # isDesktop (only dart:io Platform import)
    app_theme.dart                # ThemeData, income/expense colors
    app_routes.dart               # route name constants + argument classes
    categories.dart               # category lists per TxType
    constants.dart                # sessionMaxAge, maxAmount, seed credentials
    validators.dart               # pure validation functions (no BuildContext)
    amount_input_formatter.dart   # reject the entire edit/paste unless it is 0–12 ASCII digits
    password_hasher.dart          # salt + sha256
    text_utils.dart               # normalizeVi(), csvEscape()
    csv_export.dart               # pure CSV builder over already user-scoped rows (M10)
    budget_alert_calculator.dart  # pure budget level/transition calculation (M8)
    money_format.dart             # formatVnd(), parseAmountOrNull()
    app_exception.dart            # AppException(message)
  data/
    app_database.dart             # open(), default path, onConfigure/onCreate/onUpgrade, seed
    models/
      app_user.dart
      finance_transaction.dart    # + enum TxType
      budget.dart
      summary_totals.dart         # income, expense, balance getter
      category_total.dart         # category, total
      budget_alert.dart           # enum + payload used by SaveResult (model only; calculation is in core/)
      save_result.dart            # explicit write outcome, optional alert/message
    repositories/
      user_repository.dart
      transaction_repository.dart
      budget_repository.dart
    session_storage.dart          # wraps shared_preferences (userId + createdAt only)
  providers/
    auth_provider.dart
    transaction_provider.dart     # user-scoped state + async orchestration; delegates pure CSV/alert logic
  screens/
    splash_screen.dart            # AuthGate
    login_screen.dart
    register_screen.dart
    home_shell.dart               # NavigationBar (Dashboard | Giao dịch), FAB, AppBar menu
    dashboard_screen.dart
    transaction_list_screen.dart
    transaction_form_screen.dart  # shared by Add and Edit
    transaction_detail_screen.dart
    budget_screen.dart
  widgets/
    summary_card.dart
    transaction_tile.dart
    confirm_dialog.dart
    empty_state.dart
    require_auth.dart             # guards every protected route; sole owner of post-logout navigation
    responsive_body.dart          # Center + ConstrainedBox(maxWidth: 640)
    filter_bar.dart
    month_selector.dart
    category_breakdown.dart
    budget_progress.dart
test/
  password_hasher_test.dart            # Tier A
  text_utils_test.dart                 # Tier A
  validators_test.dart                 # Tier A
  amount_input_formatter_test.dart     # Tier A
  transaction_repository_test.dart     # Tier A  (sqflite_common_ffi in-memory DB)
  user_isolation_test.dart             # Tier A
  session_storage_test.dart            # Tier B
  auth_provider_test.dart              # Tier B
  database_error_test.dart             # Tier B
  transaction_form_test.dart           # Tier B  (fake repository, no real SQLite)
```

---

## 5. Data layer

### 5.1 Schema (DB version 1; includes `budgets` from the start so no migration is needed)

```sql
PRAGMA foreign_keys = ON;   -- executed in onConfigure on every open

CREATE TABLE users (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  username      TEXT NOT NULL UNIQUE,          -- lowercase
  password_hash TEXT NOT NULL,
  salt          TEXT NOT NULL,
  display_name  TEXT NOT NULL
);

CREATE TABLE transactions (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id    INTEGER NOT NULL,
  type       TEXT NOT NULL CHECK (type IN ('income','expense')),
  amount     INTEGER NOT NULL CHECK (amount > 0 AND amount <= 999999999999),
  category   TEXT NOT NULL,
  date       TEXT NOT NULL,                    -- yyyy-MM-dd
  note       TEXT,
  created_at TEXT NOT NULL,                    -- ISO8601, informational
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE INDEX idx_tx_user_date ON transactions(user_id, date DESC);

CREATE TABLE budgets (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id      INTEGER NOT NULL,
  month        TEXT NOT NULL,                  -- yyyy-MM
  limit_amount INTEGER NOT NULL CHECK (limit_amount > 0 AND limit_amount <= 999999999999),
  UNIQUE (user_id, month),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

### 5.2 `AppDatabase`

`open()` must accept an optional path and `DatabaseFactory` so tests can use an in-memory FFI database. When no path is given, resolve the platform default.

```dart
class AppDatabase {
  AppDatabase._(this.db);
  final Database db;
  static const _dbName = 'finance_tracker.db';
  static const _dbVersion = 1;

  /// Desktop: application support dir (stable location, independent of cwd).
  /// Android: standard sqflite databases path.
  static Future<String> defaultPath(DatabaseFactory f) async {
    if (isDesktop) {
      final dir = await getApplicationSupportDirectory();
      await Directory(dir.path).create(recursive: true);
      return join(dir.path, _dbName);
    }
    return join(await f.getDatabasesPath(), _dbName);
  }

  static Future<AppDatabase> open({String? path, DatabaseFactory? factory}) async {
    final f = factory ?? databaseFactory;      // set to databaseFactoryFfi in main() on desktop
    final dbPath = path ?? await defaultPath(f);
    final db = await f.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: _dbVersion,
        onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: _onCreate,
        onUpgrade: _onUpgrade, // future migrations; version 1 has none
      ),
    );
    return AppDatabase._(db);
  }
}
```

Do not use the default `getDatabasesPath()` of the FFI factory for the real app: on desktop it is relative to the working directory (`.dart_tool/sqflite_common_ffi/databases`), which differs between `flutter run` and a built `.exe`, so data would appear to "disappear".

`_onCreate`: run the three `CREATE TABLE` statements and the index in one batch, then insert the two seed users. For each seed user generate a salt with `PasswordHasher.generateSalt()` and store `PasswordHasher.hash(password, salt)`.
Public demo credentials appear in `core/constants.dart` and the explicitly invoked presentation tool `tool/demo_dataset.dart`; they are never persisted in plaintext. The tool's shared demo password is documented in DEMO_DATA_GUIDE.md. Real session storage still contains only userId/timestamp, and user records store only hash/salt.

### 5.3 Models

```dart
enum TxType { income, expense }   // stored as .name ('income' / 'expense')

class FinanceTransaction {
  final int? id;
  final int userId;
  final TxType type;
  final int amount;        // > 0
  final String category;
  final String date;       // 'yyyy-MM-dd'
  final String? note;
  final String createdAt;  // ISO8601
  // copyWith, toMap() (omit id when null), factory fromMap()
}

class AppUser { final int id; final String username; final String displayName; /* + hash/salt only in repo layer */ }
class Budget { final int? id; final int userId; final String month; final int limitAmount; }
class SummaryTotals { final int income; final int expense; int get balance => income - expense; }
class CategoryTotal { final String category; final int total; }

class SaveResult {
  const SaveResult({required this.ok, this.alert, this.message});
  final bool ok;                // true once the database write has committed
  final BudgetAlert? alert;     // null when no alert, or alert calculation was unavailable
  final String? message;        // failure text, or a non-fatal refresh warning after commit
}
```

### 5.4 Repositories (all signatures require `userId` where applicable)

Dart classes are implicit interfaces, so tests may fake a repository with `implements TransactionRepository`; no separate abstract interface is needed. Providers receive repositories through their constructors.

**UserRepository**
- `Future<AppUser?> findById(int id)`
- `Future<AppUser?> authenticate(String username, String password)` — lowercase+trim username, load row, `PasswordHasher.verify`, return `AppUser` or `null`.
- `Future<AppUser> register({required String username, required String password, required String displayName})` — lowercase username; on UNIQUE violation (`DatabaseException.isUniqueConstraintError()`) throw `AppException('Tên đăng nhập đã tồn tại')`.

**TransactionRepository**
- `Future<List<FinanceTransaction>> getAll(int userId)` → `WHERE user_id = ? ORDER BY date DESC, id DESC`
- `Future<FinanceTransaction?> getById(int userId, int id)` → `WHERE id = ? AND user_id = ?`
- `Future<int> insert(FinanceTransaction t)` (t.userId must be set by the provider from the logged-in user, never from UI input)
- `Future<int> update(FinanceTransaction t)` → `WHERE id = ? AND user_id = ?`; update only `type`, `amount`, `category`, `date`, `note`. Never include `id`, `user_id`, or `created_at` in the update values. Returns affected rows; if `0` throw `AppException('Không tìm thấy giao dịch')`
- `Future<int> delete(int userId, int id)` → `WHERE id = ? AND user_id = ?`; same `0` rule
- `Future<SummaryTotals> getTotals(int userId, {String? fromDate, String? toExclusive})`:
  ```sql
  SELECT
    COALESCE(SUM(CASE WHEN type='income'  THEN amount END), 0) AS income,
    COALESCE(SUM(CASE WHEN type='expense' THEN amount END), 0) AS expense
  FROM transactions
  WHERE user_id = ?
    [AND date >= ? AND date < ?]
  ```
- `Future<List<CategoryTotal>> getExpenseByCategory(int userId, String fromDate, String toExclusive)`:
  ```sql
  SELECT category, SUM(amount) AS total
  FROM transactions
  WHERE user_id = ? AND type = 'expense' AND date >= ? AND date < ?
  GROUP BY category ORDER BY total DESC
  ```

Before every transaction insert/update, reject an amount outside `1..999999999999` and require `categoriesFor(t.type).contains(t.category)`. Use the same pure validators for amount, date, and note as the form, and throw a Vietnamese `AppException` on invalid data. A non-null category from the wrong type is invalid. The provider overwrites incoming ownership with its captured authenticated user; the repository uses that user in the ownership predicate.

**BudgetRepository**
- `Future<Budget?> getForMonth(int userId, String month)`
- `Future<void> upsert(Budget b)` — validate `1 <= limitAmount <= 999999999999`; inside `db.transaction`, first `txn.update` only `limit_amount` with `WHERE user_id = ? AND month = ?`; if the affected row count is `0`, `txn.insert` a new budget without an explicit `id`. Existing budget IDs remain unchanged. Use the transaction handle for both statements. Do not use `ON CONFLICT ... DO UPDATE` or `ConflictAlgorithm.replace`; this avoids depending on SQLite 3.24 UPSERT syntax or delete-then-insert behavior.
- `Future<void> delete(int userId, String month)`

All repository methods wrap `DatabaseException` and rethrow `AppException('Lỗi cơ sở dữ liệu. Vui lòng thử lại.')` (keep the original error in a debug log). Handle the duplicate-username exception first so its specific message is preserved. Do not wrap an existing validation/not-found `AppException` as a generic DB error.

### 5.5 Session storage

```dart
class SessionData { final int userId; final DateTime createdAt; }

class SessionStorage {
  static const _kUserId = 'session_user_id';
  static const _kCreatedAt = 'session_created_at_ms';
  Future<void> save(int userId);          // writes userId + now (ms); await the writes
  Future<SessionData?> read();            // clear partial keys and return null if either is missing
  Future<void> clear();                   // removes both keys
}
```

On Windows, `shared_preferences` persists to a file in the application support directory; closing the window or ending the process after `save()` completes keeps the session.

---

## 6. Core utilities (reference implementations)

### 6.1 `password_hasher.dart`
```dart
class PasswordHasher {
  static String generateSalt([int length = 16]) {
    final r = Random.secure();
    return base64UrlEncode(List<int>.generate(length, (_) => r.nextInt(256)));
  }
  static String hash(String password, String salt) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();
  static bool verify(String password, String salt, String expectedHash) =>
      hash(password, salt) == expectedHash;
}
```

### 6.2 `text_utils.dart`
```dart
const _from = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
final _to = '${'a' * 17}${'e' * 11}${'i' * 5}${'o' * 17}${'u' * 11}${'y' * 5}d';

/// Lowercase + strip Vietnamese diacritics. Used for search only.
String normalizeVi(String input) {
  final sb = StringBuffer();
  for (final r in input.toLowerCase().trim().runes) {
    if (r >= 0x0300 && r <= 0x036F) continue; // drop combining diacritics
    final ch = String.fromCharCode(r);
    final i = _from.indexOf(ch);
    sb.write(i >= 0 ? _to[i] : ch);
  }
  return sb.toString();
}

/// CSV escaping + spreadsheet formula-injection guard.
String csvEscape(String s) {
  var v = s;
  if (v.isNotEmpty && '=+-@'.contains(v[0])) v = "'$v";
  if (v.contains(RegExp(r'[",\n\r]'))) v = '"${v.replaceAll('"', '""')}"';
  return v;
}
```
Add unit tests that `normalizeVi('Ăn uống') == 'an uong'`, `'Đi lại'` → `'di lai'`, and the decomposed input `'A\u0306n uo\u0302\u0301ng'` → `'an uong'`. Combining marks must be removed from both the search query and the text being searched.

### 6.3 `money_format.dart`
```dart
final _nf = NumberFormat.decimalPattern('vi_VN');
String formatVnd(int v) => '${_nf.format(v)} ₫';       // 1.500.000 ₫
int? parseAmountOrNull(String s) => int.tryParse(s.trim());   // input is digits only
```
During bootstrap initialization: `await initializeDateFormatting('vi_VN');` and use `DateFormat('dd/MM/yyyy', 'vi_VN')` for display. Storage format stays `yyyy-MM-dd`. `intl` formatting is separate from Material localization: configure `MaterialApp` with `locale: const Locale('vi')`, `supportedLocales: const [Locale('vi')]`, and `GlobalMaterialLocalizations.delegate`, `GlobalWidgetsLocalizations.delegate`, `GlobalCupertinoLocalizations.delegate` from `flutter_localizations`.

### 6.4 `validators.dart` (pure functions returning `String?` error or `null`)

| Field | Rule | Message |
|---|---|---|
| username (login) | not empty after trim | `Vui lòng nhập tên đăng nhập` |
| password (login) | not empty | `Vui lòng nhập mật khẩu` |
| username (register) | matches `^[a-z0-9_]{3,30}$` after lowercase | `Tên đăng nhập 3–30 ký tự: chữ, số, dấu gạch dưới` |
| password (register) | length ≥ 6, has a letter and a digit | `Mật khẩu tối thiểu 6 ký tự, gồm chữ và số` |
| confirm password | equals password | `Mật khẩu xác nhận không khớp` |
| display name | 1–40 chars after trim | `Vui lòng nhập tên hiển thị (tối đa 40 ký tự)` |
| amount | not empty; parses to int; `> 0`; `<= 999999999999` | `Vui lòng nhập số tiền` / `Số tiền không hợp lệ` / `Số tiền phải lớn hơn 0` / `Số tiền quá lớn` |
| category | not null; belongs to `categoriesFor(type)` | `Vui lòng chọn danh mục` / `Danh mục không hợp lệ` |
| date | not null and not after today | `Vui lòng chọn ngày` / `Không được chọn ngày trong tương lai` |
| note | ≤ 200 chars | `Ghi chú tối đa 200 ký tự` |
| budget limit | int, `> 0`, `<= 999999999999` | `Hạn mức phải lớn hơn 0` |

Amount `TextFormField`: `keyboardType: TextInputType.number`, one formatter that accepts/rejects the complete edit, and helper text showing a live `formatVnd(...)` preview. Put the formatter in `core/amount_input_formatter.dart` and reuse it for budget limits:

```dart
final amountInputFormatter = TextInputFormatter.withFunction((oldValue, newValue) {
  return RegExp(r'^[0-9]{0,12}$').hasMatch(newValue.text) ? newValue : oldValue;
});
```

Empty input is allowed while editing and rejected by the required-field validator on save. Pasting (Ctrl+V on desktop) `1,5`, `1.5`, `-5`, letters, or more than 12 digits must preserve the entire old value. Never silently strip characters or truncate a pasted amount. Do not combine this formatter with `digitsOnly` or `LengthLimitingTextInputFormatter`. On desktop `TextInputType.number` does not restrict keys, so this formatter is the only guard.

---

## 7. State management and flows

### 7.1 Bootstrap and provider wiring

```dart
// Called only after BootstrapApp has initialized intl and opened the database.
Widget buildInitializedApp(AppDatabase appDb) => MultiProvider(
    providers: [
      Provider.value(value: appDb),
      Provider(create: (_) => UserRepository(appDb)),
      Provider(create: (_) => TransactionRepository(appDb)),
      Provider(create: (_) => BudgetRepository(appDb)),
      Provider(create: (_) => SessionStorage()),
      ChangeNotifierProvider(create: (c) => AuthProvider(c.read(), c.read())),
      ChangeNotifierProxyProvider<AuthProvider, TransactionProvider>(
        create: (c) => TransactionProvider(c.read(), c.read()),
        update: (c, auth, prev) => prev!..setUser(auth.currentUser?.id),
      ),
    ],
    child: const App(),
  );
```

`BootstrapApp` is a small stateful widget with a cached `Future<AppDatabase>` created in `initState`. Initialization awaits `initializeDateFormatting('vi_VN')`, then `AppDatabase.open()`. A `FutureBuilder` renders:
- **pending:** a loading screen;
- **success:** `buildInitializedApp(db)`;
- **failure (Tier B):** `Không thể mở dữ liệu. Vui lòng thử lại.` with a `Thử lại` button (Tier A: show the message without a button).

**The loading and error screens must be wrapped in their own minimal `MaterialApp`** (theme + `locale: Locale('vi')` + localization delegates + a `Scaffold`). `App` (which owns the real `MaterialApp`) does not exist yet at that point; without this wrapper the screens have no `Directionality`, theme or localizations and Flutter throws. Replace the cached Future only on retry, never on every build. No auth restoration runs before the DB opens. Do not delete or reset user data to recover from an initialization error.

**`TransactionProvider.setUser` runs during build** (the proxy `update:` callback). It must therefore **never call `notifyListeners()` synchronously**.

```dart
int _epoch = 0;
int? _userId;

void setUser(int? userId) {
  if (userId == _userId) return;      // proxy update fires on every AuthProvider notification
  _epoch++;
  _userId = userId;
  _resetStateSilently();               // plain field assignments only: list, totals, filters, selected month,
                                       // month stats, budget, loading/saving flags, stale flag, error. NO notify here.
  final epoch = _epoch;
  scheduleMicrotask(() {               // runs after the current build finishes
    if (epoch != _epoch) return;       // user changed again meanwhile
    notifyListeners();
    if (userId != null) refresh();
  });
}
```

Descendants build after the proxy update, so they already see the cleared state; the deferred notify only corrects listeners that built earlier.

Every async provider operation captures `final epoch = _epoch` and `final userId = _userId` before its first `await`; reject mutations without an authenticated user. All repository calls in that operation use the captured `userId`. After an `await`, ignore stale results when `epoch != _epoch`; stale `catch`/`finally` blocks must also leave the new user's state untouched. This includes loading flags, errors, budget alerts, and CSV results. Never take ownership from a mutable `_userId` after an await. For month-specific loads, also verify that the captured month is still selected before publishing month state. Expose a read-only `userEpoch` for screens to check before showing a message or navigating after an async operation.

Clearing state removes data already in memory; epoch checks prevent pending work from restoring the previous user's data afterward. Keep these guards small rather than introducing a cancellation framework.

### 7.2 `AuthProvider`

State: `AppUser? currentUser`, `bool isBusy`, `String? errorMessage`.
Allow an optional `DateTime Function()` clock in the constructor, defaulting to `DateTime.now`, so expiry tests use a fixed time (Tier B test).

```dart
static const sessionMaxAge = Duration(days: 7);

Future<bool> restoreSession() async {
  SessionData? s;
  try {
    s = await _session.read();
  } catch (e) {                         // storage read failure: do not clear anything
    debugPrint('restoreSession read failed: $e');
    _errorMessage = 'Không đọc được phiên đăng nhập. Vui lòng đăng nhập lại.';
    notifyListeners();
    return false;                       // Splash goes to Login; Login shows the message once, then clears it
  }
  if (s == null) return false;
  final age = _now().difference(s.createdAt);
  if (age.isNegative || age >= sessionMaxAge) { await _session.clear(); return false; }
  final user = await _users.findById(s.userId);
  if (user == null) { await _session.clear(); return false; }   // stale session (user no longer in DB)
  _currentUser = user; notifyListeners(); return true;
}

Future<bool> login(String username, String password)  // sets errorMessage 'Sai tên đăng nhập hoặc mật khẩu' (generic, never reveals which field)
Future<bool> register(String username, String password, String displayName) // creates user, then logs in
Future<void> logout() async { await _session.clear(); _currentUser = null; notifyListeners(); }
```
`logout()` setting `currentUser = null` (a) triggers `TransactionProvider.setUser(null)` through the proxy, clearing all in-memory data, and (b) causes `RequireAuth` to redirect to Login. `logout()` itself never calls `Navigator`.
Missing either session key, a future timestamp, and an age exactly equal to 7 days are invalid restoration cases. Check expiry at session restoration; no background expiry timer is required for this PE scope.

### 7.3 Categories (`core/categories.dart`)

```dart
const expenseCategories = ['Ăn uống','Đi lại','Nhà ở','Mua sắm','Giải trí','Sức khỏe','Giáo dục','Khác'];
const incomeCategories  = ['Lương','Thưởng','Đầu tư','Khác'];
List<String> categoriesFor(TxType t) => t == TxType.income ? incomeCategories : expenseCategories;
```

### 7.4 `TransactionProvider` (public API)

State: `List<FinanceTransaction> _all`, `SummaryTotals totals`, `DateTime selectedMonth` (first day of month, default current), `SummaryTotals monthTotals`, `List<CategoryTotal> monthBreakdown`, `Budget? monthBudget`, search/filter/sort fields, `_epoch`, `isLoading`, `errorMessage`, and (Tier B) `needsRefresh`. Month/budget state and reads become active only at M7/M8.

```dart
// data
Future<bool> refresh();                       // true only if a current-epoch snapshot was loaded
Future<SaveResult> add(FinanceTransaction t);  // ok describes the database write, not the refresh
Future<SaveResult> update(FinanceTransaction t);
Future<bool> delete(int id);
FinanceTransaction? byId(int id);             // from _all (detail screen reads this inside a Consumer)
int get userEpoch;

// view state
String searchQuery;  TxType? typeFilter;  String? categoryFilter;  SortOption sort; // enum: newest, oldest, amountDesc, amountAsc
List<FinanceTransaction> get visible;         // derived: search AND type AND category, then sort
List<String> get categoryOptions;             // depends on typeFilter (income → incomeCategories, expense → expenseCategories, null → distinct union)
void setSearch(String q);  void setTypeFilter(TxType? t);  void setCategoryFilter(String? c);
void setSort(SortOption s);  void clearFilters();
bool get hasActiveFilters;

// month dashboard (M7+)
Future<void> changeMonth(int deltaMonths);    // reload month stats; does not touch all-time totals
String get selectedMonthKey;                  // 'yyyy-MM'
Future<void> saveBudget(int limit);  Future<void> removeBudget();   // M8+

// export (M10)
Future<String> buildCsv();                    // all transactions of the current user, see Section 12.5
```

Rules:
- `refresh()` captures the user/epoch, loads the list and SQL totals (plus month stats from M7 and budget from M8) into local variables, then publishes them together only if still current. On read failure, retain the last successful snapshot, set a Vietnamese `errorMessage` and return `false` (Tier B: also set `needsRefresh = true`). On success clear the error (and `needsRefresh`). Totals come from SQL (`getTotals`), not from summing the list.
- `add`/`update`: capture the user/epoch and set ownership from that user → validate → repository write → mark the write committed → attempt refresh and any optional budget alert calculation. Return `SaveResult(ok: false, message: ...)` only if the write did not commit. Return `SaveResult(ok: true, alert: ...)` when it committed and subsequent reads succeeded. If any post-commit read fails, return `SaveResult(ok: true, message: 'Đã lưu giao dịch, nhưng chưa tải lại được dữ liệu. Vui lòng thử tải lại.')` with `alert` null. The UI closes the saved form; it must not offer to repeat the insert/update. A later read failure never changes a committed write into a failed save.
- `delete(id)` returns `true` once the deletion commits, even if refresh fails afterward; remove the known deleted row locally and show a refresh warning. Return `false` for a failed deletion. `saveBudget`/`removeBudget` throw `AppException` only for a failed write; after commit they complete normally and expose any read warning through `errorMessage`.
- After any await, stale-epoch work must not publish state, show a message, or navigate. A write already committed still has a successful write outcome, but a screen from an obsolete epoch ignores its completion. Cancel pending search debounce timers when their screen is disposed or the session changes.
- `setTypeFilter` resets `categoryFilter` if that category is not in the new `categoryOptions`.
- `visible` filtering: `normalizeVi(note ?? '')` or `normalizeVi(category)` contains `normalizeVi(searchQuery)`; empty query matches all. Type and category filters combine with AND.
- Read methods catch `AppException`/errors, set `errorMessage`, and notify only for the captured current epoch. Save methods return the explicit `SaveResult` above. A message is displayed once: the initiating form owns `SaveResult.message`; other read errors use provider `errorMessage`. Do not show the same error both ways or navigate/show SnackBars during widget build. Log unexpected errors with `debugPrint`; never display raw exception text.
- `userId` for new transactions is captured from `_userId` inside the provider before the first await, never from the form.
- CSV generation and budget alert level/transition calculations are pure functions in `core/csv_export.dart` and `core/budget_alert_calculator.dart`; they receive data as arguments and do not access providers, databases, preferences, files, or `BuildContext`. The provider handles user-scoped reads and delegates computation. Add these files only at their optional milestones.

### 7.5 `BudgetAlert` (M8)

```dart
enum BudgetAlertLevel { warning /* >= 80% */, exceeded /* > 100% */ }
class BudgetAlert { final BudgetAlertLevel level; final int spent; final int limit; }
```
For add/update of an **expense** whose month has a budget: read the relevant pre-write month expense, then compute its post-write value; use the pure calculator to return an alert only if the level **increased** (none → warning, none/warning → exceeded). If an optional pre-write budget/stat read fails, log it, skip the alert, and still attempt the transaction write. Return an available alert in `SaveResult.alert`. The form screen shows it as a `SnackBar` (warning: amber, `Sắp vượt ngân sách tháng (xx%)`; exceeded: red, `Đã vượt ngân sách tháng!`). Optional alert calculation must not convert a committed DB write into a failed save.

---

## 8. Navigation

Use `Navigator` with named routes in `app.dart` (`onGenerateRoute`), constants in `core/app_routes.dart`.

| Route | Screen | Args |
|---|---|---|
| `/` | SplashScreen (AuthGate) | — |
| `/login` | LoginScreen | — |
| `/register` | RegisterScreen | — |
| `/home` | HomeShell | — |
| `/transaction/new` | TransactionFormScreen | — |
| `/transaction/edit` | TransactionFormScreen | `FinanceTransaction` |
| `/transaction/detail` | TransactionDetailScreen | `int id` |
| `/budget` | BudgetScreen | — |

In `onGenerateRoute`, wrap **every** protected screen (`/home`, `/transaction/new`, `/transaction/edit`, `/transaction/detail`, `/budget`) in the same `RequireAuth` widget. `/`, `/login`, and `/register` are public, with registration unavailable until M9. Budget routes are unavailable until M8. Routes for unfinished optional features must not expose placeholder screens.

Navigation rules (important for the "Back after logout" requirement):
- Splash → `pushReplacementNamed('/home')` or `'/login'`.
- Login/Register success → `pushNamedAndRemoveUntil('/home', (r) => false)`.
- **Logout:** the handler (after the confirm dialog closes) only `await`s `auth.logout()`. It does **not** navigate. `RequireAuth` performs the single redirect.
- `RequireAuth` listens to `AuthProvider`. It builds its child only when `currentUser != null`; otherwise it shows a neutral loading placeholder. It redirects with one post-frame `pushNamedAndRemoveUntil('/login', (r) => false)` **only when `ModalRoute.of(context)?.isCurrent == true`**, so a stack with several protected routes produces exactly one redirect. Check `mounted` and the latest auth state before redirecting. Never call Navigator during build. A form/detail/budget route must be protected even when opened directly by name.
- Because the stack is cleared on login and on the redirect, the system Back/Alt+Left cannot return to a protected screen after logout; Back from Home exits the app.

---

## 9. Screens (specification)

All protected screens place their body inside `ResponsiveBody` (centered, `maxWidth: 640`). The root `MobileAppFrame` applies the owner's 430 dp mobile viewport on wide Windows windows, including route overlays/dialogs. Resize without losing Navigator/tab/filter state. No fake status bar, device time, or desktop navigation rail.

### 9.1 SplashScreen (AuthGate)
- Shows app logo/name and a `CircularProgressIndicator`.
- After bootstrap succeeds, in `initState` (post-frame): `final ok = await auth.restoreSession();` then navigate (see Section 8), checking `mounted` after the await. No Login screen flash.

### 9.2 LoginScreen
- `Form` with username and password `TextFormField` (password obscured with show/hide toggle), validators from Section 6.4, `Đăng nhập` button (disabled and spinner while `isBusy`). **Enter submits the form** (`onFieldSubmitted` on the password field). Show `Chưa có tài khoản? Đăng ký` only after M9 is complete.
- On failure show the generic error in a single inline banner above the button, with a live-region semantic announcement. Keep the username, clear the password; clear the old banner when the user edits input. If `auth.errorMessage` was set by `restoreSession`, show it once and clear it. The demo hint is a separate block outside the form card.
- Footer hint (dev/demo): `Tài khoản demo: demo1 / Demo@123`.

### 9.3 RegisterScreen (optional feature F9, but wired from M9)
- Fields: display name, username, password, confirm password. Validators per Section 6.4. On `AppException('Tên đăng nhập đã tồn tại')` show it as the username field `errorText`.

### 9.4 HomeShell
- `Scaffold` with `NavigationBar` (2 destinations: `Tổng quan`, `Giao dịch`) and an `IndexedStack` to preserve each tab's state.
- `AppBar` title shows `Xin chào, {displayName}`; actions menu: `Ngân sách` only after M8, `Xuất CSV` only after M10 and only on the Giao dịch tab, `Đăng xuất` (confirm dialog first, then `auth.logout()` with no manual navigation).
- `FloatingActionButton` (`+`) opens `/transaction/new` on both tabs.

### 9.5 DashboardScreen
Top to bottom:
1. **Three `SummaryCard`s (all-time):** prominent `Số dư` (green if ≥ 0, red if < 0), followed by `Tổng thu` (green) and `Tổng chi` (red). Stack the supporting cards when amounts or scaled text need more space.
2. **Section `Theo tháng` (from M7):** `MonthSelector` (◀ `Tháng MM/yyyy` ▶; ▶ disabled on the current month), month income/expense, `CategoryBreakdown` (expense by category for the selected month: label, amount, percent of month expense, `LinearProgressIndicator`; empty state if no expense). From M8 also show `BudgetProgress` (if a budget exists: progress bar, `đã chi / hạn mức`, color green < 80%, amber 80–100%, red > 100%; if none: button `Đặt ngân sách`). Hide the entire month section before M7 and all budget controls before M8.
3. **Recent transactions:** the 5 most recent (`TransactionTile`), `Xem tất cả` switches to the Giao dịch tab.
- Wrap in `Consumer<TransactionProvider>`; pull-to-refresh (and a `Tải lại` icon button for desktop mouse users) calls `refresh()`.
- Use static skeleton placeholders for the initial load rather than displaying zero totals as actual data. A refresh after a successful load retains the current snapshot with progress.
- Tier B: when `needsRefresh` is true, show a stale-data banner with `Thử tải lại` that retries reads only; never repeat a previously committed mutation.

### 9.6 TransactionListScreen
- Search `TextField` (debounce 300 ms via `Timer`, then `provider.setSearch`), with clear button.
- `FilterBar`: `ChoiceChip`s `Tất cả | Thu | Chi` (type), a category dropdown driven by `categoryOptions` (with `Tất cả danh mục`), a visible `Sắp xếp` dropdown (`Mới nhất`, `Cũ nhất`, `Tiền giảm dần`, `Tiền tăng dần`), and `Xóa bộ lọc` visible when `hasActiveFilters`. Show the result count and removable query/type/category chips; removing one condition preserves independent state.
- `ListView.builder` over `provider.visible` using `TransactionTile` (type icon + color, category, note preview, date `dd/MM/yyyy`, amount with `+`/`−` and color). Tap → detail.
- `EmptyState`: no data at all → `Chưa có giao dịch. Nhấn + để thêm.`; no match → `Không tìm thấy giao dịch phù hợp.` with a clear-filters button.
- Swipe-to-delete is **not** used (delete only with confirmation from the Detail screen).

### 9.7 TransactionFormScreen (Add + Edit, one screen)
- Constructor: `FinanceTransaction? initial`. Title `Thêm giao dịch` / `Sửa giao dịch`.
- Fields: type `SegmentedButton<TxType>` (`Thu`/`Chi`), amount (Section 6.4 rules), category dropdown (from `categoriesFor(type)`; **reset to null when type changes**), date (read-only field opening `showDatePicker`, `firstDate: 2000-01-01`, `lastDate: today`, default today), note (optional, multi-line, max 200).
- Use a 24 dp amount style and a formatted VND helper. Category/date share a row only if the local content width is at least 420 dp and text scale is at most 1.25; otherwise stack them. Measure local content inside the mobile frame, not the outer desktop window.
- Save: reject the handler immediately if `_isSaving` is already true; validate the form; set `_isSaving = true` synchronously **before the first await**; capture the provider's `userEpoch`; build `FinanceTransaction` (`userId` set by the provider) → await `add`/`update` → inspect `SaveResult`. Disable the button while saving and ignore rapid repeated clicks.
- If unmounted or the captured epoch is obsolete after the await, perform no UI action. If `result.ok == false`, show `result.message`, stay on the form, and retain all input. If `result.ok == true`, close the form exactly once, then show `result.alert` or the post-commit refresh warning through the app's `ScaffoldMessenger`. A refresh warning must never leave a successfully inserted transaction ready to be inserted again.
- Reset `_isSaving` in `finally` only if the form is still mounted. The outcome of the write comes from `SaveResult.ok`, never from whether an alert is null or whether `errorMessage` happens to be set.

### 9.8 TransactionDetailScreen
- Takes `int id`. Wrap in `Consumer<TransactionProvider>` and read `provider.byId(id)`, so edits are reflected immediately; when a completed load confirms it is missing, schedule a single post-frame close of this detail route. A loading/refresh-error state alone does not prove deletion.
- Shows all fields: type, amount, category, date, note (or `Không có ghi chú`), created time.
- AppBar action with tooltip `Sửa giao dịch` → `/transaction/edit`. Show category/amount/date as the main card, with adaptive metadata below and a separate outlined `Xóa giao dịch` action → `ConfirmDialog` (title `Xóa giao dịch?`, actions `Hủy` (default/autofocus) and `Xóa`) → on confirm await `delete(id)`. Only a successful deletion closes the detail route and shows `SnackBar('Đã xóa giao dịch')`; a post-commit refresh warning is shown separately. Coordinate the missing-row redirect and delete handler so exactly one pop occurs, outside build and only while mounted in the current epoch.

### 9.9 BudgetScreen (optional feature F7)
- Available from M8. Shows the selected month (from the provider), numeric field `Hạn mức chi tiêu (₫)` using the complete-edit formatter in Section 6.4, `Lưu` and `Xóa ngân sách` (with confirm). Saves via `saveBudget` / `removeBudget`, then pops only after the write commits; handle any subsequent refresh warning as described in Section 7.4.

### 9.10 Shared widgets
`SummaryCard(title, amount, color, icon)`, `TransactionTile(tx, onTap)`, `ConfirmDialog.show(context, title, message, confirmLabel)` → `Future<bool>`, `EmptyState(icon, message, {actionLabel, onAction})`, `ResponsiveBody(child)`, `RequireAuth(child)`, `FilterBar`, `MonthSelector`, `CategoryBreakdown`, `BudgetProgress`.

---

## 10. Error handling matrix

| Situation | Behavior |
|---|---|
| Wrong username/password | Generic message `Sai tên đăng nhập hoặc mật khẩu`; password field cleared |
| Empty/invalid form fields | Inline `errorText`, nothing saved |
| Duplicate username (register) | Field error `Tên đăng nhập đã tồn tại` |
| DB fails to open at startup | Bootstrap error screen (inside its own `MaterialApp`) with the message; Tier B adds `Thử lại`; no raw exception, no automatic data reset |
| `sqlite3.dll` missing (Windows release build) | Same bootstrap error screen; README documents copying `sqlite3.dll` next to the `.exe` |
| Session storage read fails at startup | Go to Login with `Không đọc được phiên đăng nhập. Vui lòng đăng nhập lại.`; do not clear keys |
| DB write fails before commit | `AppException('Lỗi cơ sở dữ liệu. Vui lòng thử lại.')`; add/update return `SaveResult(ok: false, message: ...)`, retain form input |
| Read fails without a committed mutation | Retain last successful snapshot, show Vietnamese error (Tier B: stale banner + read retry) |
| Transaction write commits, then refresh/alert read fails | `SaveResult(ok: true, message: 'Đã lưu giao dịch, nhưng chưa tải lại được dữ liệu. Vui lòng thử tải lại.')`; close form; never re-insert to recover |
| Delete/budget write commits, then refresh fails | Treat the write as successful; show a read warning, never repeat the committed mutation |
| Update/delete affecting 0 rows | `AppException('Không tìm thấy giao dịch')` → SnackBar, refresh list |
| Missing session key, future timestamp, age >= 7 days at startup | Clear both keys, go to Login (no error shown) |
| Session user deleted from DB | Same as above |
| Pending async result belongs to a previous epoch | Ignore state, loading/error changes, messages, and navigation from that completion |
| CSV export failure | SnackBar `Không thể xuất file. Vui lòng thử lại.` |
| Unexpected exception in a provider method | Caught and logged with `debugPrint`; show only a generic Vietnamese message for the current epoch, preserving whether a DB write already committed |

`AppException` carries a user-presentable Vietnamese `message`. Screens display only `message`, never raw exception text.

---

## 11. UI/UX requirements (grading: UI and navigation)

- Material 3, consistent spacing (8-pt grid), `SafeArea`, no overflow at a phone-like window (360×640) **and** at the default Windows window (≈1280×720); content is centered with max width 640 via `ResponsiveBody`.
- Currency always via `formatVnd`; dates via `DateFormat('dd/MM/yyyy', 'vi_VN')`.
- Material widgets, including `showDatePicker`, use the Vietnamese locale and localization delegates in Section 6.3. Verify the picker labels/buttons are Vietnamese even when Windows display language is English.
- Income green / expense red used consistently in tiles, cards, charts.
- Loading states (`CircularProgressIndicator`) and empty states on every list/section.
- Buttons disabled while an async action is running; mutation handlers also reject repeated clicks synchronously before the first await.
- Keyboard/mouse: `textInputAction` set, Tab moves between fields, Enter submits login and form fields where natural, clicking outside dismisses the keyboard on mobile; ensure visible focus and tooltips on icon buttons for desktop.

---

## 12. Optional features (all approved by the owner; implement only after M6-DOC)

### F7. Monthly budget + alerts
Table `budgets` (already in schema). UI in Dashboard (progress) and `BudgetScreen`. Alerts per Section 7.5.

### F8. Month selector and category breakdown
Month selector affects only the month section (Section 3). Breakdown uses `getExpenseByCategory`. Sorting is already mandatory in M5 and is not part of F8. Month range helper:
```dart
// month 'yyyy-MM' -> [from, toExclusive) as 'yyyy-MM-dd' strings
(String, String) monthRange(DateTime firstOfMonth) {
  final next = DateTime(firstOfMonth.year, firstOfMonth.month + 1, 1);
  String f(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
  return (f(firstOfMonth), f(next));
}
```

### F9. Registration
`RegisterScreen`, `AuthProvider.register`, `UserRepository.register` (Section 5.4 / 7.2).

### F10. CSV export (details in 12.5)

### 12.5 CSV export
- The provider's `buildCsv()` reads all rows for its captured current user, checks `_epoch`, then calls a pure `buildTransactionsCsv(rows)` function in `core/csv_export.dart`. That function returns a string beginning with the actual UTF-8 BOM character (`'\uFEFF'` in Dart) so Excel shows Vietnamese correctly. Header: `id,date,type,category,amount,note`. One row per transaction, ordered by date ascending. Use `csvEscape` for category and note.
- File name: `finance_export_yyyyMMdd_HHmmss.csv`.
- **Desktop (Windows, primary):** write the file to `getDownloadsDirectory()` (fall back to `getApplicationDocumentsDirectory()` if null) and show a `SnackBar` with the full saved path (`Đã lưu: <path>`). Do not use `share_plus` on desktop.
- **Android:** write to `getTemporaryDirectory()` and open the system share sheet with `share_plus` (add the package at M10). No storage permission is needed. Check the installed `share_plus` version's docs for the correct call.
- If the list is empty show `Chưa có dữ liệu để xuất`.
- Verify the captured session epoch again after awaits before writing/sharing the export; abandon an obsolete export without publishing it to the new session.

Do **not** implement multi-device sync, Firebase, REST, biometrics, or password change.

---

## 13. End-to-end flows

**Cold start**
1. `main()` initializes bindings; on desktop sets `databaseFactory = databaseFactoryFfi` → `runApp(BootstrapApp)`.
2. Bootstrap loads date formatting and opens DB at the platform path (creates schema and seeds on first run); on error show the bootstrap error screen, retaining existing data.
3. On successful initialization, build providers + App; Splash → `restoreSession()`.
4. true → `/home` (provider `setUser(id)` clears silently, then loads data on a microtask). false → `/login`.

**Login**
1. Validate form → `auth.login` → `UserRepository.authenticate`.
2. Success → `SessionStorage.save(userId)` → `currentUser` set → proxy calls `TransactionProvider.setUser(id)` → `pushNamedAndRemoveUntil('/home')`.
3. Failure → generic error.

**Logout**
1. Confirm dialog closes → `await auth.logout()` (clears session, `currentUser = null`) → proxy clears all transaction state → `RequireAuth` redirects once to `/login` (`pushNamedAndRemoveUntil`).
2. Restart app → Splash finds no session → Login.

**Add transaction**
1. FAB → form → validate → synchronously guard repeated clicks → `provider.add(tx)` → insert using captured authenticated `user_id` → attempt refresh (list/totals, plus month/budget reads only after M7/M8) → `SaveResult`.
2. `ok == false`: keep the form and inputs, show failure. `ok == true`: close once and show optional alert or refresh warning, if still mounted in the same epoch.
3. Dashboard cards/list update automatically on a successful refresh. If post-commit refresh failed, show the warning; never re-insert to recover from a read failure.

**Edit transaction**
1. Detail → `Sửa` → form prefilled → `provider.update(tx)` (`WHERE id AND user_id`, preserving `user_id`/`created_at`) → inspect `SaveResult` exactly as for Add.
2. If type or amount changed, all-time totals and month stats must reflect it.

**Delete transaction**
1. Detail → `Xóa` → confirm → `provider.delete(id)` → attempt refresh → close detail exactly once only if deletion committed; show success and any read warning. A failed delete keeps the detail screen open.

**Switch account**
1. Logout A → Login B. Each actual user change increments `_epoch`, clears the previous state silently, and loads the new user's rows. Queries use their captured user; a late completion for A cannot publish state or UI effects in B's epoch.

**Export CSV**
1. From M10: menu → user-scoped `provider.buildCsv()` → pure CSV builder → current-epoch check → write file → current-epoch check → desktop: show path; Android: share sheet.

---

## 14. Security checklist (verify before finishing)

- [ ] `rg -n "password" lib/` shows no plaintext password persistence or logging; plaintext seed constants and transient hashing inputs are expected.
- [ ] `shared_preferences` contains only `session_user_id` and `session_created_at_ms`.
- [ ] Every `transactions`/`budgets` query has `user_id = ?`.
- [ ] Transaction `UPDATE`/`DELETE` reject zero affected rows; budget upsert checks the update count before inserting.
- [ ] `PRAGMA foreign_keys = ON` in `onConfigure`.
- [ ] No class named `Transaction`.
- [ ] `TransactionProvider` clears state silently and increments `_epoch` on every user change; no `notifyListeners()` is called synchronously from `setUser`.
- [ ] Stale async completions cannot overwrite data/errors/loading flags or emit UI effects.
- [ ] Every protected route uses `RequireAuth`; logout redirects exactly once.
- [ ] Transaction updates never change `user_id` or `created_at`; amount/budget maximums are enforced by DB CHECKs.
- [ ] (Tier B) Missing session keys, future timestamps, and age >= 7 days are invalid on restoration, covered by tests.
- [ ] (M10) CSV contains only the captured logged-in user's data and is not written after the epoch changes.
- [ ] REPORT states that salted SHA-256 and local session flags serve this PE scope and are not production-grade protection against compromised local storage.

---

## 15. Automated tests (`flutter test`)

Use `sqflite_common_ffi` with `sqfliteFfiInit(); databaseFactory = databaseFactoryFfi;` and `AppDatabase.open(path: inMemoryDatabasePath, factory: databaseFactoryFfi)`. These host tests run on Windows (or any desktop) and are separate from manual app evidence.

**Tier A (required in M1–M6):**

| File | Must verify |
|---|---|
| `password_hasher_test.dart` | same password + different salts → different hashes; `verify` true/false |
| `text_utils_test.dart` | precomposed and decomposed Vietnamese normalize identically; `csvEscape` cases are added at M10 |
| `validators_test.dart` | amount: empty, `abc`, `0`, `-5`, `1,5`, `1.5`, too large, valid; required date; category/type match; username/password rules |
| `amount_input_formatter_test.dart` | empty and 12-digit edits allowed; pastes containing signs, decimal separators, letters, or 13 digits return the unchanged old `TextEditingValue` |
| `transaction_repository_test.dart` | insert/getAll/update/delete; totals and month ranges; DB CHECKs reject `0` and amounts above the maximum; wrong-type category rejected; updates preserve original `user_id`/`created_at` |
| `user_isolation_test.dart` | user 1 inserts rows; user 2 `getAll` is empty; user 2 `update`/`delete` on user 1's row id throws `AppException` and leaves the row intact; totals are per-user; deleting a user cascades to their rows |

**Tier B (only after M6-DOC, if time remains):**

| File | Must verify |
|---|---|
| `session_storage_test.dart` | save/read/clear; either key missing returns null and removes the remaining key, using `SharedPreferences.setMockInitialValues` |
| `auth_provider_test.dart` | with a fixed injected clock: future timestamp invalid, exactly 7 days invalid, just under 7 days valid for an existing user; invalid sessions clear stored keys; a throwing session read returns `false` and sets the message without clearing keys |
| `database_error_test.dart` | enable `PRAGMA query_only = ON` on a real initialized test DB, attempt a valid repository insert, expect the generic Vietnamese `AppException` and no new row; restore query_only in finally |
| `transaction_form_test.dart` | uses a **fake repository** (`implements TransactionRepository`) whose `insert` waits on a `Completer`, **not** real SQLite (real DB I/O can hang under the widget-test fake clock; if unavoidable wrap in `tester.runAsync`). Tap Save twice before completing the `Completer`, expect exactly one `insert` call; a fake that throws on the second read verifies `ok: true` with the refresh warning and a single close |

Keep these tests focused; do not add a new testing framework. At M8, add small pure-function cases for budget threshold transitions and a repository check that repeated upserts keep the same budget ID and reject limits above the maximum. At M10, test the pure CSV builder's BOM, escaping, and ordering.

---

## 16. Mandatory manual test cases (evidence required)

On Windows: "kill app" means **close the window with the X button, and also once via Task Manager → End task**; stopping `flutter run` and re-running is acceptable, hot restart is **not**. For the strongest evidence run the built executable (`flutter build windows --release`, then run `build\windows\x64\runner\Release\<app>.exe`). Record videos with Windows Game Bar (Win+G) or OBS.

| # | Scenario | Expected | Evidence |
|---|---|---|---|
| 1 | Login `demo1 / Demo@123` | Home shown | Screenshot |
| 2 | Wrong credentials | Error message, stay on Login | Screenshot |
| 3 | Login, close the app completely, reopen | Goes straight to Home | **Video** |
| 4 | Logout, close the app completely, reopen | Login screen shown | **Separate video** |
| 5 | Add, edit, delete a transaction | Each works, delete asks confirmation | Video/screenshots |
| 6 | After each CRUD op check Income/Expense/Balance | Values match manual calculation | Before/after table |
| 7 | Add data, close the app completely, reopen | Data still present | **Video** |
| 8 | Login as `demo2` after `demo1` added data | `demo2` sees none of `demo1`'s data; `demo1` still sees its own | **Video** |
| 9 | Invalid input: amount empty / `0` / no category; paste `-5`, `1,5`, `1.5`, letters, 13 digits | Inline errors for invalid saved fields; invalid pastes leave old amount unchanged; nothing invalid saved | Screenshots |
| 10 | N/A for SQLite: assignment explicitly limits connection-failure tests to Firebase or RESTful API implementations | State the confirmed assignment scope in the report; SQLite error handling is evidenced separately | Report text |
| Extra | Search `an uong` finds `Ăn uống`; combined search + type + category filter | Correct results | Screenshots |
| Extra | After logout use Back/Alt+Left | Cannot return to Home | Video |
| Extra | Click Save rapidly twice | Exactly one transaction is inserted | Video and/or Tier B test |
| Extra | Release build opens the database | App reaches Login from the built `.exe` | Screenshot |
| Extra | Open date picker with Windows display language English | Picker buttons/labels remain Vietnamese | Screenshot |
| Extra (Tier B) | SQLite write failure; write succeeds but refresh fails | Generic storage error without a new row; form closes once with a refresh warning, no duplicate row | Test output |
| Optional | Budget alert (M8), CSV export with correct Vietnamese (M10) | Works only once the corresponding feature is implemented | Screenshots |
| Optional | Run once on an Android emulator if available | Login, CRUD, restart persistence work | Screenshot/note |

The form defaults its date to today, so a missing-date case belongs in validator tests rather than requiring an unreachable empty date in the manual UI flow.

Create `TEST_RESULTS.md` with this table plus `Result` and `Evidence link/file` columns. Allowed results: `Chưa chạy`, `Pass`, `Fail`, `N/A`. Default executable cases to `Chưa chạy`; test 10 is `N/A` because the owner has checked the assignment's Firebase/REST condition. Mark unfinished optional cases `N/A` with their milestone noted. Never prefill `Pass` from an expected result; only record it after an actual run, distinguishing automated output from human-captured evidence.

---

## 17. Implementation order (milestones with Definition of Done)

Mandatory functionality = **M0–M6**. Complete **M6-DOC immediately after M6** to produce a submission-ready baseline. Do not start M7+ until M6's DoD passes and the baseline documents are present. Manual results without executed evidence remain `Chưa chạy`, and a manual DoD remains unverified until that evidence exists.

### 17.1 Tiers (scope control — read first)

| Tier | Contents | Rule |
|---|---|---|
| **A — required in M0–M6** | Desktop FFI init + stable DB path; schema with CHECK bounds; per-user SQL predicates; `_epoch` + silent `setUser` + microtask notify; `SaveResult` (ok / not ok, optional message); whole-edit amount formatter; `RequireAuth` on every protected route with single-redirect logout; `BootstrapApp` with loading screen in its own `MaterialApp`; Vietnamese localization; `ResponsiveBody`; Tier A tests; M6-DOC documents | Must be done before M6 is considered finished |
| **B — hardening, after M6-DOC** | `needsRefresh` flag + `Thử tải lại` UI; bootstrap `Thử lại` button; session expiry/clock tests; `session_storage_test`, `auth_provider_test`, `database_error_test`, `transaction_form_test`; extra post-commit warning paths | Only if time remains; record in REPORT only what is actually implemented |
| **C — optional features** | M7 month dashboard, M8 budget, M9 register, M10 CSV | After M6-DOC; each hides its entry points until done |

If time is short, stop after **M6 + M6-DOC**. Do not start any Tier B/C item while a Tier A item is unfinished.

| # | Milestone | Work | DoD |
|---|---|---|---|
| M0 | Setup | Add Windows/Android platform folders, install packages, SDK localization, folders, theme, routes skeleton, `platform_utils`, `main.dart` FFI init, `BootstrapApp` loading skeleton with its own `MaterialApp` | `flutter run -d windows` shows the Vietnamese-configured loading/Splash screen |
| M1 | Data layer | `AppDatabase` (platform path, schema with bounds/FK/seed), models, hasher, repositories, session storage, `AppException`; wire real DB bootstrap | Tier A repository/isolation/totals/bounds tests pass; **release `.exe` opens the DB** (or `sqlite3.dll` step documented) |
| M2 | Auth (F1) | `AuthProvider` (incl. read-failure handling), Splash/AuthGate, Login (Enter submits), logout via `RequireAuth`, `RequireAuth` on every protected route | Tests 1–4 pass; Back/direct protected routes blocked without auth; logout redirects once |
| M3 | CRUD (F2) | Shared form, List, Detail, delete confirm, provider with epoch guards + silent `setUser`, `SaveResult`, validators, whole-edit amount formatter, `_isSaving` guard | Tests 5, 7, 9 pass; invalid paste preserves amount; no "notifyListeners during build" error on login/logout |
| M4 | Summary (F3) | Dashboard three all-time cards via SQL totals | Test 6 passes (also after editing from Detail) |
| M5 | Search/filter/sort (F4) | Search with precomposed/combining Vietnamese, type/category filter (AND), mandatory sorting, FilterBar, debounce | Vietnamese search works; filters persist across tabs; reset on user change; all four sort options work |
| M6 | Hardening (F5, F6) | Isolation verification, empty/loading states, error handling pass, widget extraction, `ResponsiveBody` everywhere, `flutter analyze` clean, Tier A tests green | Test 8 passes both directions; no console errors; Tier A items of Section 14 ticked |
| M6-DOC | Submission documents and evidence | README, REPORT, TEST_RESULTS, SCREENSHOTS, DEMO_SCRIPT for the mandatory baseline | Section 18 baseline files present; executed tests have results/evidence; outstanding human captures remain `Chưa chạy`; optional features are not claimed as implemented |
| M6-B | Tier B hardening (optional) | Items listed in Section 17.1 Tier B | Only checked off items are claimed in REPORT |
| M7 | Month dashboard | `MonthSelector`, month totals, `CategoryBreakdown` | Month stats change with selector; all-time cards unchanged |
| M8 | Budget | BudgetScreen/Progress, update-then-insert upsert in one transaction, pure alert calculator; expose budget entry points | Alert only when level increases; upsert keeps ID; bounds enforced; docs/evidence updated |
| M9 | Register | RegisterScreen, uniqueness check; expose registration link | New account can log in with an empty list; docs/evidence updated |
| M10 | CSV export | Pure CSV builder, provider user-scoped read, desktop save-to-Downloads (+ `share_plus` on Android); expose CSV menu | File opens correctly in Vietnamese; user/epoch guards hold; docs/evidence updated |

---

## 18. Deliverables the AI must generate

Generate the mandatory baseline documents at M6-DOC before optional work, and update them at M6-B/M7–M10 only for features actually implemented. Generate document templates even when human evidence is pending; never fabricate screenshots, videos, executed results, or a completed manual DoD.

1. Full Flutter source code (`lib/`, `test/`, `pubspec.yaml`, including `windows/` and `android/` platform folders).
2. `README.md`: project overview, **Windows setup (Section 2.2: Visual Studio C++ workload, Developer Mode, `flutter run -d windows`, release build and the `sqlite3.dll` fallback, DB file location and how to reset it)**, Android run notes, **demo accounts**, feature list, folder structure, how to run tests.
3. `REPORT.md` (brief report for submission): implemented features; **primary platform Windows desktop via `sqflite_common_ffi`, Android supported by the same code (state honestly whether Android was actually tested)**; why SQLite was chosen; architecture/layers; Locked Decisions; per-user SQL predicates + epoch isolation; `SaveResult` and post-commit read warnings; known limitations (no password recovery, local-only data, session age checked at restoration). Test 10 is N/A because the owner verified that the assignment says "For Firebase or RESTful API implementations, test connection failures..."; include separate SQLite error-handling evidence. Keep salted SHA-256 for this PE and explicitly document that it is a fast hash, not production-grade password storage, and that local session flags/per-user filtering do not protect a compromised local DB/preferences. Do not implement PBKDF2 or add a hashing package in this scope.
4. `TEST_RESULTS.md`: Section 16 table with expected results and actual Result/Evidence columns, defaulting to `Chưa chạy` except justified N/A cases; the human adds captures.
5. `SCREENSHOTS.md`: mandatory screens to capture (Login, Dashboard, List, Add, Edit, Detail, filtered list); append month section, Budget, and CSV only when implemented.
6. `DEMO_SCRIPT.md`: a step-by-step script for the demo video: login → close app completely → auto-login → add/edit/delete → verify totals → logout → close app completely → login required → login `demo2` (no data) → login `demo1` (data present).

---

## 19. Common pitfalls (read before coding)

1. Naming a model `Transaction` → conflicts with `sqflite`. Use `FinanceTransaction`.
2. Forgetting `WidgetsFlutterBinding.ensureInitialized()` before DB/prefs in `main()`.
3. Using SQLite `LOWER()`/`LIKE` for Vietnamese search → breaks on diacritics. Filter in Dart with `normalizeVi`.
4. Parsing amounts with `double.parse`, or stripping invalid pasted characters → wrong amounts. Use the whole-edit formatter and `int.tryParse`.
5. Forgetting `user_id` in `UPDATE`/`DELETE` → one user can modify another user's data.
6. Clearing state without invalidating pending work → late results can leak between accounts. Use `setUser` + `_epoch`, including catch/finally and UI effects.
7. Using `pushNamed` (not `pushNamedAndRemoveUntil`) after login/redirect → Back returns to a stale screen.
8. Detail screen holding a copy of the transaction → stale after edit. Read from the provider by id.
9. Changing the schema while an old DB exists → close the app and delete the old DB file (desktop) / uninstall (Android), or bump `_dbVersion` and add `onUpgrade`.
10. Date stored with time or timezone → month filters and sorting break. Always `yyyy-MM-dd`.
11. Changing type in the form but keeping the old category → invalid category for the new type. Reset it.
12. `sqflite` on Flutter **web** → not supported. Use Windows (or Android).
13. Showing raw exception text to users → always use `AppException.message`.
14. Leaving the new-user username with uppercase letters → duplicate-check bugs. Always lowercase.
15. Treating `BudgetAlert? == null` as save failure/success → ambiguous. Use `SaveResult.ok`; refresh failure after commit is a read warning.
16. Showing optional links before their screens work, or delaying all docs until after optional features → incomplete mandatory baseline. Complete M6-DOC before M7 and hide unfinished entry points.
17. Using `ON CONFLICT ... DO UPDATE` on an older SQLite, or REPLACE while assuming it preserves a budget row → use UPDATE then conditional INSERT inside one transaction.
18. Initializing a new bootstrap Future on every build → repeated DB opens. Cache it and replace it only on explicit retry.
19. **Calling `notifyListeners()` (or starting a `refresh()` that notifies) synchronously inside `setUser`** → "setState/markNeedsBuild called during build" on every login/logout. Clear silently, defer with `scheduleMicrotask`.
20. **Putting the loading/error screen outside any `MaterialApp`** → missing `Directionality`/theme errors. Wrap bootstrap screens in a minimal `MaterialApp`.
21. **Forgetting to set `databaseFactory = databaseFactoryFfi` before the first database call on Windows** → `databaseFactory not initialized` errors. Do it in `main()` before `runApp`.
22. **Using the FFI default `getDatabasesPath()` for the real DB** → the database path changes between `flutter run` and the built `.exe`, so data seems to vanish. Use the application support directory (Section 5.2).
23. **Testing persistence with hot restart** → not a real restart. Close the window / end the process, then relaunch.
24. **Release build cannot load `sqlite3.dll`** → test a release `.exe` at M1 and copy the DLL next to the executable if needed.
25. **`flutter pub add` fails or the build fails with a symlink error** → enable Windows Developer Mode.
26. Both `logout()` and `RequireAuth` navigating to Login → double navigation. Only `RequireAuth` (when its route `isCurrent`) redirects.
27. Using real SQLite I/O inside a widget test → hangs under the fake clock. Use a fake repository (or `tester.runAsync`).

---

## 20. Final acceptance checklist

**Tier A (must be true at M6-DOC):**
- [ ] `flutter run -d windows`: log in with `demo1`, add data, close the app completely, reopen → still logged in, data present.
- [ ] The built release `.exe` also opens the database and reaches Login.
- [ ] Logout, close the app completely, reopen → Login screen; Back after logout cannot reach Home.
- [ ] `demo2` cannot see `demo1`'s data, and vice versa.
- [ ] No "notifyListeners during build" error when logging in/out or switching accounts.
- [ ] Amount `0`/empty rejected; invalid signed/decimal/overlong pastes preserve old input; category/date required.
- [ ] DB money/budget upper bounds enforced; wrong-type categories rejected; updates preserve user_id/created_at.
- [ ] `SaveResult` distinguishes write failure from post-commit refresh warning; save handler is guarded against repeated clicks.
- [ ] Every protected route uses `RequireAuth`; logout redirects exactly once.
- [ ] Delete always asks for confirmation (Cancel is the default).
- [ ] Income, Expense, Balance correct after add, edit (type and amount changes), delete.
- [ ] Search handles precomposed/combining Vietnamese; combined filters and all four sort options work.
- [ ] Material date picker is Vietnamese; layout has no overflow at 360×640 and at ~1280×720.
- [ ] `flutter analyze` has no issues; Tier A `flutter test` passes.
- [ ] README (incl. Windows setup), REPORT, TEST_RESULTS, SCREENSHOTS, DEMO_SCRIPT present at M6-DOC; unexecuted tests stay `Chưa chạy`.
- [ ] Test 10 is N/A with the confirmed Firebase/REST condition; separate SQLite error-handling evidence exists.

**Tier B / C (only if implemented):**
- [ ] Old-epoch async completions cannot restore previous-user state or trigger messages/navigation (test exists).
- [ ] Missing-key, future-timestamp, and exact-7-day session restoration cases are rejected (tests exist).
- [ ] Startup DB failure offers `Thử lại` without resetting data.
- [ ] Rapid repeated Save clicks insert one row (automated test).
- [ ] Optional entry points remain hidden until implemented; optional docs/evidence are updated per milestone.
