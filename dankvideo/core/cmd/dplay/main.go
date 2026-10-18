package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"

	"github.com/AvengeMedia/dankvideo/core/internal/fs"
	"github.com/AvengeMedia/dankvideo/core/internal/probe"
	"github.com/AvengeMedia/dankvideo/core/internal/theme"
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
		"/usr/local/share/quickshell/dankvideo",
		"/usr/share/quickshell/dankvideo",
	}

	if home, err := os.UserHomeDir(); err == nil {
		candidates = append(candidates,
			filepath.Join(home, ".local/share/quickshell/dankvideo"),
		)
	}

	execPath, err := os.Executable()
	if err == nil {
		execDir := filepath.Dir(execPath)
		candidates = append([]string{
			filepath.Join(execDir, "../quickshell"),
			filepath.Join(execDir, "quickshell"),
			filepath.Join(execDir, "../share/quickshell/dankvideo"),
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
	fullscreen := flag.Bool("f", false, "open in fullscreen mode")
	showVersion := flag.Bool("v", false, "show version")
	printInfo := flag.Bool("info", false, "print video metadata as JSON and exit")
	printList := flag.Bool("list", false, "print directory video list as JSON and exit")
	restoreFlag := flag.Bool("restore", false, "restore trashed video and exit")

	flag.Usage = func() {
		fmt.Fprintf(os.Stderr, "Usage: dplay [options] [video-path]\n\n")
		fmt.Fprintf(os.Stderr, "DankVideo - Standalone Material 3 Video Player\n\nOptions:\n")
		flag.PrintDefaults()
	}

	flag.Parse()

	if *showVersion {
		fmt.Printf("dplay version %s (built %s, commit %s)\n", Version, BuildTime, Commit)
		return
	}

	if *restoreFlag {
		target := ""
		if flag.NArg() > 0 {
			target, _ = filepath.Abs(flag.Arg(0))
		}
		restored, err := fs.RestoreLastTrashed(target)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error restoring video: %v\n", err)
			os.Exit(1)
		}
		if restored != "" {
			fmt.Println(restored)
		}
		return
	}

	var initialVideo string

	if flag.NArg() > 0 {
		targetPath := flag.Arg(0)
		absPath, err := filepath.Abs(targetPath)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error resolving path: %v\n", err)
			os.Exit(1)
		}

		if *printInfo {
			meta, err := probe.GetMediaInfo(absPath)
			if err != nil {
				fmt.Fprintf(os.Stderr, "Error reading metadata: %v\n", err)
				os.Exit(1)
			}
			enc := json.NewEncoder(os.Stdout)
			enc.SetIndent("", "  ")
			enc.Encode(meta)
			return
		}

		if *printList {
			list, err := fs.ScanDirectory(absPath)
			if err != nil {
				fmt.Fprintf(os.Stderr, "Error scanning directory: %v\n", err)
				os.Exit(1)
			}
			enc := json.NewEncoder(os.Stdout)
			enc.SetIndent("", "  ")
			enc.Encode(list)
			return
		}

		fi, err := os.Stat(absPath)
		if err == nil && fi.IsDir() {
			vList, err := fs.ScanDirectory(absPath)
			if err == nil && len(vList.Files) > 0 {
				initialVideo = vList.Files[0]
			} else {
				initialVideo = absPath
			}
		} else {
			initialVideo = absPath
		}
	} else if *printInfo || *printList {
		fmt.Fprintf(os.Stderr, "Error: no video path provided\n")
		os.Exit(1)
	}

	qsDir, err := findQuickshellDir(*configDir)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}

	env := os.Environ()
	execPath, err := os.Executable()
	if err == nil {
		env = append(env, "DPLAY_BIN="+execPath)
	}

	if initialVideo != "" {
		env = append(env, "DPLAY_INITIAL_VIDEO="+initialVideo)
		env = append(env, "DPLAY_DIR="+filepath.Dir(initialVideo))
	}

	fontCfg := theme.GetSystemFontSettings()
	if fontCfg.Family != "" {
		env = append(env, "DPLAY_FONT_FAMILY="+fontCfg.Family)
	}
	if fontCfg.Scale > 0 {
		env = append(env, fmt.Sprintf("DPLAY_FONT_SCALE=%.2f", fontCfg.Scale))
	}
	if fontCfg.Mono != "" {
		env = append(env, "DPLAY_MONO_FONT="+fontCfg.Mono)
	}
	if *fullscreen {
		env = append(env, "DPLAY_FULLSCREEN=1")
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
