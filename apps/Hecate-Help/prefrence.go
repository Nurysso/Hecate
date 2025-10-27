package main

import (
	"bufio"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

type PreferencesConfig struct {
	Term    string `json:"term"`
	Browser string `json:"browser"`
	Shell   string `json:"shell"`
	Profile string `json:"profile"`
}

// GetPreferences reads the preferences from hecate.toml
func (a *App) GetPreferences() (PreferencesConfig, error) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return PreferencesConfig{}, err
	}

	configPath := filepath.Join(homeDir, ".config", "hecate", "hecate.toml")
	file, err := os.Open(configPath)
	if err != nil {
		return PreferencesConfig{}, err
	}
	defer file.Close()

	config := PreferencesConfig{}
	scanner := bufio.NewScanner(file)
	inPreferences := false

	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())

		// Check if we're entering the preferences section
		if line == "[preferences]" {
			inPreferences = true
			continue
		}

		// Check if we're leaving the preferences section
		if inPreferences && strings.HasPrefix(line, "[") {
			break
		}

		// Parse preference values
		if inPreferences && strings.Contains(line, "=") {
			parts := strings.SplitN(line, "=", 2)
			if len(parts) == 2 {
				key := strings.TrimSpace(parts[0])
				value := strings.Trim(strings.TrimSpace(parts[1]), `"`)

				switch key {
				case "term":
					config.Term = value
				case "browser":
					config.Browser = value
				case "shell":
					config.Shell = value
				case "profile":
					config.Profile = value
				}
			}
		}
	}

	if err := scanner.Err(); err != nil {
		return PreferencesConfig{}, err
	}

	return config, nil
}

// UpdatePreferences updates the preferences in hecate.toml
func (a *App) UpdatePreferences(config PreferencesConfig) error {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return err
	}

	configPath := filepath.Join(homeDir, ".config", "hecate", "hecate.toml")
	file, err := os.Open(configPath)
	if err != nil {
		return err
	}

	var lines []string
	scanner := bufio.NewScanner(file)
	inPreferences := false

	// Read and modify the file content
	for scanner.Scan() {
		line := scanner.Text()
		trimmedLine := strings.TrimSpace(line)

		// Check if we're entering the preferences section
		if trimmedLine == "[preferences]" {
			inPreferences = true
			lines = append(lines, line)
			continue
		}

		// Check if we're leaving the preferences section
		if inPreferences && strings.HasPrefix(trimmedLine, "[") {
			inPreferences = false
			lines = append(lines, line)
			continue
		}

		// Update preference values
		if inPreferences && strings.Contains(line, "=") {
			// Preserve indentation
			leadingSpace := line[:len(line)-len(strings.TrimLeft(line, " \t"))]
			parts := strings.SplitN(trimmedLine, "=", 2)

			if len(parts) == 2 {
				key := strings.TrimSpace(parts[0])

				switch key {
				case "term":
					lines = append(lines, fmt.Sprintf(`%sterm = "%s"`, leadingSpace, config.Term))
				case "browser":
					lines = append(lines, fmt.Sprintf(`%sbrowser = "%s"`, leadingSpace, config.Browser))
				case "shell":
					lines = append(lines, fmt.Sprintf(`%sshell = "%s"`, leadingSpace, config.Shell))
				case "profile":
					lines = append(lines, fmt.Sprintf(`%sprofile = "%s"`, leadingSpace, config.Profile))
				default:
					lines = append(lines, line)
				}
			} else {
				lines = append(lines, line)
			}
		} else {
			lines = append(lines, line)
		}
	}

	file.Close()

	if err := scanner.Err(); err != nil {
		return err
	}

	// Write the modified content back to the file
	return os.WriteFile(configPath, []byte(strings.Join(lines, "\n")), 0644)
}

// ValidatePreferences checks if the provided values are valid
func (a *App) ValidatePreferences(config PreferencesConfig) error {
	validTerms := map[string]bool{
		"kitty":      true,
		"alacritty":  true,
		"ghostty":    true,
		"foot":       true,
	}

	validShells := map[string]bool{
		"zsh":  true,
		"bash": true,
		"fish": true,
	}

	if !validTerms[config.Term] {
		return fmt.Errorf("invalid terminal: %s (valid: kitty, alacritty, ghostty, foot)", config.Term)
	}

	if !validShells[config.Shell] {
		return fmt.Errorf("invalid shell: %s (valid: zsh, bash, fish)", config.Shell)
	}

	return nil
}
