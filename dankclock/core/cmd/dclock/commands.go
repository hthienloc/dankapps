package main

import (
	"github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
	Use:   "dclock",
	Short: "DankClock - Standalone Material 3 Clock, Alarm, Timer & Stopwatch",
}

var showCmd = &cobra.Command{
	Use:     "show",
	Short:   "Show the clock window, launching dclock if it is not running",
	PreRunE: shellApp.ResolveConfig,
	RunE: func(_ *cobra.Command, _ []string) error {
		return shellApp.CallOrLaunch("ui.show", nil)
	},
}

var toggleCmd = &cobra.Command{
	Use:     "toggle",
	Short:   "Toggle clock window visibility, launching dclock if it is not running",
	PreRunE: shellApp.ResolveConfig,
	RunE: func(_ *cobra.Command, _ []string) error {
		return shellApp.CallOrLaunch("ui.toggle", nil)
	},
}

var daemonCmd = &cobra.Command{
	Use:   "daemon",
	Short: "Run the dclock daemon (IPC only, no UI)",
	RunE: func(_ *cobra.Command, _ []string) error {
		return shellApp.RunDaemon(false)
	},
}

func init() {
	rootCmd.AddCommand(showCmd)
	rootCmd.AddCommand(toggleCmd)
	rootCmd.AddCommand(daemonCmd)
	rootCmd.AddCommand(shellApp.Commands()...)
}
