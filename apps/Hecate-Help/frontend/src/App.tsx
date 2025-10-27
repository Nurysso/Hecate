import React, { useState, useEffect } from 'react';
import { Keyboard, Terminal, Palette, Waves, HomeIcon, Monitor, LucideIcon } from 'lucide-react';
import KeybindsView from './components/KeybindsView';
// import DummyPage from './components/DummyPage';
import PreferencesView from './components/Prefrence';
import ThemeView from "./components/Themes";
import WaybarView from "./components/Waybar";
import MonitorsView from './components/Monitors';
import SettingsView from './components/SettingView';
import { GetStartupArgs } from '../wailsjs/go/main/App';
interface MenuItem {
  id: string;
  label: string;
  icon: LucideIcon;
}

const App: React.FC = () => {
  const [activePage, setActivePage] = useState<string>('keybinds');

  const menuItems: MenuItem[] = [
    { id: 'home', label: 'Settings', icon: HomeIcon },
    { id: 'keybinds', label: 'Keybinds', icon: Keyboard },
    { id: 'waybar', label: 'Waybar', icon: Waves },
    { id: 'Prefrences', label: 'Prefrences', icon: Terminal },
    { id: 'theme', label: 'Theme', icon: Palette },
    { id: 'monitors', label: 'Monitors', icon: Monitor },
  ];

  useEffect(() => {
    // Check for startup arguments on component mount
    GetStartupArgs().then((args: string[]) => {
      if (args && args.length > 0) {
        // Get the first argument and convert to lowercase for case-insensitive matching
        const tabArg = args[0].toLowerCase();

        // Check if it matches any valid tab ID (case-insensitive)
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
      case 'Prefrences':
        return <PreferencesView />;
      case 'theme':
        return <ThemeView />;
      case 'settings':
        return <SettingsView />;
      case 'monitors':
        return <MonitorsView />;
      default:
        return <SettingsView />;
    }
  };

  return (
    <div className="flex h-screen" style={{ backgroundColor: '#0f1416' }}>
      <div className="w-48 border-r flex flex-col" style={{ backgroundColor: '#141b1e', borderColor: '#1e272b' }}>
        <div className="p-4 border-b" style={{ borderColor: '#1e272b' }}>
          <h1 className="text-base font-semibold text-gray-100">Hecate</h1>
          <p className="text-xs text-gray-400">Helper</p>
        </div>

        <nav className="flex-1 p-2 overflow-y-auto overflow-x-hidden h-[20px]">
          <div className="space-y-0.5">
            {menuItems.map(item => {
              const Icon = item.icon;
              return (
                <button
                  key={item.id}
                  onClick={() => setActivePage(item.id)}
                  className={`w-full flex items-center gap-2 px-3 py-2 rounded text-sm transition-colors overflow-hidden whitespace-nowrap ${
                    activePage === item.id
                      ? 'text-white'
                      : 'text-gray-400 hover:text-gray-200'
                  }`}
                  style={activePage === item.id ? { backgroundColor: '#1e3a5f' } : {}}
                >
                  <Icon size={16} />
                  <span className="overflow-hidden text-ellipsis">{item.label}</span>
                </button>
              );
            })}
          </div>
        </nav>

        <div className="p-3 border-t" style={{ borderColor: '#1e272b' }}>
          <div className="text-xs text-gray-500 text-center">v0.4.0 shy eagle</div>
        </div>
      </div>

      <div className="flex-1 flex flex-col overflow-hidden">
        {renderPage()}
      </div>
    </div>
  );
}

export default App;
