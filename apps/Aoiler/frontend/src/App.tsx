import { useState, useRef, useEffect } from 'react';
import { Send, Loader2 } from 'lucide-react';
import { ProcessQuery, GetPathSuggestions } from '../wailsjs/go/main/App';

interface Message {
  id: string;
  type: 'user' | 'assistant';
  content: string;
  service?: string;
  result?: any;
  error?: string;
  timestamp: Date;
}

interface QueryResponse {
  success: boolean;
  service: string;
  result: any;
  error?: string;
}

interface AutoCompleteResult {
  suggestions: string[];
  isPath: boolean;
}

function App() {
  const [messages, setMessages] = useState<Message[]>([]);
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(false);
  const [suggestions, setSuggestions] = useState<string[]>([]);
  const [showSuggestions, setShowSuggestions] = useState(false);
  const [selectedIndex, setSelectedIndex] = useState(0);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLTextAreaElement>(null);

  const exampleQueries = [
    'Where is my waybar layout file?',
    'Organize ~/Downloads by category',
    'Format main.py',
    'Extract text from screen',
    'Convert video.mp4 to webm',
  ];

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  // Reset selected index when suggestions change
  useEffect(() => {
    setSelectedIndex(0);
  }, [suggestions]);

  // Auto-complete logic with actual backend call
  useEffect(() => {
    const getAutoComplete = async () => {
      if (input.length === 0) {
        setShowSuggestions(false);
        return;
      }

      try {
        const result: AutoCompleteResult = await GetPathSuggestions(input);

        if (result.isPath && result.suggestions && result.suggestions.length > 0) {
          setSuggestions(result.suggestions);
          setShowSuggestions(true);
        } else {
          setShowSuggestions(false);
        }
      } catch (error) {
        console.error('Autocomplete error:', error);
        setShowSuggestions(false);
      }
    };

    const debounce = setTimeout(getAutoComplete, 300);
    return () => clearTimeout(debounce);
  }, [input]);

  const handleSubmit = async () => {
    if (!input.trim() || loading) return;

    const userMessage: Message = {
      id: Date.now().toString(),
      type: 'user',
      content: input,
      timestamp: new Date(),
    };

    setMessages(prev => [...prev, userMessage]);
    const currentInput = input;
    setInput('');
    setLoading(true);
    setShowSuggestions(false);

    try {
      const response: QueryResponse = await ProcessQuery({ query: currentInput });

      let assistantContent = '';

      if (response.success) {
        // Generate appropriate response based on service
        if (response.service === 'filesearch') {
          assistantContent = response.result?.found
            ? `Found the file you're looking for.`
            : `Could not find the file.`;
        } else if (response.service === 'organizer') {
          assistantContent = `Files have been organized.`;
        } else if (response.service === 'linter') {
          assistantContent = response.result?.fixed
            ? `File has been formatted successfully.`
            : `Could not format the file.`;
        } else if (response.service === 'ocr') {
          assistantContent = `Text extracted from image.`;
        } else if (response.service === 'converter') {
          assistantContent = `File conversion completed.`;
        } else if (response.service === 'llm') {
          assistantContent = response.result?.response || 'LLM response received.';
        } else {
          assistantContent = `Request processed.`;
        }
      } else {
        assistantContent = response.error || 'An error occurred while processing your request.';
      }

      const assistantMessage: Message = {
        id: (Date.now() + 1).toString(),
        type: 'assistant',
        content: assistantContent,
        service: response.service,
        result: response.success ? response.result : null,
        error: response.error,
        timestamp: new Date(),
      };

      setMessages(prev => [...prev, assistantMessage]);
    } catch (err) {
      const errorMessage: Message = {
        id: (Date.now() + 1).toString(),
        type: 'assistant',
        content: 'An error occurred: ' + String(err),
        error: String(err),
        timestamp: new Date(),
      };
      setMessages(prev => [...prev, errorMessage]);
    } finally {
      setLoading(false);
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    // Handle autocomplete navigation
    if (showSuggestions && suggestions.length > 0) {
      if (e.key === 'Tab') {
        e.preventDefault();
        setSelectedIndex(prev => (prev + 1) % suggestions.length);
        return;
      }

      if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        handleSuggestionClick(suggestions[selectedIndex]);
        return;
      }

      if (e.key === 'Escape') {
        setShowSuggestions(false);
        return;
      }
    }

    // Handle normal Enter for submission
    if (e.key === 'Enter' && !e.shiftKey && !showSuggestions) {
      e.preventDefault();
      handleSubmit();
    }
  };

  const handleExampleClick = (example: string) => {
    setInput(example);
    inputRef.current?.focus();
  };

  const handleSuggestionClick = (suggestion: string) => {
    // Replace the path portion with the selected suggestion
    const words = input.split(' ');
    let replaced = false;

    for (let i = words.length - 1; i >= 0; i--) {
      if (words[i].includes('/') || words[i].startsWith('.') || words[i].startsWith('~')) {
        words[i] = suggestion;
        replaced = true;
        break;
      }
    }

    if (!replaced) {
      words[words.length - 1] = suggestion;
    }

    setInput(words.join(' '));
    setShowSuggestions(false);
    inputRef.current?.focus();
  };

  const renderResult = (msg: Message) => {
    if (!msg.result || msg.error) {
      if (msg.error) {
        return (
          <div className="mt-2 p-2 sm:p-3 rounded-lg text-xs sm:text-sm" style={{ backgroundColor: '#1a2227' }}>
            <p className="font-medium" style={{ color: '#ef4444' }}>Error</p>
            <p className="mt-1 break-words" style={{ color: '#e5e7eb' }}>{msg.error}</p>
          </div>
        );
      }
      return null;
    }

    if (msg.service === 'filesearch') {
      if (msg.result.found) {
        return (
          <div className="mt-2 p-2 sm:p-3 rounded-lg text-xs sm:text-sm" style={{ backgroundColor: '#1a2227'}}>
            <p className="font-medium" style={{ color: '#10b981' }}>File Found</p>
            <p className="mt-1 break-all" style={{ color: '#e5e7eb' }}>
              <span style={{ color: '#9ca3af' }}>Path:</span> {msg.result.path}
            </p>
            <p className="mt-1" style={{ color: '#9ca3af' }}>Type: {msg.result.type}</p>
          </div>
        );
      } else {
        return (
          <div className="mt-2 p-2 sm:p-3 rounded-lg text-xs sm:text-sm" style={{ backgroundColor: '#1a2227'}}>
            <p style={{ color: '#f59e0b' }}>File not found</p>
          </div>
        );
      }
    }

    if (msg.service === 'organizer') {
      return (
        <div className="mt-2 p-2 sm:p-3 rounded-lg text-xs sm:text-sm" style={{ backgroundColor: '#1a2227'}}>
          <p className="font-medium" style={{ color: '#3b82f6' }}>Organization Complete</p>
          <pre className="mt-2 whitespace-pre-wrap break-words" style={{ color: '#e5e7eb' }}>{msg.result.output}</pre>
        </div>
      );
    }

    if (msg.service === 'linter') {
      return (
        <div className="mt-2 p-2 sm:p-3 rounded-lg text-xs sm:text-sm" style={{ backgroundColor: '#1a2227'}}>
          <p className="font-medium" style={{ color: '#a855f7' }}>
            {msg.result.fixed ? 'Formatting Complete' : 'Formatting Failed'}
          </p>
          <p className="mt-1 break-all" style={{ color: '#e5e7eb' }}>
            <span style={{ color: '#9ca3af' }}>File:</span> {msg.result.filePath}
          </p>
          {msg.result.output && (
            <pre className="mt-2 whitespace-pre-wrap break-words" style={{ color: '#e5e7eb' }}>{msg.result.output}</pre>
          )}
        </div>
      );
    }

    if (msg.service === 'ocr') {
      return (
        <div className="mt-2 p-2 sm:p-3 rounded-lg text-xs sm:text-sm" style={{ backgroundColor: '#1a2227'}}>
          <p className="font-medium mb-2" style={{ color: '#6366f1' }}>Extracted Text</p>
          <div className="p-2 rounded" style={{ backgroundColor: '#0f1416' }}>
            <pre className="whitespace-pre-wrap break-words" style={{ color: '#e5e7eb' }}>{msg.result.text}</pre>
          </div>
        </div>
      );
    }

    if (msg.service === 'converter') {
      return (
        <div className="mt-2 p-2 sm:p-3 rounded-lg text-xs sm:text-sm" style={{ backgroundColor: '#1a2227'}}>
          <p className="font-medium" style={{ color: '#06b6d4' }}>Conversion Complete</p>
          <p className="mt-1 break-all" style={{ color: '#e5e7eb' }}>
            <span style={{ color: '#9ca3af' }}>Output:</span> {msg.result.outputPath}
          </p>
        </div>
      );
    }

    if (msg.service === 'llm') {
      return (
        <div className="mt-2 p-2 sm:p-3 rounded-lg text-xs sm:text-sm" style={{ backgroundColor: '#1a2227'}}>
          <p className="font-medium mb-2" style={{ color: '#ec4899' }}>LLM Response</p>
          <p className="whitespace-pre-wrap break-words" style={{ color: '#e5e7eb' }}>{msg.result.response}</p>
        </div>
      );
    }

    return null;
  };

  return (
    <div className="flex flex-col h-screen" style={{ backgroundColor: '#0a0e10', minWidth: '250px' }}>
      {/* Header */}
      <div className="flex-shrink-0 px-3 sm:px-6 py-3 sm:py-4 border-b" style={{ backgroundColor: '#0f1416', borderColor: '#1e272b' }}>
        <h1 className="text-lg sm:text-xl font-semibold truncate" style={{ color: '#e5e7eb' }}>Aoiler</h1>
        <p className="text-xs sm:text-sm truncate" style={{ color: '#6b7280' }}>intelligent command center</p>
      </div>

      {/* Messages Area */}
      <div className="flex-1 overflow-y-auto px-3 sm:px-6 py-3 sm:py-4">
        {messages.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-full px-2">
            {/* <div className="w-12 h-12 sm:w-16 sm:h-16 rounded-full mb-4 sm:mb-6 flex items-center justify-center" style={{ backgroundColor: '#1e3a5f' }}>
              <span className="text-2xl sm:text-3xl">🌙</span>
            </div> */}
            <h2 className="text-xl sm:text-2xl font-bold mb-2 text-center" style={{ color: '#e5e7eb' }}>How can I help you today?</h2>
            <p className="text-xs sm:text-sm mb-6 sm:mb-8 text-center px-2" style={{ color: '#6b7280' }}>Try asking me to organize directories, extract text from image or convert files</p>

            <div className="grid grid-cols-1 gap-2 sm:gap-3 w-full max-w-2xl">
              {exampleQueries.map((example, idx) => (
                <button
                  key={idx}
                  onClick={() => handleExampleClick(example)}
                  className="p-3 sm:p-4 rounded-lg text-left transition-all"
                  style={{ backgroundColor: '#1a2227', border: '1px solid #1e272b' }}
                >
                  <p className="text-xs sm:text-sm break-words" style={{ color: '#e5e7eb' }}>{example}</p>
                </button>
              ))}
            </div>
          </div>
        ) : (
          <div className="max-w-3xl mx-auto space-y-4 sm:space-y-6">
            {messages.map((msg) => (
              <div
                key={msg.id}
                className={`flex ${msg.type === 'user' ? 'justify-end' : 'justify-start'}`}
              >
                <div
                  className={`max-w-[85%] sm:max-w-[80%] rounded-lg px-3 py-2 sm:px-4 sm:py-3 ${
                    msg.type === 'user' ? 'rounded-br-none' : 'rounded-bl-none'
                  }`}
                  style={{
                    backgroundColor: msg.type === 'user' ? '#1e3a5f' : '#1a2227',
                  }}
                >
                  <p className="text-xs sm:text-sm whitespace-pre-wrap break-words" style={{ color: '#e5e7eb' }}>
                    {msg.content}
                  </p>
                  {msg.type === 'assistant' && renderResult(msg)}
                </div>
              </div>
            ))}
            {loading && (
              <div className="flex justify-start">
                <div className="rounded-lg px-3 py-2 sm:px-4 sm:py-3 rounded-bl-none" style={{ backgroundColor: '#1a2227' }}>
                  <Loader2 className="animate-spin" size={16} style={{ color: '#6b7280' }} />
                </div>
              </div>
            )}
            <div ref={messagesEndRef} />
          </div>
        )}
      </div>

      {/* Input Area */}
      <div className="flex-shrink-0 border-t" style={{ backgroundColor: '#0f1416', borderColor: '#1e272b' }}>
        <div className="max-w-3xl mx-auto px-3 sm:px-6 py-3 sm:py-4">
          {/* Suggestions */}
          {showSuggestions && suggestions.length > 0 && (
            <div className="mb-2 rounded-lg max-h-32 overflow-y-auto" style={{ backgroundColor: '#1a2227', border: '1px solid #1e272b' }}>
              {suggestions.map((suggestion, idx) => (
                <button
                  key={idx}
                  onClick={() => handleSuggestionClick(suggestion)}
                  className="w-full text-left px-3 py-2 text-xs sm:text-sm transition-colors"
                  style={{
                    color: '#e5e7eb',
                    backgroundColor: idx === selectedIndex ? '#1e272b' : 'transparent'
                  }}
                  onMouseEnter={(e) => {
                    setSelectedIndex(idx);
                    e.currentTarget.style.backgroundColor = '#1e272b';
                  }}
                  onMouseLeave={(e) => {
                    if (idx !== selectedIndex) {
                      e.currentTarget.style.backgroundColor = 'transparent';
                    }
                  }}
                >
                  {suggestion}
                </button>
              ))}
            </div>
          )}

          <div className="relative">
            <textarea
              ref={inputRef}
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={handleKeyDown}
              placeholder="Ask me anything..."
              disabled={loading}
              rows={1}
              className="w-full px-3 py-2 sm:px-4 sm:py-3 pr-10 sm:pr-12 rounded-lg resize-none border outline-none text-xs sm:text-sm"
              style={{
                backgroundColor: '#1a2227',
                borderColor: '#1e272b',
                color: '#e5e7eb',
              }}
            />
            <button
              onClick={handleSubmit}
              disabled={loading || !input.trim()}
              className="absolute right-1.5 bottom-1.5 sm:right-2 sm:bottom-2 p-1.5 sm:p-2 rounded-lg transition-all disabled:opacity-50 disabled:cursor-not-allowed"
              style={{ backgroundColor: '#1e3a5f' }}
            >
              {loading ? (
                <Loader2 className="animate-spin" size={16} style={{ color: '#e5e7eb' }} />
              ) : (
                <Send size={16} style={{ color: '#e5e7eb' }} />
              )}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

export default App;
