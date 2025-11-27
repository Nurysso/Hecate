package services

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

// Result types with more metadata
type FileSearchResult struct {
	Path         string    `json:"path"`
	Type         string    `json:"type"`
	Found        bool      `json:"found"`
	Size         int64     `json:"size,omitempty"`
	ModTime      time.Time `json:"modTime,omitempty"`
	Matches      []string  `json:"matches,omitempty"`
	SearchScore  int       `json:"searchScore,omitempty"`
}

type OrganizerResult struct {
	Output       string   `json:"output"`
	Success      bool     `json:"success"`
	FilesChanged int      `json:"filesChanged,omitempty"`
	Path         string   `json:"path"`
	Mode         string   `json:"mode"`
}

type LinterResult struct {
	Output      string `json:"output"`
	Fixed       bool   `json:"fixed"`
	FilePath    string `json:"filePath"`
	LinterUsed  string `json:"linterUsed"`
	ErrorCount  int    `json:"errorCount,omitempty"`
}

type OCRResult struct {
	Text       string `json:"text"`
	Success    bool   `json:"success"`
	Mode       string `json:"mode"`
	WordCount  int    `json:"wordCount,omitempty"`
	Confidence string `json:"confidence,omitempty"`
}

type ConverterResult struct {
	OutputPath  string `json:"outputPath"`
	Success     bool   `json:"success"`
	InputFormat string `json:"inputFormat"`
	OutputFormat string `json:"outputFormat"`
	FileSize    int64  `json:"fileSize,omitempty"`
}

type AutoCompleteResult struct {
	Suggestions []string `json:"suggestions"`
	IsPath      bool     `json:"isPath"`
	Total       int      `json:"total"`
}

// FileSearchService with enhanced search capabilities
type FileSearchService struct {
	maxDepth     int
	maxResults   int
}

func NewFileSearchService() *FileSearchService {
	return &FileSearchService{
		maxDepth:   10,
		maxResults: 5,
	}
}

// Search with scoring and multiple results
func (fs *FileSearchService) Search(query string) (FileSearchResult, error) {
	searchTerms := extractSearchTerms(query)

	homeDir, _ := os.UserHomeDir()
	searchPaths := []string{
		filepath.Join(homeDir, ".config"),
		homeDir, // Search home as fallback
	}

	type candidate struct {
		path  string
		score int
		info  os.FileInfo
	}

	candidates := []candidate{}

	for _, searchPath := range searchPaths {
		// depth := 0
		filepath.Walk(searchPath, func(path string, info os.FileInfo, err error) error {
			if err != nil {
				return nil
			}

			// Control recursion depth
			relPath, _ := filepath.Rel(searchPath, path)
			currentDepth := strings.Count(relPath, string(os.PathSeparator))
			if currentDepth > fs.maxDepth {
				if info.IsDir() {
					return filepath.SkipDir
				}
				return nil
			}
			// depth := currentDepth

			// Skip hidden directories except .config
			if info.IsDir() && strings.HasPrefix(info.Name(), ".") &&
			   info.Name() != ".config" {
				return filepath.SkipDir
			}

			fileName := strings.ToLower(filepath.Base(path))
			lowerPath := strings.ToLower(path)

			// Calculate match score
			score := 0
			matchedTerms := 0

			for _, term := range searchTerms {
				if fileName == term || fileName == term+".conf" ||
				   fileName == term+".config" || fileName == term+".json" {
					score += 100
				} else if strings.HasPrefix(fileName, term) {
					score += 50
				} else if strings.Contains(fileName, term) {
					score += 25
				} else if strings.Contains(lowerPath, term) {
					score += 10
				}

				if strings.Contains(lowerPath, term) {
					matchedTerms++
				}
			}

			// Bonus for .config directory
			if strings.Contains(path, ".config") {
				score += 20
			}

			// Only consider if all terms are matched
			if matchedTerms == len(searchTerms) && score > 0 {
				candidates = append(candidates, candidate{
					path:  path,
					score: score,
					info:  info,
				})
			}

			return nil
		})
	}

	if len(candidates) == 0 {
		return FileSearchResult{Found: false}, fmt.Errorf("file not found")
	}

	// Sort by score (simple bubble sort for small lists)
	for i := 0; i < len(candidates)-1; i++ {
		for j := 0; j < len(candidates)-i-1; j++ {
			if candidates[j].score < candidates[j+1].score {
				candidates[j], candidates[j+1] = candidates[j+1], candidates[j]
			}
		}
	}

	// Return best match with alternatives
	best := candidates[0]
	fileType := "file"
	if best.info.IsDir() {
		fileType = "directory"
	}

	matches := []string{}
	limit := min(fs.maxResults, len(candidates))
	for i := 1; i < limit; i++ {
		matches = append(matches, candidates[i].path)
	}

	return FileSearchResult{
		Path:        best.path,
		Type:        fileType,
		Found:       true,
		Size:        best.info.Size(),
		ModTime:     best.info.ModTime(),
		Matches:     matches,
		SearchScore: best.score,
	}, nil
}

