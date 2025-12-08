package services

import (
	"fmt"
	"strings"
)

// Intent represents classified user intent
type Intent struct {
	ServiceName string
	Confidence  float64
	Params      map[string]string
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

// ClassifyIntent uses keyword matching to determine intent
func (sm *ServiceManager) ClassifyIntent(query string) Intent {
	lowerQuery := strings.ToLower(query)

	// File search patterns
	fileSearchKeywords := []string{"find", "where is", "locate", "search for", "look for"}
	for _, keyword := range fileSearchKeywords {
		if strings.Contains(lowerQuery, keyword) {
			return Intent{
				ServiceName: "filesearch",
				Confidence:  0.9,
				Params:      map[string]string{"query": query},
			}
		}
	}

	// Organizer patterns
	organizerKeywords := []string{"organize", "clean", "sort", "tyr"}
	for _, keyword := range organizerKeywords {
		if strings.Contains(lowerQuery, keyword) {
			params := make(map[string]string)
			if strings.Contains(lowerQuery, "category") || strings.Contains(lowerQuery, "type") {
				params["mode"] = "category"
			} else if strings.Contains(lowerQuery, "filename") || strings.Contains(lowerQuery, "name") {
				params["mode"] = "filename"
			}
			return Intent{
				ServiceName: "organizer",
				Confidence:  0.9,
				Params:      params,
			}
		}
	}

	// Linter patterns
	linterKeywords := []string{"lint", "format", "check code", "fix code"}
	for _, keyword := range linterKeywords {
		if strings.Contains(lowerQuery, keyword) {
			return Intent{
				ServiceName: "linter",
				Confidence:  0.9,
				Params:      map[string]string{"query": query},
			}
		}
	}

	// OCR patterns
	ocrKeywords := []string{"ocr", "extract text", "read screen", "capture text", "screenshot text"}
	for _, keyword := range ocrKeywords {
		if strings.Contains(lowerQuery, keyword) {
			return Intent{
				ServiceName: "ocr",
				Confidence:  0.9,
				Params:      map[string]string{},
			}
		}
	}

	// Converter patterns
	converterKeywords := []string{"convert", "transcode", "change format", "encode"}
	for _, keyword := range converterKeywords {
		if strings.Contains(lowerQuery, keyword) {
			return Intent{
				ServiceName: "converter",
				Confidence:  0.9,
				Params:      map[string]string{"query": query},
			}
		}
	}

	// Default to LLM for everything else
	return Intent{
		ServiceName: "llm",
		Confidence:  0.5,
		Params:      map[string]string{"query": query},
	}
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
		return sm.organizer.Organize(query, mode)
	case "linter":
		return sm.linter.LintFormat(query)
	case "ocr":
		return sm.ocr.ExtractText()
	case "converter":
		return sm.converter.Convert(query)
	case "llm":
		return sm.llm.Query(query)
	default:
		return nil, fmt.Errorf("unknown service: %s", intent.ServiceName)
	}
}
