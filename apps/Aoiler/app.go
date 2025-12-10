package main

import (
	"context"
	"os/exec"
	"strings"
	"Aoiler/services"
)

type App struct {
	ctx            context.Context
	serviceManager *services.ServiceManager
	fileSearch     *services.FileSearchService
}

type QueryRequest struct {
	Query string `json:"query"`
}

type QueryResponse struct {
	Success bool        `json:"success"`
	Service string      `json:"service"`
	Result  interface{} `json:"result"`
	Error   string      `json:"error,omitempty"`
}

// NewApp creates a new App application struct
func NewApp() *App {
	return &App{
		serviceManager: services.NewServiceManager(),
		fileSearch:     services.NewFileSearchService(),
	}
}
// startup is called when the app starts
func (a *App) startup(ctx context.Context) {
	a.ctx = ctx
	// a.services = services.NewServiceManager()
}

// ProcessQuery handles the main query processing
func (a *App) ProcessQuery(req QueryRequest) QueryResponse {
	intent := a.serviceManager.ClassifyIntent(req.Query)
	result, err := a.serviceManager.RouteToService(intent, req.Query)

	if err != nil {
		return QueryResponse{
			Success: false,
			Service: intent.ServiceName,
			Error:   err.Error(),
		}
	}

	return QueryResponse{
		Success: true,
		Service: intent.ServiceName,
		Result:  result,
	}
}

// GetAvailableServices returns list of available services
func (a *App) GetAvailableServices() []ServiceInfo {
	return []ServiceInfo{
		{Name: "filesearch", Description: "Find files and directories"},
		{Name: "organizer", Description: "Organize files with Tyr"},
		{Name: "linter", Description: "Lint and format code files"},
		{Name: "ocr", Description: "Extract text from screen area"},
		{Name: "converter", Description: "Convert media files with ffmpeg"},
		{Name: "llm", Description: "Query LLM for assistance"},
	}
}

func (a *App) GetPathSuggestions(input string) services.AutoCompleteResult {
	result, err := a.fileSearch.GetPathSuggestions(input, false)
	if err != nil {
		return services.AutoCompleteResult{
			Suggestions: []string{},
			IsPath:      false,
		}
	}
	return result
}
type ServiceInfo struct {
	Name        string `json:"name"`
	Description string `json:"description"`
}

// PickFile opens a file picker dialog using yad
func (a *App) PickFile(fileType string) string {
    var cmd *exec.Cmd

    switch fileType {
    case "directory":
        cmd = exec.Command("yad", "--file", "--directory", "--title=Select Directory")
    case "image":
        cmd = exec.Command("yad", "--file", "--title=Select Image",
            "--file-filter=Images | *.png *.jpg *.jpeg *.bmp *.gif *.tiff")
    default:
        cmd = exec.Command("yad", "--file", "--title=Select File")
    }

    output, err := cmd.Output()
    if err != nil {
        return "" // User cancelled or error occurred
    }

    // yad returns the path with a newline, so trim it
    return strings.TrimSpace(string(output))
}