// Enhanced autocomplete with better context awareness
func (fs *FileSearchService) AutoComplete(partial string) ([]string, error) {
	if partial == "" {
		cwd, _ := os.Getwd()
		return []string{cwd + "/"}, nil
	}

	// Expand ~ to home directory
	if strings.HasPrefix(partial, "~") {
		homeDir, _ := os.UserHomeDir()
		partial = filepath.Join(homeDir, partial[1:])
	}

	// Handle relative paths
	if !filepath.IsAbs(partial) && !strings.HasPrefix(partial, "~") {
		cwd, _ := os.Getwd()
		partial = filepath.Join(cwd, partial)
	}

	dir := filepath.Dir(partial)
	prefix := filepath.Base(partial)

	if _, err := os.Stat(dir); os.IsNotExist(err) {
		return []string{}, nil
	}

	var matches []string
	entries, err := os.ReadDir(dir)
	if err != nil {
		return matches, err
	}

	for _, entry := range entries {
		name := entry.Name()

		// Skip hidden files unless explicitly searching for them
		if strings.HasPrefix(name, ".") && !strings.HasPrefix(prefix, ".") {
			continue
		}

		if strings.HasPrefix(strings.ToLower(name), strings.ToLower(prefix)) {
			fullPath := filepath.Join(dir, name)
			if entry.IsDir() {
				fullPath += "/"
			}
			matches = append(matches, fullPath)
		}
	}

	// Limit results
	if len(matches) > 20 {
		matches = matches[:20]
	}

	return matches, nil
}

func (fs *FileSearchService) GetPathSuggestions(input string, forceFromStart bool) (AutoCompleteResult, error) {
	isPath := forceFromStart || strings.Contains(input, "/") ||
	          strings.Contains(input, "~") || strings.HasPrefix(input, ".")

	if !isPath {
		return AutoCompleteResult{Suggestions: []string{}, IsPath: false, Total: 0}, nil
	}

	pathPart := extractPathFromInput(input)
	if pathPart == "" && forceFromStart {
		pathPart = "./"
	}

	suggestions, err := fs.AutoComplete(pathPart)
	if err != nil {
		return AutoCompleteResult{Suggestions: []string{}, IsPath: true, Total: 0}, err
	}

	return AutoCompleteResult{
		Suggestions: suggestions,
		IsPath:      true,
		Total:       len(suggestions),
	}, nil
}

// OrganizerService with better feedback
type OrganizerService struct{}

func NewOrganizerService() *OrganizerService {
	return &OrganizerService{}
}

