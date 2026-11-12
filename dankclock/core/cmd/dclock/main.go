package main

import (
	"flag"
	"fmt"
	"os"
	"os/exec"
	"os/signal"
	"path/filepath"
	"strings"
	"syscall"

	"github.com/hthienloc/dankclock/core/internal/theme"
)

var (
	Version   = "0.1.0"
	BuildTime = "unknown"
	Commit    = "unknown"
)

func findQuickshellDir(specified string) (string, error) {
	if specified != "" {
		abs, err := filepath.Abs(specified)
		if err == nil {
			if _, err := os.Stat(filepath.Join(abs, "shell.qml")); err == nil {
				return abs, nil
			}
		}
	}

	candidates := []string{
		"quickshell",
		"../quickshell",
		"../../quickshell",
		"/usr/local/share/quickshell/dankclock",
		"/usr/share/quickshell/dankclock",
	}

	if home, err := os.UserHomeDir(); err == nil {
		candidates = append(candidates,
			filepath.Join(home, ".local/share/quickshell/dankclock"),
		)
	}

	execPath, err := os.Executable()
	if err == nil {
		execDir := filepath.Dir(execPath)
		candidates = append([]string{
			filepath.Join(execDir, "../quickshell"),
			filepath.Join(execDir, "quickshell"),
			filepath.Join(execDir, "../share/quickshell/dankclock"),
		}, candidates...)
	}

	for _, cand := range candidates {
		abs, err := filepath.Abs(cand)
		if err == nil {
			if _, err := os.Stat(filepath.Join(abs, "shell.qml")); err == nil {
				return abs, nil
			}
		}
	}

	return "", fmt.Errorf("could not locate quickshell configuration (shell.qml)")
}

func main() {
	configDir := flag.String("c", "", "path to quickshell configuration directory")
	tabFlag := flag.String("tab", "", "initial tab to open (clock, worldclock, alarm, alarms, reminder, reminders, timer, timers, stopwatch, pomodoro, pomo, settings)")
	showVersion := flag.Bool("v", false, "show version")

	flag.Usage = func() {
		fmt.Fprintf(os.Stderr, "Usage: dclock [options]\n\n")
		fmt.Fprintf(os.Stderr, "DankClock - Standalone Material 3 Clock, Alarm, Timer & Stopwatch\n\nOptions:\n")
		flag.PrintDefaults()
	}

	flag.Parse()

	// Single-instance guard: refuse to start a second instance. When another
	// DankClock is already running (visible or hidden in the system tray),
	// exit quietly and point the user at the tray icon instead of opening a
	// duplicate window.
	if !singleInstanceGuard() {
		os.Exit(0)
	}

	if *showVersion {
		fmt.Printf("dclock version %s (built %s, commit %s)\n", Version, BuildTime, Commit)
		return
	}

	if *tabFlag != "" {
		normalizedTab := strings.ToLower(strings.TrimSpace(*tabFlag))
		switch normalizedTab {
		case "clock", "worldclock", "alarm", "alarms", "reminder", "reminders", "timer", "timers", "stopwatch", "pomodoro", "pomo", "settings":
			*tabFlag = normalizedTab
		default:
			fmt.Fprintf(os.Stderr, "Error: unknown tab %q (supported: clock, worldclock, alarm, alarms, reminder, reminders, timer, timers, stopwatch, pomodoro, pomo, settings)\n", *tabFlag)
			os.Exit(1)
		}
	}

	qsDir, err := findQuickshellDir(*configDir)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}

	env := os.Environ()
	execPath, err := os.Executable()
	if err == nil {
		env = append(env, "DCLOCK_BIN="+execPath)
	}
	if *tabFlag != "" {
		env = append(env, "DCLOCK_INITIAL_TAB="+*tabFlag)
	}

	fontCfg := theme.GetSystemFontSettings()
	if fontCfg.Family != "" {
		env = append(env, "DCLOCK_FONT_FAMILY="+fontCfg.Family)
	}
	if fontCfg.Scale > 0 {
		env = append(env, fmt.Sprintf("DCLOCK_FONT_SCALE=%.2f", fontCfg.Scale))
	}
	if fontCfg.Mono != "" {
		env = append(env, "DCLOCK_MONO_FONT="+fontCfg.Mono)
	}

	// --no-duplicate: belt-and-braces guard so quickshell itself also exits if
	// another instance of this config is already running.
	cmd := exec.Command("quickshell", "-n", "-p", qsDir)
	cmd.Env = env
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin

	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, os.Interrupt, syscall.SIGTERM, syscall.SIGHUP, syscall.SIGQUIT)

	if err := cmd.Start(); err != nil {
		signal.Stop(sigCh)
		fmt.Fprintf(os.Stderr, "Error running quickshell: %v\n", err)
		os.Exit(1)
	}

	doneCh := make(chan error, 1)
	go func() {
		doneCh <- cmd.Wait()
	}()

	var forwardedSig os.Signal
	for {
		select {
		case sig := <-sigCh:
			forwardedSig = sig
			if cmd.Process != nil {
				_ = cmd.Process.Signal(sig)
			}
		case err := <-doneCh:
			signal.Stop(sigCh)
			if err != nil {
				if exitErr, ok := err.(*exec.ExitError); ok {
					if ws, ok := exitErr.Sys().(syscall.WaitStatus); ok && ws.Signaled() {
						sig := ws.Signal()
						signal.Reset(sig)
						_ = syscall.Kill(os.Getpid(), sig)
						os.Exit(128 + int(sig))
					}
					if forwardedSig != nil {
						if sig, ok := forwardedSig.(syscall.Signal); ok {
							signal.Reset(sig)
							_ = syscall.Kill(os.Getpid(), sig)
							os.Exit(128 + int(sig))
						}
						return
					}
					os.Exit(exitErr.ExitCode())
				}
				fmt.Fprintf(os.Stderr, "Error running quickshell: %v\n", err)
				os.Exit(1)
			}
			return
		}
	}
}


func singleInstanceGuard() bool {
	runtimeDir := os.Getenv("XDG_RUNTIME_DIR")
	if runtimeDir == "" {
		runtimeDir = "/tmp"
	}
	lockPath := filepath.Join(runtimeDir, "dankclock.lock")

	lockFile, err := os.OpenFile(lockPath, os.O_CREATE|os.O_RDWR, 0644)
	if err != nil {
		// Cannot create lock file: fall back to allowing the instance.
		return true
	}
	defer lockFile.Close()

	// LOCK_NB: fail immediately if another process already holds the lock.
	if err := syscall.Flock(int(lockFile.Fd()), syscall.LOCK_EX|syscall.LOCK_NB); err != nil {
		fmt.Fprintf(os.Stderr, "DankClock is already running — click the system tray icon to open it.\n")
		return false
	}
	return true
}
