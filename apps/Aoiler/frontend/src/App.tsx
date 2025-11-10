import { useState, useRef, useEffect } from 'react';
import { Send, Loader2, Sparkles } from 'lucide-react';
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
  const suggestionsRef = useRef<HTMLDivElement>(null);

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

  useEffect(() => {
    setSelectedIndex(0);
  }, [suggestions]);

  useEffect(() => {
    const getAutoComplete = async () => {
      if (input.length === 0) {
        setShowSuggestions(false);
        setSuggestions([]);
        return;
      }

      try {
        const result: AutoCompleteResult = await GetPathSuggestions(input);

        if (result.isPath && result.suggestions && result.suggestions.length > 0) {
          setSuggestions(result.suggestions);
          setShowSuggestions(true);
        } else {
          setSuggestions([]);
          setShowSuggestions(false);
        }
      } catch (error) {
        console.error('Autocomplete error:', error);
        setSuggestions([]);
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
    setSuggestions([]);

    try {
      const response: QueryResponse = await ProcessQuery({ query: currentInput });

      let assistantContent = '';

      if (response.success) {
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
    if (showSuggestions && suggestions.length > 0) {
      if (e.key === 'ArrowDown') {
        e.preventDefault();
        setSelectedIndex(prev => (prev + 1) % suggestions.length);
        return;
      }

      if (e.key === 'ArrowUp') {
        e.preventDefault();
        setSelectedIndex(prev => (prev - 1 + suggestions.length) % suggestions.length);
        return;
      }

      if (e.key === 'Tab') {
        e.preventDefault();
        handleSuggestionClick(suggestions[selectedIndex]);
        return;
      }

      if (e.key === 'Escape') {
        e.preventDefault();
        setShowSuggestions(false);
        setSuggestions([]);
        return;
      }
    }

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
    setSuggestions([]);
    inputRef.current?.focus();
  };

  const renderResult = (msg: Message) => {
    if (!msg.result || msg.error) {
      if (msg.error) {
        return (
          <div className="mt-2 p-3 rounded-lg border border-red-900/30" style={{ backgroundColor: '#141B1E' }}>
            <p className="font-medium text-red-400 text-sm mb-1">Error</p>
            <p className="text-sm text-gray-300 break-words">{msg.error}</p>
          </div>
        );
      }
      return null;
    }

    if (msg.service === 'filesearch') {
      if (msg.result.found) {
        return (
          <div className="mt-2 p-3 rounded-lg border border-green-900/30" style={{ backgroundColor: '#141B1E' }}>
            <p className="font-medium text-green-400 text-sm mb-2">File Found</p>
            <p className="text-sm text-gray-300 break-all mb-1">
              <span className="text-gray-500">Path:</span> {msg.result.path}
            </p>
            <p className="text-sm text-gray-500">Type: {msg.result.type}</p>
          </div>
        );
      } else {
        return (
          <div className="mt-2 p-3 rounded-lg border border-yellow-900/30" style={{ backgroundColor: '#141B1E' }}>
            <p className="text-sm text-yellow-400">File not found</p>
          </div>
        );
      }
    }

    if (msg.service === 'organizer') {
      return (
        <div className="mt-2 p-3 rounded-lg border border-blue-900/30" style={{ backgroundColor: '#141B1E' }}>
          <p className="font-medium text-blue-400 text-sm mb-2">Organization Complete</p>
          <pre className="text-sm text-gray-300 whitespace-pre-wrap break-words">{msg.result.output}</pre>
        </div>
      );
    }

    if (msg.service === 'linter') {
      return (
        <div className="mt-2 p-3 rounded-lg border border-purple-900/30" style={{ backgroundColor: '#141B1E' }}>
          <p className="font-medium text-purple-400 text-sm mb-2">
            {msg.result.fixed ? 'Formatting Complete' : 'Formatting Failed'}
          </p>
          <p className="text-sm text-gray-300 break-all mb-1">
            <span className="text-gray-500">File:</span> {msg.result.filePath}
          </p>
          {msg.result.output && (
            <pre className="text-sm text-gray-300 mt-2 whitespace-pre-wrap break-words">{msg.result.output}</pre>
          )}
        </div>
      );
    }

    if (msg.service === 'ocr') {
      return (
        <div className="mt-2 p-3 rounded-lg border border-indigo-900/30" style={{ backgroundColor: '#141B1E' }}>
          <p className="font-medium text-indigo-400 text-sm mb-2">Extracted Text</p>
          <div className="p-2 rounded" style={{ backgroundColor: '#0F1416' }}>
            <pre className="text-sm text-gray-300 whitespace-pre-wrap break-words">{msg.result.text}</pre>
          </div>
        </div>
      );
    }

    if (msg.service === 'converter') {
      return (
        <div className="mt-2 p-3 rounded-lg border border-cyan-900/30" style={{ backgroundColor: '#141B1E' }}>
          <p className="font-medium text-cyan-400 text-sm mb-2">Conversion Complete</p>
          <p className="text-sm text-gray-300 break-all">
            <span className="text-gray-500">Output:</span> {msg.result.outputPath}
          </p>
        </div>
      );
    }

    if (msg.service === 'llm') {
      return (
        <div className="mt-2 p-3 rounded-lg border border-pink-900/30" style={{ backgroundColor: '#141B1E' }}>
          <div className="flex items-center justify-between mb-2">
            <p className="font-medium text-pink-400 text-sm">LLM Response</p>
            {msg.result.provider && (
              <span className="text-xs px-2 py-0.5 rounded" style={{ backgroundColor: '#1E3A5F', color: '#9ca3af' }}>
                {msg.result.provider}
              </span>
            )}
          </div>
          <p className="text-sm text-gray-300 whitespace-pre-wrap break-words">{msg.result.response}</p>
        </div>
      );
    }

    return null;
  };

  return (
    <div className="flex flex-col h-screen" style={{ backgroundColor: '#0F1416' }}>
      {/* Header */}
      <div className="flex-shrink-0 px-6 py-4 border-b" style={{ backgroundColor: '#141B1E', borderColor: '#1E3A5F' }}>
        <div className="flex items-center gap-2">
          <h1 className="text-xl font-semibold text-gray-100">Aoiler</h1>
        </div>
        <p className="text-sm text-gray-500 mt-0.5">intelligent command center</p>
      </div>

      {/* Messages Area */}
      <div className="flex-1 overflow-y-auto">
        {messages.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-full px-4">
            <h2 className="text-2xl font-semibold mb-2 text-gray-100 text-center">
              How can I help you today?
            </h2>
            <p className="text-sm mb-8 text-gray-500 text-center max-w-md">
              Try asking me to organize directories, extract text from images, or convert files
            </p>

            <div className="grid grid-cols-1 gap-2 w-full max-w-2xl">
              {exampleQueries.map((example, idx) => (
                <button
                  key={idx}
                  onClick={() => handleExampleClick(example)}
                  className="p-4 rounded-lg text-left transition-all border hover:border-gray-600"
                  style={{
                    backgroundColor: '#141B1E',
                    borderColor: '#1E3A5F'
                  }}
                >
                  <p className="text-sm text-gray-300">{example}</p>
                </button>
              ))}
            </div>
          </div>
        ) : (
          <div className="max-w-3xl mx-auto px-4 py-6 space-y-4">
            {messages.map((msg) => (
              <div
                key={msg.id}
                className={`flex ${msg.type === 'user' ? 'justify-end' : 'justify-start'}`}
              >
                <div
                  className={`max-w-[85%] rounded-lg px-4 py-3 ${
                    msg.type === 'user' ? 'rounded-br-sm' : 'rounded-bl-sm'
                  }`}
                  style={{
                    backgroundColor: msg.type === 'user' ? '#1E3A5F' : '#141B1E',
                  }}
                >
                  <p className="text-sm text-gray-100 whitespace-pre-wrap break-words">
                    {msg.content}
                  </p>
                  {msg.type === 'assistant' && renderResult(msg)}
                </div>
              </div>
            ))}
            {loading && (
              <div className="flex justify-start">
                <div className="rounded-lg px-4 py-3 rounded-bl-sm" style={{ backgroundColor: '#141B1E' }}>
                  <Loader2 className="animate-spin text-gray-500" size={18} />
                </div>
              </div>
            )}
            <div ref={messagesEndRef} />
          </div>
        )}
      </div>

      {/* Input Area */}
      <div className="flex-shrink-0 border-t" style={{ backgroundColor: '#141B1E', borderColor: '#1E3A5F' }}>
        <div className="max-w-3xl mx-auto px-4 py-4">
          <div className="relative">
            {/* Suggestions Dropdown */}
            {showSuggestions && suggestions.length > 0 && (
              <div
                ref={suggestionsRef}
                className="absolute bottom-full mb-2 w-full rounded-lg border max-h-40 overflow-y-auto"
                style={{
                  backgroundColor: '#141B1E',
                  borderColor: '#1E3A5F'
                }}
              >
                {suggestions.map((suggestion, idx) => (
                  <button
                    key={idx}
                    onClick={() => handleSuggestionClick(suggestion)}
                    className="w-full text-left px-4 py-2.5 text-sm transition-colors border-b last:border-b-0"
                    style={{
                      color: '#e5e7eb',
                      backgroundColor: idx === selectedIndex ? '#1E3A5F' : 'transparent',
                      borderColor: '#1E3A5F'
                    }}
                  >
                    <span className="font-mono">{suggestion}</span>
                  </button>
                ))}
              </div>
            )}

            {/* Input */}
            <div className="flex items-end gap-2">
              <textarea
                ref={inputRef}
                value={input}
                onChange={(e) => setInput(e.target.value)}
                onKeyDown={handleKeyDown}
                placeholder="Ask me anything..."
                disabled={loading}
                rows={1}
                className="flex-1 px-4 py-3 rounded-lg resize-none border outline-none text-sm"
                style={{
                  backgroundColor: '#0F1416',
                  borderColor: '#1E3A5F',
                  color: '#e5e7eb',
                  maxHeight: '120px'
                }}
              />
              <button
                onClick={handleSubmit}
                disabled={loading || !input.trim()}
                className="p-3 rounded-lg transition-all disabled:opacity-40 disabled:cursor-not-allowed flex-shrink-0"
                style={{ backgroundColor: '#1E3A5F' }}
              >
                {loading ? (
                  <Loader2 className="animate-spin text-gray-100" size={18} />
                ) : (
                  <Send size={18} className="text-gray-100" />
                )}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default App;
