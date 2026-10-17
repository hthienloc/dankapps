package fs

import (
	"os"
	"path/filepath"
	"sort"
	"strings"
)

var supportedExtensions = map[string]bool{
	".jpg":  true,
	".jpeg": true,
	".png":  true,
	".gif":  true,
	".webp": true,
	".svg":  true,
	".bmp":  true,
	".ico":  true,
	".avif": true,
	".heic": true,
	".heif": true,
	".jxl":  true,
	".tif":  true,
	".tiff": true,
	".exr":  true,
	".hdr":  true,
	".tga":  true,
	".qoi":  true,
	".psd":  true,
	".dds":  true,
}

// IsSupportedImage checks if the file has a supported image extension.
func IsSupportedImage(path string) bool {
	ext := strings.ToLower(filepath.Ext(path))
	return supportedExtensions[ext]
}

// ImageList contains sorted images in a directory and the index of the selected file.
type ImageList struct {
	Directory    string   `json:"directory"`
	Files        []string `json:"files"`
	CurrentIndex int      `json:"currentIndex"`
}

// ScanDirectory finds all image files in the directory containing targetPath.
func ScanDirectory(targetPath string) (*ImageList, error) {
	absPath, err := filepath.Abs(targetPath)
	if err != nil {
		return nil, err
	}

	dir := absPath
	selectedFile := ""

	fileInfo, err := os.Stat(absPath)
	if err == nil && !fileInfo.IsDir() {
		dir = filepath.Dir(absPath)
		selectedFile = absPath
	}

	entries, err := os.ReadDir(dir)
	if err != nil {
		return nil, err
	}

	var images []string
	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}
		if IsSupportedImage(entry.Name()) {
			images = append(images, filepath.Join(dir, entry.Name()))
		}
	}

	sort.Slice(images, func(i, j int) bool {
		return NaturalLess(images[i], images[j])
	})

	currentIndex := 0
	if selectedFile != "" {
		for i, img := range images {
			if img == selectedFile {
				currentIndex = i
				break
			}
		}
	}

	return &ImageList{
		Directory:    dir,
		Files:        images,
		CurrentIndex: currentIndex,
	}, nil
}

// NaturalLess compares two strings using natural order (numeric comparison for digit runs, case-insensitive).
func NaturalLess(a, b string) bool {
	ia, ib := 0, 0
	la, lb := len(a), len(b)

	for ia < la && ib < lb {
		ca, cb := a[ia], b[ib]

		if isDigit(ca) && isDigit(cb) {
			startA := ia
			for ia < la && isDigit(a[ia]) {
				ia++
			}
			numA := a[startA:ia]

			startB := ib
			for ib < lb && isDigit(b[ib]) {
				ib++
			}
			numB := b[startB:ib]

			trimA := strings.TrimLeft(numA, "0")
			trimB := strings.TrimLeft(numB, "0")

			if len(trimA) != len(trimB) {
				return len(trimA) < len(trimB)
			}
			if trimA != trimB {
				return trimA < trimB
			}
			if len(numA) != len(numB) {
				return len(numA) < len(numB)
			}
			continue
		}

		caLow := toLower(ca)
		cbLow := toLower(cb)

		if caLow != cbLow {
			return caLow < cbLow
		}

		ia++
		ib++
	}

	return (la - ia) < (lb - ib)
}

func isDigit(b byte) bool {
	return b >= '0' && b <= '9'
}

func toLower(b byte) byte {
	if b >= 'A' && b <= 'Z' {
		return b + ('a' - 'A')
	}
	return b
}
