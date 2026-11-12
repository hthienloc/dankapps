package main

import (
	"os"

	"github.com/duxlabs-dev/dux-clock/core/internal/qtbaseembed"
	"github.com/duxlabs-dev/dux-clock/core/internal/shellembed"
	"github.com/duxlabs-dev/dux-go/log"
	"github.com/duxlabs-dev/dux-go/qtbase"
	"github.com/duxlabs-dev/dux-go/shellapp"
)

var (
	Version   = "0.1.0"
	BuildTime = "unknown"
	Commit    = "unknown"
)

var shellApp = shellapp.New(shellapp.Config{
	ID:       "dankclock",
	QSAppID:  "com.danklinux.dankclock",
	Version:  Version,
	Embedded: embeddedShell{},
	QtBase:   qtbaseembed.Extract,
	Boot:     bootBackend,
	ExtraEnv: uiEnv,
})

func uiEnv(string) []string {
	return nil
}

type embeddedShell struct{}

func (embeddedShell) Available() bool { return shellembed.Available() }

func (embeddedShell) Extract(baseDir string) (string, error) {
	return shellembed.Extract(baseDir)
}

func (embeddedShell) Prune(baseDir, keep string) {
	shellembed.Prune(baseDir, keep)
}

func main() {
	log.SetEnvPrefix("DCLOCK")
	qtbase.MaybeRunAndExit(qtbaseembed.Extract)
	if err := rootCmd.Execute(); err != nil {
		log.Errorf("%v", err)
		os.Exit(1)
	}
}
