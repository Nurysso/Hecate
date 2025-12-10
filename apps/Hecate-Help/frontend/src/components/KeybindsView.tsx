import React, { useState, useEffect } from 'react';
import { Search, RefreshCw, Edit2, Info, Save, X, Plus } from 'lucide-react';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from './ui/select';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from './ui/dialog';

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

interface EditingKeybind {
  index: number;
  bindType: string;
  mods: string;
  key: string;
  action: string;
  description: string;
  isCommented: boolean;
  rawLine: string;
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
  const [editingKeybind, setEditingKeybind] = useState<EditingKeybind | null>(null);
  const [saveError, setSaveError] = useState('');
  const [isDialogOpen, setIsDialogOpen] = useState(false);

  useEffect(() => {
    loadKeybinds();

    // Auto-reload every 5 seconds without showing loading state
    const intervalId = setInterval(() => {
      loadKeybinds(true); // Pass true to skip loading state
    }, 5000);

    return () => clearInterval(intervalId);
  }, []);

  const loadKeybinds = async (silent = false) => {
    if (!silent) {
      setLoading(true);
    }
    setError('');

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
      if (!silent) {
        setLoading(false);
      }
    }
  };

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

  const startEditing = (bind: Keybind, index: number) => {
    // Extract bind type from rawLine
    const bindTypeMatch = bind.rawLine.match(/bind([lertm]*)/);
    const bindType = bindTypeMatch ? bindTypeMatch[1] || 'default' : 'default';

    // Extract original mods from rawLine to preserve $mainMod format
    const rawLineMatch = bind.rawLine.match(/bind[lertm]*\s*=\s*([^,]*),/);
    const originalMods = rawLineMatch ? rawLineMatch[1].trim() : bind.mods.replace(/ \+ /g, '_');

    setEditingKeybind({
      index,
      bindType,
      mods: originalMods,
      key: bind.key.toLowerCase(),
      action: bind.action,
      description: bind.description,
      isCommented: bind.isCommented,
      rawLine: bind.rawLine,
    });
    setSaveError('');
    setIsDialogOpen(true);
  };

  const startAddingNew = () => {
    setEditingKeybind({
      index: -1, // -1 indicates new keybind
      bindType: 'default',
      mods: '$mainMod',
      key: '',
      action: '',
      description: '',
      isCommented: false,
      rawLine: '',
    });
    setSaveError('');
    setIsDialogOpen(true);
  };

  const cancelEditing = () => {
    setEditingKeybind(null);
    setSaveError('');
    setIsDialogOpen(false);
  };

  const saveKeybind = async () => {
    if (!editingKeybind) return;

    // Validate description is not empty
    if (!editingKeybind.description.trim()) {
      setSaveError('Description is required');
      return;
    }

    // Validate key is not empty
    if (!editingKeybind.key.trim()) {
      setSaveError('Key is required');
      return;
    }

    // Validate action is not empty
    if (!editingKeybind.action.trim()) {
      setSaveError('Action is required');
      return;
    }

    try {
      const wailsApp = getWailsRuntime();
      if (wailsApp && wailsApp.UpdateKeybind) {
        const success = await wailsApp.UpdateKeybind(
          editingKeybind.rawLine,
          editingKeybind.bindType,
          editingKeybind.mods,
          editingKeybind.key,
          editingKeybind.action,
          editingKeybind.description,
          editingKeybind.isCommented
        );

        if (success) {
          setEditingKeybind(null);
          setSaveError('');
          setIsDialogOpen(false);
          await loadKeybinds(); // Reload to show changes
        } else {
          setSaveError('Failed to update keybind');
        }
      } else {
        setSaveError('Wails backend not available');
      }
    } catch (error) {
      setSaveError('Error updating keybind: ' + error);
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
      <div className="flex items-center justify-center min-h-screen bg-gray-950">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-2 border-gray-700 border-t-gray-400 mx-auto mb-4"></div>
          <p className="text-gray-400 text-sm">Loading keybinds...</p>
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
            onClick={() => loadKeybinds()}
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
    <div className="h-full flex flex-col">
      <div className="sticky bg-[#0A0E10] top-0 z-40 border-b border-gray-800 rounded-lg mb-2">
            <div className="max-w-4xl mx-auto">
                <div className="flex items-center justify-between p-3 m-2 rounded-lg">
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
                <div className='flex gap-2'>
                <button
                    onClick={startAddingNew}
                    className="h-[38px] px-3 py-2 rounded text-sm flex items-center gap-2 transition-colors hover:opacity-80"
                    style={{ backgroundColor: '#1e3a5f', color: '#fff' }}
                    title="Add new keybind"
                >
                    <Plus size={18} />
                </button>
                <button
                    onClick={openConfigInNeovim}
                    className="h-[38px] px-3 py-2 rounded text-sm flex items-center gap-2 transition-colors hover:opacity-80"
                    style={{ backgroundColor: '#1e3a5f', color: '#fff' }}
                    title="Open config in Neovim"
                >
                    <Edit2 size={18} />
                </button>
                <Select value={selectedCategory} onValueChange={setSelectedCategory}>
                    <SelectTrigger className="h-[38px] bg-[#141b1e] text-gray-200 border border-[#1e272b] rounded px-3 py-2 text-sm focus:outline-none focus:ring-0">
                    <SelectValue />
                    </SelectTrigger>
                    <SelectContent className="bg-[#141b1e] border border-[#1e272b]">
                    {categories.map(cat => (
                        <SelectItem
                        key={cat}
                        value={cat}
                        className="text-gray-200 focus:bg-[#1e272b] focus:text-gray-100"
                        >
                        {cat}
                        </SelectItem>
                    ))}
                    </SelectContent>
                </Select>
                </div>
                </div>
            </div>
        </div>
        <div className="m-2 max-w-4xl mx-auto">
        <div className="flex-1">
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
                  {binds.map((bind, idx) => {
                    const globalIndex = keybinds.indexOf(bind);

                    return (
                      <div
                        key={idx}
                        onClick={() => startEditing(bind, globalIndex)}
                        onContextMenu={(e) => {
                          e.preventDefault();
                          openConfigInNeovim();
                        }}
                        className={`flex flex-col justify-between p-4 rounded border transition-all cursor-pointer ${
                          bind.isCommented ? 'opacity-50 hover:opacity-70' : 'hover:opacity-90'
                        }`}
                        style={{
                          backgroundColor: bind.isCommented ? '#0f1416' : '#141b1e',
                          borderColor: '#1e272b',
                          minHeight: '100px',
                        }}
                        title="Left click to edit • Right click to open in Neovim"
                      >
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
                    );
                  })}
                </div>
              </div>
            ))
          )}
        </div>

      </div>

      {/* Edit/Add Keybind Dialog */}
      <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
        <DialogContent className="bg-[#141b1e] border border-[#1e272b] text-gray-200 max-w-2xl">
          <DialogHeader>
            <DialogTitle className="text-gray-100">
              {editingKeybind?.index === -1 ? 'Add New Keybind' : 'Edit Keybind'}
            </DialogTitle>
          </DialogHeader>

          {saveError && (
            <div className="mb-3 p-2 bg-red-900/20 border border-red-700 rounded text-red-400 text-xs">
              {saveError}
            </div>
          )}

          {editingKeybind && (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-xs text-gray-400 mb-1">Bind Type</label>
                <Select
                  value={editingKeybind.bindType}
                  onValueChange={(value) => setEditingKeybind({ ...editingKeybind, bindType: value })}
                >
                  <SelectTrigger className="w-full bg-[#1a2227] text-gray-200 border border-[#2a3439] rounded px-3 py-2 text-sm focus:outline-none focus:ring-0">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent className="bg-[#1a2227] border border-[#2a3439]">
                    <SelectItem value="default" className="text-gray-200 focus:bg-[#2a3439] focus:text-gray-100">
                      bind (default)
                    </SelectItem>
                    <SelectItem value="l" className="text-gray-200 focus:bg-[#2a3439] focus:text-gray-100">
                      bindl (locked)
                    </SelectItem>
                    <SelectItem value="r" className="text-gray-200 focus:bg-[#2a3439] focus:text-gray-100">
                      bindr (on release)
                    </SelectItem>
                    <SelectItem value="e" className="text-gray-200 focus:bg-[#2a3439] focus:text-gray-100">
                      binde (repeat)
                    </SelectItem>
                    <SelectItem value="m" className="text-gray-200 focus:bg-[#2a3439] focus:text-gray-100">
                      bindm (mouse)
                    </SelectItem>
                    <SelectItem value="t" className="text-gray-200 focus:bg-[#2a3439] focus:text-gray-100">
                      bindt (transparent)
                    </SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div>
                <label className="block text-xs text-gray-400 mb-1">Modifiers</label>
                <input
                  type="text"
                  value={editingKeybind.mods}
                  onChange={e => setEditingKeybind({ ...editingKeybind, mods: e.target.value })}
                  placeholder="$mainMod, ALT_SHIFT, etc."
                  className="w-full bg-[#1a2227] text-gray-200 border border-[#2a3439] rounded px-3 py-2 text-sm focus:outline-none"
                />
              </div>

              <div>
                <label className="block text-xs text-gray-400 mb-1">Key <span className="text-red-400">*</span></label>
                <input
                  type="text"
                  value={editingKeybind.key}
                  onChange={e => setEditingKeybind({ ...editingKeybind, key: e.target.value })}
                  placeholder="return, space, etc."
                  className="w-full bg-[#1a2227] text-gray-200 border border-[#2a3439] rounded px-3 py-2 text-sm focus:outline-none"
                />
              </div>

              <div>
                <label className="block text-xs text-gray-400 mb-1">Action <span className="text-red-400">*</span></label>
                <input
                  type="text"
                  value={editingKeybind.action}
                  onChange={e => setEditingKeybind({ ...editingKeybind, action: e.target.value })}
                  placeholder="exec kitty, workspace 1, etc."
                  className="w-full bg-[#1a2227] text-gray-200 border border-[#2a3439] rounded px-3 py-2 text-sm focus:outline-none"
                />
              </div>

              <div className="md:col-span-2">
                <label className="block text-xs text-gray-400 mb-1">
                  Description <span className="text-red-400">*</span>
                </label>
                <input
                  type="text"
                  value={editingKeybind.description}
                  onChange={e => setEditingKeybind({ ...editingKeybind, description: e.target.value })}
                  placeholder="Description is required"
                  className="w-full bg-[#1a2227] text-gray-200 border border-[#2a3439] rounded px-3 py-2 text-sm focus:outline-none"
                />
              </div>

              <div className="md:col-span-2">
                <label className="flex items-center gap-2 text-sm text-gray-400">
                  <input
                    type="checkbox"
                    checked={editingKeybind.isCommented}
                    onChange={e => setEditingKeybind({ ...editingKeybind, isCommented: e.target.checked })}
                    className="rounded"
                  />
                  Commented out (disabled)
                </label>
              </div>
            </div>
          )}

          <DialogFooter className="gap-2">
            <button
              onClick={cancelEditing}
              className="px-4 py-2 bg-gray-700 hover:bg-gray-600 text-white rounded text-sm flex items-center gap-2 transition-colors"
            >
              <X size={16} />
              Cancel
            </button>
            <button
              onClick={saveKeybind}
              className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded text-sm flex items-center gap-2 transition-colors"
            >
              <Save size={16} />
              Save
            </button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
};

export default KeybindsView;
