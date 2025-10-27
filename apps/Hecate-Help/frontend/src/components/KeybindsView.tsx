import React, { useState, useEffect } from 'react';
import { Search, RefreshCw, Edit2, Info } from 'lucide-react';
// import HecateLoader from './loader';
import { Popover, PopoverTrigger, PopoverContent } from './ui/popover';
interface Keybind {
  mods: string;
  key: string;
  action: string;
  description: string;
  category: string;
  isCommented: boolean;
  rawLine: string;
}

interface GroupedKeybinds {
  [category: string]: Keybind[];
}

const getWailsRuntime = () => {
  if (typeof window !== 'undefined' && (window as any).go?.main?.App) {
    return (window as any).go.main.App;
  }
  return null;
};

const KeybindsView: React.FC = () => {
  const [keybinds, setKeybinds] = useState<Keybind[]>([]);
  const [search, setSearch] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('All');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    loadKeybinds();
  }, []);

const loadKeybinds = async () => {
  setLoading(true);
  setError('');

  // Declare startTime outside try/catch so it’s always available
//   const startTime = Date.now();

  try {
    const wailsApp = getWailsRuntime();
    let data: Keybind[] = [];

    if (wailsApp && wailsApp.GetKeybinds) {
      data = await wailsApp.GetKeybinds();
      setKeybinds(data || []);
    } else {
      setError('Wails runtime not available. Please run with Wails.');
      setKeybinds([]);
    }
  } catch (err) {
    setError(
      'Failed to load keybinds from config file. Make sure ~/.config/hypr/configs/keybinds.conf exists.'
    );
  } finally {
    // Ensure loader stays visible for at least 1 second
    // const elapsed = Date.now() - startTime;
    // const remaining = Math.max(0, 800 - elapsed);
    // await new Promise((resolve) => setTimeout(resolve, remaining));

    setLoading(false);
  }
};


  // Open entire config file in Neovim
  const openConfigInNeovim = async () => {
    try {
      const wailsApp = getWailsRuntime();
      if (wailsApp && wailsApp.OpenConfigInNeovim) {
        await wailsApp.OpenConfigInNeovim();
      } else {
        alert('Wails backend not available');
      }
    } catch (error) {
      alert('Failed to open config in Neovim');
    }
  };

  const categories = ['All', ...new Set(keybinds.map(k => k.category))];

  const filteredKeybinds = keybinds.filter(k => {
    const searchTerm = search.toLowerCase();
    const matchesSearch =
      k.description.toLowerCase().includes(searchTerm) ||
      k.key.toLowerCase().includes(searchTerm) ||
      k.mods.toLowerCase().includes(searchTerm);
    const matchesCategory = selectedCategory === 'All' || k.category === selectedCategory;
    return matchesSearch && matchesCategory;
  });

  const groupedKeybinds: GroupedKeybinds = filteredKeybinds.reduce((acc, k) => {
    if (!acc[k.category]) acc[k.category] = [];
    acc[k.category].push(k);
    return acc;
  }, {} as GroupedKeybinds);

  if (loading) {
    return (
       <div className="flex items-center justify-center h-full bg-gray-950">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-2 border-gray-700 border-t-gray-400 mx-auto mb-4"></div>
          <p className="text-gray-400 text-sm">Loading preferences...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex-1 flex items-center justify-center" style={{ backgroundColor: '#0f1416' }}>
        <div className="text-center max-w-md">
          <div className="text-red-400 mb-4 px-4">{error}</div>
          <button
            onClick={loadKeybinds}
            className="px-4 py-2 rounded text-sm text-white transition-colors flex items-center gap-2 mx-auto hover:opacity-80"
            style={{ backgroundColor: '#1e3a5f' }}
          >
            <RefreshCw size={16} />
            Retry
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="h-full overflow-y-auto bg-[#0f1416]">
      <div className="p-6 max-w-4xl mx-auto">
             <div className="mb-6 pb-4 border-b border-gray-800">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-2xl font-semibold text-gray-100 mb-1">Key Binds Configuration</h1>
              <p className="text-sm text-gray-500">
                Manage Key Binds
                <Popover>
                  <PopoverTrigger asChild>
                    <button className="ml-2 text-gray-600 hover:text-gray-400 inline-flex items-center">
                      <Info className="w-3.5 h-3.5" />
                    </button>
                  </PopoverTrigger>
    <PopoverContent className="w-80 bg-gray-900 border-gray-800 text-gray-300 text-sm">
                    <div className="space-y-2">
                      <p className="font-medium text-gray-200">How it works</p>
                      <p>Key Binds mut be a single file located at ~/.config/hypr/configs/keybinds.conf </p>
              <ul className="space-y-0.5 text-blue-400/80">
                        <li> start line with "#/"" to create category</li>
                        <li>start line with "#."" to be completely ignore</li>
                      </ul>
                    </div>
                  </PopoverContent>
                </Popover>
              </p>
            </div>
          </div>
        </div>
      <div className="p-4 border-b" style={{ borderColor: '#1e272b' }}>
        <div className="flex items-center justify-between mb-3 gap-2">
          <div className="relative flex-1 mr-2">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-500" size={16} />
            <input
              type="text"
              placeholder="Search keybindings..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full pl-9 pr-3 py-2 border rounded text-sm focus:outline-none text-gray-200"
              style={{ backgroundColor: '#141b1e', borderColor: '#2a3439' }}
            />
          </div>
          {/* Button to open all in neovim */}
          <button
            onClick={openConfigInNeovim}
            className="px-3 py-2 rounded text-sm flex items-center gap-2 transition-colors hover:opacity-80"
            style={{ backgroundColor: '#1e3a5f', color: '#fff' }}
            title="Open config in Neovim"
          >
            <Edit2 size={16} />
          </button>
          <button
            onClick={loadKeybinds}
            className="px-3 py-2 rounded text-sm transition-colors flex items-center gap-2 hover:opacity-80"
            style={{ backgroundColor: '#1a2227', color: '#9ca3af' }}
            title="Reload keybinds"
          >
            <RefreshCw size={16} />
          </button>
          <button className="flex items-center gap-2 bg-[#141b1e] rounded">
  <select
    value={selectedCategory}
    onChange={e => setSelectedCategory(e.target.value)}
    className="bg-[#141b1e] text-gray-200 border border-[#1e272b] rounded px-3 py-2 text-xs focus:outline-none appearance-none"
    style={{
      backgroundColor: '#141b1e',
      color: '#e5e7eb',
    }}
  >
    {categories.map(cat => (
      <option
        key={cat}
        value={cat}
        style={{ backgroundColor: '#141b1e', color: '#e5e7eb' }}
      >
        {cat}
      </option>
    ))}
  </select>
</button>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto p-4">
        {Object.entries(groupedKeybinds).length === 0 ? (
          <div className="text-center text-gray-500 mt-8">
            {keybinds.length === 0
              ? 'No keybinds found. Make sure ~/.config/hypr/configs/keybinds.conf exists.'
              : 'No keybinds found matching your search.'}
          </div>
        ) : (
          Object.entries(groupedKeybinds).map(([category, binds]) => (
            <div key={category} className="mb-6">
              <h3 className="text-sm font-semibold text-gray-300 mb-4 uppercase tracking-wide">
                {category}
              </h3>

              <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
                {binds.map((bind, idx) => (
                  <div
                    key={idx}
                    className={`flex flex-col justify-between p-4 rounded border transition-all ${
                      bind.isCommented ? 'opacity-50 hover:opacity-70' : 'hover:opacity-90'
                    }`}
                    style={{
                      backgroundColor: bind.isCommented ? '#0f1416' : '#141b1e',
                      borderColor: '#1e272b',
                      minHeight: '100px',
                    }}
                  >
                    {/* No action line */}
                    <div className={`text-xs mb-2 ${bind.isCommented ? 'text-gray-600' : 'text-gray-400'}`}>
                      {bind.description}
                    </div>
                    <div className="flex items-center gap-1 mt-auto flex-wrap">
                      {bind.mods && bind.mods.trim() !== '' && (
                        <>
                          {bind.mods.split(' + ').map((mod, i) => (
                            <React.Fragment key={i}>
                              <kbd
                                className="px-2 py-1 border rounded text-xs font-mono"
                                style={{
                                  backgroundColor: '#1a2227',
                                  borderColor: '#2a3439',
                                  color: bind.isCommented ? '#6b7280' : '#9ca3af',
                                }}
                              >
                                {mod}
                              </kbd>
                              <span className="text-gray-600 text-xs">+</span>
                            </React.Fragment>
                          ))}
                        </>
                      )}
                      <kbd
                        className="px-2 py-1 border rounded text-xs font-mono"
                        style={{
                          backgroundColor: '#1a2227',
                          borderColor: '#2a3439',
                          color: bind.isCommented ? '#6b7280' : '#9ca3af',
                        }}
                      >
                        {bind.key}
                      </kbd>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          ))
        )}
      </div>
    </div>
    </div>
  );
};

export default KeybindsView;