func (o *OrganizerService) Organize(query, mode string) (OrganizerResult, error) {
	path := extractPath(query)
	homeDir, _ := os.UserHomeDir()

	if path == "" {
		path = "."
	}

	if strings.HasPrefix(path, "~") {
		path = filepath.Join(homeDir, path[1:])
	}

	// Verify path exists
	if _, err := os.Stat(path); os.IsNotExist(err) {
		return OrganizerResult{Success: false}, fmt.Errorf("path does not exist: %s", path)
	}

	var cmd *exec.Cmd
	if mode == "filename" {
		cmd = exec.Command("kondo", "-f", "-nui", path)
	} else {
		cmd = exec.Command("kondo", "-c", "-nui", path)
	}

	cmd.Env = append(os.Environ(),
		"PATH="+os.Getenv("PATH")+":"+filepath.Join(homeDir, ".local/bin"))

	output, err := cmd.CombinedOutput()

	// Count files changed (rough estimate)
	filesChanged := strings.Count(string(output), "→")

	return OrganizerResult{
		Output:       string(output),
		Success:      err == nil,
		FilesChanged: filesChanged,
		Path:         path,
		Mode:         mode,
	}, err
}

func (o *OrganizerService) GetPathSuggestions(input string) (AutoCompleteResult, error) {
	fs := NewFileSearchService()
	return fs.GetPathSuggestions(input, true)
}

// LinterService with better error reporting
type LinterService struct{}

func NewLinterService() *LinterService {
	return &LinterService{}
}

func (ls *LinterService) LintFormat(query string) (LinterResult, error) {
	filePath := extractPath(query)
	if filePath == "" {
		return LinterResult{}, fmt.Errorf("no file path found in query")
	}

	// Verify file exists
	if _, err := os.Stat(filePath); os.IsNotExist(err) {
		return LinterResult{}, fmt.Errorf("file does not exist: %s", filePath)
	}

	ext := strings.ToLower(filepath.Ext(filePath))

	var cmd *exec.Cmd
	var linterName string

	switch ext {
	case ".py":
		cmd = exec.Command("black", filePath)
		linterName = "black"
	case ".go":
		cmd = exec.Command("gofmt", "-w", filePath)
		linterName = "gofmt"
	case ".sh":
		cmd = exec.Command("shfmt", "-w", filePath)
		linterName = "shfmt"
	case ".js", ".ts", ".jsx", ".tsx":
		cmd = exec.Command("prettier", "--write", filePath)
		linterName = "prettier"
	default:
		return LinterResult{}, fmt.Errorf("unsupported file type: %s", ext)
	}

	output, err := cmd.CombinedOutput()

	// Count errors (rough heuristic)
	errorCount := strings.Count(strings.ToLower(string(output)), "error")

	return LinterResult{
		Output:     string(output),
		Fixed:      err == nil,
		FilePath:   filePath,
		LinterUsed: linterName,
		ErrorCount: errorCount,
	}, err
}

func (ls *LinterService) GetPathSuggestions(input string) (AutoCompleteResult, error) {
	fs := NewFileSearchService()
	result, err := fs.GetPathSuggestions(input, true)

	if err != nil {
		return result, err
	}

	supportedExts := map[string]bool{
		".py": true, ".go": true, ".sh": true,
		".js": true, ".ts": true, ".jsx": true, ".tsx": true,
	}

	var filtered []string
	for _, path := range result.Suggestions {
		ext := strings.ToLower(filepath.Ext(path))
		if strings.HasSuffix(path, "/") || supportedExts[ext] {
			filtered = append(filtered, path)
		}
	}

	result.Suggestions = filtered
	result.Total = len(filtered)
	return result, nil
}

// OCRService with confidence estimation
type OCRService struct {
	scriptPath string
}

func NewOCRService() *OCRService {
	homeDir, _ := os.UserHomeDir()
	scriptPath := filepath.Join(homeDir, ".config/hecate/scripts/ocr-capture.sh")
	if _, err := os.Stat(scriptPath); err == nil {
		return &OCRService{scriptPath: scriptPath}
	}
	return &OCRService{}
}

func (ocr *OCRService) ExtractText() (OCRResult, error) {
	text, err := ocr.runOCR("", true)

	if err != nil {
		return OCRResult{
			Text:    text,
			Success: false,
			Mode:    "screen",
		}, err
	}

	return OCRResult{
		Text:       strings.TrimSpace(text),
		Success:    true,
		Mode:       "screen",
		WordCount:  len(strings.Fields(text)),
		Confidence: estimateConfidence(text),
	}, nil
}

