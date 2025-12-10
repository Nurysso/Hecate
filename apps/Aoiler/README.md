# Aoiler

An intelligent command center that routes natural language queries to specialized system services.

## What it does

Aoiler understands what you want and automatically routes your request to the right tool:

- **File Search** - "Where is my waybar config?"
- **File Organization** - "Organize ~/Downloads by category"
- **Code Formatting** - "Format main.py"
- **OCR** - "Extract text from screen"
- **File Conversion** - "Convert video.mp4 to webm"
- **LLM Chat** - Ask anything else

## Setup

### Environment Variables

Set at least one LLM API key (optional, only needed for chat) :
#### in future will add local model support but not right cause i got amd gpu and it sucks 🥲

```bash
export OPENAI_API_KEY="sk-..."
# or
export CLAUDE_API_KEY="sk-ant-..."
# or
export GEMINI_API_KEY="..."
```

### Dependencies

- **Tyr** - File organization
- **black/gofmt/shfmt/prettier** - Code formatting
- **tesseract/grim/slurp** - OCR
- **ffmpeg** - File conversion

### Run

```bash
wails dev
```

## How it works

1. Type a natural language command
2. Aoiler classifies your intent
3. Routes to the appropriate service
4. Returns the result

Path autocomplete works with Tab/Arrow keys when typing file paths.


- **Contribution:** LLM logic and path completion implemented by Claude
- **Architecture:** Designed and built by me
- **Tools:** grim + slurp + tesseract (OCR), Tyr (file organization), ffmpeg (conversion), black, gofmt, prettier, shfmt (Lint), filepath-go module(search)

## Note right now only .config module is searched not the entire homeDir
