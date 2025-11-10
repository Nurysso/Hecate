#!/bin/bash
# OCR Capture Script - Works with grim + slurp + tesseract
# Usage: ./ocr-capture.sh [options]
# Options:
#   -o, --output FILE    Save screenshot to file (optional)
#   -l, --lang LANG      Tesseract language (default: eng)
#   -c, --clipboard      Copy result to clipboard (requires wl-copy)
#   -au, --auto          Auto mode - suppress status messages
#   -h, --help           Show this help

set -e

TMPFILE="/tmp/ocr_screenshot_$(date +%s).png"
LANG="eng"
SAVE_FILE=""
USE_CLIPBOARD=false
AUTO_MODE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
	case $1 in
	-o | --output)
		SAVE_FILE="$2"
		shift 2
		;;
	-l | --lang)
		LANG="$2"
		shift 2
		;;
	-c | --clipboard)
		USE_CLIPBOARD=true
		shift
		;;
	-au | --auto)
		AUTO_MODE=true
		shift
		;;
	-h | --help)
		echo "OCR Capture Script"
		echo "Usage: $0 [options]"
		echo ""
		echo "Options:"
		echo "  -o, --output FILE    Save screenshot to file"
		echo "  -l, --lang LANG      Tesseract language (default: eng)"
		echo "  -c, --clipboard      Copy result to clipboard"
		echo "  -au, --auto          Auto mode - suppress status messages"
		echo "  -h, --help           Show this help"
		exit 0
		;;
	*)
		echo "Unknown option: $1"
		exit 1
		;;
	esac
done

# Check dependencies
for cmd in grim slurp tesseract; do
	if ! command -v $cmd &>/dev/null; then
		echo "Error: $cmd is not installed" >&2
		exit 1
	fi
done

if [ "$USE_CLIPBOARD" = true ] && ! command -v wl-copy &>/dev/null; then
	echo "Error: wl-copy is not installed (needed for clipboard)" >&2
	exit 1
fi

# Capture screen area
if [ "$AUTO_MODE" = false ]; then
	echo "Select area to capture..." >&2
fi

if ! grim -g "$(slurp)" "$TMPFILE" 2>/dev/null; then
	echo "Screenshot cancelled or failed" >&2
	exit 1
fi

# Save screenshot if requested
if [ -n "$SAVE_FILE" ]; then
	cp "$TMPFILE" "$SAVE_FILE"
	if [ "$AUTO_MODE" = false ]; then
		echo "Screenshot saved to: $SAVE_FILE" >&2
	fi
fi

# Run OCR
if [ "$AUTO_MODE" = false ]; then
	echo "Running OCR..." >&2
fi

OCR_OUTPUT=$(tesseract "$TMPFILE" stdout -l "$LANG" 2>/dev/null)

# Cleanup temp file
rm -f "$TMPFILE"

# Output result
if [ -z "$OCR_OUTPUT" ]; then
	echo "No text detected" >&2
	exit 1
fi

echo "$OCR_OUTPUT"

# Copy to clipboard if requested
if [ "$USE_CLIPBOARD" = true ]; then
	echo "$OCR_OUTPUT" | wl-copy
	if [ "$AUTO_MODE" = false ]; then
		echo "Text copied to clipboard!" >&2
	fi
fi

exit 0
