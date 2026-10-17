package fs

import (
	"os"
	"path/filepath"
	"testing"
)

func TestIsSupportedImage(t *testing.T) {
	tests := []struct {
		path     string
		expected bool
	}{
		{"image.png", true},
		{"photo.JPG", true},
		{"banner.jpeg", true},
		{"graphic.webp", true},
		{"vector.svg", true},
		{"anim.gif", true},
		{"modern.avif", true},
		{"nextgen.jxl", true},
		{"document.pdf", false},
		{"notes.txt", false},
		{"binary.exe", false},
	}

	for _, tt := range tests {
		if got := IsSupportedImage(tt.path); got != tt.expected {
			t.Errorf("IsSupportedImage(%q) = %v; want %v", tt.path, got, tt.expected)
		}
	}
}

func TestScanDirectory(t *testing.T) {
	tmpDir := t.TempDir()

	img1 := filepath.Join(tmpDir, "a.png")
	img2 := filepath.Join(tmpDir, "b.jpg")
	nonImg := filepath.Join(tmpDir, "readme.txt")

	_ = os.WriteFile(img1, []byte("fake png"), 0o644)
	_ = os.WriteFile(img2, []byte("fake jpg"), 0o644)
	_ = os.WriteFile(nonImg, []byte("text"), 0o644)

	list, err := ScanDirectory(img2)
	if err != nil {
		t.Fatalf("ScanDirectory failed: %v", err)
	}

	if len(list.Files) != 2 {
		t.Errorf("expected 2 images, got %d", len(list.Files))
	}

	if list.CurrentIndex != 1 {
		t.Errorf("expected currentIndex to be 1 for b.jpg, got %d", list.CurrentIndex)
	}
}

func TestNaturalLess(t *testing.T) {
	tests := []struct {
		a        string
		b        string
		expected bool
	}{
		{"img1.png", "img2.png", true},
		{"img2.png", "img10.png", true},
		{"img10.png", "img2.png", false},
		{"photo_1_a.jpg", "photo_1_b.jpg", true},
		{"photo_2.jpg", "photo_10.jpg", true},
		{"Image.png", "image.png", false},
		{"a", "a1", true},
		{"file01.png", "file1.png", false},
		{"file1.png", "file01.png", true},
	}

	for _, tt := range tests {
		if got := NaturalLess(tt.a, tt.b); got != tt.expected {
			t.Errorf("NaturalLess(%q, %q) = %v; want %v", tt.a, tt.b, got, tt.expected)
		}
	}
}
