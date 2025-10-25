import React, { useState } from 'react';
import { Keyboard, Terminal, Palette, Waves, Settings, LucideIcon } from 'lucide-react';
import KeybindsView from './components/KeybindsView';
import DummyPage from './components/DummyPage';

interface MenuItem {
  id: string;
  label: string;
  icon: LucideIcon;
}

const App: React.FC = () => {
  const [activePage, setActivePage] = useState<string>('keybinds');

  const menuItems: MenuItem[] = [
    { id: 'keybinds', label: 'Keybinds', icon: Keyboard },
    { id: 'waybar', label: 'Waybar', icon: Waves },
    { id: 'shell', label: 'Shell', icon: Terminal },
    { id: 'terminal', label: 'Terminal', icon: Terminal },
    { id: 'theme', label: 'Theme', icon: Palette },
    { id: 'settings', label: 'Settings', icon: Settings },
  ];

  const renderPage = () => {
    switch (activePage) {
      case 'keybinds':
        return <KeybindsView />;
      case 'waybar':
        return <DummyPage title="Waybar Config" icon={Waves} />;
      case 'shell':
        return <DummyPage title="Shell Config" icon={Terminal} />;
      case 'terminal':
        return <DummyPage title="Terminal Config" icon={Terminal} />;
      case 'theme':
        return <DummyPage title="Theme Settings" icon={Palette} />;
      case 'settings':
        return <DummyPage title="Settings" icon={Settings} />;
      default:
        return <KeybindsView />;
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
