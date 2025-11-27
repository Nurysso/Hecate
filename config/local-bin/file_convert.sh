#!/bin/bash

# File Format Converter with gum and tte
# Usage: ./convert.sh <file_or_directory>

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Conversion map: source_format -> space-separated list of target formats
declare -A CONVERSION_MAP=(
    ["jpg"]="png webp bmp tiff"
    ["jpeg"]="png webp bmp tiff"
    ["png"]="jpg webp bmp tiff"
    ["webp"]="jpg png bmp"
    ["bmp"]="jpg png webp"
    ["tiff"]="jpg png webp"
    ["mp4"]="avi mkv webm mov"
    ["avi"]="mp4 mkv webm"
    ["mkv"]="mp4 avi webm"
    ["webm"]="mp4 avi mkv"
    ["mov"]="mp4 avi mkv"
    ["mp3"]="wav ogg flac m4a"
    ["wav"]="mp3 ogg flac"
    ["ogg"]="mp3 wav flac"
    ["flac"]="mp3 wav ogg"
    ["m4a"]="mp3 wav ogg"
    ["pdf"]="txt html docx"
    ["txt"]="pdf html"
    ["html"]="pdf txt"
    ["md"]="pdf html txt"
    ["docx"]="pdf txt html"
)

# Check if required tools are installed
check_dependencies() {
    local missing=()
    
    if ! command -v gum &> /dev/null; then
        missing+=("gum")
    fi
    
    if ! command -v tte &> /dev/null; then
        missing+=("tte")
    fi
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${RED}Error: Missing required tools: ${missing[*]}${NC}"
        echo "Install with:"
        echo "  gum: https://github.com/charmbracelet/gum"
        echo "  tte: pip install terminaltexteffects"
        exit 1
    fi
}

# Get file extension
get_extension() {
    local file="$1"
    echo "${file##*.}" | tr '[:upper:]' '[:lower:]'
}

# Get available conversions for a format
get_available_conversions() {
    local ext="$1"
    echo "${CONVERSION_MAP[$ext]}"
}

# Perform the actual conversion
convert_file() {
    local source="$1"
    local target_format="$2"
    local output="${source%.*}.$target_format"
    
    local source_ext=$(get_extension "$source")
    
    # Image conversions
    if [[ "$source_ext" =~ ^(jpg|jpeg|png|webp|bmp|tiff)$ ]]; then
        if command -v convert &> /dev/null; then
            convert "$source" "$output" 2>/dev/null
            return $?
        elif command -v magick &> /dev/null; then
            magick "$source" "$output" 2>/dev/null
            return $?
        else
            echo -e "${RED}Error: ImageMagick not installed${NC}"
            return 1
        fi
    fi
    
    # Video conversions
    if [[ "$source_ext" =~ ^(mp4|avi|mkv|webm|mov)$ ]]; then
        if command -v ffmpeg &> /dev/null; then
            ffmpeg -i "$source" -y "$output" 2>/dev/null
            return $?
        else
            echo -e "${RED}Error: ffmpeg not installed${NC}"
            return 1
        fi
    fi
    
    # Audio conversions
    if [[ "$source_ext" =~ ^(mp3|wav|ogg|flac|m4a)$ ]]; then
        if command -v ffmpeg &> /dev/null; then
            ffmpeg -i "$source" -y "$output" 2>/dev/null
            return $?
        else
            echo -e "${RED}Error: ffmpeg not installed${NC}"
            return 1
        fi
    fi
    
    # Document conversions
    if [[ "$source_ext" =~ ^(pdf|txt|html|md|docx)$ ]]; then
        if command -v pandoc &> /dev/null; then
            pandoc "$source" -o "$output" 2>/dev/null
            return $?
        else
            echo -e "${RED}Error: pandoc not installed for document conversion${NC}"
            return 1
        fi
    fi
    
    return 1
}

# Process a single file
process_file() {
    local file="$1"
    local ext=$(get_extension "$file")
    local conversions=$(get_available_conversions "$ext")
    
    if [ -z "$conversions" ]; then
        echo -e "${RED}No conversions available for .$ext files${NC}"
        return 1
    fi
    
    echo ""
    gum style --border rounded --padding "1 2" --border-foreground 212 "File: $file"
    
    local target=$(echo "$conversions" | tr ' ' '\n' | gum choose --header "Select target format:")
    
    if [ -z "$target" ]; then
        echo -e "${YELLOW}Conversion cancelled${NC}"
        return 0
    fi
    
    echo ""
    gum spin --spinner dot --title "Converting $file to .$target..." -- sleep 0.5
    
    if convert_file "$file" "$target"; then
        local output="${file%.*}.$target"
        echo "✓ Converted: $file → $output" | tte slide --movement-speed 0.5
        return 0
    else
        echo -e "${RED}✗ Failed to convert $file${NC}"
        return 1
    fi
}

# Process directory
process_directory() {
    local dir="$1"
    
    # Get all unique extensions in directory
    local extensions=$(find "$dir" -maxdepth 1 -type f -name "*.*" | while read f; do get_extension "$f"; done | sort -u)
    
    if [ -z "$extensions" ]; then
        echo -e "${RED}No files found in directory${NC}"
        exit 1
    fi
    
    echo ""
    local chosen_ext=$(echo "$extensions" | gum choose --header "Select file type to convert:")
    
    if [ -z "$chosen_ext" ]; then
        echo -e "${YELLOW}Operation cancelled${NC}"
        exit 0
    fi
    
    local conversions=$(get_available_conversions "$chosen_ext")
    
    if [ -z "$conversions" ]; then
        echo -e "${RED}No conversions available for .$chosen_ext files${NC}"
        exit 1
    fi
    
    local target=$(echo "$conversions" | tr ' ' '\n' | gum choose --header "Select target format:")
    
    if [ -z "$target" ]; then
        echo -e "${YELLOW}Conversion cancelled${NC}"
        exit 0
    fi
    
    local files=$(find "$dir" -maxdepth 1 -type f -iname "*.$chosen_ext")
    local total=$(echo "$files" | wc -l)
    local success=0
    local failed=0
    
    echo ""
    gum style --border double --padding "1 2" --border-foreground 57 "Converting $total .$chosen_ext files to .$target"
    echo ""
    
    while IFS= read -r file; do
        if convert_file "$file" "$target"; then
            ((success++))
            echo "✓ $(basename "$file")" | tte slide --movement-speed 0.3
        else
            ((failed++))
            echo -e "${RED}✗ $(basename "$file")${NC}"
        fi
    done <<< "$files"
    
    echo ""
    gum style --border rounded --padding "1 2" --border-foreground 156 "Results: $success succeeded, $failed failed"
}

# Main script
main() {
    check_dependencies
    
    if [ $# -eq 0 ]; then
        echo "File Format Converter" | tte beams --beam-delay 50
        echo ""
        gum style --border double --padding "1 2" --border-foreground 212 "Usage: $0 <file_or_directory>"
        exit 1
    fi
    
    local path="$1"
    
    if [ ! -e "$path" ]; then
        echo -e "${RED}Error: Path does not exist: $path${NC}"
        exit 1
    fi
    
    echo "File Format Converter" | tte beams --beam-delay 50
    
    if [ -f "$path" ]; then
        process_file "$path"
    elif [ -d "$path" ]; then
        process_directory "$path"
    else
        echo -e "${RED}Error: Invalid path${NC}"
        exit 1
    fi
}

main "$@"
