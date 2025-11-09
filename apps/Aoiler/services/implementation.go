package services

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

// Result types
type FileSearchResult struct {
	Path  string `json:"path"`
	Type  string `json:"type"`
	Found bool   `json:"found"`
}

type OrganizerResult struct {
	Output  string `json:"output"`
	Success bool   `json:"success"`
}

type LinterResult struct {
	Output   string `json:"output"`
	Fixed    bool   `json:"fixed"`
	FilePath string `json:"filePath"`
}

type OCRResult struct {
	Text    string `json:"text"`
	Success bool   `json:"success"`
}

type ConverterResult struct {
	OutputPath string `json:"outputPath"`
	Success    bool   `json:"success"`
}

type LLMResult struct {
	Response string `json:"response"`
	Success  bool   `json:"success"`
}

type AutoCompleteResult struct {
	Suggestions []string `json:"suggestions"`
	IsPath      bool     `json:"isPath"`
}

// FileSearchService handles file/directory search
type FileSearchService struct{}

func NewFileSearchService() *FileSearchService {
	return &FileSearchService{}
}

func (fs *FileSearchService) Search(query string) (FileSearchResult, error) {
	searchTerms := extractSearchTerms(query)

	homeDir, _ := os.UserHomeDir()
	configDir := filepath.Join(homeDir, ".config")

	var foundPath string
	var bestScore int

	filepath.Walk(configDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return nil
		}

		fileName := strings.ToLower(filepath.Base(path))
		lowerPath := strings.ToLower(path)

		// Calculate match score
		score := 0
		matchedTerms := 0

		for _, term := range searchTerms {
			// Exact filename match gets highest score
			if fileName == term || fileName == term+".conf" || fileName == term+".config" {
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

		// Only consider if all terms are matched
		if matchedTerms == len(searchTerms) && score > bestScore {
			bestScore = score
			foundPath = path
		}

		return nil
	})

	if foundPath != "" {
		fileType := "file"
		if info, _ := os.Stat(foundPath); info != nil && info.IsDir() {
			fileType = "directory"
		}

		return FileSearchResult{
			Path:  foundPath,
			Type:  fileType,
			Found: true,
		}, nil
	}

	return FileSearchResult{Found: false}, fmt.Errorf("file not found")
}

