package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"

	"github.com/hthienloc/dankview/core/internal/exif"
	"github.com/hthienloc/dankview/core/internal/fs"
	"github.com/hthienloc/dankview/core/internal/theme"
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
		"/usr/local/share/quickshell/dankview",
		"/usr/share/quickshell/dankview",
	}

	if home, err := os.UserHomeDir(); err == nil {
		candidates = append(candidates,
			filepath.Join(home, ".local/share/quickshell/dankview"),
		)
	}

	execPath, err := os.Executable()
	if err == nil {
		execDir := filepath.Dir(execPath)
		candidates = append([]string{
			filepath.Join(execDir, "../quickshell"),
			filepath.Join(execDir, "quickshell"),
			filepath.Join(execDir, "../share/quickshell/dankview"),
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
	printInfo := flag.Bool("info", false, "print image metadata as JSON and exit")
	printList := flag.Bool("list", false, "print directory image list as JSON and exit")
	printGallery := flag.Bool("gallery", false, "print gallery data as JSON and exit")
	excludeFlag := flag.String("exclude", "", "comma-separated directories to exclude from gallery scan")
	restoreFlag := flag.Bool("restore", false, "restore trashed image and exit")

	flag.Usage = func() {
		fmt.Fprintf(os.Stderr, "Usage: dview [options] [image-path]\n\n")
		fmt.Fprintf(os.Stderr, "DankView - Standalone Material 3 Image Viewer\n\nOptions:\n")
		flag.PrintDefaults()
	}

	flag.Parse()

	if *showVersion {
		fmt.Printf("dview version %s (built %s, commit %s)\n", Version, BuildTime, Commit)
		return
	}

	if *printGallery {
		dir := ""
		var extraDirs []string
		if flag.NArg() > 0 {
			dir = flag.Arg(0)
			if flag.NArg() > 1 {
				extraDirs = flag.Args()[1:]
			}
		}
		var excludes []string
		if *excludeFlag != "" {
			for _, e := range strings.Split(*excludeFlag, ",") {
				if t := strings.TrimSpace(e); t != "" {
					excludes = append(excludes, t)
				}
			}
		}
		data, err := fs.ScanGallery(dir, excludes, extraDirs...)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error scanning gallery: %v\n", err)
			os.Exit(1)
		}
		enc := json.NewEncoder(os.Stdout)
		enc.SetIndent("", "  ")
		enc.Encode(data)
		return
	}

	if *restoreFlag {
		target := ""
		if flag.NArg() > 0 {
			target = flag.Arg(0)
		}
		restored, err := fs.RestoreLastTrashed(target)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error restoring file: %v\n", err)
			os.Exit(1)
		}
		if restored != "" {
			fmt.Println(restored)
		}
		return
	}

	var initialImage string
	var imgList *fs.ImageList

	if flag.NArg() > 0 {
		targetPath := flag.Arg(0)
		if strings.HasPrefix(targetPath, "file://") {
			if u, err := url.Parse(targetPath); err == nil {
				targetPath = u.Path
			} else {
				targetPath = strings.TrimPrefix(targetPath, "file://")
			}
		}
		if unescaped, err := url.PathUnescape(targetPath); err == nil {
			targetPath = unescaped
		}

		absPath, err := filepath.Abs(targetPath)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error resolving path: %v\n", err)
			os.Exit(1)
		}

		if *printInfo {
			meta, err := exif.GetMetadata(absPath)
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

		var scanErr error
		imgList, scanErr = fs.ScanDirectory(absPath)
		if scanErr != nil {
			imgList = &fs.ImageList{
				Directory:    filepath.Dir(absPath),
				Files:        []string{absPath},
				CurrentIndex: 0,
			}
		}

		initialImage = absPath
		if len(imgList.Files) > 0 && imgList.CurrentIndex < len(imgList.Files) {
			initialImage = imgList.Files[imgList.CurrentIndex]
		}
	} else if *printInfo || *printList {
		fmt.Fprintf(os.Stderr, "Error: no image path provided\n")
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
		env = append(env, "DVIEW_BIN="+execPath)
	}

	if initialImage != "" {
		env = append(env, "DVIEW_INITIAL_IMAGE="+initialImage)
	}
	if imgList != nil {
		env = append(env,
			"DVIEW_DIR="+imgList.Directory,
			"DVIEW_INDEX="+strconv.Itoa(imgList.CurrentIndex),
		)
	}

	fontCfg := theme.GetSystemFontSettings()
	if fontCfg.Family != "" {
		env = append(env, "DVIEW_FONT_FAMILY="+fontCfg.Family)
	}
	if fontCfg.Scale > 0 {
		env = append(env, fmt.Sprintf("DVIEW_FONT_SCALE=%.2f", fontCfg.Scale))
	}
	if fontCfg.Mono != "" {
		env = append(env, "DVIEW_MONO_FONT="+fontCfg.Mono)
	}
	if *fullscreen {
		env = append(env, "DVIEW_FULLSCREEN=1")
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
