pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common

Singleton {
    id: root

    property int currentTabIndex: 0
    property var now: new Date()

    // Modal / Sheet states
    property bool citySheetOpen: false
    property bool worldClockEditMode: false
    property bool alarmEditMode: false
    property bool timerEditMode: false
    property bool pomodoroEditMode: false
    property bool settingsOpen: false
    property int settingsTabIndex: 0
    property bool timePickerOpen: false
    property int editingAlarmIndex: -1
    property bool labelDialogOpen: false
    property int editingLabelAlarmIndex: -1
    property bool timerSetupMode: false

    // Active ringing notification state & queue
    property var ringingAlert: null // { type: "alarm" | "timer" | "pomodoro", title: "", subtitle: "", alarmIndex: -1, timerId: -1, soundId: "classic", snoozeMin: 5 }
    property var _alertQueue: []

    // Monotonic elapsed clock (ms) driven by Qt's FrameAnimation / steady timer so NTP/clock jumps never corrupt elapsed time
    property double _monoNowMs: 0
    FrameAnimation {
        id: monoClock
        running: root.anyTimerRunning || root.pomodoroRunning || root.stopwatchRunning
        onTriggered: {
            root._monoNowMs += frameTime * 1000;
        }
    }

    readonly property string stateFilePath: SettingsData.configDir + "/state.json"

    // Default World Clocks
    property var worldClocks: [
        { city: "Tokyo", country: "Japan", tz: "Asia/Tokyo", offsetMin: 540 },
        { city: "London", country: "United Kingdom", tz: "Europe/London", offsetMin: 0 },
        { city: "New York", country: "United States", tz: "America/New_York", offsetMin: -300 }
    ]

    // Catalog of World Cities for Search
    readonly property var cityCatalog: [
        { city: "Ho Chi Minh City", code: "SGN", country: "Vietnam", tz: "Asia/Ho_Chi_Minh", offsetMin: 420 },
        { city: "Hanoi", code: "HAN", country: "Vietnam", tz: "Asia/Ho_Chi_Minh", offsetMin: 420 },
        { city: "Bangkok", code: "BKK", country: "Thailand", tz: "Asia/Bangkok", offsetMin: 420 },
        { city: "Singapore", code: "SIN", country: "Singapore", tz: "Asia/Singapore", offsetMin: 480 },
        { city: "Tokyo", code: "TYO", country: "Japan", tz: "Asia/Tokyo", offsetMin: 540 },
        { city: "Seoul", code: "SEL", country: "South Korea", tz: "Asia/Seoul", offsetMin: 540 },
        { city: "Taipei", code: "TPE", country: "Taiwan", tz: "Asia/Taipei", offsetMin: 480 },
        { city: "Hong Kong", code: "HKG", country: "China", tz: "Asia/Hong_Kong", offsetMin: 480 },
        { city: "Shanghai", code: "SHA", country: "China", tz: "Asia/Shanghai", offsetMin: 480 },
        { city: "Manila", code: "MNL", country: "Philippines", tz: "Asia/Manila", offsetMin: 480 },
        { city: "Jakarta", code: "JKT", country: "Indonesia", tz: "Asia/Jakarta", offsetMin: 420 },
        { city: "Kuala Lumpur", code: "KUL", country: "Malaysia", tz: "Asia/Kuala_Lumpur", offsetMin: 480 },
        { city: "New Delhi", code: "DEL", country: "India", tz: "Asia/Kolkata", offsetMin: 330 },
        { city: "Mumbai", code: "BOM", country: "India", tz: "Asia/Kolkata", offsetMin: 330 },
        { city: "Dubai", code: "DXB", country: "United Arab Emirates", tz: "Asia/Dubai", offsetMin: 240 },
        { city: "Sydney", code: "SYD", country: "Australia", tz: "Australia/Sydney", offsetMin: 600 },
        { city: "Melbourne", code: "MEL", country: "Australia", tz: "Australia/Melbourne", offsetMin: 600 },
        { city: "Auckland", code: "AKL", country: "New Zealand", tz: "Pacific/Auckland", offsetMin: 720 },
        { city: "London", code: "LON", country: "United Kingdom", tz: "Europe/London", offsetMin: 0 },
        { city: "Paris", code: "PAR", country: "France", tz: "Europe/Paris", offsetMin: 60 },
        { city: "Berlin", code: "BER", country: "Germany", tz: "Europe/Berlin", offsetMin: 60 },
        { city: "Amsterdam", code: "AMS", country: "Netherlands", tz: "Europe/Amsterdam", offsetMin: 60 },
        { city: "Zurich", code: "ZRH", country: "Switzerland", tz: "Europe/Zurich", offsetMin: 60 },
        { city: "Madrid", code: "MAD", country: "Spain", tz: "Europe/Madrid", offsetMin: 60 },
        { city: "Rome", code: "ROM", country: "Italy", tz: "Europe/Rome", offsetMin: 60 },
        { city: "Stockholm", code: "STO", country: "Sweden", tz: "Europe/Stockholm", offsetMin: 60 },
        { city: "Warsaw", code: "WAW", country: "Poland", tz: "Europe/Warsaw", offsetMin: 60 },
        { city: "Athens", code: "ATH", country: "Greece", tz: "Europe/Athens", offsetMin: 120 },
        { city: "Istanbul", code: "IST", country: "Turkey", tz: "Europe/Istanbul", offsetMin: 180 },
        { city: "Cairo", code: "CAI", country: "Egypt", tz: "Africa/Cairo", offsetMin: 120 },
        { city: "Johannesburg", code: "JNB", country: "South Africa", tz: "Africa/Johannesburg", offsetMin: 120 },
        { city: "Moscow", code: "MOW", country: "Russia", tz: "Europe/Moscow", offsetMin: 180 },
        { city: "New York", code: "NYC", country: "United States", tz: "America/New_York", offsetMin: -300 },
        { city: "Chicago", code: "CHI", country: "United States", tz: "America/Chicago", offsetMin: -360 },
        { city: "Denver", code: "DEN", country: "United States", tz: "America/Denver", offsetMin: -420 },
        { city: "Los Angeles", code: "LAX", country: "United States", tz: "America/Los_Angeles", offsetMin: -480 },
        { city: "San Francisco", code: "SFO", country: "United States", tz: "America/Los_Angeles", offsetMin: -480 },
        { city: "Seattle", code: "SEA", country: "United States", tz: "America/Los_Angeles", offsetMin: -480 },
        { city: "Toronto", code: "YTO", country: "Canada", tz: "America/Toronto", offsetMin: -300 },
        { city: "Vancouver", code: "YVR", country: "Canada", tz: "America/Vancouver", offsetMin: -480 },
        { city: "Mexico City", code: "MEX", country: "Mexico", tz: "America/Mexico_City", offsetMin: -360 },
        { city: "Sao Paulo", code: "SAO", country: "Brazil", tz: "America/Sao_Paulo", offsetMin: -180 },
        { city: "Buenos Aires", code: "BUE", country: "Argentina", tz: "America/Argentina/Buenos_Aires", offsetMin: -180 },
        { city: "Honolulu", code: "HNL", country: "United States", tz: "Pacific/Honolulu", offsetMin: -600 }
    ]

    // Alarms: [{ hour: 7, minute: 0, label: "Wake Up", enabled: true, days: ["Mon", ...], soundId: "classic", snoozeMin: 10, deleteAfterGoesOff: false, skippedDateKey: "" }]
    property int alarmRevision: 0
    property int expandedAlarmIndex: -1
    readonly property var alarmSounds: [
        { id: "classic", name: "Classic Bell", icon: "notifications_active", path: "/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga" },
        { id: "chime", name: "Bright Chime", icon: "music_note", path: "/usr/share/sounds/freedesktop/stereo/complete.oga" },
        { id: "gentle", name: "Gentle Pulse", icon: "waves", path: "/usr/share/sounds/freedesktop/stereo/message-new-instant.oga" },
        { id: "silent", name: "Silent (Visual Only)", icon: "notifications_off", path: "" }
    ]
    readonly property var snoozeOptions: [5, 10, 15, 30]
    property var alarms: [
        { hour: 7, minute: 0, label: "Morning Alarm", enabled: true, days: ["Mon", "Tue", "Wed", "Thu", "Fri"], soundId: "classic", snoozeMin: 10, deleteAfterGoesOff: false, skippedDateKey: "" },
        { hour: 8, minute: 30, label: "Daily Standup", enabled: false, days: ["Mon", "Tue", "Wed", "Thu", "Fri"], soundId: "chime", snoozeMin: 5, deleteAfterGoesOff: false, skippedDateKey: "" }
    ]

    readonly property var weekDays: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    property string _lastTriggeredMinuteKey: ""

    // Timer Setup Steppers
    property int setupHours: 0
    property int setupMinutes: 5
    property int setupSeconds: 0

    // Active / Saved Timers
    property int _nextTimerId: 4
    property int activeTimerIndex: 0
    property int timerTickRevision: 0
    property var timers: [
        { id: 1, label: "Focus / Pomodoro", totalMs: 25 * 60 * 1000, remainingMs: 25 * 60 * 1000, running: false, finished: false },
        { id: 2, label: "Short Break", totalMs: 5 * 60 * 1000, remainingMs: 5 * 60 * 1000, running: false, finished: false },
        { id: 3, label: "Tea Steep", totalMs: 3 * 60 * 1000, remainingMs: 3 * 60 * 1000, running: false, finished: false }
    ]
    property double _lastTimerTickMs: -1

    readonly property bool anyTimerRunning: {
        void timerTickRevision;
        for (let i = 0; i < timers.length; i++) {
            if (timers[i].running)
                return true;
        }
        return false;
    }

    // Pomodoro State
    property string pomodoroPhase: "focus" // "focus" | "shortBreak" | "longBreak"
    property bool pomodoroRunning: false
    property int pomodoroCyclesCompleted: 0
    property int pomodoroStatsRevision: 0
    property double _accumulatedFocusSec: 0
    property var pomodoroHistory: [] // [{ date: "YYYY-MM-DD", hour: 9, minutes: 25 }]
    readonly property int pomodoroTargetCycles: Math.max(1, SettingsData.pomodoroTargetCycles || 4)
    readonly property int pomodoroFocusDuration: Math.max(1, SettingsData.pomodoroFocusMinutes || 25) * 60
    readonly property int pomodoroShortBreakDuration: Math.max(1, SettingsData.pomodoroShortBreakMinutes || 5) * 60
    readonly property int pomodoroLongBreakDuration: Math.max(1, SettingsData.pomodoroLongBreakMinutes || 15) * 60
    property double pomodoroRemainingSeconds: 25 * 60
    property double _lastPomoTickMs: -1

    function _ensureDefaultPomodoroHistory() {
        if (!Array.isArray(pomodoroHistory))
            pomodoroHistory = [];
    }

    function recordPomodoroFocusMinutes(mins) {
        if (!root._stateReady)
            return;
        const m = Math.round(mins);
        if (m <= 0)
            return;
        const cur = root.now || new Date();
        const dKey = _dateKey(cur);
        const hr = cur.getHours();
        const next = Array.isArray(pomodoroHistory) ? pomodoroHistory.slice() : [];
        let found = false;
        for (let i = 0; i < next.length; i++) {
            if (next[i].date === dKey && next[i].hour === hr) {
                next[i] = { date: dKey, hour: hr, minutes: (next[i].minutes || 0) + m };
                found = true;
                break;
            }
        }
        if (!found)
            next.push({ date: dKey, hour: hr, minutes: m });
        pomodoroHistory = next;
        pomodoroStatsRevision++;
        saveState();
    }

    function formatFocusMinutes(mins) {
        const m = Math.max(0, Math.round(mins));
        if (m === 0)
            return "0m";
        const h = Math.floor(m / 60);
        const rem = m % 60;
        if (h > 0 && rem > 0)
            return `${h}h ${rem}m`;
        if (h > 0)
            return `${h}h`;
        return `${rem}m`;
    }

    function getPomodoroStats(period) {
        void pomodoroStatsRevision;
        const cur = root.now || new Date();
        const todayKey = _dateKey(cur);
        const hist = Array.isArray(pomodoroHistory) ? pomodoroHistory : [];
        const focusSessionMins = Math.max(1, SettingsData.pomodoroFocusMinutes || 25);
        let bars = [];

        if (period === "day") {
            const curBlock = Math.floor(cur.getHours() / 3);
            for (let b = 0; b < 8; b++) {
                const startH = b * 3;
                let mins = 0;
                for (let i = 0; i < hist.length; i++) {
                    const item = hist[i];
                    if (item.date === todayKey && Math.floor((item.hour || 0) / 3) === b)
                        mins += (item.minutes || 0);
                }
                bars.push({
                    label: `${String(startH).padStart(2, "0")}h`,
                    sublabel: `${String(startH).padStart(2, "0")}:00–${String(startH + 3).padStart(2, "0")}:00`,
                    minutes: mins,
                    isCurrent: b === curBlock
                });
            }
        } else if (period === "week") {
            const jsDay = cur.getDay(); // 0=Sun..6=Sat
            const monOffset = (jsDay + 6) % 7;
            const dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
            for (let d = 0; d < 7; d++) {
                const dt = new Date(cur.getFullYear(), cur.getMonth(), cur.getDate() - monOffset + d);
                const dKey = _dateKey(dt);
                let mins = 0;
                for (let i = 0; i < hist.length; i++) {
                    if (hist[i].date === dKey)
                        mins += (hist[i].minutes || 0);
                }
                bars.push({
                    label: dayNames[d],
                    sublabel: Qt.formatDate(dt, "ddd, MMM d"),
                    minutes: mins,
                    isCurrent: dKey === todayKey
                });
            }
        } else {
            // "month": 10 buckets of 3 days across the last 30 days
            for (let g = 9; g >= 0; g--) {
                const endDt = new Date(cur.getFullYear(), cur.getMonth(), cur.getDate() - g * 3);
                const startDt = new Date(cur.getFullYear(), cur.getMonth(), cur.getDate() - g * 3 - 2);
                const keys = [
                    _dateKey(startDt),
                    _dateKey(new Date(cur.getFullYear(), cur.getMonth(), cur.getDate() - g * 3 - 1)),
                    _dateKey(endDt)
                ];
                let mins = 0;
                for (let i = 0; i < hist.length; i++) {
                    if (keys.indexOf(hist[i].date) >= 0)
                        mins += (hist[i].minutes || 0);
                }
                bars.push({
                    label: g === 0 ? "Now" : Qt.formatDate(endDt, "d/M"),
                    sublabel: `${Qt.formatDate(startDt, "MMM d")} – ${Qt.formatDate(endDt, "MMM d")}`,
                    minutes: mins,
                    isCurrent: g === 0
                });
            }
        }

        let totalMinutes = 0;
        let maxMinutes = 0;
        let peakLabel = "—";
        for (let i = 0; i < bars.length; i++) {
            totalMinutes += bars[i].minutes;
            if (bars[i].minutes > maxMinutes) {
                maxMinutes = bars[i].minutes;
                peakLabel = `${bars[i].label} (${formatFocusMinutes(bars[i].minutes)})`;
            }
        }
        const scaleMax = Math.max(focusSessionMins * 2, Math.ceil(maxMinutes / 25) * 25);
        const avgMinutes = bars.length > 0 ? Math.round(totalMinutes / bars.length) : 0;
        const totalSessions = Math.round(totalMinutes / focusSessionMins);

        return {
            bars: bars,
            totalMinutes: totalMinutes,
            totalFormatted: formatFocusMinutes(totalMinutes),
            avgMinutes: avgMinutes,
            avgFormatted: formatFocusMinutes(avgMinutes),
            totalSessions: totalSessions,
            peakLabel: peakLabel,
            scaleMax: scaleMax
        };
    }

    onPomodoroTotalDurationChanged: {
        if (!pomodoroRunning)
            pomodoroRemainingSeconds = pomodoroTotalDuration;
    }

    readonly property int pomodoroTotalDuration: {
        switch (pomodoroPhase) {
        case "shortBreak": return pomodoroShortBreakDuration;
        case "longBreak": return pomodoroLongBreakDuration;
        default: return pomodoroFocusDuration;
        }
    }
    readonly property real pomodoroProgress: {
        if (pomodoroTotalDuration <= 0) return 0;
        return Math.max(0, Math.min(1, pomodoroRemainingSeconds / pomodoroTotalDuration));
    }

    function togglePomodoro() {
        if (!root._stateReady)
            return;
        if (pomodoroRunning) {
            pomodoroRunning = false;
        } else {
            _lastPomoTickMs = _monoNowMs;
            pomodoroRunning = true;
        }
    }

    function resetPomodoro() {
        if (!root._stateReady)
            return;
        pomodoroRunning = false;
        pomodoroRemainingSeconds = pomodoroTotalDuration;
    }

    function skipPomodoroPhase() {
        if (!root._stateReady)
            return;
        pomodoroRunning = false;
        if (pomodoroPhase === "focus") {
            const nextCount = pomodoroCyclesCompleted + 1;
            pomodoroCyclesCompleted = nextCount;
            saveState();
            if (nextCount % pomodoroTargetCycles === 0) {
                pomodoroPhase = "longBreak";
                pomodoroRemainingSeconds = pomodoroLongBreakDuration;
            } else {
                pomodoroPhase = "shortBreak";
                pomodoroRemainingSeconds = pomodoroShortBreakDuration;
            }
        } else {
            pomodoroPhase = "focus";
            pomodoroRemainingSeconds = pomodoroFocusDuration;
        }
    }

    function setPomodoroPhase(phase) {
        if (!root._stateReady)
            return;
        pomodoroRunning = false;
        pomodoroPhase = phase;
        pomodoroRemainingSeconds = pomodoroTotalDuration;
    }

    function setPomodoroStep(stepIdx) {
        if (!root._stateReady)
            return;
        const n = Math.max(1, pomodoroTargetCycles);
        const totalSteps = n * 2;
        const clamped = Math.max(0, Math.min(totalSteps - 1, stepIdx));
        const baseCycles = Math.floor(pomodoroCyclesCompleted / n) * n;
        pomodoroRunning = false;
        if (clamped === totalSteps - 1) {
            pomodoroCyclesCompleted = baseCycles + n;
            pomodoroPhase = "longBreak";
            pomodoroRemainingSeconds = pomodoroLongBreakDuration;
        } else if (clamped % 2 === 0) {
            pomodoroCyclesCompleted = baseCycles + Math.floor(clamped / 2);
            pomodoroPhase = "focus";
            pomodoroRemainingSeconds = pomodoroFocusDuration;
        } else {
            pomodoroCyclesCompleted = baseCycles + Math.floor((clamped + 1) / 2);
            pomodoroPhase = "shortBreak";
            pomodoroRemainingSeconds = pomodoroShortBreakDuration;
        }
        saveState();
    }

    // Stopwatch state
    property bool stopwatchRunning: false
    property double stopwatchElapsedMs: 0
    property double _lastStopwatchTickMs: -1
    property var stopwatchLaps: [] // [{ lapNumber: 1, lapMs: 1230, totalMs: 1230 }]

    readonly property double currentLapElapsedMs: {
        if (stopwatchLaps.length === 0)
            return stopwatchElapsedMs;
        return Math.max(0, stopwatchElapsedMs - stopwatchLaps[0].totalMs);
    }

    readonly property int fastestLapNumber: {
        if (stopwatchLaps.length < 2)
            return -1;
        let bestNum = stopwatchLaps[0].lapNumber;
        let bestMs = stopwatchLaps[0].lapMs;
        for (let i = 1; i < stopwatchLaps.length; i++) {
            if (stopwatchLaps[i].lapMs < bestMs) {
                bestMs = stopwatchLaps[i].lapMs;
                bestNum = stopwatchLaps[i].lapNumber;
            }
        }
        return bestNum;
    }

    readonly property int slowestLapNumber: {
        if (stopwatchLaps.length < 2)
            return -1;
        let worstNum = stopwatchLaps[0].lapNumber;
        let worstMs = stopwatchLaps[0].lapMs;
        for (let i = 1; i < stopwatchLaps.length; i++) {
            if (stopwatchLaps[i].lapMs > worstMs) {
                worstMs = stopwatchLaps[i].lapMs;
                worstNum = stopwatchLaps[i].lapNumber;
            }
        }
        return worstNum;
    }

    Component.onCompleted: {
        _ensureDefaultPomodoroHistory();
        const initTab = (Quickshell.env("DCLOCK_INITIAL_TAB") || "").toLowerCase();
        if (initTab === "clock" || initTab === "worldclock")
            currentTabIndex = 1;
        else if (initTab === "alarm" || initTab === "alarms")
            currentTabIndex = 0;
        else if (initTab === "timer" || initTab === "timers")
            currentTabIndex = 2;
        else if (initTab === "pomodoro" || initTab === "pomo")
            currentTabIndex = 3;
        else if (initTab === "stopwatch")
            currentTabIndex = 4;
        else if (initTab === "settings")
            currentTabIndex = 5;

        if (Quickshell.env("DCLOCK_OPEN_SETTINGS") === "1")
            currentTabIndex = 5;
    }

    onSettingsOpenChanged: {
        if (settingsOpen) {
            currentTabIndex = 5;
            settingsOpen = false;
        }
    }

    // State Persistence
    property bool _stateReady: false
    readonly property bool stateReady: _stateReady
    property bool _pendingSave: false
    property bool _quitRequested: false

    FileView {
        id: stateFileView
        path: root.stateFilePath
        blockLoading: false
        printErrors: false
        onLoaded: {
            try {
                const raw = stateFileView.text();
                if (raw) {
                    const data = JSON.parse(raw);
                    if (Array.isArray(data.worldClocks))
                        root.worldClocks = data.worldClocks;
                    if (Array.isArray(data.alarms))
                        root.alarms = data.alarms;
                    if (Array.isArray(data.timers)) {
                        let maxId = 1;
                        root.timers = data.timers.map(t => {
                            if (t.id >= maxId)
                                maxId = t.id + 1;
                            return {
                                id: t.id || maxId++,
                                label: t.label || "Timer",
                                totalMs: t.totalMs || 60000,
                                remainingMs: t.totalMs || 60000,
                                running: false,
                                finished: false
                            };
                        });
                        root._nextTimerId = maxId;
                    }
                    if (Array.isArray(data.pomodoroHistory)) {
                        root.pomodoroHistory = data.pomodoroHistory;
                        root.pomodoroStatsRevision++;
                    }
                    if (typeof data.pomodoroCyclesCompleted === "number")
                        root.pomodoroCyclesCompleted = data.pomodoroCyclesCompleted;
                }
            } catch (e) {
                console.warn("Failed to load DankClock state:", e);
            }
            root._stateReady = true;
            root._checkAlarms(root.now);
            if (root._pendingSave)
                root._writeStateNow();
            else if (root._quitRequested)
                Qt.quit();
        }
        onLoadFailed: {
            root._stateReady = true;
            root._checkAlarms(root.now);
            if (root._pendingSave)
                root._writeStateNow();
            else if (root._quitRequested)
                Qt.quit();
        }
    }

    function _writeStateNow() {
        if (!root._stateReady)
            return;
        if (saveStateProc.running) {
            root._pendingSave = true;
            return;
        }
        root._pendingSave = false;
        const payload = {
            worldClocks: root.worldClocks,
            alarms: root.alarms,
            timers: root.timers.map(t => ({
                id: t.id,
                label: t.label,
                totalMs: t.totalMs
            })),
            pomodoroCyclesCompleted: root.pomodoroCyclesCompleted,
            pomodoroHistory: root.pomodoroHistory
        };
        saveStateProc.command = [
            "sh", "-c",
            'dir="$(dirname "$1")" && mkdir -p "$dir" && tmp="$1.tmp.$$" && printf "%s" "$2" > "$tmp" && mv -f "$tmp" "$1"',
            "saveClockState",
            root.stateFilePath,
            JSON.stringify(payload, null, 2)
        ];
        saveStateProc.running = true;
    }

    Process {
        id: saveStateProc
        running: false
        command: []
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root._pendingSave = true;
                root._quitRequested = false;
                Quickshell.execDetached(["dms", "ipc", "call", "toast", "error", "DankClock — Failed to save clock state to disk."]);
                return;
            }
            if (root._pendingSave) {
                root._writeStateNow();
            } else if (root._quitRequested) {
                Qt.quit();
            }
        }
    }

    Timer {
        id: saveStateDebounce
        interval: 250
        repeat: false
        onTriggered: {
            root._writeStateNow();
        }
    }

    function saveState() {
        if (!root._stateReady)
            return;
        root._pendingSave = true;
        saveStateDebounce.restart();
    }

    function requestQuit() {
        if (!root._stateReady) {
            saveStateDebounce.stop();
            Qt.quit();
            return;
        }
        if (saveStateDebounce.running) {
            saveStateDebounce.stop();
            root._quitRequested = true;
            root._writeStateNow();
            return;
        }
        if (saveStateProc.running || root._pendingSave) {
            root._quitRequested = true;
            if (!saveStateProc.running)
                root._writeStateNow();
            return;
        }
        Qt.quit();
    }

    // Wall-clock 1-second timer for Clock & Alarms
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.now = new Date();
            if (root._stateReady)
                root._checkAlarms(root.now);
        }
    }

    function _settleRunningTimers() {
        const currentMs = root._monoNowMs;
        const dt = root._lastTimerTickMs >= 0 ? Math.max(0, currentMs - root._lastTimerTickMs) : 0;
        root._lastTimerTickMs = currentMs;
        if (dt <= 0)
            return;

        let list = root.timers;
        let stateChanged = false;
        let tickChanged = false;
        for (let i = 0; i < list.length; i++) {
            const t = list[i];
            if (t.running) {
                const nextRem = Math.max(0, t.remainingMs - dt);
                const done = nextRem <= 0;
                t.remainingMs = nextRem;
                tickChanged = true;
                if (done) {
                    t.running = false;
                    t.finished = true;
                    stateChanged = true;
                    root._triggerAlert("timer", t.label || "Timer", root.formatDuration(t.totalMs) + " countdown finished", -1, t.id);
                }
            }
        }
        if (stateChanged || tickChanged)
            root.timerTickRevision++;
    }

    // High-resolution timer for active Countdown Timers
    Timer {
        interval: 50
        running: root.anyTimerRunning
        repeat: true
        onTriggered: {
            root._settleRunningTimers();
        }
    }

    // 60fps Stopwatch & Pomodoro Timer
    Timer {
        interval: 100
        running: root.pomodoroRunning
        repeat: true
        onTriggered: {
            const nowMs = root._monoNowMs;
            const elapsed = root._lastPomoTickMs >= 0 ? Math.max(0, (nowMs - root._lastPomoTickMs) / 1000) : 0.1;
            root._lastPomoTickMs = nowMs;
            if (root.pomodoroPhase === "focus") {
                root._accumulatedFocusSec += Math.min(elapsed, root.pomodoroRemainingSeconds);
                if (root._accumulatedFocusSec >= 60) {
                    const wholeMins = Math.floor(root._accumulatedFocusSec / 60);
                    root._accumulatedFocusSec -= wholeMins * 60;
                    root.recordPomodoroFocusMinutes(wholeMins);
                }
            }
            const rem = Math.max(0, root.pomodoroRemainingSeconds - elapsed);
            root.pomodoroRemainingSeconds = rem;
            if (rem <= 0) {
                root.pomodoroRunning = false;
                const isFocus = root.pomodoroPhase === "focus";
                if (isFocus && root._accumulatedFocusSec >= 15) {
                    root.recordPomodoroFocusMinutes(1);
                    root._accumulatedFocusSec = 0;
                }
                root._triggerAlert("pomodoro", isFocus ? "Pomodoro Finished" : "Break Over", isFocus ? "Great job! Time for a break." : "Break is over! Time to focus.", -1, -1);
                root.skipPomodoroPhase();
            }
        }
    }

    // 60fps Stopwatch Timer
    Timer {
        interval: 16
        running: root.stopwatchRunning
        repeat: true
        onTriggered: {
            const currentMs = root._monoNowMs;
            const dt = root._lastStopwatchTickMs >= 0 ? Math.max(0, currentMs - root._lastStopwatchTickMs) : 16;
            root._lastStopwatchTickMs = currentMs;
            root.stopwatchElapsedMs += dt;
        }
    }

    // World Clock Helpers
    function getCityCode(cityObj) {
        if (!cityObj)
            return "";
        if (cityObj.code)
            return cityObj.code;
        for (let i = 0; i < cityCatalog.length; i++) {
            if (cityCatalog[i].city === cityObj.city && cityCatalog[i].code)
                return cityCatalog[i].code;
        }
        return (cityObj.city || "CTY").replace(/\s+/g, "").slice(0, 3).toUpperCase();
    }

    function _resolveCityParts(cityObj, d) {
        const localOffsetMin = -d.getTimezoneOffset();
        const fallbackOffsetMin = cityObj && cityObj.offsetMin !== undefined ? cityObj.offsetMin : localOffsetMin;
        if (cityObj && cityObj.tz) {
            try {
                const fmt = new Intl.DateTimeFormat("en-US", {
                    timeZone: cityObj.tz,
                    year: "numeric",
                    month: "numeric",
                    day: "numeric",
                    hour: "numeric",
                    minute: "numeric",
                    second: "numeric",
                    weekday: "long",
                    hourCycle: "h23"
                });
                const parts = fmt.formatToParts(d);
                let year = 0, month = 1, day = 1, hour = 0, minute = 0, second = 0, weekday = "";
                for (let i = 0; i < parts.length; i++) {
                    const p = parts[i];
                    if (p.type === "year") year = parseInt(p.value, 10);
                    else if (p.type === "month") month = parseInt(p.value, 10);
                    else if (p.type === "day") day = parseInt(p.value, 10);
                    else if (p.type === "hour") hour = parseInt(p.value, 10) % 24;
                    else if (p.type === "minute") minute = parseInt(p.value, 10);
                    else if (p.type === "second") second = parseInt(p.value, 10);
                    else if (p.type === "weekday") weekday = p.value;
                }
                if (year > 0) {
                    const asUtcMs = Date.UTC(year, month - 1, day, hour, minute, second);
                    const instantSecMs = Math.floor(d.getTime() / 1000) * 1000;
                    const offsetMin = Math.round((asUtcMs - instantSecMs) / 60000);
                    return {
                        year: year,
                        month: month,
                        day: day,
                        hour: hour,
                        minute: minute,
                        second: second,
                        dayName: weekday || Qt.formatDate(new Date(year, month - 1, day), "dddd"),
                        offsetMin: offsetMin
                    };
                }
            } catch (e) {
                // Fall back to fixed offset calculation below
            }
        }
        const shifted = new Date(d.getTime() + fallbackOffsetMin * 60000);
        const year = shifted.getUTCFullYear();
        const month = shifted.getUTCMonth() + 1;
        const day = shifted.getUTCDate();
        return {
            year: year,
            month: month,
            day: day,
            hour: shifted.getUTCHours(),
            minute: shifted.getUTCMinutes(),
            second: shifted.getUTCSeconds(),
            dayName: Qt.formatDate(new Date(year, month - 1, day), "dddd"),
            offsetMin: fallbackOffsetMin
        };
    }

    function getCityTimeInfo(cityObj, refDate) {
        const d = refDate || root.now;
        const localOffsetMin = -d.getTimezoneOffset();
        const resolved = _resolveCityParts(cityObj, d);
        const targetOffsetMin = resolved.offsetMin;
        const diffMin = targetOffsetMin - localOffsetMin;

        const h24 = resolved.hour;
        const m = String(resolved.minute).padStart(2, "0");
        const s = String(resolved.second).padStart(2, "0");
        const use24 = SettingsData.use24HourClock;
        const hDisp = use24 ? String(h24).padStart(2, "0") : String(h24 % 12 || 12);
        const meridiem = use24 ? "" : (h24 >= 12 ? "PM" : "AM");

        // Compare day relative to local date
        let dayRelation = "Today";
        let dayDelta = 0;
        const localDay = d.getFullYear() * 10000 + (d.getMonth() + 1) * 100 + d.getDate();
        const targetDay = resolved.year * 10000 + resolved.month * 100 + resolved.day;
        if (targetDay > localDay) {
            dayRelation = "Tomorrow";
            dayDelta = 1;
        } else if (targetDay < localDay) {
            dayRelation = "Yesterday";
            dayDelta = -1;
        }
        const dayDeltaBadge = dayDelta > 0 ? "+1" : (dayDelta < 0 ? "-1" : "");

        const diffHrs = diffMin / 60;
        let offsetStr = "Same time";
        let shortOffset = "0h";
        if (diffMin !== 0) {
            const sign = diffHrs > 0 ? "+" : "";
            const numStr = diffHrs % 1 === 0 ? String(diffHrs) : diffHrs.toFixed(1);
            offsetStr = `${sign}${numStr} HRS`;
            shortOffset = `${sign}${numStr}h`;
        }

        const dayName = resolved.dayName;

        return {
            hour24: h24,
            minute: resolved.minute,
            second: resolved.second,
            hourFrac24: (h24 + resolved.minute / 60) / 24,
            hourAngle12Deg: ((h24 % 12) + resolved.minute / 60) * 30,
            offsetMin: targetOffsetMin,
            timeText: `${hDisp}:${m}`,
            secondsText: s,
            meridiem: meridiem,
            dayName: dayName,
            dayRelation: dayRelation,
            dayDelta: dayDelta,
            dayDeltaBadge: dayDeltaBadge,
            offsetBadge: offsetStr,
            shortOffset: shortOffset,
            compactSubtitle: `${dayName}, ${shortOffset}`,
            subtitle: `${cityObj.country} • ${dayRelation}`
        };
    }

    function addWorldClock(cityObj) {
        if (!root._stateReady || !cityObj || !cityObj.city)
            return;
        for (let i = 0; i < worldClocks.length; i++) {
            if (worldClocks[i].city === cityObj.city)
                return;
        }
        const next = worldClocks.slice();
        next.push({
            city: cityObj.city,
            country: cityObj.country || "",
            tz: cityObj.tz || "",
            offsetMin: cityObj.offsetMin
        });
        worldClocks = next;
        saveState();
    }

    function removeWorldClock(index) {
        if (!root._stateReady || index < 0 || index >= worldClocks.length)
            return;
        const next = worldClocks.slice();
        next.splice(index, 1);
        worldClocks = next;
        if (worldClocks.length === 0)
            worldClockEditMode = false;
        saveState();
    }

    function moveWorldClock(fromIndex, toIndex) {
        if (!root._stateReady || fromIndex < 0 || fromIndex >= worldClocks.length || toIndex < 0 || toIndex >= worldClocks.length || fromIndex === toIndex)
            return;
        const next = worldClocks.slice();
        const item = next.splice(fromIndex, 1)[0];
        next.splice(toIndex, 0, item);
        worldClocks = next;
        saveState();
    }

    function reorderWorldClocks(indices) {
        if (!root._stateReady || !Array.isArray(indices) || indices.length !== worldClocks.length)
            return;
        const next = indices.map(idx => worldClocks[idx]);
        worldClocks = next;
        saveState();
    }

    // Alarm Management
    function _dateKey(d) {
        return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
    }

    function _todayDateKey() {
        return _dateKey(root.now);
    }

    function getSoundInfo(soundId) {
        for (let i = 0; i < alarmSounds.length; i++) {
            if (alarmSounds[i].id === soundId)
                return alarmSounds[i];
        }
        return alarmSounds[0];
    }

    function _playSoundFile(soundId) {
        const s = getSoundInfo(soundId || "classic");
        if (!s || !s.path)
            return;
        Quickshell.execDetached([
            "sh", "-c",
            `pw-play "${s.path}" 2>/dev/null || paplay "${s.path}" 2>/dev/null || true`
        ]);
    }

    function previewAlarmSound(soundId) {
        _playSoundFile(soundId);
    }

    function formatClockParts(hour24, minute) {
        const m = String(minute).padStart(2, "0");
        if (SettingsData.use24HourClock) {
            return {
                timeText: `${String(hour24).padStart(2, "0")}:${m}`,
                meridiem: ""
            };
        }
        const h12 = hour24 % 12 || 12;
        return {
            timeText: `${h12}:${m}`,
            meridiem: hour24 >= 12 ? "PM" : "AM"
        };
    }

    function calcGridDropIndex(item, grid, mouseX, mouseY, cardWidth, cardHeight, spacing, columns, count, offset = 0) {
        if (count <= 0)
            return -1;
        const mapped = item.mapToItem(grid, mouseX, mouseY);
        const colW = cardWidth + spacing;
        const rowH = cardHeight + spacing;
        const targetCol = Math.max(0, Math.min(columns - 1, Math.floor(mapped.x / colW)));
        const targetRow = Math.max(0, Math.floor(mapped.y / rowH));
        const slotIdx = targetRow * columns + targetCol;
        if (slotIdx < offset)
            return -1;
        return Math.max(0, Math.min(count - 1, slotIdx - offset));
    }

    function formatAlarmSchedule(days) {
        if (!Array.isArray(days) || days.length === 0)
            return "One-time";
        if (days.length === 7)
            return "Every day";
        const weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri"];
        const weekends = ["Sat", "Sun"];
        if (days.length === 5 && weekdays.every(d => days.indexOf(d) >= 0))
            return "Weekdays";
        if (days.length === 2 && weekends.every(d => days.indexOf(d) >= 0))
            return "Weekends";
        return days.join(", ");
    }

    function _checkAlarms(d) {
        const key = `${d.getFullYear()}-${d.getMonth()}-${d.getDate()}-${d.getHours()}-${d.getMinutes()}`;
        const nowMs = d.getTime();
        const jsDay = d.getDay(); // 0=Sun .. 6=Sat
        const dayName = weekDays[(jsDay + 6) % 7];
        const todayKey = _dateKey(d);
        const h = d.getHours();
        const m = d.getMinutes();

        let stateModified = false;
        let removeIndices = [];

        for (let i = 0; i < alarms.length; i++) {
            const a = alarms[i];
            if (!a || !a.enabled)
                continue;

            const hasSnoozeDeadline = typeof a.snoozeUntilMs === "number" && a.snoozeUntilMs > 0;
            if (hasSnoozeDeadline) {
                if (nowMs < a.snoozeUntilMs)
                    continue;
            } else {
                if (a.hour !== h || a.minute !== m)
                    continue;
                if (a.lastTriggeredMinuteKey === key)
                    continue;
            }

            const hasDays = Array.isArray(a.days) && a.days.length > 0;
            if (hasSnoozeDeadline || !hasDays || a.days.indexOf(dayName) >= 0) {
                a.lastTriggeredMinuteKey = key;
                if (hasSnoozeDeadline)
                    a.snoozeUntilMs = 0;

                if (!hasSnoozeDeadline && hasDays && a.skippedDateKey === todayKey) {
                    a.skippedDateKey = "";
                    stateModified = true;
                    continue;
                }

                _triggerAlert("alarm", a.label || "Alarm", formatAlarmTime(a.hour, a.minute), i, -1, a.soundId || "classic", a.snoozeMin || 10);
                if (!hasDays) {
                    if (a.deleteAfterGoesOff) {
                        removeIndices.push(i);
                    } else {
                        a.enabled = false;
                        a.skippedDateKey = "";
                        stateModified = true;
                    }
                } else {
                    stateModified = true;
                }
            }
        }

        if (removeIndices.length > 0) {
            for (let r = removeIndices.length - 1; r >= 0; r--)
                removeAlarm(removeIndices[r]);
        } else if (stateModified) {
            alarmRevision++;
            saveState();
        }
    }

    function formatAlarmTime(hour, minute) {
        const parts = formatClockParts(hour, minute);
        return parts.meridiem ? `${parts.timeText} ${parts.meridiem}` : parts.timeText;
    }

    function openAddAlarmPicker() {
        if (!root._stateReady)
            return;
        editingAlarmIndex = -1;
        timePickerOpen = true;
    }

    function openEditAlarmPicker(index) {
        if (!root._stateReady || index < 0 || index >= alarms.length)
            return;
        editingAlarmIndex = index;
        timePickerOpen = true;
    }

    function commitTimePicker(hour, minute) {
        if (!root._stateReady)
            return;
        if (editingAlarmIndex >= 0 && editingAlarmIndex < alarms.length) {
            const cur = alarms[editingAlarmIndex];
            cur.hour = hour;
            cur.minute = minute;
            cur.enabled = true;
            cur.skippedDateKey = "";
            cur.lastTriggeredMinuteKey = "";
            cur.snoozeUntilMs = 0;
            alarmRevision++;
        } else {
            const next = alarms.slice();
            next.push({
                hour: hour,
                minute: minute,
                label: "Alarm",
                enabled: true,
                days: ["Mon", "Tue", "Wed", "Thu", "Fri"],
                soundId: "classic",
                snoozeMin: 10,
                deleteAfterGoesOff: false,
                skippedDateKey: "",
                lastTriggeredMinuteKey: "",
                snoozeUntilMs: 0
            });
            alarms = next;
            expandedAlarmIndex = next.length - 1;
            alarmRevision++;
        }
        timePickerOpen = false;
        editingAlarmIndex = -1;
        saveState();
    }

    function toggleAlarm(index, enabled) {
        if (!root._stateReady || index < 0 || index >= alarms.length)
            return;
        alarms[index].enabled = enabled;
        alarms[index].skippedDateKey = "";
        alarms[index].lastTriggeredMinuteKey = "";
        alarms[index].snoozeUntilMs = 0;
        alarmRevision++;
        saveState();
    }

    function skipAlarmOnce(index) {
        if (!root._stateReady || index < 0 || index >= alarms.length)
            return;
        const a = alarms[index];
        const hasDays = Array.isArray(a.days) && a.days.length > 0;
        if (!hasDays) {
            a.enabled = false;
            a.skippedDateKey = "";
            alarmRevision++;
            saveState();
            return;
        }
        const nextOcc = _getNextAlarmOccurrence(a, root.now, true);
        if (!nextOcc)
            return;
        const nextKey = _dateKey(nextOcc.targetDate);
        a.skippedDateKey = (a.skippedDateKey === nextKey) ? "" : nextKey;
        alarmRevision++;
        saveState();
    }

    function updateAlarmDays(index, daysArray) {
        if (!root._stateReady || index < 0 || index >= alarms.length)
            return;
        alarms[index].days = daysArray;
        alarms[index].skippedDateKey = "";
        alarmRevision++;
        saveState();
    }

    function updateAlarmLabel(index, newLabel) {
        if (!root._stateReady || index < 0 || index >= alarms.length)
            return;
        alarms[index].label = newLabel.trim() || "Alarm";
        alarmRevision++;
        saveState();
    }

    function updateAlarmSound(index, soundId) {
        if (!root._stateReady || index < 0 || index >= alarms.length)
            return;
        alarms[index].soundId = soundId;
        alarmRevision++;
        saveState();
        previewAlarmSound(soundId);
    }

    function updateAlarmSnooze(index, snoozeMin) {
        if (!root._stateReady || index < 0 || index >= alarms.length)
            return;
        alarms[index].snoozeMin = snoozeMin;
        alarmRevision++;
        saveState();
    }

    function updateAlarmDeleteAfter(index, delAfter) {
        if (!root._stateReady || index < 0 || index >= alarms.length)
            return;
        alarms[index].deleteAfterGoesOff = delAfter;
        alarmRevision++;
        saveState();
    }

    function duplicateAlarm(index) {
        if (!root._stateReady || index < 0 || index >= alarms.length)
            return;
        const src = alarms[index];
        const next = alarms.slice();
        next.splice(index + 1, 0, {
            hour: src.hour,
            minute: src.minute,
            label: (src.label || "Alarm") + " (Copy)",
            enabled: true,
            days: Array.isArray(src.days) ? src.days.slice() : [],
            soundId: src.soundId || "classic",
            snoozeMin: src.snoozeMin || 10,
            deleteAfterGoesOff: Boolean(src.deleteAfterGoesOff),
            skippedDateKey: ""
        });
        alarms = next;
        expandedAlarmIndex = index + 1;
        alarmRevision++;
        saveState();
    }

    function removeAlarm(index) {
        if (!root._stateReady || index < 0 || index >= alarms.length)
            return;
        const next = alarms.slice();
        next.splice(index, 1);
        alarms = next;
        if (expandedAlarmIndex === index)
            expandedAlarmIndex = -1;
        else if (expandedAlarmIndex > index)
            expandedAlarmIndex--;

        if (editingAlarmIndex === index) {
            editingAlarmIndex = -1;
            timePickerOpen = false;
        } else if (editingAlarmIndex > index) {
            editingAlarmIndex--;
        }

        if (editingLabelAlarmIndex === index) {
            editingLabelAlarmIndex = -1;
            labelDialogOpen = false;
        } else if (editingLabelAlarmIndex > index) {
            editingLabelAlarmIndex--;
        }

        alarmRevision++;
        if (alarms.length === 0)
            alarmEditMode = false;
        saveState();
    }

    function _getNextAlarmOccurrence(a, cur, ignoreSkip) {
        if (!a || !a.enabled)
            return null;
        if (typeof a.snoozeUntilMs === "number" && a.snoozeUntilMs > cur.getTime()) {
            const target = new Date(a.snoozeUntilMs);
            const targetKey = _dateKey(target);
            const diffMs = target.getTime() - cur.getTime();
            const totalMin = Math.max(1, Math.round(diffMs / 60000));
            const hours = Math.floor(totalMin / 60);
            const mins = totalMin % 60;
            const relativeText = hours > 0 ? (mins > 0 ? `in ${hours} hr ${mins} min` : `in ${hours} hr`) : `in ${mins} min`;
            const jsDay = target.getDay();
            const dayName = weekDays[(jsDay + 6) % 7];
            const localDay = cur.getFullYear() * 10000 + (cur.getMonth() + 1) * 100 + cur.getDate();
            const targetDay = target.getFullYear() * 10000 + (target.getMonth() + 1) * 100 + target.getDate();
            const dayRelation = targetDay > localDay ? "Tomorrow" : (targetDay < localDay ? dayName : "Today");
            return {
                targetDate: target,
                targetKey: targetKey,
                diffMs: diffMs,
                relativeText: relativeText,
                dayRelation: dayRelation,
                timeText: formatAlarmTime(target.getHours(), target.getMinutes())
            };
        }
        const days = Array.isArray(a.days) ? a.days : [];
        for (let delta = 0; delta <= 14; delta++) {
            const target = new Date(cur.getFullYear(), cur.getMonth(), cur.getDate() + delta, a.hour, a.minute, 0, 0);
            if (target.getTime() <= cur.getTime())
                continue;
            const jsDay = target.getDay();
            const dayName = weekDays[(jsDay + 6) % 7];
            if (days.length === 0 || days.indexOf(dayName) >= 0) {
                const targetKey = _dateKey(target);
                if (!ignoreSkip && days.length > 0 && a.skippedDateKey === targetKey)
                    continue;

                const diffMs = target.getTime() - cur.getTime();
                const totalMin = Math.round(diffMs / 60000);
                const hours = Math.floor(totalMin / 60);
                const mins = totalMin % 60;
                let relativeText = "";
                if (hours > 24) {
                    const dCount = Math.floor(hours / 24);
                    const remH = hours % 24;
                    relativeText = remH > 0 ? `in ${dCount}d ${remH}h` : `in ${dCount} days`;
                } else if (hours > 0 && mins > 0) {
                    relativeText = `in ${hours} hr ${mins} min`;
                } else if (hours > 0) {
                    relativeText = `in ${hours} hr`;
                } else if (mins > 0) {
                    relativeText = `in ${mins} min`;
                } else {
                    relativeText = "in less than a minute";
                }

                let dayRelation = "Today";
                const localDay = cur.getFullYear() * 10000 + (cur.getMonth() + 1) * 100 + cur.getDate();
                const targetDay = target.getFullYear() * 10000 + (target.getMonth() + 1) * 100 + target.getDate();
                if (targetDay > localDay)
                    dayRelation = delta === 1 ? "Tomorrow" : dayName;

                return {
                    targetDate: target,
                    targetKey: targetKey,
                    diffMs: diffMs,
                    relativeText: relativeText,
                    dayRelation: dayRelation,
                    timeText: formatAlarmTime(a.hour, a.minute)
                };
            }
        }
        return null;
    }

    function getAlarmNextInfo(index) {
        if (index < 0 || index >= alarms.length)
            return null;
        return _getNextAlarmOccurrence(alarms[index], root.now, false);
    }

    function isAlarmSkippedNext(index) {
        if (index < 0 || index >= alarms.length)
            return false;
        const a = alarms[index];
        if (!a.enabled || !a.skippedDateKey || !Array.isArray(a.days) || a.days.length === 0)
            return false;
        const rawNext = _getNextAlarmOccurrence(a, root.now, true);
        return Boolean(rawNext && rawNext.targetKey === a.skippedDateKey);
    }

    // Incoming / Next Alarm
    readonly property var nextIncomingAlarm: {
        void alarmRevision;
        const cur = root.now;
        let best = null;
        for (let i = 0; i < alarms.length; i++) {
            const a = alarms[i];
            const occ = _getNextAlarmOccurrence(a, cur, false);
            if (occ && (!best || occ.diffMs < best.diffMs)) {
                best = {
                    index: i,
                    alarm: a,
                    targetDate: occ.targetDate,
                    diffMs: occ.diffMs,
                    relativeText: occ.relativeText,
                    dayRelation: occ.dayRelation,
                    timeText: occ.timeText,
                    isRecurring: Array.isArray(a.days) && a.days.length > 0
                };
            }
        }
        return best;
    }

    // Timer Management
    function startCustomTimer(label) {
        if (!root._stateReady)
            return;
        const totalSec = setupHours * 3600 + setupMinutes * 60 + setupSeconds;
        if (totalSec <= 0)
            return;
        startPresetTimer(totalSec, label || _defaultTimerLabel(totalSec));
        timerSetupMode = false;
    }

    function _defaultTimerLabel(totalSec) {
        if (totalSec % 60 === 0)
            return `${totalSec / 60} min Timer`;
        return `${formatDuration(totalSec * 1000)} Timer`;
    }

    function startPresetTimer(durationSec, label) {
        if (!root._stateReady)
            return;
        if (anyTimerRunning)
            _settleRunningTimers();
        const ms = durationSec * 1000;
        const next = timers.slice();
        const newTimer = {
            id: _nextTimerId++,
            label: label || _defaultTimerLabel(durationSec),
            totalMs: ms,
            remainingMs: ms,
            running: true,
            finished: false
        };
        _lastTimerTickMs = _monoNowMs;
        next.unshift(newTimer);
        timers = next;
        activeTimerIndex = 0;
        saveState();
    }

    function toggleTimer(index) {
        if (!root._stateReady || index < 0 || index >= timers.length)
            return;
        const wasRunning = Boolean(timers[index].running);
        if (anyTimerRunning)
            _settleRunningTimers();
        const t = timers[index];
        if (!t || (wasRunning && !t.running))
            return;
        const willRun = !t.running;
        t.remainingMs = (willRun && t.remainingMs <= 0) ? t.totalMs : t.remainingMs;
        if (willRun)
            _lastTimerTickMs = _monoNowMs;
        t.running = willRun;
        t.finished = false;
        timerTickRevision++;
    }

    function resetTimer(index) {
        if (!root._stateReady || index < 0 || index >= timers.length)
            return;
        const t = timers[index];
        t.remainingMs = t.totalMs;
        t.running = false;
        t.finished = false;
        timerTickRevision++;
    }

    function addOneMinute(index) {
        if (!root._stateReady || index < 0 || index >= timers.length)
            return;
        const t = timers[index];
        const extra = 60 * 1000;
        const prevTotal = t.totalMs;
        t.totalMs = Math.max(t.totalMs, t.remainingMs + extra);
        t.remainingMs = t.remainingMs + extra;
        t.finished = false;
        timerTickRevision++;
        if (t.totalMs !== prevTotal)
            saveState();
    }

    function removeTimer(index) {
        if (!root._stateReady || index < 0 || index >= timers.length)
            return;
        const next = timers.slice();
        next.splice(index, 1);
        timers = next;
        if (index < activeTimerIndex)
            activeTimerIndex = Math.max(0, activeTimerIndex - 1);
        else if (activeTimerIndex >= timers.length)
            activeTimerIndex = Math.max(0, timers.length - 1);
        saveState();
    }

    function moveTimer(fromIndex, toIndex) {
        if (!root._stateReady || fromIndex < 0 || fromIndex >= timers.length || toIndex < 0 || toIndex >= timers.length || fromIndex === toIndex)
            return;
        const next = timers.slice();
        const item = next.splice(fromIndex, 1)[0];
        next.splice(toIndex, 0, item);
        if (activeTimerIndex === fromIndex)
            activeTimerIndex = toIndex;
        else if (fromIndex < activeTimerIndex && toIndex >= activeTimerIndex)
            activeTimerIndex--;
        else if (fromIndex > activeTimerIndex && toIndex <= activeTimerIndex)
            activeTimerIndex++;
        timers = next;
        timerTickRevision++;
        saveState();
    }

    // Stopwatch Management
    function toggleStopwatch() {
        if (!stopwatchRunning) {
            _lastStopwatchTickMs = _monoNowMs;
            stopwatchRunning = true;
        } else {
            stopwatchRunning = false;
        }
    }

    function lapStopwatch() {
        if (!stopwatchRunning && stopwatchElapsedMs <= 0)
            return;
        const prevTotal = stopwatchLaps.length > 0 ? stopwatchLaps[0].totalMs : 0;
        const lapDuration = Math.max(0, stopwatchElapsedMs - prevTotal);
        const next = stopwatchLaps.slice();
        next.unshift({
            lapNumber: next.length + 1,
            lapMs: lapDuration,
            totalMs: stopwatchElapsedMs
        });
        stopwatchLaps = next;
    }

    function resetStopwatch() {
        stopwatchRunning = false;
        stopwatchElapsedMs = 0;
        stopwatchLaps = [];
    }

    // Formatting Helpers
    function formatDuration(ms) {
        const totalSec = Math.ceil(Math.max(0, ms) / 1000);
        const h = Math.floor(totalSec / 3600);
        const m = Math.floor((totalSec % 3600) / 60);
        const s = totalSec % 60;
        if (h > 0)
            return `${String(h).padStart(2, "0")}:${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`;
        return `${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`;
    }

    function formatStopwatch(ms) {
        const clamped = Math.max(0, ms);
        const totalSec = Math.floor(clamped / 1000);
        const centis = Math.floor((clamped % 1000) / 10);
        const h = Math.floor(totalSec / 3600);
        const m = Math.floor((totalSec % 3600) / 60);
        const s = totalSec % 60;
        if (h > 0)
            return `${String(h).padStart(2, "0")}:${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}.${String(centis).padStart(2, "0")}`;
        return `${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}.${String(centis).padStart(2, "0")}`;
    }

    // Sound & Toast Notification
    function _playAlertNotification(alertObj) {
        if (!alertObj)
            return;
        Quickshell.execDetached(["dms", "ipc", "call", "toast", "info", `${alertObj.title} — ${alertObj.subtitle}`]);
        _playSoundFile(alertObj.soundId || "classic");
    }

    function _showNextQueuedAlert() {
        if (_alertQueue.length > 0) {
            const nextQueue = _alertQueue.slice();
            const nextAlert = nextQueue.shift();
            _alertQueue = nextQueue;
            ringingAlert = nextAlert;
        } else {
            ringingAlert = null;
        }
    }

    function _triggerAlert(type, title, subtitle, alarmIdx, timerId, soundId, snoozeMin) {
        const alertObj = {
            type: type,
            title: title,
            subtitle: subtitle,
            alarmIndex: alarmIdx,
            timerId: timerId,
            soundId: soundId || "classic",
            snoozeMin: snoozeMin || 5
        };
        _playAlertNotification(alertObj);
        if (ringingAlert !== null) {
            const nextQueue = _alertQueue.slice();
            nextQueue.push(alertObj);
            _alertQueue = nextQueue;
            return;
        }
        ringingAlert = alertObj;
    }

    function dismissRingingAlert() {
        _showNextQueuedAlert();
    }

    function snoozeRingingAlert() {
        if (!ringingAlert)
            return;
        const current = ringingAlert;
        const mins = current.snoozeMin || 5;
        if (current.type === "alarm") {
            const snoozeUntilMs = Date.now() + mins * 60 * 1000;
            const d = new Date(snoozeUntilMs);
            const next = alarms.slice();
            next.push({
                hour: d.getHours(),
                minute: d.getMinutes(),
                label: `${current.title || "Alarm"} (Snoozed +${mins}m)`,
                enabled: true,
                days: [],
                soundId: current.soundId || "classic",
                snoozeMin: mins,
                deleteAfterGoesOff: true,
                skippedDateKey: "",
                lastTriggeredMinuteKey: "",
                snoozeUntilMs: snoozeUntilMs
            });
            alarms = next;
            alarmRevision++;
            saveState();
        } else if (current.type === "timer" || current.type === "pomodoro") {
            startPresetTimer(mins * 60, `${current.title || (current.type === "pomodoro" ? "Pomodoro" : "Timer")} (+${mins}m)`);
        }
        _showNextQueuedAlert();
    }
}
