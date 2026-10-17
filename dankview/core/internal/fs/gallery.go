package fs

import (
	"crypto/md5"
	"encoding/hex"
	"encoding/json"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"
	"time"
)

// GalleryImage represents a single image with metadata for the gallery.
type GalleryImage struct {
	Path      string `json:"path"`
	Thumbnail string `json:"thumbnail"`
	Name      string `json:"name"`
	ModTime   int64  `json:"modTime"`
	DateGroup string `json:"dateGroup"`
	Category  string `json:"category"`
}

// GalleryGroup groups images under a specific date header (e.g., "Today", "Yesterday").
type GalleryGroup struct {
	DateGroup string         `json:"dateGroup"`
	Images    []GalleryImage `json:"images"`
}

// GalleryAlbum represents a category/folder of images with preview thumbnails.
type GalleryAlbum struct {
	Name       string   `json:"name"`
	Path       string   `json:"path"`
	IsPinned   bool     `json:"isPinned"`
	Previews   []string `json:"previews"`
	TotalCount int      `json:"totalCount"`
}

// GalleryData is the payload returned to QML.
type GalleryData struct {
	AllImages  []GalleryImage `json:"allImages"`
	Groups     []GalleryGroup `json:"groups"`
	Albums     []GalleryAlbum `json:"albums"`
	Categories []string       `json:"categories"`
}

// GetPicturesDir returns the user's Pictures directory or fallback ~/Pictures.
func GetPicturesDir() string {
	if out, err := exec.Command("xdg-user-dir", "PICTURES").Output(); err == nil {
		dir := strings.TrimSpace(string(out))
		if dir != "" && dir != "/" {
			return dir
		}
	}
	if home, err := os.UserHomeDir(); err == nil {
		return filepath.Join(home, "Pictures")
	}
	return ""
}

// resolveXdgThumbnail finds the Freedesktop cached thumbnail if available.
func resolveXdgThumbnail(filePath string, thumbDir string) string {
	if thumbDir == "" {
		return ""
	}
	abs, err := filepath.Abs(filePath)
	if err != nil {
		return ""
	}
	// XDG format: "file://" + url.PathEscape(abs)
	uri := "file://" + (&url.URL{Path: abs}).EscapedPath()
	h := md5.Sum([]byte(uri))
	hashStr := hex.EncodeToString(h[:])
	fileName := hashStr + ".png"

	for _, size := range []string{"large", "normal", "x-large"} {
		cand := filepath.Join(thumbDir, size, fileName)
		if fi, err := os.Stat(cand); err == nil && !fi.IsDir() && fi.Size() > 0 {
			return cand
		}
	}
	return ""
}

func computeDateGroup(t time.Time, today, yesterday time.Time) string {
	fileDate := time.Date(t.Year(), t.Month(), t.Day(), 0, 0, 0, 0, t.Location())
	if !fileDate.Before(today) {
		return "Today"
	}
	if fileDate.Equal(yesterday) {
		return "Yesterday"
	}
	if fileDate.Year() == today.Year() {
		return t.Format("January 2")
	}
	return t.Format("January 2, 2006")
}

type dsearchHit struct {
	ID string `json:"id"`
}

type dsearchResult struct {
	Hits []dsearchHit `json:"hits"`
}

func addGalleryImage(
	path, absRoot, thumbDir, name string,
	modTime time.Time,
	today, yesterday time.Time,
	albumMap map[string]*GalleryAlbum,
	categorySet map[string]bool,
) GalleryImage {
	parentDir := filepath.Dir(path)
	category := "Pictures"
	if parentDir != absRoot {
		category = filepath.Base(parentDir)
		if _, exists := albumMap[parentDir]; !exists {
			isPinned := strings.EqualFold(category, "Screenshots") || strings.EqualFold(category, "Wallpapers")
			albumMap[parentDir] = &GalleryAlbum{
				Name:     category,
				Path:     parentDir,
				IsPinned: isPinned,
				Previews: []string{},
			}
		}
	}

	thumbPath := resolveXdgThumbnail(path, thumbDir)

	img := GalleryImage{
		Path:      path,
		Thumbnail: thumbPath,
		Name:      name,
		ModTime:   modTime.Unix(),
		DateGroup: computeDateGroup(modTime, today, yesterday),
		Category:  category,
	}

	categorySet[category] = true

	if alb, ok := albumMap[parentDir]; ok {
		alb.TotalCount++
		if len(alb.Previews) < 4 {
			alb.Previews = append(alb.Previews, path)
		}
	}

	return img
}

