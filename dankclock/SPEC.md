# Spec: DankClock Application

## 1. Objective
Xây dựng **DankClock** — một ứng dụng đồng hồ để bàn độc lập (Desktop Clock) trong hệ sinh thái DankApps dành cho Linux (chạy trên môi trường Quickshell và tích hợp sâu với DankMaterialShell/Dux Shell). 
Ứng dụng cung cấp 5 module chính:
1. **Alarms**: Quản lý báo thức dạng thẻ lưới thích ứng (Responsive Card Grid), tích hợp banner **Incoming Alarm** riêng biệt ở trên cùng và FAB chuyển đổi chế độ Edit / Done.
2. **Clock (World Clock & Local Time)**: Hợp nhất đồng hồ số (Digital) và mặt kim hoa Material You (Organic Blob Analog) trong một layout gọn gàng, hiển thị múi giờ địa phương và các thành phố quốc tế với độ lệch giờ trực quan. Hỗ trợ hiển thị kim giờ đa múi giờ và kéo thả danh sách.
3. **Timers**: Quản lý các bộ đếm ngược thời gian tùy chỉnh và preset tiện lợi.
4. **Pomodoro**: Không gian tập trung chuyên biệt (25 phút tập trung / 5 phút nghỉ ngắn / 15 phút nghỉ dài) với bộ đếm chu kỳ và âm báo hoàn thành.
5. **Stopwatch**: Đồng hồ bấm giờ chuẩn xác cao kèm ghi nhận vòng (Laps), thống kê Best/Worst lap.

---

