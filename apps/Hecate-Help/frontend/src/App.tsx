import React, { useState, useEffect } from 'react';
import { Keyboard, Info, X, Home, Monitor, ArrowRight, Flower2, AppWindow, Orbit, Search, Settings } from 'lucide-react';
// import Hecate from '../public/hecate.svg';
import KeybindsView from './components/KeybindsView';
import MonitorsView from './components/Monitors';
import SettingsView from './components/SettingView';
import WindowRulesView from './components/windowRules';
import AnimationsView from './components/AnimationView';
import DecorationsView from './components/Decor';
import { GetStartupArgs } from '../wailsjs/go/main/App';
import { Popover, PopoverTrigger, PopoverContent } from './components/ui/popover';

const App = () => {
  const [activePage, setActivePage] = useState('home');
  const [searchQuery, setSearchQuery] = useState('');
  const [hoveredItem, setHoveredItem] = useState<string | null>(null);
  const [isSearchOpen, setIsSearchOpen] = useState(false);
  const [searchResults, setSearchResults] = useState<Array<{page: string, term: string, score: number}>>([]);

  const menuItems = [
    { id: 'home', label: 'Settings', icon: Home, color: '#60a5fa' },
    { id: 'decoration', label: 'General', icon: Flower2, color: '#60a5fa'},
    { id: 'keybinds', label: 'Keybinds', icon: Keyboard, color: '#60a5fa' },
    { id: 'monitors', label: 'Monitors', icon: Monitor, color: '#60a5fa' },
    { id: 'windows', label: 'Window Rules', icon: AppWindow, color: '#60a5fa' },
    { id: 'animations', label: 'Animations', icon: Orbit, color: '#60a5fa' },
  ];

  // Page-specific information for popovers
  const pageInfo: Record<string, { title: string; description: string; tips: string[] }> = {
    home: {
      title: 'General Settings',
      description: 'Configure core Hecate settings and general preferences.',
      tips: ['General and common changes', 'Save changes before switching pages', 'Use search to quickly find options', 'Hover over settings for more info']
    },
    general: {
      title: 'Hyprland General Settings',
      description: 'Configure decoration settings and general preferences.',
      tips: ['General and Decorations', 'Save changes before switching pages', 'Use search to quickly find options']
    },
    keybinds: {
      title: 'Keyboard Shortcuts',
      description: 'Customize keyboard bindings for window management and system controls.',
      tips: ['Click a binding to edit it', 'Use modifier keys: Super, Alt, Ctrl, Shift', 'Avoid conflicts with system shortcuts']
    },
    waybar: {
      title: 'Waybar Configuration',
      description: 'Customize your status bar appearance and modules.',
      tips: ['Set layout and style you like', 'Preview changes in real-time']
    },
    prefrences: {
      title: 'Advanced Preferences',
      description: 'Fine-tune advanced Hecate behavior and performance settings.',
      tips: ['️⚠️ still in progress','These settings affect system behavior', 'Restart may be required']
    },
    theme: {
      title: 'Theme Customization',
      description: 'Personalize colors, borders, gaps, and visual effects.',
      tips: ['changes system theme dynamic/static', 'choose from existing colors','⚠️ your own colors are upcoming in next update']
    },
    monitors: {
      title: 'Display Configuration',
      description: 'Configure resolution, refresh rate, and multi-monitor setup.',
      tips: ['Drag monitors to arrange layout', 'Set primary display', 'Configure per-monitor workspaces']
    },
    windows: {
      title: 'Window Rules',
      description: 'Create rules to control window behavior based on class, title, or other properties.',
      tips: ['Use regex for pattern matching', 'Test rules before applying', 'Rules are evaluated in order']
    },
    animations: {
      title: 'Animation Settings',
      description: 'Configure window animations, transitions, and effects.',
      tips: ['Balance performance vs aesthetics', 'Disable on older hardware', 'Customize speed and easing']
    }
  };

  // Search terms mapped to pages (fuzzy searchable)
  const searchIndex: Record<string, string[]> = {
    home: ['settings', 'general', 'config', 'configuration', 'main', 'home', 'start', 'waybar', 'status bar', 'bar', 'panel', 'taskbar', 'modules', 'clock', 'battery', 'preferences', 'advanced', 'options', 'terminal', 'shell', 'performance', 'theme', 'colors', 'appearance', 'style', 'borders', 'gaps', 'visual', 'palette', 'design'],
    keybinds: ['keyboard', 'shortcuts', 'hotkeys', 'bindings', 'keys', 'keybinds'],
    general: ['decoration', 'decorations', 'blur', 'window'],
    // theme: [],
    monitors: ['monitors', 'displays', 'screens', 'resolution', 'refresh rate', 'layout', 'output'],
    windows: ['window rules', 'rules', 'window', 'floating', 'tiling', 'workspace', 'class', 'title'],
    animations: ['animations', 'effects', 'transitions', 'bezier', 'speed', 'fade', 'slide']
  };

  // Fuzzy search implementation
  const fuzzySearch = (query: string, text: string): number => {
    query = query.toLowerCase();
    text = text.toLowerCase();

    let score = 0;
    let queryIndex = 0;
    let lastMatchIndex = -1;

    for (let i = 0; i < text.length && queryIndex < query.length; i++) {
      if (text[i] === query[queryIndex]) {
        score += (lastMatchIndex === i - 1) ? 2 : 1; // Bonus for consecutive matches
        lastMatchIndex = i;
        queryIndex++;
      }
    }

    if (queryIndex === query.length) {
      // Bonus for exact substring match
      if (text.includes(query)) score += 10;
      // Bonus for match at start
      if (text.startsWith(query)) score += 5;
      return score;
    }

    return 0;
  };

  // Search effect
  useEffect(() => {
    if (searchQuery.trim().length < 2) {
      setSearchResults([]);
      setIsSearchOpen(false);
      return;
    }

    const results: Array<{page: string, term: string, score: number}> = [];

    Object.entries(searchIndex).forEach(([page, terms]) => {
      terms.forEach(term => {
        const score = fuzzySearch(searchQuery, term);
        if (score > 0) {
          results.push({ page, term, score });
        }
      });
    });

    // Sort by score (highest first) and take top 10
    results.sort((a, b) => b.score - a.score);
    setSearchResults(results.slice(0, 10));
    setIsSearchOpen(results.length > 0);
  }, [searchQuery]);

  const handleSearchResultClick = (page: string) => {
    setActivePage(page);
    setSearchQuery('');
    setIsSearchOpen(false);
  };

  const activeItem = menuItems.find(i => i.id === activePage);
  const currentPageInfo = pageInfo[activePage] || pageInfo.home;
  useEffect(() => {
    GetStartupArgs().then((args: string[]) => {
      if (args && args.length > 0) {
        const tabArg = args[0].toLowerCase();
        const validTab = menuItems.find(item => item.id.toLowerCase() === tabArg);
        if (validTab) {
          setActivePage(validTab.id);
        }
      }
    }).catch(err => {
      console.error('Failed to get startup args:', err);
    });
  }, []);

  const renderPage = () => {
    switch (activePage) {
      case 'keybinds':
        return <KeybindsView />;
      case 'decoration':
        return <DecorationsView />;
      case 'settings':
        return <SettingsView />;
      case 'monitors':
        return <MonitorsView />;
      case 'windows':
        return <WindowRulesView />;
      case 'animations':
        return <AnimationsView />;
      default:
        return <SettingsView />;
    }
  };

  return (
    <div className="flex h-screen overflow-hidden" style={{ backgroundColor: '#0a0e10' }}>
      {/* Compact Sidebar */}
      <div className="w-20 flex flex-col items-center border-r flex-shrink-0" style={{ backgroundColor: '#0f1416', borderColor: '#1e272b' }}>
        {/* Logo */}
        <div className="w-full py-6 flex justify-center border-b" style={{ borderColor: '#1e272b' }}>
          <div className="w-10 h-10 rounded-xl flex items-center justify-center relative overflow-hidden" style={{ backgroundColor: '#1e3a5f' }}>
            <Settings size={20} className="text-white relative z-10" />
            <div className="absolute inset-0 opacity-20" />
          </div>
        </div>

        {/* Menu Icons */}
        <nav className="flex-1 w-full py-4 overflow-y-auto overflow-x-hidden">
          <div className="space-y-2 px-2">
            {menuItems.map(item => {
              const Icon = item.icon;
              const isActive = activePage === item.id;
              const isHovered = hoveredItem === item.id;

              return (
                <div key={item.id} className="relative">
                  <button
                    onClick={() => setActivePage(item.id)}
                    onMouseEnter={() => setHoveredItem(item.id)}
                    onMouseLeave={() => setHoveredItem(null)}
                    className="w-full aspect-square flex items-center justify-center rounded-xl transition-all duration-200 relative overflow-hidden"
                    style={{
                      backgroundColor: isActive ? '#1e3a5f' : isHovered ? '#1a2227' : 'transparent',
                      transform: isActive ? 'scale(1.05)' : 'scale(1)',
                    }}
                  >
                    {isActive && (
                      <div
                        className="absolute left-0 top-1/2 -translate-y-1/2 w-1 h-6 rounded-r-full transition-all"
                        style={{ backgroundColor: item.color }}
                      />
                    )}

                    {isActive && (
                      <div className="absolute inset-0 opacity-20" />
                    )}

                    <Icon
                      size={20}
                      strokeWidth={isActive ? 2.5 : 2}
                      style={{
                        color: isActive ? item.color : '#9ca3af',
                        transition: 'all 0.2s'
                      }}
                    />
                  </button>
                </div>
              );
            })}
          </div>
        </nav>

        {/* Version indicator */}
        <div className="w-full p-3 flex flex-col justify-center border-t" style={{ borderColor: '#1e272b' }}>
          <h3 className="text-md font-bold text-gray-100 mb-1">0.4.6</h3>
          <p className="text-xs text-gray-500">shy eagle</p>
        </div>
      </div>

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col overflow-hidden">
        {/* Header */}
        <div className="h-16 px-8 flex items-center justify-between border-b flex-shrink-0" style={{ backgroundColor: '#0f1416', borderColor: '#1e272b' }}>
          <div className="flex items-center gap-4">
            <div
              className="w-8 h-8 rounded-lg flex items-center justify-center"
              style={{ backgroundColor: `${activeItem?.color}20` }}
            >
              {activeItem && <activeItem.icon size={18} style={{ color: activeItem.color }} />}
            </div>
            <div>
              <h1 className="text-lg font-semibold text-gray-100">{activeItem?.label}</h1>
              <p className="text-xs text-gray-500">Hecate Configuration Helper</p>
            </div>

            {/* Info Popover */}
            <Popover>
              <PopoverTrigger asChild>
                <button
                  className="ml-2 p-1.5 rounded-lg hover:bg-opacity-20 transition-colors"
                  style={{ backgroundColor: '#1a2227' }}
                >
                  <Info size={16} className="text-gray-400" />
                </button>
              </PopoverTrigger>
              <PopoverContent
                className="w-80 border-0 p-0 overflow-hidden"
                style={{ backgroundColor: '#1a2227' }}
              >
                <div className="p-4">
                  <div className="flex items-start gap-3 mb-3">
                    <div
                      className="w-10 h-10 rounded-lg flex items-center justify-center flex-shrink-0"
                      style={{ backgroundColor: `${activeItem?.color}20` }}
                    >
                      {activeItem && <activeItem.icon size={20} style={{ color: activeItem.color }} />}
                    </div>
                    <div className="flex-1">
                      <h3 className="text-sm font-semibold text-gray-100 mb-1">
                        {currentPageInfo.title}
                      </h3>
                      <p className="text-xs text-gray-400 leading-relaxed">
                        {currentPageInfo.description}
                      </p>
                    </div>
                  </div>

                  <div className="border-t pt-3" style={{ borderColor: '#2a3439' }}>
                    <p className="text-xs font-medium text-gray-300 mb-2">Quick Tips:</p>
                    <ul className="space-y-1.5">
                      {currentPageInfo.tips.map((tip, index) => (
                        <li key={index} className="text-xs text-gray-400 flex items-start gap-2">
                          <span className="text-blue-400 mt-0.5">•</span>
                          <span>{tip}</span>
                        </li>
                      ))}
                    </ul>
                  </div>
                </div>
              </PopoverContent>
            </Popover>
          </div>

          {/* Search with dropdown */}
         <div className="relative">
  <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500" size={16} />
  <input
    type="text"
    placeholder="Search settings..."
    value={searchQuery}
    onChange={(e) => setSearchQuery(e.target.value)}
    onFocus={() => searchQuery.length >= 2 && setIsSearchOpen(true)}
    className="pl-10 pr-10 py-2 rounded-lg text-sm border-0 outline-none w-64 transition-all focus:w-80"
    style={{ backgroundColor: '#1a2227', color: '#e5e7eb' }}
  />
  {searchQuery && (
    <button
      onClick={() => {
        setSearchQuery('');
        setIsSearchOpen(false);
      }}
      className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-500 hover:text-gray-300"
    >
      <X size={14} />
    </button>
  )}
  {/* Search Results Dropdown */}
  {isSearchOpen && searchResults.length > 0 && (
    <div
      className="absolute top-full right-0 mt-2 w-96 rounded-lg border overflow-hidden shadow-xl z-50 mr-5"
      style={{ backgroundColor: '#1a2227', borderColor: '#2a3439', maxWidth: 'calc(100vw - 40px)' }}
    >
      <div className="p-2">
        <p className="text-xs text-gray-500 px-3 py-2">
          Found {searchResults.length} result{searchResults.length !== 1 ? 's' : ''}
        </p>
        <div className="space-y-1">
          {searchResults.map((result, index) => {
            const page = menuItems.find(item => item.id === result.page);
            if (!page) return null;
            const Icon = page.icon;
            return (
              <button
                key={`${result.page}-${result.term}-${index}`}
                onClick={() => handleSearchResultClick(result.page)}
                className="group w-full flex items-center gap-3 px-3 py-2.5 rounded-lg hover:bg-[#0f1416] transition-all duration-200 text-left hover:scale-[1.02] hover:shadow-lg"
                style={{ backgroundColor: activePage === result.page ? '#0f1416' : 'transparent' }}
              >
                <div
                  className="w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0 transition-transform duration-200 group-hover:scale-110"
                  style={{ backgroundColor: `${page.color}20` }}
                >
                  <Icon size={16} style={{ color: page.color }} />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-gray-100">{page.label}</p>
                  <p className="text-xs text-gray-500 truncate">{result.term}</p>
                </div>
                <div className="opacity-0 group-hover:opacity-100 transition-all duration-200 group-hover:translate-x-0 translate-x-2">
                  <ArrowRight size={16} className="text-blue-400" />
                </div>
              </button>
            );
          })}
        </div>
      </div>
    </div>
  )}
</div>

        </div>

        {/* Content Area */}
        <div className="flex-1 overflow-y-auto" style={{ backgroundColor: '#0a0e10' }}>
          <div className="px-8 pb-8">
            {renderPage()}
          </div>
        </div>
      </div>
    </div>
  );
};

export default App;
