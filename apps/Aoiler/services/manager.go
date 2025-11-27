package services

import (
	"fmt"
	"regexp"
	"math"
	"strings"
)

// Intent represents classified user intent
type Intent struct {
	ServiceName string
	Confidence  float64
	Params      map[string]string
	Alternatives []Alternative 
}

// Alternative represents an alternative intent interpretation
type Alternative struct {
	ServiceName string
	Confidence  float64
}

// ServiceManager manages all services
type ServiceManager struct {
	fileSearch *FileSearchService
	organizer  *OrganizerService
	linter     *LinterService
	ocr        *OCRService
	converter  *ConverterService
	llm        *LLMService
}

// NewServiceManager creates a new service manager
func NewServiceManager() *ServiceManager {
	return &ServiceManager{
		fileSearch: NewFileSearchService(),
		organizer:  NewOrganizerService(),
		linter:     NewLinterService(),
		ocr:        NewOCRService(),
		converter:  NewConverterService(),
		llm:        NewLLMService(),
	}
}

// ClassifyIntent uses improved pattern matching to determine intent
func (sm *ServiceManager) ClassifyIntent(query string) Intent {
	lowerQuery := strings.ToLower(query)

	// Score-based classification
	scores := make(map[string]float64)
	params := make(map[string]map[string]string)

	// File search scoring
	fileSearchScore := sm.scoreFileSearch(lowerQuery)
	if fileSearchScore > 0 {
		scores["filesearch"] = fileSearchScore
		params["filesearch"] = map[string]string{"query": query}
	}

	// Organizer scoring
	organizerScore, organizerParams := sm.scoreOrganizer(lowerQuery, query)
	if organizerScore > 0 {
		scores["organizer"] = organizerScore
		params["organizer"] = organizerParams
	}

	// Linter scoring
	linterScore, linterParams := sm.scoreLinter(lowerQuery, query)
	if linterScore > 0 {
		scores["linter"] = linterScore
		params["linter"] = linterParams
	}

	// OCR scoring
	ocrScore, ocrParams := sm.scoreOCR(lowerQuery, query)
	if ocrScore > 0 {
		scores["ocr"] = ocrScore
		params["ocr"] = ocrParams
	}

	// Converter scoring
	converterScore, converterParams := sm.scoreConverter(lowerQuery, query)
	if converterScore > 0 {
		scores["converter"] = converterScore
		params["converter"] = converterParams
	}

	// Find best match
	bestService := ""
	bestScore := 0.0
	alternatives := []Alternative{}

	for service, score := range scores {
		if score > bestScore {
			if bestScore > 0.3 { // Previous best becomes alternative
				alternatives = append(alternatives, Alternative{
					ServiceName: bestService,
					Confidence:  bestScore,
				})
			}
			bestScore = score
			bestService = service
		} else if score > 0.3 {
			alternatives = append(alternatives, Alternative{
				ServiceName: service,
				Confidence:  score,
			})
		}
	}

	// Default to LLM if no strong match
	if bestScore < 0.4 {
		return Intent{
			ServiceName:  "llm",
			Confidence:   0.5,
			Params:       map[string]string{"query": query},
			Alternatives: alternatives,
		}
	}

	return Intent{
		ServiceName:  bestService,
		Confidence:   bestScore,
		Params:       params[bestService],
		Alternatives: alternatives,
	}
}

// scoreFileSearch calculates file search intent score
func (sm *ServiceManager) scoreFileSearch(query string) float64 {
	score := 0.0

	// Strong indicators
	strongPatterns := []string{
		"where is", "where's", "find my", "locate",
		"search for", "look for", "looking for",
	}
	for _, pattern := range strongPatterns {
		if strings.Contains(query, pattern) {
			score += 0.4
		}
	}

	// Medium indicators
	mediumPatterns := []string{"find", "search", "get"}
	for _, pattern := range mediumPatterns {
		if strings.Contains(query, pattern) {
			score += 0.2
		}
	}

	// File/directory mentions
	filePatterns := []string{
		"file", "folder", "directory", "config",
		".conf", ".config", ".json", ".yaml", ".toml",
	}
	for _, pattern := range filePatterns {
		if strings.Contains(query, pattern) {
			score += 0.3
		}
	}

	// Specific locations
	if strings.Contains(query, ".config") || strings.Contains(query, "home") {
		score += 0.2
	}

	return  math.Min(float64(score), 1.0)
}

// scoreOrganizer calculates organizer intent score
func (sm *ServiceManager) scoreOrganizer(query, original string) (float64, map[string]string) {
	score := 0.0
	params := make(map[string]string)

	// Strong indicators
	strongPatterns := []string{"organize", "clean up", "tidy", "kondo"}
	for _, pattern := range strongPatterns {
		if strings.Contains(query, pattern) {
			score += 0.5
		}
	}

	// Action words
	actionPatterns := []string{"sort", "arrange", "group"}
	for _, pattern := range actionPatterns {
		if strings.Contains(query, pattern) {
			score += 0.3
		}
	}

	// Detect mode
	if strings.Contains(query, "category") || strings.Contains(query, "type") ||
	   strings.Contains(query, "extension") {
		params["mode"] = "category"
		score += 0.1
	} else if strings.Contains(query, "filename") || strings.Contains(query, "name") ||
	          strings.Contains(query, "alphabetical") {
		params["mode"] = "filename"
		score += 0.1
	}

	// Detect path
	if path := extractPath(original); path != "" {
		params["path"] = path
	}

	return  math.Min(float64(score), 1.0), params
}

