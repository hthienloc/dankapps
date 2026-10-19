package fs

import (
	"crypto/md5"
	"encoding/binary"
	"encoding/hex"
	"encoding/json"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"
	"sync"
	"syscall"
	"time"
)

type fileID struct {
	dev uint64
	ino uint64
}

func getFileID(fi os.FileInfo) (fileID, bool) {
	if stat, ok := fi.Sys().(*syscall.Stat_t); ok {
		return fileID{dev: uint64(stat.Dev), ino: uint64(stat.Ino)}, true
	}
	return fileID{}, false
}

var exifBufPool = sync.Pool{
	New: func() interface{} {
		b := make([]byte, 65536)
		return &b
	},
}

// GalleryImage represents a single image with metadata for the gallery.
type GalleryImage struct {
	Path      string `json:"path"`
	Thumbnail string `json:"thumbnail"`
	Name      string `json:"name"`
	ModTime   int64  `json:"modTime"`
	SortTime  int64  `json:"sortTime"`
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

func canonicalPath(p string) string {
	clean := filepath.Clean(p)
	if realP, err := filepath.EvalSymlinks(clean); err == nil {
		return filepath.Clean(realP)
	}
	return clean
}

func parseTiffExifDate(data []byte) (time.Time, bool) {
	if len(data) < 8 {
		return time.Time{}, false
	}
	var bo binary.ByteOrder
	if data[0] == 'I' && data[1] == 'I' {
		bo = binary.LittleEndian
	} else if data[0] == 'M' && data[1] == 'M' {
		bo = binary.BigEndian
	} else {
		return time.Time{}, false
	}
	if bo.Uint16(data[2:4]) != 42 {
		return time.Time{}, false
	}
	ifdOffset := int(bo.Uint32(data[4:8]))
	if ifdOffset < 0 || ifdOffset+2 > len(data) {
		return time.Time{}, false
	}

	readEntries := func(offset int) map[uint16][]byte {
		if offset < 0 || offset+2 > len(data) {
			return nil
		}
		numEntries := int(bo.Uint16(data[offset : offset+2]))
		curr := offset + 2
		tags := make(map[uint16][]byte)
		for i := 0; i < numEntries; i++ {
			if curr+12 > len(data) {
				break
			}
			tag := bo.Uint16(data[curr : curr+2])
			typ := bo.Uint16(data[curr+2 : curr+4])
			count := int(bo.Uint32(data[curr+4 : curr+8]))
			valOffsetBytes := data[curr+8 : curr+12]

			if typ == 2 && count > 0 { // ASCII string
				if count <= 4 {
					tags[tag] = valOffsetBytes[:count]
				} else {
					vOff := int(bo.Uint32(valOffsetBytes))
					if vOff >= 0 && vOff+count <= len(data) {
						tags[tag] = data[vOff : vOff+count]
					}
				}
			} else if (typ == 3 || typ == 4) && count == 1 { // SHORT or LONG
				tags[tag] = valOffsetBytes
			}
			curr += 12
		}
		return tags
	}

	var ifd0Date string
	var exifSubIfdOffset int
	ifd0Tags := readEntries(ifdOffset)
	if ifd0Tags != nil {
		if val, ok := ifd0Tags[0x0132]; ok { // DateTime
			ifd0Date = strings.TrimRight(string(val), "\x00")
		}
		if val, ok := ifd0Tags[0x8769]; ok && len(val) >= 4 { // ExifOffset
			exifSubIfdOffset = int(bo.Uint32(val))
		}
	}

	if exifSubIfdOffset > 0 && exifSubIfdOffset+2 <= len(data) {
		subTags := readEntries(exifSubIfdOffset)
		if subTags != nil {
			if val, ok := subTags[0x9003]; ok { // DateTimeOriginal
				origDate := strings.TrimRight(string(val), "\x00")
				if t, err := time.ParseInLocation("2006:01:02 15:04:05", origDate, time.Local); err == nil {
					return t, true
				}
			}
		}
	}

	if ifd0Date != "" {
		if t, err := time.ParseInLocation("2006:01:02 15:04:05", ifd0Date, time.Local); err == nil {
			return t, true
		}
	}

	return time.Time{}, false
}

// extractExifDate extracts the EXIF DateTimeOriginal (or DateTime) if present in a JPEG header.
func extractExifDate(path string, fallback time.Time) time.Time {
	ext := strings.ToLower(filepath.Ext(path))
	if ext != ".jpg" && ext != ".jpeg" {
		return fallback
	}

	f, err := os.Open(path)
	if err != nil {
		return fallback
	}
	defer f.Close()

	bufPtr := exifBufPool.Get().(*[]byte)
	defer exifBufPool.Put(bufPtr)
	header := *bufPtr

	n, err := f.Read(header)
	if err != nil || n < 16 {
		return fallback
	}
	buf := header[:n]

	if buf[0] != 0xFF || buf[1] != 0xD8 {
		return fallback
	}

	pos := 2
	for pos < len(buf)-4 {
		if buf[pos] != 0xFF {
			pos++
			continue
		}
		marker := buf[pos+1]
		if marker == 0xD9 || marker == 0xDA { // EOI or SOS
			break
		}
		if marker == 0x00 || (marker >= 0xD0 && marker <= 0xD7) { // RST
			pos += 2
			continue
		}
		segLen := int(binary.BigEndian.Uint16(buf[pos+2 : pos+4]))
		if segLen < 2 {
			break
		}
		if marker == 0xE1 { // APP1 segment
			segEnd := pos + 2 + segLen
			if segEnd > len(buf) {
				segEnd = len(buf)
			}
			exifPayload := buf[pos+4 : segEnd]
			if len(exifPayload) > 14 && string(exifPayload[:6]) == "Exif\x00\x00" {
				if t, ok := parseTiffExifDate(exifPayload[6:]); ok {
					return t
				}
			}
		}
		pos += 2 + segLen
	}

	return fallback
}

func addGalleryImage(
	path, absRoot, thumbDir, name string,
	modTime time.Time,
	actualTime time.Time,
	today, yesterday time.Time,
	albumMap map[string]*GalleryAlbum,
	categorySet map[string]bool,
) GalleryImage {
	parentDir := filepath.Dir(path)
	category := "Pictures"
	albumDir := absRoot
	if parentDir != absRoot {
		rel, err := filepath.Rel(absRoot, parentDir)
		if err == nil && rel != "." {
			topFolder := strings.Split(rel, string(os.PathSeparator))[0]
			category = topFolder
			albumDir = filepath.Join(absRoot, topFolder)
		} else {
			category = filepath.Base(parentDir)
			albumDir = parentDir
		}
	}

	if _, exists := albumMap[albumDir]; !exists {
		isPinned := strings.EqualFold(category, "Screenshots") || strings.EqualFold(category, "Wallpapers")
		albumMap[albumDir] = &GalleryAlbum{
			Name:     category,
			Path:     albumDir,
			IsPinned: isPinned,
			Previews: []string{},
		}
	}

	thumbPath := resolveXdgThumbnail(path, thumbDir)

	img := GalleryImage{
		Path:      path,
		Thumbnail: thumbPath,
		Name:      name,
		ModTime:   modTime.Unix(),
		SortTime:  actualTime.Unix(),
		DateGroup: computeDateGroup(actualTime, today, yesterday),
		Category:  category,
	}

	categorySet[category] = true

	if alb, ok := albumMap[albumDir]; ok {
		alb.TotalCount++
		if len(alb.Previews) < 4 {
			alb.Previews = append(alb.Previews, path)
		}
	}

	return img
}

// tryScanWithDsearch attempts to query danksearch index for instant results.
func tryScanWithDsearch(
	absRoot string,
	thumbDir string,
	today, yesterday time.Time,
	isExcluded func(string) bool,
	seenCanonical map[string]bool,
	seenInodes map[fileID]bool,
) ([]GalleryImage, map[string]*GalleryAlbum, map[string]bool, bool) {
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
	if !isExcluded(screenshotDir) {
		albumMap[screenshotDir] = &GalleryAlbum{
			Name:     "Screenshots",
			Path:     screenshotDir,
			IsPinned: true,
			Previews: []string{},
		}
	}

	for _, hit := range res.Hits {
		p := filepath.Clean(hit.ID)
		if isExcluded(p) || !IsSupportedImage(p) {
			continue
		}
		canon := canonicalPath(p)
		if seenCanonical[canon] {
			continue
		}
		fi, err := os.Stat(p)
		if err != nil || fi.IsDir() {
			continue
		}
		if id, ok := getFileID(fi); ok {
			if seenInodes[id] {
				continue
			}
			seenInodes[id] = true
		}
		if strings.HasPrefix(fi.Name(), ".") {
			continue
		}

		seenCanonical[canon] = true
		actualTime := extractExifDate(p, fi.ModTime())
		img := addGalleryImage(p, absRoot, thumbDir, fi.Name(), fi.ModTime(), actualTime, today, yesterday, albumMap, categorySet)
		allImages = append(allImages, img)
	}

	if len(allImages) == 0 {
		return nil, nil, nil, false
	}

	return allImages, albumMap, categorySet, true
}

// ScanGallery scans rootDir and its subdirectories (plus any extraDirs) for images,
// ignoring any directories in excludedDirs, and organizes them into GalleryData.
func ScanGallery(rootDir string, excludedDirs []string, extraDirs ...string) (*GalleryData, error) {
	if rootDir == "" {
		rootDir = GetPicturesDir()
	}

	absRoot, err := filepath.Abs(rootDir)
	if err != nil {
		return nil, err
	}
	absRoot = filepath.Clean(absRoot)

	var canonicalExcludes []string
	for _, ex := range excludedDirs {
		trimmed := strings.TrimSpace(ex)
		if trimmed != "" {
			if abs, err := filepath.Abs(trimmed); err == nil {
				canonicalExcludes = append(canonicalExcludes, canonicalPath(abs))
			}
		}
	}

	isExcluded := func(p string) bool {
		if len(canonicalExcludes) == 0 {
			return false
		}
		canon := canonicalPath(p)
		for _, ex := range canonicalExcludes {
			if canon == ex || strings.HasPrefix(canon, ex+string(os.PathSeparator)) {
				return true
			}
		}
		return false
	}

	now := time.Now()
	today := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())
	yesterday := today.AddDate(0, 0, -1)

	var allImages []GalleryImage
	albumMap := make(map[string]*GalleryAlbum)
	categorySet := make(map[string]bool)
	explicitAlbums := make(map[string]bool)
	seenCanonical := make(map[string]bool)
	seenInodes := make(map[fileID]bool)

	thumbDir := ""
	if cacheDir, err := os.UserCacheDir(); err == nil {
		thumbDir = filepath.Join(cacheDir, "thumbnails")
	}

	if !isExcluded(absRoot) {
		// Try danksearch (dsearch) first for instant indexing results
		if dsearchImages, dsearchAlbums, dsearchCats, ok := tryScanWithDsearch(absRoot, thumbDir, today, yesterday, isExcluded, seenCanonical, seenInodes); ok {
			allImages = dsearchImages
			albumMap = dsearchAlbums
			categorySet = dsearchCats
		} else {
			// Fallback to filesystem traversal
			screenshotDir := filepath.Join(absRoot, "Screenshots")
			if !isExcluded(screenshotDir) {
				albumMap[screenshotDir] = &GalleryAlbum{
					Name:     "Screenshots",
					Path:     screenshotDir,
					IsPinned: true,
					Previews: []string{},
				}
			}

			// Walk up to 5 levels deep, skipping hidden directories
			_ = filepath.Walk(absRoot, func(path string, info os.FileInfo, err error) error {
				if err != nil || info == nil {
					return nil
				}

				if isExcluded(path) {
					if info.IsDir() {
						return filepath.SkipDir
					}
					return nil
				}

				name := info.Name()
				if strings.HasPrefix(name, ".") && path != absRoot {
					if info.IsDir() {
						return filepath.SkipDir
					}
					return nil
				}

				rel, relErr := filepath.Rel(absRoot, path)
				if relErr == nil {
					depth := len(strings.Split(rel, string(os.PathSeparator)))
					if info.IsDir() && depth > 5 && rel != "." {
						return filepath.SkipDir
					}
				}

				if info.IsDir() {
					if id, ok := getFileID(info); ok {
						if seenInodes[id] {
							return filepath.SkipDir
						}
						seenInodes[id] = true
					}

					if path != absRoot && filepath.Dir(path) == absRoot {
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

				canon := canonicalPath(path)
				if seenCanonical[canon] {
					return nil
				}
				if id, ok := getFileID(info); ok {
					if seenInodes[id] {
						return nil
					}
					seenInodes[id] = true
				}
				seenCanonical[canon] = true

				actualTime := extractExifDate(path, info.ModTime())
				img := addGalleryImage(path, absRoot, thumbDir, info.Name(), info.ModTime(), actualTime, today, yesterday, albumMap, categorySet)
				allImages = append(allImages, img)
				return nil
			})
		}
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
		absExtra = filepath.Clean(absExtra)
		if isExcluded(absExtra) {
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

		if id, ok := getFileID(fi); ok {
			if seenInodes[id] {
				// Already walked under absRoot or another directory; populate previews and count if not yet populated
				if alb.TotalCount == 0 {
					canonExtra := canonicalPath(absExtra)
					for _, img := range allImages {
						canonImg := canonicalPath(img.Path)
						if canonImg == canonExtra || strings.HasPrefix(canonImg, canonExtra+string(os.PathSeparator)) {
							alb.TotalCount++
							if len(alb.Previews) < 4 {
								alb.Previews = append(alb.Previews, img.Path)
							}
						}
					}
				}
				continue
			}
			seenInodes[id] = true
		}

		_ = filepath.Walk(absExtra, func(path string, info os.FileInfo, err error) error {
			if err != nil || info == nil {
				return nil
			}

			if isExcluded(path) {
				if info.IsDir() {
					return filepath.SkipDir
				}
				return nil
			}

			name := info.Name()
			if strings.HasPrefix(name, ".") && path != absExtra {
				if info.IsDir() {
					return filepath.SkipDir
				}
				return nil
			}

			rel, relErr := filepath.Rel(absExtra, path)
			if relErr == nil {
				depth := len(strings.Split(rel, string(os.PathSeparator)))
				if info.IsDir() && depth > 5 && rel != "." {
					return filepath.SkipDir
				}
			}

			if info.IsDir() {
				if id, ok := getFileID(info); ok {
					if seenInodes[id] {
						return filepath.SkipDir
					}
					seenInodes[id] = true
				}
				return nil
			}

			if !IsSupportedImage(path) {
				return nil
			}

			canon := canonicalPath(path)
			if seenCanonical[canon] {
				return nil
			}
			if id, ok := getFileID(info); ok {
				if seenInodes[id] {
					return nil
				}
				seenInodes[id] = true
			}
			seenCanonical[canon] = true

			actualTime := extractExifDate(path, info.ModTime())
			thumbPath := resolveXdgThumbnail(path, thumbDir)
			img := GalleryImage{
				Path:      path,
				Thumbnail: thumbPath,
				Name:      info.Name(),
				ModTime:   info.ModTime().Unix(),
				SortTime:  actualTime.Unix(),
				DateGroup: computeDateGroup(actualTime, today, yesterday),
				Category:  albumName,
			}
			allImages = append(allImages, img)
			alb.TotalCount++
			if len(alb.Previews) < 4 {
				alb.Previews = append(alb.Previews, path)
			}
			return nil
		})

		// If extra directory was already traversed under absRoot, populate previews and count
		if alb.TotalCount == 0 {
			canonExtra := canonicalPath(absExtra)
			for _, img := range allImages {
				canonImg := canonicalPath(img.Path)
				if canonImg == canonExtra || strings.HasPrefix(canonImg, canonExtra+string(os.PathSeparator)) {
					alb.TotalCount++
					if len(alb.Previews) < 4 {
						alb.Previews = append(alb.Previews, img.Path)
					}
				}
			}
		}
	}

	// For any image that belongs to an extraDir, update its category to albumName if nested
	for _, extra := range extraDirs {
		trimmed := strings.TrimSpace(extra)
		if trimmed == "" {
			continue
		}
		if absExtra, err := filepath.Abs(trimmed); err == nil {
			canonExtra := canonicalPath(absExtra)
			albumName := filepath.Base(canonExtra)
			for i := range allImages {
				canonImg := canonicalPath(allImages[i].Path)
				if canonImg == canonExtra || strings.HasPrefix(canonImg, canonExtra+string(os.PathSeparator)) {
					allImages[i].Category = albumName
				}
			}
		}
	}

	// Sort images newest first (by SortTime, then ModTime)
	sort.Slice(allImages, func(i, j int) bool {
		if allImages[i].SortTime != allImages[j].SortTime {
			return allImages[i].SortTime > allImages[j].SortTime
		}
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