// tryScanWithDsearch attempts to query danksearch index for instant results.
func tryScanWithDsearch(absRoot string, thumbDir string, today, yesterday time.Time) ([]GalleryImage, map[string]*GalleryAlbum, map[string]bool, bool) {
	dsearchBin, err := exec.LookPath("dsearch")
	if err != nil {
		return nil, nil, nil, false
	}

	cmd := exec.Command(dsearchBin, "search", "", "--folder", absRoot, "--limit", "10000", "--json")
	out, err := cmd.Output()
	if err != nil {
		return nil, nil, nil, false
	}

	var res dsearchResult
	if err := json.Unmarshal(out, &res); err != nil || len(res.Hits) == 0 {
		return nil, nil, nil, false
	}

	var allImages []GalleryImage
	albumMap := make(map[string]*GalleryAlbum)
	categorySet := make(map[string]bool)

	screenshotDir := filepath.Join(absRoot, "Screenshots")
	albumMap[screenshotDir] = &GalleryAlbum{
		Name:     "Screenshots",
		Path:     screenshotDir,
		IsPinned: true,
		Previews: []string{},
	}

	for _, hit := range res.Hits {
		p := hit.ID
		if !IsSupportedImage(p) {
			continue
		}
		fi, err := os.Stat(p)
		if err != nil || fi.IsDir() {
			continue
		}

		img := addGalleryImage(p, absRoot, thumbDir, fi.Name(), fi.ModTime(), today, yesterday, albumMap, categorySet)
		allImages = append(allImages, img)
	}

	if len(allImages) == 0 {
		return nil, nil, nil, false
	}

	return allImages, albumMap, categorySet, true
}

