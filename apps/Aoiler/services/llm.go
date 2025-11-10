package services

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"
	"time"
)

// LLMProvider represents different LLM providers
type LLMProvider string
type LLMResult struct {
	Response string `json:"response"`
	Success  bool   `json:"success"`
	Provider string `json:"provider,omitempty"`
}
const (
	ProviderOpenAI  LLMProvider = "openai"
	ProviderClaude  LLMProvider = "claude"
	ProviderGemini  LLMProvider = "gemini"
	ProviderDefault LLMProvider = "default"
)

// LLMService handles LLM API queries
type LLMService struct {
	provider       LLMProvider
	openAIKey      string
	claudeKey      string
	geminiKey      string
	httpClient     *http.Client
	defaultModel   map[LLMProvider]string
}

// OpenAI API structures
type OpenAIRequest struct {
	Model    string          `json:"model"`
	Messages []OpenAIMessage `json:"messages"`
	Stream   bool            `json:"stream"`
}

type OpenAIMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type OpenAIResponse struct {
	Choices []struct {
		Message OpenAIMessage `json:"message"`
	} `json:"choices"`
	Error *struct {
		Message string `json:"message"`
		Type    string `json:"type"`
	} `json:"error,omitempty"`
}

// Claude API structures
type ClaudeRequest struct {
	Model     string          `json:"model"`
	Messages  []ClaudeMessage `json:"messages"`
	MaxTokens int             `json:"max_tokens"`
}

type ClaudeMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type ClaudeResponse struct {
	Content []struct {
		Text string `json:"text"`
	} `json:"content"`
	Error *struct {
		Message string `json:"message"`
		Type    string `json:"type"`
	} `json:"error,omitempty"`
}

// Gemini API structures
type GeminiRequest struct {
	Contents []GeminiContent `json:"contents"`
}

type GeminiContent struct {
	Parts []GeminiPart `json:"parts"`
}

type GeminiPart struct {
	Text string `json:"text"`
}

type GeminiResponse struct {
	Candidates []struct {
		Content struct {
			Parts []GeminiPart `json:"parts"`
		} `json:"content"`
	} `json:"candidates"`
	Error *struct {
		Message string `json:"message"`
		Code    int    `json:"code"`
	} `json:"error,omitempty"`
}

// NewLLMService creates a new LLM service
func NewLLMService() *LLMService {
	service := &LLMService{
		openAIKey: os.Getenv("OPENAI_API_KEY"),
		claudeKey: os.Getenv("CLAUDE_API_KEY"),
		geminiKey: os.Getenv("GEMINI_API_KEY"),
		httpClient: &http.Client{
			Timeout: 60 * time.Second,
		},
		defaultModel: map[LLMProvider]string{
			ProviderOpenAI: "gpt-4o-mini",
			ProviderClaude: "claude-3-5-sonnet-20241022",
			ProviderGemini: "gemini-1.5-flash",
		},
	}

	// Determine which provider to use based on available keys
	service.provider = service.detectProvider()

	return service
}

// detectProvider determines which provider to use based on available API keys
func (llm *LLMService) detectProvider() LLMProvider {
	// Priority: OpenAI > Claude > Gemini
	if llm.openAIKey != "" {
		return ProviderOpenAI
	}
	if llm.claudeKey != "" {
		return ProviderClaude
	}
	if llm.geminiKey != "" {
		return ProviderGemini
	}
	return ProviderDefault
}

// Query sends a query to the configured LLM provider
func (llm *LLMService) Query(query string) (LLMResult, error) {
	if llm.provider == ProviderDefault {
		return LLMResult{
			Response: "No LLM API key configured. Please set one of:\n- OPENAI_API_KEY\n- CLAUDE_API_KEY\n- GEMINI_API_KEY",
			Success:  false,
		}, nil
	}

	switch llm.provider {
	case ProviderOpenAI:
		return llm.queryOpenAI(query)
	case ProviderClaude:
		return llm.queryClaude(query)
	case ProviderGemini:
		return llm.queryGemini(query)
	default:
		return LLMResult{
			Response: "Unknown provider",
			Success:  false,
		}, fmt.Errorf("unknown provider: %s", llm.provider)
	}
}

// queryOpenAI sends a query to OpenAI API
func (llm *LLMService) queryOpenAI(query string) (LLMResult, error) {
	url := "https://api.openai.com/v1/chat/completions"

	reqBody := OpenAIRequest{
		Model: llm.defaultModel[ProviderOpenAI],
		Messages: []OpenAIMessage{
			{
				Role:    "user",
				Content: query,
			},
		},
		Stream: false,
	}

	jsonData, err := json.Marshal(reqBody)
	if err != nil {
		return LLMResult{Success: false}, fmt.Errorf("failed to marshal request: %w", err)
	}

	req, err := http.NewRequest("POST", url, bytes.NewBuffer(jsonData))
	if err != nil {
		return LLMResult{Success: false}, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+llm.openAIKey)

	resp, err := llm.httpClient.Do(req)
	if err != nil {
		return LLMResult{Success: false}, fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return LLMResult{Success: false}, fmt.Errorf("failed to read response: %w", err)
	}

	var openAIResp OpenAIResponse
	if err := json.Unmarshal(body, &openAIResp); err != nil {
		return LLMResult{Success: false}, fmt.Errorf("failed to parse response: %w", err)
	}

	if openAIResp.Error != nil {
		return LLMResult{
			Response: fmt.Sprintf("OpenAI Error: %s", openAIResp.Error.Message),
			Success:  false,
		}, nil
	}

	if len(openAIResp.Choices) == 0 {
		return LLMResult{
			Response: "No response from OpenAI",
			Success:  false,
		}, nil
	}

	return LLMResult{
		Response: strings.TrimSpace(openAIResp.Choices[0].Message.Content),
		Success:  true,
	}, nil
}

