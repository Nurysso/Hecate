import { useState, useRef, useEffect } from 'react';
import { Send, Loader2, Search, FolderTree, Code, ScanText, Film, Sparkles, HelpCircle, FileText } from 'lucide-react';
import { ProcessQuery, GetPathSuggestions, PickFile } from '../wailsjs/go/main/App';

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

interface QuickAction {
  id: string;
  label: string;
  icon: any;
  description: string;
  category: string;
  query: string;
  needsFile?: boolean;
  fileType?: 'file' | 'directory' | 'image';
}

function App() {
  const [messages, setMessages] = useState<Message[]>([]);
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(false);
  const [suggestions, setSuggestions] = useState<string[]>([]);
  const [showSuggestions, setShowSuggestions] = useState(false);
  const [selectedIndex, setSelectedIndex] = useState(0);
  const [showQuickActions, setShowQuickActions] = useState(true);
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLTextAreaElement>(null);

  const quickActions: QuickAction[] = [
    {
      id: 'find-config',
      label: 'Find Config',
      icon: Search,
      description: 'Search for configuration files',
      category: 'File Search',
      query: 'find my config',
      needsFile: false,
    },
    {
      id: 'search-file',
      label: 'Search File',
      icon: FileText,
      description: 'Search for any file',
      category: 'File Search',
      query: 'search for ',
      needsFile: false,
    },
    {
      id: 'organize-category',
      label: 'Organize by Type',
      icon: FolderTree,
      description: 'Organize files by category',
      category: 'Organization',
      query: 'organize {path}',
      needsFile: true,
      fileType: 'directory',
    },
    {
      id: 'organize-name',
      label: 'Organize by Name',
      icon: FolderTree,
      description: 'Sort files alphabetically',
      category: 'Organization',
      query: 'organize {path} by name',
      needsFile: true,
      fileType: 'directory',
    },
    {
      id: 'format-code',
      label: 'Format Code',
      icon: Code,
      description: 'Auto-format code file',
      category: 'Code Tools',
      query: 'format {path}',
      needsFile: true,
      fileType: 'file',
    },
    {
      id: 'lint-code',
      label: 'Lint Code',
      icon: Code,
      description: 'Check and fix code style',
      category: 'Code Tools',
      query: 'lint {path}',
      needsFile: true,
      fileType: 'file',
    },
    {
      id: 'ocr-screen',
      label: 'OCR Screen',
      icon: ScanText,
      description: 'Capture and extract text',
      category: 'OCR & Text',
      query: 'ocr',
      needsFile: false,
    },
    {
      id: 'ocr-file',
      label: 'OCR Image',
      icon: ScanText,
      description: 'Extract text from image',
      category: 'OCR & Text',
      query: 'extract text from {path}',
      needsFile: true,
      fileType: 'image',
    },
    {
      id: 'convert-media',
      label: 'Convert Media',
      icon: Film,
      description: 'Convert media files',
      category: 'Media Conversion',
      query: 'convert {path} to ',
      needsFile: true,
      fileType: 'file',
    },
  ];

  const categories = ['all', 'File Search', 'Organization', 'Code Tools', 'OCR & Text', 'Media Conversion'];

  const filteredActions = selectedCategory === 'all'
    ? quickActions
    : quickActions.filter(action => action.category === selectedCategory);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  useEffect(() => {
    setSelectedIndex(0);
  }, [suggestions]);

  useEffect(() => {
    if (messages.length > 0) {
      setShowQuickActions(false);
    }
  }, [messages]);

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

  const openFilePicker = async (fileType: 'file' | 'directory' | 'image'): Promise<string | null> => {
    try {
      const filePath = await PickFile(fileType);

      // PickFile returns empty string if user cancels or error occurs
      if (!filePath || filePath.trim() === '') {
        return null;
      }

      return filePath;
    } catch (error) {
      console.error('File picker error:', error);
      return null;
    }
  };

  const handleQuickAction = async (action: QuickAction) => {
    let finalQuery = action.query;

    if (action.needsFile) {
      const filePath = await openFilePicker(action.fileType || 'file');
      if (!filePath) {
        return; // User cancelled
      }
      finalQuery = finalQuery.replace('{path}', filePath);
    }

    // If query ends with a space or incomplete, focus input for user to complete
    if (finalQuery.endsWith(' ')) {
      setInput(finalQuery);
      inputRef.current?.focus();
      return;
    }

    // Execute directly
    setInput(finalQuery);
    setTimeout(() => handleSubmit(finalQuery), 100);
  };

  const handleSubmit = async (queryOverride?: string) => {
    const queryToSubmit = queryOverride || input;
    if (!queryToSubmit.trim() || loading) return;

    const userMessage: Message = {
      id: Date.now().toString(),
      type: 'user',
      content: queryToSubmit,
      timestamp: new Date(),
    };

    setMessages(prev => [...prev, userMessage]);
    setInput('');
    setLoading(true);
    setShowSuggestions(false);
    setSuggestions([]);

    try {
      const response: QueryResponse = await ProcessQuery({ query: queryToSubmit });

      let assistantContent = '';

      if (response.success) {
        switch (response.service) {
          case 'filesearch':
            assistantContent = response.result?.found
              ? `Found: ${response.result.path}`
              : `Could not find the file.`;
            break;
          case 'organizer':
            assistantContent = `Files organized successfully.`;
            break;
          case 'linter':
            assistantContent = response.result?.fixed
              ? `Code formatted successfully.`
              : `Formatting completed.`;
            break;
          case 'ocr':
            assistantContent = `Text extracted from ${response.result?.source || 'image'}.`;
            break;
          case 'converter':
            assistantContent = `Conversion completed.`;
            break;
          case 'llm':
            assistantContent = response.result?.response || 'Response received.';
            break;
          default:
            assistantContent = `Request processed.`;
        }
      } else {
        assistantContent = response.error || 'An error occurred.';
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
        content: 'Error: ' + String(err),
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
          <div className="mt-2 p-3 rounded-lg border border-red-900/30" style={{ backgroundColor: '#0F1416' }}>
            <p className="font-medium text-red-400 text-xs mb-1">Error</p>
            <p className="text-xs text-gray-300 break-words font-mono">{msg.error}</p>
          </div>
        );
      }
      return null;
    }

    const resultStyles = {
      filesearch: { border: 'border-emerald-900/30', bg: '#0F1416', accent: 'text-emerald-400' },
      organizer: { border: 'border-blue-900/30', bg: '#0F1416', accent: 'text-blue-400' },
      linter: { border: 'border-purple-900/30', bg: '#0F1416', accent: 'text-purple-400' },
      ocr: { border: 'border-amber-900/30', bg: '#0F1416', accent: 'text-amber-400' },
      converter: { border: 'border-cyan-900/30', bg: '#0F1416', accent: 'text-cyan-400' },
      llm: { border: 'border-pink-900/30', bg: '#0F1416', accent: 'text-pink-400' },
    };

    const style = resultStyles[msg.service as keyof typeof resultStyles] || resultStyles.llm;

    return (
      <div className={`mt-2 p-3 rounded-lg border ${style.border}`} style={{ backgroundColor: style.bg }}>
        {msg.service === 'filesearch' && msg.result.found && (
          <>
            <p className={`font-medium ${style.accent} text-xs mb-2`}>Found</p>
            <p className="text-xs text-gray-300 break-all font-mono">
              {msg.result.path}
            </p>
            <p className="text-xs text-gray-500 mt-1">Type: {msg.result.type}</p>
          </>
        )}

        {msg.service === 'organizer' && (
          <>
            <p className={`font-medium ${style.accent} text-xs mb-2`}>Organized</p>
            <pre className="text-xs text-gray-300 whitespace-pre-wrap break-words font-mono">
              {msg.result.output}
            </pre>
          </>
        )}

        {msg.service === 'linter' && (
          <>
            <p className={`font-medium ${style.accent} text-xs mb-2`}>
              {msg.result.fixed ? 'Formatted' : 'Checked'}
            </p>
            <p className="text-xs text-gray-300 break-all mb-1 font-mono">
              {msg.result.filePath}
            </p>
            {msg.result.output && (
              <pre className="text-xs text-gray-400 mt-2 whitespace-pre-wrap font-mono">
                {msg.result.output}
              </pre>
            )}
          </>
        )}

        {msg.service === 'ocr' && (
          <>
            <p className={`font-medium ${style.accent} text-xs mb-2`}>Extracted Text</p>
            <div className="p-2 rounded" style={{ backgroundColor: '#0A0E10' }}>
              <pre className="text-xs text-gray-300 whitespace-pre-wrap break-words">
                {msg.result.text}
              </pre>
            </div>
          </>
        )}

        {msg.service === 'converter' && (
          <>
            <p className={`font-medium ${style.accent} text-xs mb-2`}>Converted</p>
            <p className="text-xs text-gray-300 break-all font-mono">
              {msg.result.outputPath}
            </p>
          </>
        )}

        {msg.service === 'llm' && (
          <>
            <div className="flex items-center justify-between mb-2">
              <p className={`font-medium ${style.accent} text-xs`}>Response</p>
              {msg.result.provider && (
                <span className="text-xs px-2 py-0.5 rounded bg-gray-800 text-gray-400">
                  {msg.result.provider}
                </span>
              )}
            </div>
            <p className="text-xs text-gray-300 whitespace-pre-wrap break-words">
              {msg.result.response}
            </p>
          </>
        )}
      </div>
    );
  };

  return (
    <div className="flex flex-col h-screen" style={{ backgroundColor: '#0F1416' }}>
      {/* Header */}
      <div className="flex-shrink-0 px-6 py-3 border-b flex items-center justify-between"
           style={{ backgroundColor: '#141B1E', borderColor: '#1E3A5F' }}>
        <div>
          <div className="flex items-center gap-2">
            <Sparkles size={20} className="text-blue-400" />
            <h1 className="text-lg font-semibold text-gray-100">Aoiler</h1>
          </div>
          <p className="text-xs text-gray-500 mt-0.5">intelligent command center</p>
        </div>

        <button
          onClick={() => setShowQuickActions(!showQuickActions)}
          className="p-2 rounded-lg hover:bg-gray-800/50 transition-colors"
          title="Toggle Quick Actions"
        >
          <HelpCircle size={18} className="text-gray-400" />
        </button>
      </div>

      {/* Messages Area */}
      <div className="flex-1 overflow-y-auto">
        {showQuickActions && (
          <div className="border-b" style={{ backgroundColor: '#141B1E', borderColor: '#1E3A5F' }}>
            <div className="max-w-5xl mx-auto px-4 py-4">
              <h3 className="text-sm font-medium text-gray-300 mb-3">Quick Actions</h3>

              {/* Category Filter */}
              <div className="flex gap-2 mb-3 overflow-x-auto pb-2">
                {categories.map(cat => (
                  <button
                    key={cat}
                    onClick={() => setSelectedCategory(cat)}
                    className={`px-3 py-1 rounded-full text-xs whitespace-nowrap transition-colors ${
                      selectedCategory === cat
                        ? 'bg-blue-600 text-white'
                        : 'bg-gray-800 text-gray-400 hover:bg-gray-700'
                    }`}
                  >
                    {cat === 'all' ? 'All' : cat}
                  </button>
                ))}
              </div>

              {/* Action Buttons */}
              <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-2">
                {filteredActions.map(action => {
                  const Icon = action.icon;
                  return (
                    <button
                      key={action.id}
                      onClick={() => handleQuickAction(action)}
                      className="p-3 rounded-lg text-left transition-all border hover:border-gray-600 hover:bg-gray-800/30 group"
                      style={{
                        backgroundColor: '#0F1416',
                        borderColor: '#1E3A5F'
                      }}
                    >
                      <div className="flex items-start gap-2 mb-1">
                        <Icon size={16} className="text-blue-400 flex-shrink-0 mt-0.5" />
                        <div className="flex-1 min-w-0">
                          <p className="text-xs font-medium text-gray-200 group-hover:text-blue-400 transition-colors">
                            {action.label}
                          </p>
                          <p className="text-xs text-gray-500 mt-0.5 line-clamp-1">
                            {action.description}
                          </p>
                        </div>
                      </div>
                    </button>
                  );
                })}
              </div>
            </div>
          </div>
        )}

        {messages.length === 0 && !showQuickActions ? (
          <div className="flex flex-col items-center justify-center h-full px-4">
            <Sparkles size={48} className="text-blue-400 mb-4" />
            <h2 className="text-xl font-semibold mb-2 text-gray-100 text-center">
              How can I help you today?
            </h2>
            <p className="text-sm mb-6 text-gray-500 text-center max-w-md">
              Use quick actions above or type your command below
            </p>
          </div>
        ) : messages.length > 0 ? (
          <div className="max-w-4xl mx-auto px-4 py-6 space-y-3">
            {messages.map((msg) => (
              <div
                key={msg.id}
                className={`flex ${msg.type === 'user' ? 'justify-end' : 'justify-start'}`}
              >
                <div
                  className={`max-w-[85%] rounded-lg px-4 py-2.5 ${
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
                <div className="rounded-lg px-4 py-2.5 rounded-bl-sm" style={{ backgroundColor: '#141B1E' }}>
                  <Loader2 className="animate-spin text-gray-500" size={16} />
                </div>
              </div>
            )}
            <div ref={messagesEndRef} />
          </div>
        ) : null}
      </div>

      {/* Input Area */}
      <div className="flex-shrink-0 border-t" style={{ backgroundColor: '#141B1E', borderColor: '#1E3A5F' }}>
        <div className="max-w-4xl mx-auto px-4 py-3">
          <div className="relative">
            {/* Suggestions Dropdown */}
            {showSuggestions && suggestions.length > 0 && (
              <div
                className="absolute bottom-full mb-2 w-full rounded-lg border max-h-48 overflow-y-auto shadow-lg"
                style={{
                  backgroundColor: '#0F1416',
                  borderColor: '#1E3A5F'
                }}
              >
                {suggestions.map((suggestion, idx) => (
                  <button
                    key={idx}
                    onClick={() => handleSuggestionClick(suggestion)}
                    className="w-full text-left px-3 py-2 text-xs transition-colors border-b last:border-b-0"
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
                placeholder="Ask me anything or use quick actions above..."
                disabled={loading}
                rows={1}
                className="flex-1 px-3 py-2.5 rounded-lg resize-none border outline-none text-sm"
                style={{
                  backgroundColor: '#0F1416',
                  borderColor: '#1E3A5F',
                  color: '#e5e7eb',
                  maxHeight: '100px'
                }}
              />
              <button
                onClick={() => handleSubmit()}
                disabled={loading || !input.trim()}
                className="p-2.5 rounded-lg transition-all disabled:opacity-40 disabled:cursor-not-allowed flex-shrink-0 hover:opacity-80"
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
