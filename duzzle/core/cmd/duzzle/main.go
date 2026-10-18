package main

import (
	"flag"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"

	"github.com/hthienloc/duzzle/core/internal/theme"
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
		"/usr/local/share/quickshell/duzzle",
		"/usr/share/quickshell/duzzle",
	}

	if home, err := os.UserHomeDir(); err == nil {
		candidates = append(candidates,
			filepath.Join(home, ".local/share/quickshell/duzzle"),
		)
	}

	execPath, err := os.Executable()
	if err == nil {
		execDir := filepath.Dir(execPath)
		candidates = append([]string{
			filepath.Join(execDir, "../quickshell"),
			filepath.Join(execDir, "quickshell"),
			filepath.Join(execDir, "../share/quickshell/duzzle"),
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
	game := flag.String("g", "", "launch specific puzzle game directly (e.g. minesweeper)")
	daily := flag.Bool("daily", false, "launch directly in daily challenge mode")
	showVersion := flag.Bool("v", false, "show version")

	flag.Usage = func() {
		fmt.Fprintf(os.Stderr, "Usage: duzzle [options]\n\n")
		fmt.Fprintf(os.Stderr, "Duzzle - Standalone Material 3 Puzzle Hub & Daily Games\n\nOptions:\n")
		flag.PrintDefaults()
	}

	flag.Parse()

	if *showVersion {
		fmt.Printf("duzzle version %s (built %s, commit %s)\n", Version, BuildTime, Commit)
		return
	}

	qsDir, err := findQuickshellDir(*configDir)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}

	env := os.Environ()
	execPath, err := os.Executable()
	if err == nil {
		env = append(env, "DUZZLE_BIN="+execPath)
	}

	if *game != "" {
		env = append(env, "DUZZLE_INITIAL_GAME="+*game)
	}
	if *daily {
		env = append(env, "DUZZLE_INITIAL_DAILY=1")
	}

	fontCfg := theme.GetSystemFontSettings()
	if fontCfg.Family != "" {
		env = append(env, "DUZZLE_FONT_FAMILY="+fontCfg.Family)
	}
	if fontCfg.Scale > 0 {
		env = append(env, fmt.Sprintf("DUZZLE_FONT_SCALE=%.2f", fontCfg.Scale))
	}
	if fontCfg.Mono != "" {
		env = append(env, "DUZZLE_MONO_FONT="+fontCfg.Mono)
	}

	cmd := exec.Command("quickshell", "-p", qsDir)
	cmd.Env = env
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin

	if err := cmd.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "Error running quickshell: %v\n", err)
		os.Exit(1)
	}
}