// queryClaude sends a query to Claude API
func (llm *LLMService) queryClaude(query string) (LLMResult, error) {
	url := "https://api.anthropic.com/v1/messages"

	reqBody := ClaudeRequest{
		Model: llm.defaultModel[ProviderClaude],
		Messages: []ClaudeMessage{
			{
				Role:    "user",
				Content: query,
			},
		},
		MaxTokens: 4096,
	}

	jsonData, err := json.Marshal(reqBody)
	if err != nil {
		return LLMResult{Success: false}, fmt.Errorf("failed to marshal request: %w", err)
	}

	req, err := http.NewRequest("POST", url, bytes.NewBuffer(jsonData))
	if err != nil {
		return LLMResult{Success: false}, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("x-api-key", llm.claudeKey)
	req.Header.Set("anthropic-version", "2023-06-01")

	resp, err := llm.httpClient.Do(req)
	if err != nil {
		return LLMResult{Success: false}, fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return LLMResult{Success: false}, fmt.Errorf("failed to read response: %w", err)
	}

	var claudeResp ClaudeResponse
	if err := json.Unmarshal(body, &claudeResp); err != nil {
		return LLMResult{Success: false}, fmt.Errorf("failed to parse response: %w", err)
	}

	if claudeResp.Error != nil {
		return LLMResult{
			Response: fmt.Sprintf("Claude Error: %s", claudeResp.Error.Message),
			Success:  false,
		}, nil
	}

	if len(claudeResp.Content) == 0 {
		return LLMResult{
			Response: "No response from Claude",
			Success:  false,
		}, nil
	}

	return LLMResult{
		Response: strings.TrimSpace(claudeResp.Content[0].Text),
		Success:  true,
	}, nil
}

// queryGemini sends a query to Gemini API
func (llm *LLMService) queryGemini(query string) (LLMResult, error) {
	model := llm.defaultModel[ProviderGemini]
	url := fmt.Sprintf("https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=%s",
		model, llm.geminiKey)

	reqBody := GeminiRequest{
		Contents: []GeminiContent{
			{
				Parts: []GeminiPart{
					{Text: query},
				},
			},
		},
	}

	jsonData, err := json.Marshal(reqBody)
	if err != nil {
		return LLMResult{Success: false}, fmt.Errorf("failed to marshal request: %w", err)
	}

	req, err := http.NewRequest("POST", url, bytes.NewBuffer(jsonData))
	if err != nil {
		return LLMResult{Success: false}, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")

	resp, err := llm.httpClient.Do(req)
	if err != nil {
		return LLMResult{Success: false}, fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return LLMResult{Success: false}, fmt.Errorf("failed to read response: %w", err)
	}

	var geminiResp GeminiResponse
	if err := json.Unmarshal(body, &geminiResp); err != nil {
		return LLMResult{Success: false}, fmt.Errorf("failed to parse response: %w", err)
	}

	if geminiResp.Error != nil {
		return LLMResult{
			Response: fmt.Sprintf("Gemini Error: %s", geminiResp.Error.Message),
			Success:  false,
		}, nil
	}

	if len(geminiResp.Candidates) == 0 || len(geminiResp.Candidates[0].Content.Parts) == 0 {
		return LLMResult{
			Response: "No response from Gemini",
			Success:  false,
		}, nil
	}

	return LLMResult{
		Response: strings.TrimSpace(geminiResp.Candidates[0].Content.Parts[0].Text),
		Success:  true,
	}, nil
}

// GetCurrentProvider returns the currently active provider
func (llm *LLMService) GetCurrentProvider() string {
	return string(llm.provider)
}

// SetProvider allows manual override of the provider
func (llm *LLMService) SetProvider(provider LLMProvider) error {
	switch provider {
	case ProviderOpenAI:
		if llm.openAIKey == "" {
			return fmt.Errorf("OpenAI API key not configured")
		}
	case ProviderClaude:
		if llm.claudeKey == "" {
			return fmt.Errorf("Claude API key not configured")
		}
	case ProviderGemini:
		if llm.geminiKey == "" {
			return fmt.Errorf("Gemini API key not configured")
		}
	default:
		return fmt.Errorf("invalid provider: %s", provider)
	}
	llm.provider = provider
	return nil
}

// GetAvailableProviders returns a list of providers with configured API keys
func (llm *LLMService) GetAvailableProviders() []string {
	var providers []string
	if llm.openAIKey != "" {
		providers = append(providers, string(ProviderOpenAI))
	}
	if llm.claudeKey != "" {
		providers = append(providers, string(ProviderClaude))
	}
	if llm.geminiKey != "" {
		providers = append(providers, string(ProviderGemini))
	}
	return providers
}