func (ocr *OCRService) ExtractTextFromFile(imagePath string) (OCRResult, error) {
	if _, err := os.Stat(imagePath); os.IsNotExist(err) {
		return OCRResult{Success: false}, fmt.Errorf("image file not found: %s", imagePath)
	}

	text, err := ocr.runOCR(imagePath, false)

	if err != nil {
		return OCRResult{
			Text:    text,
			Success: false,
			Mode:    "file",
		}, err
	}

	return OCRResult{
		Text:       strings.TrimSpace(text),
		Success:    true,
		Mode:       "file",
		WordCount:  len(strings.Fields(text)),
		Confidence: estimateConfidence(text),
	}, nil
}

func (ocr *OCRService) runOCR(imagePath string, screenCapture bool) (string, error) {
	var cmd *exec.Cmd

	if screenCapture {
		if ocr.scriptPath != "" {
			cmd = exec.Command(ocr.scriptPath, "-au")
		} else {
			// Use inline script
			return ocr.runInlineOCRScript()
		}
	} else {
		cmd = exec.Command("tesseract", imagePath, "stdout")
	}

	output, err := cmd.CombinedOutput()
	return string(output), err
}

func (ocr *OCRService) runInlineOCRScript() (string, error) {
	scriptPath := "/tmp/ocr_capture.sh"
	script := `#!/bin/bash
set -e
TMPFILE="/tmp/ocr_screenshot_$(date +%s).png"
LANG="eng"

if ! grim -g "$(slurp)" "$TMPFILE" 2>/dev/null; then
    echo "Screenshot cancelled or failed" >&2
    exit 1
fi

OCR_OUTPUT=$(tesseract "$TMPFILE" stdout -l "$LANG" 2>/dev/null)
rm -f "$TMPFILE"

if [ -z "$OCR_OUTPUT" ]; then
    echo "No text detected" >&2
    exit 1
fi

echo "$OCR_OUTPUT"
exit 0
`

	if err := os.WriteFile(scriptPath, []byte(script), 0755); err != nil {
		return "", fmt.Errorf("failed to create OCR script: %w", err)
	}
	defer os.Remove(scriptPath)

	cmd := exec.Command("bash", scriptPath, "-au")
	output, err := cmd.CombinedOutput()

	return string(output), err
}

func (ocr *OCRService) GetPathSuggestions(input string) (AutoCompleteResult, error) {
	fs := NewFileSearchService()
	result, err := fs.GetPathSuggestions(input, true)

	if err != nil {
		return result, err
	}

	imageExts := map[string]bool{
		".png": true, ".jpg": true, ".jpeg": true,
		".bmp": true, ".tiff": true, ".tif": true,
		".gif": true, ".webp": true,
	}

	var filtered []string
	for _, path := range result.Suggestions {
		ext := strings.ToLower(filepath.Ext(path))
		if strings.HasSuffix(path, "/") || imageExts[ext] {
			filtered = append(filtered, path)
		}
	}

	result.Suggestions = filtered
	result.Total = len(filtered)
	return result, nil
}

// ConverterService with format detection
type ConverterService struct{}

func NewConverterService() *ConverterService {
	return &ConverterService{}
}

func (cs *ConverterService) Convert(query string) (ConverterResult, error) {
	inputPath := extractPath(query)
	if inputPath == "" {
		return ConverterResult{}, fmt.Errorf("no input file found")
	}

	targetFormat := extractFormat(query)
	if targetFormat == "" {
		return ConverterResult{}, fmt.Errorf("no target format specified")
	}

	return cs.ConvertWithFormat(inputPath, targetFormat)
}