// AutoComplete returns matching file paths for partial input
func (fs *FileSearchService) AutoComplete(partial string) ([]string, error) {
	if partial == "" {
		return []string{}, nil
	}

	// Expand ~ to home directory
	if strings.HasPrefix(partial, "~") {
		homeDir, _ := os.UserHomeDir()
		partial = filepath.Join(homeDir, partial[1:])
	}

	// Get directory and prefix
	dir := filepath.Dir(partial)
	prefix := filepath.Base(partial)

	// If directory doesn't exist, try current directory
	if _, err := os.Stat(dir); os.IsNotExist(err) {
		dir = "."
		prefix = partial
	}

	var matches []string

	entries, err := os.ReadDir(dir)
	if err != nil {
		return matches, err
	}

	for _, entry := range entries {
		name := entry.Name()
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

// GetPathSuggestions provides autocomplete suggestions for any input that looks like a path
func (fs *FileSearchService) GetPathSuggestions(input string, forceFromStart bool) (AutoCompleteResult, error) {
	// Detect if input contains path-like characters or if forced
	isPath := forceFromStart || strings.Contains(input, "/") || strings.Contains(input, "~") || strings.HasPrefix(input, ".")

	if !isPath {
		return AutoCompleteResult{Suggestions: []string{}, IsPath: false}, nil
	}

	// Extract the path portion from the input
	pathPart := extractPathFromInput(input)

	if pathPart == "" && forceFromStart {
		// For services that need paths, start from current directory
		pathPart = "./"
	}

	suggestions, err := fs.AutoComplete(pathPart)
	if err != nil {
		return AutoCompleteResult{Suggestions: []string{}, IsPath: true}, err
	}

	return AutoCompleteResult{
		Suggestions: suggestions,
		IsPath:      true,
	}, nil
}

func extractSearchTerms(query string) []string {
	commonWords := map[string]bool{
		"where": true, "is": true, "my": true, "the": true, "a": true,
		"find": true, "search": true, "for": true, "file": true,
	}

	words := strings.Fields(strings.ToLower(query))
	var terms []string

	for _, word := range words {
		if !commonWords[word] && len(word) > 2 {
			terms = append(terms, word)
		}
	}

	return terms
}

// OrganizerService handles file organization with kondo
type OrganizerService struct{}

func NewOrganizerService() *OrganizerService {
	return &OrganizerService{}
}

func (o *OrganizerService) Organize(query, mode string) (OrganizerResult, error) {
	path := extractPath(query)
	if path == "" {
		path = "."
	}

	if strings.HasPrefix(path, "~") {
		homeDir, _ := os.UserHomeDir()
		path = filepath.Join(homeDir, path[1:])
	}

	var cmd *exec.Cmd
	if mode == "filename" {
		cmd = exec.Command("kondo", "-f", "-nui", path)
	} else {
		cmd = exec.Command("kondo", "-c", "-nui", path)
	}

	output, err := cmd.CombinedOutput()
	if err != nil {
		return OrganizerResult{
			Output:  string(output),
			Success: false,
		}, err
	}

	return OrganizerResult{
		Output:  string(output),
		Success: true,
	}, nil
}

// GetPathSuggestions for organizer - always shows path suggestions
func (o *OrganizerService) GetPathSuggestions(input string) (AutoCompleteResult, error) {
	fs := NewFileSearchService()
	return fs.GetPathSuggestions(input, true)
}

// LinterService handles linting and formatting
type LinterService struct{}

func NewLinterService() *LinterService {
	return &LinterService{}
}

func (ls *LinterService) LintFormat(query string) (LinterResult, error) {
	filePath := extractPath(query)
	if filePath == "" {
		return LinterResult{}, fmt.Errorf("no file path found in query")
	}

	ext := strings.ToLower(filepath.Ext(filePath))

	var cmd *exec.Cmd
	switch ext {
	case ".py":
		cmd = exec.Command("black", filePath)
	case ".go":
		cmd = exec.Command("gofmt", "-w", filePath)
	case ".sh":
		cmd = exec.Command("shfmt", "-w", filePath)
	case ".js", ".ts", ".jsx", ".tsx":
		cmd = exec.Command("prettier", "--write", filePath)
	default:
		return LinterResult{}, fmt.Errorf("unsupported file type: %s", ext)
	}

	output, err := cmd.CombinedOutput()

	return LinterResult{
		Output:   string(output),
		Fixed:    err == nil,
		FilePath: filePath,
	}, err
}

// GetPathSuggestions for linter - always shows path suggestions
func (ls *LinterService) GetPathSuggestions(input string) (AutoCompleteResult, error) {
	fs := NewFileSearchService()
	result, err := fs.GetPathSuggestions(input, true)

	if err != nil {
		return result, err
	}

	// Filter to only show supported file types
	supportedExts := map[string]bool{
		".py": true, ".go": true, ".sh": true,
		".js": true, ".ts": true, ".jsx": true, ".tsx": true,
	}

	var filtered []string
	for _, path := range result.Suggestions {
		ext := strings.ToLower(filepath.Ext(path))
		// Include directories (for navigation) and supported files
		if strings.HasSuffix(path, "/") || supportedExts[ext] {
			filtered = append(filtered, path)
		}
	}

	result.Suggestions = filtered
	return result, nil
}

// OCRService handles OCR with tesseract and grim
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
	var output []byte
	var err error

	if ocr.scriptPath != "" {
		cmd := exec.Command(ocr.scriptPath, "-au")
		output, err = cmd.CombinedOutput()
	} else {
		scriptPath := "/tmp/ocr_capture.sh"
		script := `#!/bin/bash
set -e
TMPFILE="/tmp/ocr_screenshot_$(date +%s).png"
LANG="eng"
AUTO_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -au|--auto)
            AUTO_MODE=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

if [ "$AUTO_MODE" = false ]; then
    echo "Select area to capture..." >&2
fi

if ! grim -g "$(slurp)" "$TMPFILE" 2>/dev/null; then
    echo "Screenshot cancelled or failed" >&2
    exit 1
fi

if [ "$AUTO_MODE" = false ]; then
    echo "Running OCR..." >&2
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

		if writeErr := os.WriteFile(scriptPath, []byte(script), 0755); writeErr != nil {
			return OCRResult{Success: false}, fmt.Errorf("failed to create OCR script: %w", writeErr)
		}

		cmd := exec.Command("bash", scriptPath, "-au")
		output, err = cmd.CombinedOutput()

		os.Remove(scriptPath)
	}

	if err != nil {
		return OCRResult{
			Text:    string(output),
			Success: false,
		}, fmt.Errorf("OCR failed: %w", err)
	}

	return OCRResult{
		Text:    strings.TrimSpace(string(output)),
		Success: true,
	}, nil
}

// ExtractTextFromFile performs OCR on an uploaded image file
func (ocr *OCRService) ExtractTextFromFile(imagePath string) (OCRResult, error) {
	if _, err := os.Stat(imagePath); os.IsNotExist(err) {
		return OCRResult{Success: false}, fmt.Errorf("image file not found: %s", imagePath)
	}

	cmd := exec.Command("tesseract", imagePath, "stdout")
	output, err := cmd.CombinedOutput()

	if err != nil {
		return OCRResult{
			Text:    string(output),
			Success: false,
		}, fmt.Errorf("OCR failed: %w", err)
	}

	return OCRResult{
		Text:    strings.TrimSpace(string(output)),
		Success: true,
	}, nil
}

// GetPathSuggestions for OCR file upload - shows image files
func (ocr *OCRService) GetPathSuggestions(input string) (AutoCompleteResult, error) {
	fs := NewFileSearchService()
	result, err := fs.GetPathSuggestions(input, true)

	if err != nil {
		return result, err
	}

	// Filter to only show image files
	imageExts := map[string]bool{
		".png": true, ".jpg": true, ".jpeg": true,
		".bmp": true, ".tiff": true, ".tif": true,
		".gif": true, ".webp": true,
	}

	var filtered []string
	for _, path := range result.Suggestions {
		ext := strings.ToLower(filepath.Ext(path))
		// Include directories (for navigation) and image files
		if strings.HasSuffix(path, "/") || imageExts[ext] {
			filtered = append(filtered, path)
		}
	}

	result.Suggestions = filtered
	return result, nil
}

// ConverterService handles file conversion with ffmpeg
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

	outputPath := strings.TrimSuffix(inputPath, filepath.Ext(inputPath)) + "." + targetFormat

	cmd := exec.Command("ffmpeg", "-i", inputPath, outputPath)
	output, err := cmd.CombinedOutput()
	if err != nil {
		return ConverterResult{Success: false}, fmt.Errorf("conversion failed: %s", string(output))
	}

	return ConverterResult{
		OutputPath: outputPath,
		Success:    true,
	}, nil
}

// GetPathSuggestions for converter - shows media files
func (cs *ConverterService) GetPathSuggestions(input string) (AutoCompleteResult, error) {
	fs := NewFileSearchService()
	result, err := fs.GetPathSuggestions(input, true)

	if err != nil {
		return result, err
	}

	// Filter to only show media files
	mediaExts := map[string]bool{
		".mp4": true, ".webm": true, ".avi": true, ".mkv": true, ".mov": true,
		".mp3": true, ".wav": true, ".flac": true, ".ogg": true, ".m4a": true,
		".png": true, ".jpg": true, ".jpeg": true, ".gif": true, ".webp": true,
	}

	var filtered []string
	for _, path := range result.Suggestions {
		ext := strings.ToLower(filepath.Ext(path))
		// Include directories (for navigation) and media files
		if strings.HasSuffix(path, "/") || mediaExts[ext] {
			filtered = append(filtered, path)
		}
	}

	result.Suggestions = filtered
	return result, nil
}

// LLMService handles LLM API queries
type LLMService struct {
	apiKey string
	apiURL string
}

func NewLLMService() *LLMService {
	return &LLMService{
		apiKey: os.Getenv("LLM_API_KEY"),
		apiURL: os.Getenv("LLM_API_URL"),
	}
}

func (llm *LLMService) Query(query string) (LLMResult, error) {
	if llm.apiKey == "" {
		return LLMResult{
			Response: "LLM API key not configured. Please set LLM_API_KEY environment variable.",
			Success:  false,
		}, nil
	}

	return LLMResult{
		Response: fmt.Sprintf("LLM response for: %s (Implementation pending)", query),
		Success:  true,
	}, nil
}

// Helper functions
func extractPath(query string) string {
	words := strings.Fields(query)
	for _, word := range words {
		if strings.Contains(word, "/") || strings.Contains(word, ".") {
			return word
		}
	}
	return ""
}

func extractPathFromInput(input string) string {
	// If input starts with path characters, treat entire input as path
	if strings.HasPrefix(input, "/") || strings.HasPrefix(input, "~") || strings.HasPrefix(input, "./") || strings.HasPrefix(input, "../") {
		return input
	}

	// Otherwise, extract last word that looks like a path
	words := strings.Fields(input)
	for i := len(words) - 1; i >= 0; i-- {
		word := words[i]
		if strings.Contains(word, "/") || strings.Contains(word, "~") || strings.HasPrefix(word, ".") {
			return word
		}
	}

	return ""
}

func extractFormat(query string) string {
	formats := []string{"mp4", "webm", "mp3", "wav", "png", "jpg", "jpeg", "gif"}
	lowerQuery := strings.ToLower(query)

	for _, format := range formats {
		if strings.Contains(lowerQuery, format) {
			return format
		}
	}
	return ""
}
