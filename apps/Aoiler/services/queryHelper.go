package services

import (
	"strings"
)

// QuerySuggestion represents a suggested query pattern
type QuerySuggestion struct {
	Query       string   `json:"query"`
	Description string   `json:"description"`
	Category    string   `json:"category"`
	Examples    []string `json:"examples"`
}

// HelpService provides query suggestions and examples
type HelpService struct{}

func NewHelpService() *HelpService {
	return &HelpService{}
}

// GetSuggestions returns relevant query suggestions based on partial input
func (h *HelpService) GetSuggestions(partial string) []QuerySuggestion {
	allSuggestions := h.getAllSuggestions()

	if partial == "" {
		// Return popular/featured suggestions
		return h.getFeaturedSuggestions()
	}

	lowerPartial := strings.ToLower(partial)
	var matches []QuerySuggestion

	for _, suggestion := range allSuggestions {
		// Match against query, description, or category
		if strings.Contains(strings.ToLower(suggestion.Query), lowerPartial) ||
		   strings.Contains(strings.ToLower(suggestion.Description), lowerPartial) ||
		   strings.Contains(strings.ToLower(suggestion.Category), lowerPartial) {
			matches = append(matches, suggestion)
		}
	}

	// Limit to top 10
	if len(matches) > 10 {
		matches = matches[:10]
	}

	return matches
}

// GetByCategory returns all suggestions for a specific category
func (h *HelpService) GetByCategory(category string) []QuerySuggestion {
	allSuggestions := h.getAllSuggestions()
	var matches []QuerySuggestion

	for _, suggestion := range allSuggestions {
		if strings.EqualFold(suggestion.Category, category) {
			matches = append(matches, suggestion)
		}
	}

	return matches
}

// GetCategories returns all available categories
func (h *HelpService) GetCategories() []string {
	return []string{
		"File Search",
		"Organization",
		"Code Tools",
		"OCR & Text",
		"Media Conversion",
		"General",
	}
}

// getFeaturedSuggestions returns the most useful suggestions
func (h *HelpService) getFeaturedSuggestions() []QuerySuggestion {
	return []QuerySuggestion{
		{
			Query:       "find my config",
			Description: "Search for configuration files",
			Category:    "File Search",
			Examples:    []string{"find my neovim config", "where is hyprland config"},
		},
		{
			Query:       "organize downloads",
			Description: "Organize files by category or name",
			Category:    "Organization",
			Examples:    []string{"organize ~/Downloads", "clean up ~/Desktop"},
		},
		{
			Query:       "format code.py",
			Description: "Auto-format code files",
			Category:    "Code Tools",
			Examples:    []string{"lint main.go", "format script.sh"},
		},
		{
			Query:       "extract text from screen",
			Description: "OCR from screenshot or image",
			Category:    "OCR & Text",
			Examples:    []string{"ocr", "read text from image.png"},
		},
		{
			Query:       "convert video to mp4",
			Description: "Convert media files between formats",
			Category:    "Media Conversion",
			Examples:    []string{"convert song.flac to mp3", "encode video.avi to webm"},
		},
	}
}

// getAllSuggestions returns the complete suggestion database
func (h *HelpService) getAllSuggestions() []QuerySuggestion {
	return []QuerySuggestion{
		// File Search
		{
			Query:       "find my [filename]",
			Description: "Search for files in ~/.config and home directory",
			Category:    "File Search",
			Examples:    []string{"find my bashrc", "find my nvim config", "where is alacritty.toml"},
		},
		{
			Query:       "where is [config]",
			Description: "Locate configuration files",
			Category:    "File Search",
			Examples:    []string{"where is my kitty config", "locate waybar config"},
		},
		{
			Query:       "search for [term]",
			Description: "Search for files matching terms",
			Category:    "File Search",
			Examples:    []string{"search for hypr", "look for zsh"},
		},

		// Organization
		{
			Query:       "organize [path]",
			Description: "Organize files by category (default)",
			Category:    "Organization",
			Examples:    []string{"organize ~/Downloads", "organize .", "tyr ~/Desktop"},
		},
		{
			Query:       "organize [path] by name",
			Description: "Organize files alphabetically by filename",
			Category:    "Organization",
			Examples:    []string{"organize ~/Pictures by filename", "sort ~/Documents by name"},
		},
		{
			Query:       "clean up [path]",
			Description: "Tidy up a directory",
			Category:    "Organization",
			Examples:    []string{"clean up ~/Downloads", "tidy ~/workspace"},
		},

		// Code Tools
		{
			Query:       "format [file]",
			Description: "Auto-format code file (Python, Go, JS/TS, Shell)",
			Category:    "Code Tools",
			Examples:    []string{"format main.py", "lint script.go", "fix code.js"},
		},
		{
			Query:       "lint [file]",
			Description: "Check and fix code formatting",
			Category:    "Code Tools",
			Examples:    []string{"lint app.ts", "check code.sh"},
		},

		// OCR
		{
			Query:       "ocr",
			Description: "Capture screenshot and extract text",
			Category:    "OCR & Text",
			Examples:    []string{"ocr", "extract text", "read screen"},
		},
		{
			Query:       "extract text from [image]",
			Description: "Extract text from an image file",
			Category:    "OCR & Text",
			Examples:    []string{"ocr screenshot.png", "extract text from photo.jpg"},
		},
		{
			Query:       "read text from screen",
			Description: "Screenshot selection and OCR",
			Category:    "OCR & Text",
			Examples:    []string{"capture text", "screenshot text"},
		},

		// Media Conversion
		{
			Query:       "convert [file] to [format]",
			Description: "Convert media files using ffmpeg",
			Category:    "Media Conversion",
			Examples:    []string{"convert video.webm to mp4", "convert song.flac to mp3"},
		},
		{
			Query:       "transcode [file]",
			Description: "Re-encode media file",
			Category:    "Media Conversion",
			Examples:    []string{"transcode movie.avi", "encode audio.wav to ogg"},
		},
		{
			Query:       "change format [file] to [format]",
			Description: "Change media format",
			Category:    "Media Conversion",
			Examples:    []string{"change format image.png to jpg"},
		},

		// General
		{
			Query:       "help",
			Description: "Show available commands and examples",
			Category:    "General",
			Examples:    []string{"help", "what can you do", "commands"},
		},
	}
}