// scoreLinter calculates linter intent score
func (sm *ServiceManager) scoreLinter(query, original string) (float64, map[string]string) {
	score := 0.0
	params := make(map[string]string)

	// Strong indicators
	strongPatterns := []string{"lint", "format", "prettier", "beautify"}
	for _, pattern := range strongPatterns {
		if strings.Contains(query, pattern) {
			score += 0.5
		}
	}

	// Code-related terms
	codePatterns := []string{
		"fix code", "check code", "style", "formatting",
		"indentation", "syntax",
	}
	for _, pattern := range codePatterns {
		if strings.Contains(query, pattern) {
			score += 0.3
		}
	}

	// File extensions that indicate linting
	lintableExts := []string{".py", ".go", ".js", ".ts", ".jsx", ".tsx", ".sh"}
	for _, ext := range lintableExts {
		if strings.Contains(query, ext) {
			score += 0.4
		}
	}

	// Extract file path
	if path := extractPath(original); path != "" {
		params["path"] = path
		score += 0.1
	}

	return  math.Min(float64(score), 1.0), params
}

// scoreOCR calculates OCR intent score
func (sm *ServiceManager) scoreOCR(query, original string) (float64, map[string]string) {
	score := 0.0
	params := make(map[string]string)

	// Strong indicators
	strongPatterns := []string{"ocr", "extract text", "read text"}
	for _, pattern := range strongPatterns {
		if strings.Contains(query, pattern) {
			score += 0.6
		}
	}

	// Medium indicators
	mediumPatterns := []string{
		"screenshot", "capture", "scan", "read screen",
		"text from image", "image to text",
	}
	for _, pattern := range mediumPatterns {
		if strings.Contains(query, pattern) {
			score += 0.4
		}
	}

	// Check if file path is provided (indicates file-based OCR)
	if path := extractPath(original); path != "" {
		params["path"] = path
		params["mode"] = "file"

		// Check for image extensions
		imageExts := []string{".png", ".jpg", ".jpeg", ".bmp", ".tiff", ".gif"}
		for _, ext := range imageExts {
			if strings.HasSuffix(strings.ToLower(path), ext) {
				score += 0.2
			}
		}
	} else {
		params["mode"] = "screen"
	}

	return  math.Min(float64(score), 1.0), params
}

// scoreConverter calculates converter intent score
func (sm *ServiceManager) scoreConverter(query, original string) (float64, map[string]string) {
	score := 0.0
	params := make(map[string]string)

	// Strong indicators
	strongPatterns := []string{"convert", "transcode", "encode"}
	for _, pattern := range strongPatterns {
		if strings.Contains(query, pattern) {
			score += 0.5
		}
	}

	// Format change indicators
	formatPatterns := []string{"to mp4", "to mp3", "to wav", "to png", "to jpg", "change format"}
	for _, pattern := range formatPatterns {
		if strings.Contains(query, pattern) {
			score += 0.3
		}
	}

	// Detect formats using regex
	formatRegex := regexp.MustCompile(`\b(mp4|webm|avi|mkv|mov|mp3|wav|flac|ogg|m4a|png|jpg|jpeg|gif|webp)\b`)
	matches := formatRegex.FindAllString(query, -1)

	if len(matches) >= 2 {
		// Likely "convert X to Y"
		params["from_format"] = matches[0]
		params["to_format"] = matches[len(matches)-1]
		score += 0.3
	} else if len(matches) == 1 {
		params["to_format"] = matches[0]
		score += 0.2
	}

	// Extract file path
	if path := extractPath(original); path != "" {
		params["path"] = path
		score += 0.2
	}

	return  math.Min(float64(score), 1.0), params
}

// RouteToService routes the query to appropriate service
func (sm *ServiceManager) RouteToService(intent Intent, query string) (interface{}, error) {
	switch intent.ServiceName {
	case "filesearch":
		return sm.fileSearch.Search(query)

	case "organizer":
		mode := intent.Params["mode"]
		if mode == "" {
			mode = "category"
		}
		path := intent.Params["path"]
		if path == "" {
			path = query
		}
		return sm.organizer.Organize(path, mode)

	case "linter":
		path := intent.Params["path"]
		if path == "" {
			path = query
		}
		return sm.linter.LintFormat(path)

	case "ocr":
		mode := intent.Params["mode"]
		if mode == "file" {
			path := intent.Params["path"]
			return sm.ocr.ExtractTextFromFile(path)
		}
		return sm.ocr.ExtractText()

	case "converter":
		path := intent.Params["path"]
		if path == "" {
			return nil, fmt.Errorf("no file path provided for conversion")
		}

		// If we have explicit formats, use them
		if toFormat := intent.Params["to_format"]; toFormat != "" {
			return sm.converter.ConvertWithFormat(path, toFormat)
		}

		return sm.converter.Convert(query)

	case "llm":
		return sm.llm.Query(query)

	default:
		return nil, fmt.Errorf("unknown service: %s", intent.ServiceName)
	}
}

// GetSuggestions returns autocomplete suggestions based on current input
func (sm *ServiceManager) GetSuggestions(query string, currentIntent Intent) (interface{}, error) {
	switch currentIntent.ServiceName {
	case "filesearch":
		return sm.fileSearch.GetPathSuggestions(query, false)
	case "organizer":
		return sm.organizer.GetPathSuggestions(query)
	case "linter":
		return sm.linter.GetPathSuggestions(query)
	case "ocr":
		return sm.ocr.GetPathSuggestions(query)
	case "converter":
		return sm.converter.GetPathSuggestions(query)
	default:
		return nil, nil
	}
}