## 2. Tech Stack & Architecture
- **Launcher Core**: Go (`cmd/dclock/main.go`), binary siêu nhẹ (~4 MB), quản lý nạp phông chữ, biến môi trường và kích hoạt Quickshell process.
- **Frontend / UI**: QML (Qt 6.x) chạy trên nền engine [Quickshell](https://quickshell.outfoxxed.me/).
- **Design System**: Material 3 / Material You Expressive với hệ thống token từ `dank-qml-common` (hỗ trợ Dark/Light, dynamic palette, shape roundness, typography, state layers và elevation shadows).
- **State & Storage**: File JSON lưu tại `~/.config/dankclock/` (`state.json` cho dữ liệu alarm/timer/worldclocks; `ui-settings.json` cho cấu hình hiển thị giao diện).

---

## 3. Commands
- **Dev build**: `make -C dankclock dev`
- **Chạy ứng dụng từ mã nguồn**: `make -C dankclock run` (hoặc mở trực tiếp tab: `dclock -tab alarm`)
- **Cài đặt cho người dùng (User-level)**: `make -C dankclock install-user` (cài vào `~/.local/bin/dclock` và `~/.local/share/quickshell/dankclock`)
- **Gỡ cài đặt**: `make -C dankclock uninstall-user`
- **Kiểm tra cú pháp / format Go**: `make -C dankclock fmt` và `make -C dankclock vet`

---

## 4. Project Structure
```
dankclock/
├── Makefile                          # Build & install targets
├── README.md                         # Tài liệu hướng dẫn sử dụng & phím tắt
├── assets/                           # Icon SVG, hình ảnh minh họa
│   └── com.danklinux.dankclock.svg
├── distro/                           # File desktop entry (.desktop)
│   └── com.danklinux.dankclock.desktop
├── core/                             # Mã nguồn Go launcher
│   ├── cmd/dclock/main.go            # Entry point binary
│   ├── internal/theme/font.go        # Quản lý font hệ thống
│   ├── go.mod
│   └── Makefile
├── quickshell/                       # Toàn bộ mã nguồn giao diện QML
│   ├── shell.qml                     # Root Quickshell entry
│   ├── Common/
│   │   ├── ClockMetrics.qml          # Kích thước, padding, gap, radius hằng số
│   │   ├── Paths.qml                 # Đường dẫn thư mục config/state
│   │   ├── SettingsData.qml          # Binding cài đặt người dùng
│   │   ├── Theme.qml                 # Theme tokens fallback
│   │   └── StockTheme.js
│   ├── Services/
│   │   └── ClockService.qml          # Singleton quản lý thời gian, timer tick, báo thức, múi giờ
│   ├── Modules/Clock/
│   │   ├── ClockWindow.qml           # Cửa sổ chính, Navigation Rail bên trái, hotkeys
│   │   ├── AlarmView.qml             # Tab 1: Alarms (Incoming banner + Grid cards + FAB)
│   │   ├── WorldClockView.qml        # Tab 2: Clock (Hero card + Multi-hands + DnD World clocks)
│   │   ├── TimerView.qml             # Tab 3: Timers
│   │   ├── PomodoroView.qml          # Tab 4: Pomodoro (Focus / Break / Cycle stats)
│   │   ├── StopwatchView.qml         # Tab 5: Stopwatch
│   │   ├── ClockRow.qml              # Component hàng đồng hồ cơ sở
│   │   ├── ClockGroup.qml            # Container bo góc danh sách
│   │   ├── ClockSectionLabel.qml     # Tiêu đề nhóm + action buttons
│   │   └── ClockSettingsModal.qml    # Modal cài đặt chung
│   └── DCommon -> ../../dankview/dank-qml-common/DCommon
└── dank-qml-common -> ../dankview/dank-qml-common
```

---

## 5. UI/UX & Functional Specifications

### 5.1. Navigation & App Shell
- Cửa sổ nổi (`FloatingWindow`) kích thước mặc định $520 \times 680$ px (co giãn linh hoạt, min $420 \times 520$ px).
- Thanh điều hướng đứng (`DNavigationBar` dạng vertical rail) bên trái gồm 5 tab chính:
  1. **Alarms** (`alarm`, index 0, phím tắt `Ctrl+1`)
  2. **Clock** (`public`, index 1, phím tắt `Ctrl+2`)
  3. **Timers** (`hourglass_empty`, index 2, phím tắt `Ctrl+3`)
  4. **Pomodoro** (`psychology` / `nest_clock_farsight_analog`, index 3, phím tắt `Ctrl+4`)
  5. **Stopwatch** (`timer`, index 4, phím tắt `Ctrl+5`)
  - Đáy sidebar: nút **Settings** (`settings`, mở modal cài đặt).

### 5.2. Tab Alarms & Sound Notification
- **Âm thanh thông báo (Tối ưu Wayland / PipeWire)**:
  - Sử dụng **`pw-play`** (PipeWire native audio player tiêu chuẩn trên Linux/Wayland hiện đại, fallback sang `canberra-gtk-play` / `paplay` nếu không có PipeWire).
  - Kết hợp với gửi desktop notification qua `notify-send` khi báo thức hoặc timer hoàn tất.
- **Banner Incoming Alarm (trên cùng)**:
  - Chỉ hiển thị khi có báo thức sắp diễn ra.
  - Tự động tính toán mốc giờ kế tiếp dựa theo thứ trong tuần, hiển thị thời gian còn lại (VD: `in 25 min`, `in 3 hr 15 min`).
  - Có nút tắt nhanh (`alarm_off`) để hủy phiên báo thức kế tiếp nếu người dùng muốn.
- **Lưới báo thức thích ứng (Adaptive Grid)**:
  - Tự động co giãn số cột dựa theo chiều rộng khả dụng: $\text{columns} = \max(1, \lfloor(\text{width} + \text{gap}) / (\text{minWidth} + \text{gap})\rfloor)$ với `minWidth = 260px`.
  - Mỗi thẻ Alarm:
    - **Hàng 1**: Giờ to rõ (~38px bold), chạm vào mở `DTimePicker`. Bên phải là công tắc `DToggle` (hoặc nút xóa `delete_outline` khi ở Edit mode).
    - **Hàng 2**: Nhãn báo thức (`label`), chạm vào mở dialog sửa tên.
    - **Hàng 3**: 7 ngày lặp lại `S M T W T F S` (Chủ Nhật đến Thứ Bảy). Ngày được chọn nằm trong vòng tròn sáng chữ đậm, ngày không chọn là chữ mờ.
- **Nút FAB góc dưới phải**:
  - Bình thường: FAB hiển thị icon `edit` để vào chế độ chỉnh sửa (ẩn toggle, hiện nút xóa).
  - Khi đang ở Edit mode: FAB chuyển thành icon `check` (Done) để hoàn tất, đồng thời bên cạnh xuất hiện nút phụ `+` (`add_alarm`) để thêm báo thức mới.

### 5.3. Tab Clock (World Clock with Multi-Timezone Hands & Drag-and-Drop)
- Hợp nhất hiển thị Digital + Analog (bỏ hoàn toàn tùy chọn chuyển đổi Digital/Analog trong Settings):
  - **Hero Local Clock**: Card lớn phía trên thể hiện vị trí địa phương: Tên thành phố (`Ho Chi Minh City`), ngày tháng đầy đủ, giờ số to bên trái và mặt đồng hồ kim hoa Organic Blob 12 cánh (`DAnalogClock`) bên phải.
  - **Mặt đồng hồ kim đa múi giờ (Multi-Timezone Hands)**:
    - Trên mặt đồng hồ chính, ngoài kim giờ & phút của giờ địa phương, **xuất hiện thêm các kim chỉ giờ tương ứng với các thành phố World Clock** được ghim bên dưới.
    - Mỗi kim giờ phụ có màu trùng khớp với màu accent đại diện cho thành phố đó (xanh dương cho Tokyo, xanh lá cho London, tím cho New York, hồng cho Cairo,...), giúp người dùng dễ dàng so sánh vị trí thời gian của các thành phố trực quan trong nháy mắt.
  - **World Clocks List & Kéo thả (Drag-and-Drop Reordering)**:
    - Danh sách các thành phố quốc tế hiển thị dưới dạng các card riêng biệt (hoặc hàng danh sách).
    - Hỗ trợ **kéo và thả (Drag and Drop)** trực tiếp trên danh sách để sắp xếp thứ tự ưu tiên các thành phố một cách mượt mà và trực quan, kèm nút thêm thành phố mới (`Add City`).

### 5.4. Tab Timers, Pomodoro & Stopwatch
- **Timers**: Quản lý nhiều timer đồng thời (5 min, 15 min, 1 hr,...), hỗ trợ tạm dừng, tiếp tục, làm mới (`reset`) và tạo timer tùy biến giờ/phút/giây.
- **Pomodoro (Không gian làm việc & tập trung)**:
  - Phân tách riêng biệt với Timer thông thường.
  - Ba chế độ chính: **Focus (25m)**, **Short Break (5m)**, **Long Break (15m)**.
  - Đếm chu kỳ Pomodoro (đạt 4 chu kỳ chuyển sang Long Break), vòng tiến trình tròn trực quan, nút Start/Pause/Skip/Reset và phát âm thanh chuông nhẹ qua `pw-play` khi đổi pha.
- **Stopwatch**: Bấm giờ chạy ở tần số ~60fps, ghi nhận từng Lap, tự động đánh dấu vòng nhanh nhất (Best Lap - xanh) và chậm nhất (Worst Lap - cam/đỏ). Phím tắt: `Space` (Start/Stop), `L` (Lap), `R` (Reset).

---

## 6. Code Style & Conventions
- **QML Component Behavior**: Luôn khai báo `pragma ComponentBehavior: Bound` ở đầu file.
- **StateLayer API**: Dùng `cornerRadius` (thay vì `radius`) khi gắn cho hình chữ nhật bo góc, gán `control` hoặc dùng trực tiếp `onClicked`.
- **DNavigationBar**: Gán thuộc tính `labelFontSize: Theme.fontSizeMedium`.
- **Không hardcode màu sắc**: Sử dụng biến hệ thống `Theme.*` hoặc `Style.*` (`Theme.surfaceContainerHigh`, `Theme.primaryContainer`, `Theme.onPrimaryContainer`, `Theme.outlineMedium`,...).

---

## 7. Boundaries & Rules
- **Luôn luôn**:
  - Kiểm tra chạy thử thực tế (`dclock`) trước khi bàn giao để đảm bảo không có lỗi QML runtime hay thuộc tính không tồn tại.
  - Cập nhật và chạy `make install-user` sau mỗi lần chỉnh sửa mã nguồn.
- **Hỏi trước**:
  - Khi muốn thay đổi cấu trúc lưu trữ `state.json` hoặc bổ sung dependency mới vào Go launcher.
- **Tuyệt đối không**:
  - Không hardcode các đường dẫn tuyệt đối tĩnh (dùng `Paths.qml` hoặc biến môi trường `HOME`).
  - Không phá vỡ tương thích với các widget chung trong `dank-qml-common`.

---

## 8. Success Criteria (Tiêu chí nghiệm thu)
1. Lệnh `make dev` và `make install-user` thực thi thành công không có lỗi build Go hay Makefile.
2. Khởi chạy `dclock` qua terminal mở đúng cửa sổ, không ném exception trong log.
3. Tab **Alarms** đứng đầu danh sách (`Ctrl+1`), hiển thị thẻ **Incoming Alarm** riêng biệt khi có báo thức sắp tới. Chuông reo sử dụng cơ chế phát qua `pw-play` (PipeWire).
4. Lưới thẻ báo thức co giãn linh hoạt theo chiều rộng cửa sổ. Bấm FAB `edit` chuyển sang chế độ edit và ẩn/hiện nút xóa.
5. Tab **Clock** hiển thị kết hợp cả đồng hồ số và mặt kim hoa Organic Blob; trên mặt đồng hồ chính xuất hiện các kim chỉ giờ có màu sắc tương ứng với các thành phố World Clock; danh sách World Clock hỗ trợ thao tác kéo thả (drag & drop) mượt mà.
