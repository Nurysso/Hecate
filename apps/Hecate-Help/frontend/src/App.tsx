import React, { useState, useEffect } from 'react';
import { Keyboard, Terminal, Palette, Waves, Home, Monitor, AppWindow, Orbit, Search, Settings } from 'lucide-react';
   import Hecate from '../public/hecate.svg';
import PreferencesView from './components/Prefrence';
import KeybindsView from './components/KeybindsView';
import ThemeView from "./components/Themes";
import WaybarView from "./components/Waybar";
import MonitorsView from './components/Monitors';
import SettingsView from './components/SettingView';
import WindowRulesView from './components/windowRules';
import AnimationsView from './components/AnimationView';
import { GetStartupArgs } from '../wailsjs/go/main/App';

const App = () => {
  const [activePage, setActivePage] = useState('home');
  const [searchQuery, setSearchQuery] = useState('');
  const [hoveredItem, setHoveredItem] = useState<string | null>(null);

  const menuItems = [
    { id: 'home', label: 'Settings', icon: Home, color: '#60a5fa' },
    { id: 'keybinds', label: 'Keybinds', icon: Keyboard, color: '#60a5fa' },
    { id: 'waybar', label: 'Waybar', icon: Waves, color: '#60a5fa' },
    { id: 'prefrences', label: 'Preferences', icon: Terminal, color: '#60a5fa' },
    { id: 'theme', label: 'Theme', icon: Palette, color: '#60a5fa' },
    { id: 'monitors', label: 'Monitors', icon: Monitor, color: '#60a5fa' },
    { id: 'windows', label: 'Window Rules', icon: AppWindow, color: '#60a5fa' },
    { id: 'animations', label: 'Animations', icon: Orbit, color: '#60a5fa' },
  ];

  const filteredItems = menuItems.filter(item =>
    item.label.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const activeItem = menuItems.find(i => i.id === activePage);

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
      case 'waybar':
        return <WaybarView />
      case 'prefrences':
        return <PreferencesView />;
      case 'theme':
        return <ThemeView />;
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
<img src={Hecate} style={{ width: 20, height: 20 }} className="text-white relative z-10" />
            {/* <Settings size={20} className="text-white relative z-10" /> */}
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
                    {/* Active indicator line */}
                    {isActive && (
                      <div
                        className="absolute left-0 top-1/2 -translate-y-1/2 w-1 h-6 rounded-r-full transition-all"
                        style={{ backgroundColor: item.color }}
                      />
                    )}

                    {/* Icon glow effect */}
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
          </div>

          {/* Search */}
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500" size={16} />
            <input
              type="text"
              placeholder="Search..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="pl-10 pr-4 py-2 rounded-lg text-sm border-0 outline-none w-64 transition-all focus:w-80"
              style={{ backgroundColor: '#1a2227', color: '#e5e7eb' }}
            />
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
