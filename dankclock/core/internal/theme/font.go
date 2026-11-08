package theme

import (
	"encoding/json"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
)

// FontSettings holds typography configuration from DMS or desktop settings.
type FontSettings struct {
	Family string
	Scale  float64
	Mono   string
}

// GetSystemFontSettings queries font configuration from ~/.config/DankMaterialShell/settings.json,
// falling back to org.gnome.desktop.interface font-name via gsettings.
func GetSystemFontSettings() FontSettings {
	settings := FontSettings{
		Scale: 1.0,
	}

	home, err := os.UserHomeDir()
	if err == nil {
		dmsPath := filepath.Join(home, ".config", "DankMaterialShell", "settings.json")
		if data, err := os.ReadFile(dmsPath); err == nil {
			var raw struct {
				FontFamily     string  `json:"fontFamily"`
				MonoFontFamily string  `json:"monoFontFamily"`
				FontScale      float64 `json:"fontScale"`
			}
			if err := json.Unmarshal(data, &raw); err == nil {
				if raw.FontFamily != "" {
					settings.Family = raw.FontFamily
				}
				if raw.MonoFontFamily != "" {
					settings.Mono = raw.MonoFontFamily
				}
				if raw.FontScale > 0 {
					settings.Scale = raw.FontScale
				}
			}
		}
	}

	if settings.Family == "" {
		out, err := exec.Command("gsettings", "get", "org.gnome.desktop.interface", "font-name").Output()
		if err == nil {
			f := strings.Trim(string(out), "'\n\" ")
			fields := strings.Fields(f)
			if len(fields) > 1 {
				if _, err := strconv.ParseFloat(fields[len(fields)-1], 64); err == nil {
					settings.Family = strings.Join(fields[:len(fields)-1], " ")
				} else {
					settings.Family = f
				}
			} else {
				settings.Family = f
			}
		}
	}

	return settings
}