// ScanGallery scans rootDir and its subdirectories (plus any extraDirs) for images and organizes them into GalleryData.
func ScanGallery(rootDir string, extraDirs ...string) (*GalleryData, error) {
	if rootDir == "" {
		rootDir = GetPicturesDir()
	}

	absRoot, err := filepath.Abs(rootDir)
	if err != nil {
		return nil, err
	}

	now := time.Now()
	today := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())
	yesterday := today.AddDate(0, 0, -1)

	var allImages []GalleryImage
	albumMap := make(map[string]*GalleryAlbum)
	categorySet := make(map[string]bool)
	explicitAlbums := make(map[string]bool)

	thumbDir := ""
	if cacheDir, err := os.UserCacheDir(); err == nil {
		thumbDir = filepath.Join(cacheDir, "thumbnails")
	}

	// Try danksearch (dsearch) first for instant indexing results
	if dsearchImages, dsearchAlbums, dsearchCats, ok := tryScanWithDsearch(absRoot, thumbDir, today, yesterday); ok {
		allImages = dsearchImages
		albumMap = dsearchAlbums
		categorySet = dsearchCats
	} else {
		// Fallback to filesystem traversal
		screenshotDir := filepath.Join(absRoot, "Screenshots")
		albumMap[screenshotDir] = &GalleryAlbum{
			Name:     "Screenshots",
			Path:     screenshotDir,
			IsPinned: true,
			Previews: []string{},
		}

		// Walk max 2 levels deep
		_ = filepath.Walk(absRoot, func(path string, info os.FileInfo, err error) error {
			if err != nil || info == nil {
				return nil
			}

			rel, relErr := filepath.Rel(absRoot, path)
			if relErr == nil {
				depth := len(strings.Split(rel, string(os.PathSeparator)))
				if info.IsDir() && depth > 2 && rel != "." {
					return filepath.SkipDir
				}
			}

			if info.IsDir() {
				if path != absRoot {
					albumName := info.Name()
					isPinned := strings.EqualFold(albumName, "Screenshots") || strings.EqualFold(albumName, "Wallpapers")
					if _, exists := albumMap[path]; !exists {
						albumMap[path] = &GalleryAlbum{
							Name:     albumName,
							Path:     path,
							IsPinned: isPinned,
							Previews: []string{},
						}
					}
				}
				return nil
			}

			if !IsSupportedImage(path) {
				return nil
			}

			img := addGalleryImage(path, absRoot, thumbDir, info.Name(), info.ModTime(), today, yesterday, albumMap, categorySet)
			allImages = append(allImages, img)
			return nil
		})
	}

	seenPaths := make(map[string]bool, len(allImages))
	for _, img := range allImages {
		seenPaths[img.Path] = true
	}

	// Scan any user-added extra folders
	for _, extra := range extraDirs {
		if strings.TrimSpace(extra) == "" {
			continue
		}
		absExtra, err := filepath.Abs(extra)
		if err != nil {
			continue
		}
		fi, err := os.Stat(absExtra)
		if err != nil || !fi.IsDir() {
			continue
		}

		explicitAlbums[absExtra] = true
		albumName := filepath.Base(absExtra)
		alb, exists := albumMap[absExtra]
		if !exists {
			alb = &GalleryAlbum{
				Name:     albumName,
				Path:     absExtra,
				IsPinned: false,
				Previews: []string{},
			}
			albumMap[absExtra] = alb
		}
		categorySet[albumName] = true

		_ = filepath.Walk(absExtra, func(path string, info os.FileInfo, err error) error {
			if err != nil || info == nil {
				return nil
			}
			rel, relErr := filepath.Rel(absExtra, path)
			if relErr == nil {
				depth := len(strings.Split(rel, string(os.PathSeparator)))
				if info.IsDir() && depth > 2 && rel != "." {
					return filepath.SkipDir
				}
			}
			if info.IsDir() || !IsSupportedImage(path) || seenPaths[path] {
				return nil
			}

			seenPaths[path] = true
			thumbPath := resolveXdgThumbnail(path, thumbDir)
			img := GalleryImage{
				Path:      path,
				Thumbnail: thumbPath,
				Name:      info.Name(),
				ModTime:   info.ModTime().Unix(),
				DateGroup: computeDateGroup(info.ModTime(), today, yesterday),
				Category:  albumName,
			}
			allImages = append(allImages, img)
			alb.TotalCount++
			if len(alb.Previews) < 4 {
				alb.Previews = append(alb.Previews, path)
			}
			return nil
		})
	}

	// Sort images newest first
	sort.Slice(allImages, func(i, j int) bool {
		return allImages[i].ModTime > allImages[j].ModTime
	})

	// Group by date
	groupMap := make(map[string][]GalleryImage)
	var dateOrder []string
	for _, img := range allImages {
		grp := img.DateGroup
		if _, exists := groupMap[grp]; !exists {
			dateOrder = append(dateOrder, grp)
		}
		groupMap[grp] = append(groupMap[grp], img)
	}

	var groups []GalleryGroup
	for _, grpName := range dateOrder {
		groups = append(groups, GalleryGroup{
			DateGroup: grpName,
			Images:    groupMap[grpName],
		})
	}

	// Build albums list (Pinned first, then custom)
	var pinnedAlbums []GalleryAlbum
	var customAlbums []GalleryAlbum
	for pathKey, alb := range albumMap {
		if alb.TotalCount > 0 || alb.IsPinned || explicitAlbums[pathKey] {
			if alb.IsPinned {
				pinnedAlbums = append(pinnedAlbums, *alb)
			} else {
				customAlbums = append(customAlbums, *alb)
			}
		}
	}

	sort.Slice(pinnedAlbums, func(i, j int) bool {
		return pinnedAlbums[i].Name < pinnedAlbums[j].Name
	})
	sort.Slice(customAlbums, func(i, j int) bool {
		return customAlbums[i].Name < customAlbums[j].Name
	})

	albums := append(pinnedAlbums, customAlbums...)

	// Build sorted categories: "All" first, then "Screenshots" if exists, then alphabetical
	var categories []string
	categories = append(categories, "All")
	if categorySet["Screenshots"] {
		categories = append(categories, "Screenshots")
	}
	var otherCats []string
	for cat := range categorySet {
		if cat != "All" && cat != "Screenshots" {
			otherCats = append(otherCats, cat)
		}
	}
	sort.Strings(otherCats)
	categories = append(categories, otherCats...)

	return &GalleryData{
		AllImages:  allImages,
		Groups:     groups,
		Albums:     albums,
		Categories: categories,
	}, nil
}