// GetQuickHelp returns a formatted help message
func (h *HelpService) GetQuickHelp() string {
	return `Available Commands:

📁 File Search
  • find my [file] - Search for files in ~/.config and home
  • where is [config] - Locate configuration files

🗂️  Organization
  • organize [path] - Organize files by category
  • organize [path] by name - Sort alphabetically
  • clean up [path] - Tidy up directory

💻 Code Tools
  • format [file] - Auto-format code (Python/Go/JS/Shell)
  • lint [file] - Check and fix code style

📸 OCR & Text
  • ocr - Screenshot and extract text
  • extract text from [image] - OCR from image file

🎬 Media Conversion
  • convert [file] to [format] - Convert media files
  • Supports: mp4, webm, mp3, wav, png, jpg, etc.

💡 Tips:
  • Tab/arrow keys for autocomplete on file paths
  • Most commands support ~ for home directory
  • Ask anything else and I'll help with LLM!`
}

// ExampleQueries provides categorized examples
type ExampleQueries struct {
	Category string   `json:"category"`
	Icon     string   `json:"icon"`
	Queries  []string `json:"queries"`
}

// GetExamplesByCategory returns organized example queries
func (h *HelpService) GetExamplesByCategory() []ExampleQueries {
	return []ExampleQueries{
		{
			Category: "File Search",
			Icon:     "📁",
			Queries: []string{
				"find my neovim config",
				"where is alacritty.toml",
				"locate waybar config",
				"search for hyprland",
			},
		},
		{
			Category: "Organization",
			Icon:     "🗂️",
			Queries: []string{
				"organize ~/Downloads",
				"organize . by name",
				"clean up ~/Desktop",
				"tyr ~/Documents",
			},
		},
		{
			Category: "Code Tools",
			Icon:     "💻",
			Queries: []string{
				"format main.py",
				"lint app.go",
				"fix script.sh",
				"check code.ts",
			},
		},
		{
			Category: "OCR & Text",
			Icon:     "📸",
			Queries: []string{
				"ocr",
				"extract text from screenshot.png",
				"read screen",
				"capture text",
			},
		},
		{
			Category: "Media Conversion",
			Icon:     "🎬",
			Queries: []string{
				"convert video.webm to mp4",
				"convert song.flac to mp3",
				"transcode movie.avi",
				"change format image.png to jpg",
			},
		},
	}
}

// DetectTypos suggests corrections for common misspellings
func (h *HelpService) DetectTypos(query string) []string {
	typoMap := map[string]string{
		"fnd":       "find",
		"serach":    "search",
		"organize":  "organize",
		"organze":   "organize",
		"formatt":   "format",
		"lint":      "lint",
		"conver":    "convert",
		"convrt":    "convert",
		"trnscode":  "transcode",
	}

	words := strings.Fields(strings.ToLower(query))
	var suggestions []string
	hasTypo := false

	for i, word := range words {
		if correction, exists := typoMap[word]; exists {
			hasTypo = true
			words[i] = correction
		}
	}

	if hasTypo {
		suggestions = append(suggestions, strings.Join(words, " "))
	}

	return suggestions
}