func (cs *ConverterService) ConvertWithFormat(inputPath, targetFormat string) (ConverterResult, error) {
	// Verify input file exists
	_, err := os.Stat(inputPath)
	if os.IsNotExist(err) {
		return ConverterResult{}, fmt.Errorf("input file does not exist: %s", inputPath)
	}

	inputFormat := strings.TrimPrefix(filepath.Ext(inputPath), ".")
	outputPath := strings.TrimSuffix(inputPath, filepath.Ext(inputPath)) + "." + targetFormat

	// Check if output already exists
	if _, err := os.Stat(outputPath); err == nil {
		outputPath = strings.TrimSuffix(inputPath, filepath.Ext(inputPath)) +
		            "_converted." + targetFormat
	}

	cmd := exec.Command("ffmpeg", "-i", inputPath, "-y", outputPath)
	output, err := cmd.CombinedOutput()

	if err != nil {
		return ConverterResult{
			Success: false,
			InputFormat: inputFormat,
			OutputFormat: targetFormat,
		}, fmt.Errorf("conversion failed: %s", string(output))
	}

	outputInfo, _ := os.Stat(outputPath)

	return ConverterResult{
		OutputPath:   outputPath,
		Success:      true,
		InputFormat:  inputFormat,
		OutputFormat: targetFormat,
		FileSize:     outputInfo.Size(),
	}, nil
}

func (cs *ConverterService) GetPathSuggestions(input string) (AutoCompleteResult, error) {
	fs := NewFileSearchService()
	result, err := fs.GetPathSuggestions(input, true)

	if err != nil {
		return result, err
	}

	mediaExts := map[string]bool{
		".mp4": true, ".webm": true, ".avi": true, ".mkv": true, ".mov": true,
		".mp3": true, ".wav": true, ".flac": true, ".ogg": true, ".m4a": true,
		".png": true, ".jpg": true, ".jpeg": true, ".gif": true, ".webp": true,
	}

	var filtered []string
	for _, path := range result.Suggestions {
		ext := strings.ToLower(filepath.Ext(path))
		if strings.HasSuffix(path, "/") || mediaExts[ext] {
			filtered = append(filtered, path)
		}
	}

	result.Suggestions = filtered
	result.Total = len(filtered)
	return result, nil
}

// Helper functions
func extractPath(query string) string {
	words := strings.Fields(query)
	for _, word := range words {
		// Clean quotes
		word = strings.Trim(word, "\"'")

		if strings.Contains(word, "/") || strings.HasPrefix(word, "~") ||
		   strings.HasPrefix(word, ".") {
			return word
		}
	}
	return ""
}

func extractPathFromInput(input string) string {
	if strings.HasPrefix(input, "/") || strings.HasPrefix(input, "~") ||
	   strings.HasPrefix(input, "./") || strings.HasPrefix(input, "../") {
		return input
	}

	words := strings.Fields(input)
	for i := len(words) - 1; i >= 0; i-- {
		word := words[i]
		if strings.Contains(word, "/") || strings.Contains(word, "~") ||
		   strings.HasPrefix(word, ".") {
			return word
		}
	}

	return ""
}

func extractFormat(query string) string {
	formats := []string{
		"mp4", "webm", "avi", "mkv", "mov",
		"mp3", "wav", "flac", "ogg", "m4a",
		"png", "jpg", "jpeg", "gif", "webp",
	}
	lowerQuery := strings.ToLower(query)

	for _, format := range formats {
		if strings.Contains(lowerQuery, " "+format) ||
		   strings.Contains(lowerQuery, "."+format) ||
		   strings.HasSuffix(lowerQuery, format) {
			return format
		}
	}
	return ""
}

func extractSearchTerms(query string) []string {
	commonWords := map[string]bool{
		"where": true, "is": true, "my": true, "the": true, "a": true,
		"find": true, "search": true, "for": true, "file": true, "an": true,
	}

	words := strings.Fields(strings.ToLower(query))
	var terms []string

	for _, word := range words {
		// Remove punctuation
		word = strings.Trim(word, ".,!?;:")

		if !commonWords[word] && len(word) > 2 {
			terms = append(terms, word)
		}
	}

	return terms
}

// estimateConfidence provides a rough quality estimate of OCR output
func estimateConfidence(text string) string {
	if len(text) == 0 {
		return "none"
	}

	// Simple heuristics
	words := strings.Fields(text)
	specialChars := strings.Count(text, "�") + strings.Count(text, "□")
	wordCount := len(words)

	if specialChars > wordCount/4 {
		return "low"
	}

	if wordCount < 3 {
		return "medium"
	}

	return "high"
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
