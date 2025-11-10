import React, { useState, useEffect } from 'react';
import { Search, RefreshCw, Edit2, Trash2, Plus, Monitor, Layers, Check, X } from 'lucide-react';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from './ui/select';

// Type definitions
interface HyprlandClient {
  address: string;
  mapped: boolean;
  hidden: boolean;
  at: number[];
  size: number[];
  workspace: {
    id: number;
    name: string;
  };
  floating: boolean;
  pseudo: boolean;
  monitor: number;
  class: string;
  title: string;
  initialClass: string;
  initialTitle: string;
  pid: number;
  xwayland: boolean;
  pinned: boolean;
  fullscreen: number;
  fullscreenClient: number;
  grouped: string[];
  tags: string[];
  swallowing: string;
  focusHistoryID: number;
}

interface RuleOption {
  value: string;
  label: string;
  requiresValue: boolean;
  placeholder?: string;
  description?: string;
}


const WindowRulesView: React.FC = () => {
  const [windows, setWindows] = useState<HyprlandClient[]>([]);
  const [existingRules, setExistingRules] = useState<string[]>([]);
  const [selectedWindow, setSelectedWindow] = useState<HyprlandClient | null>(null);
  const [loading, setLoading] = useState(false);
  const [rulePreview, setRulePreview] = useState<string>('Configure rule above...');
  const [activeTab, setActiveTab] = useState<'windows' | 'create' | 'rules'>('windows');
  const [search, setSearch] = useState('');

  // Rule form state
  const [ruleType, setRuleType] = useState('float');
  const [ruleValue, setRuleValue] = useState('');
  const [useInitial, setUseInitial] = useState(true);
  const [matchClass, setMatchClass] = useState(true);
  const [matchTitle, setMatchTitle] = useState(false);

  const ruleOptions: RuleOption[] = [
    { value: 'float', label: 'Float', requiresValue: false, description: 'Make window floating' },
    { value: 'tile', label: 'Tile', requiresValue: false, description: 'Tile the window' },
    { value: 'fullscreen', label: 'Fullscreen', requiresValue: false, description: 'Fullscreen the window' },
    { value: 'maximize', label: 'Maximize', requiresValue: false, description: 'Maximize the window' },
    { value: 'workspace', label: 'Workspace', requiresValue: true, placeholder: '1', description: 'Set workspace (e.g., 1, 2, special:scratchpad)' },
    { value: 'monitor', label: 'Monitor', requiresValue: true, placeholder: '0', description: 'Set monitor (e.g., 0, 1, DP-1)' },
    { value: 'size', label: 'Size', requiresValue: true, placeholder: '1280 720', description: 'Set window size (e.g., 1280 720, 50% 50%)' },
    { value: 'move', label: 'Move', requiresValue: true, placeholder: '100 100', description: 'Move window (e.g., 100 100, cursor 50% 50%)' },
    { value: 'center', label: 'Center', requiresValue: false, description: 'Center the floating window' },
    { value: 'pseudo', label: 'Pseudo', requiresValue: false, description: 'Pseudotile the window' },
    { value: 'pin', label: 'Pin', requiresValue: false, description: 'Pin window to all workspaces' },
    { value: 'noinitialfocus', label: 'No Initial Focus', requiresValue: false, description: 'Disable initial focus' },
    { value: 'nomaxsize', label: 'No Max Size', requiresValue: false, description: 'Remove max size limitations' },
    { value: 'stayfocused', label: 'Stay Focused', requiresValue: false, description: 'Force focus while visible' },
    { value: 'fullscreenstate', label: 'Fullscreen State', requiresValue: true, placeholder: '0 2', description: 'Set fullscreen mode (internal client)' },
    { value: 'suppressevent', label: 'Suppress Event', requiresValue: true, placeholder: 'fullscreen maximize', description: 'Ignore specific events' },
    { value: 'persistentsize', label: 'Persistent Size', requiresValue: false, description: 'Allow size persistence' },
    { value: 'group', label: 'Group', requiresValue: true, placeholder: 'set', description: 'Set window group properties' },
    { value: 'content', label: 'Content', requiresValue: true, placeholder: 'video', description: 'Set content type (none, photo, video, game)' },
    { value: 'noclosefor', label: 'No Close For', requiresValue: true, placeholder: '5000', description: 'Uncloseable for X milliseconds' },
    { value: 'unset', label: 'Unset', requiresValue: true, placeholder: 'float', description: 'Unset a specific rule' },
  ];
useEffect(() => {
  generateRule().then(setRulePreview).catch(() => setRulePreview('Error generating rule'));
}, [/* dependencies */]);
  useEffect(() => {
    loadWindows();
    loadExistingRules();
  }, []);

  const loadWindows = async () => {
    setLoading(true);
    try {
      // @ts-ignore - Wails runtime
      const result = await window.go.main.App.GetOpenWindows();
      setWindows(result || []);
    } catch (error) {
      console.error('Failed to load windows:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadExistingRules = async () => {
    try {
      // @ts-ignore - Wails runtime
      const result = await window.go.main.App.GetExistingRules();
      setExistingRules(result || []);
    } catch (error) {
      console.error('Failed to load existing rules:', error);
    }
  };

  const handleWindowSelect = (window: HyprlandClient) => {
    setSelectedWindow(window);
    setActiveTab('create');
  };

  const generateRule = async (): Promise<string> => {
    if (!selectedWindow) return '';

    const classValue = useInitial ? selectedWindow.initialClass : selectedWindow.class;
    const titleValue = useInitial ? selectedWindow.initialTitle : selectedWindow.title;

    const currentRule = ruleOptions.find(r => r.value === ruleType);
    const ruleStr = currentRule?.requiresValue ? `${ruleType} ${ruleValue}` : ruleType;

    const matchClassStr = matchClass ? classValue : '';
    const matchTitleStr = matchTitle ? titleValue : '';

    try {
      // @ts-ignore - Wails runtime
      return await window.go.main.App.GenerateWindowRule(
        ruleStr,
        matchClassStr,
        matchTitleStr,
        useInitial
      );
    } catch (error) {
      console.error('Failed to generate rule:', error);
      return '';
    }
  };

  const handleSaveRule = async () => {
    try {
      const rule = await generateRule();
      if (!rule) {
        // @ts-ignore - Wails runtime
        window.go.main.App.ShowError('Error', 'Failed to generate rule');
        return;
      }

      // @ts-ignore - Wails runtime
      await window.go.main.App.SaveWindowRule(rule);
      // @ts-ignore - Wails runtime
      window.go.main.App.ShowMessage('Success', 'Window rule saved successfully!');
      await loadExistingRules();
      setActiveTab('rules');
      // Reset form
      setRuleValue('');
    } catch (error) {
      // @ts-ignore - Wails runtime
      window.go.main.App.ShowError('Error', `Failed to save rule: ${error}`);
    }
  };

  const handleRemoveRule = async (rule: string) => {
    try {
      // @ts-ignore - Wails runtime
      await window.go.main.App.RemoveWindowRule(rule);
      // @ts-ignore - Wails runtime
      window.go.main.App.ShowMessage('Success', 'Window rule removed successfully!');
      await loadExistingRules();
    } catch (error) {
      // @ts-ignore - Wails runtime
      window.go.main.App.ShowError('Error', `Failed to remove rule: ${error}`);
    }
  };

  const filteredWindows = windows.filter(w =>
    w.class.toLowerCase().includes(search.toLowerCase()) ||
    w.title.toLowerCase().includes(search.toLowerCase()) ||
    w.initialClass.toLowerCase().includes(search.toLowerCase()) ||
    w.initialTitle.toLowerCase().includes(search.toLowerCase())
  );

  const currentRuleOption = ruleOptions.find(r => r.value === ruleType);

  const canSave = selectedWindow && (matchClass || matchTitle) && (!currentRuleOption?.requiresValue || ruleValue.trim() !== '');

  return (
        <div className="h-full overflow-y-auto bg-gray-950">
      <div className="p-6 max-w-7xl mx-auto">


        {/* Tabs */}
        <div className="flex gap-2 mb-6 border-b" style={{ borderColor: '#1e272b' }}>
          <button
            onClick={() => setActiveTab('windows')}
            className={`px-4 py-2 text-sm font-medium transition-colors border-b-2 ${
              activeTab === 'windows'
                ? 'text-blue-400 border-blue-400'
                : 'text-gray-400 border-transparent hover:text-gray-300'
            }`}
          >
            <div className="flex items-center gap-2">
              <Layers size={16} />
              Open Windows
            </div>
          </button>
          <button
            onClick={() => setActiveTab('create')}
            disabled={!selectedWindow}
            className={`px-4 py-2 text-sm font-medium transition-colors border-b-2 ${
              activeTab === 'create'
                ? 'text-blue-400 border-blue-400'
                : 'text-gray-400 border-transparent hover:text-gray-300'
            } ${!selectedWindow ? 'opacity-50 cursor-not-allowed' : ''}`}
          >
            <div className="flex items-center gap-2">
              <Plus size={16} />
              Create Rule
            </div>
          </button>
          <button
            onClick={() => setActiveTab('rules')}
            className={`px-4 py-2 text-sm font-medium transition-colors border-b-2 ${
              activeTab === 'rules'
                ? 'text-blue-400 border-blue-400'
                : 'text-gray-400 border-transparent hover:text-gray-300'
            }`}
          >
            <div className="flex items-center gap-2">
              <Edit2 size={16} />
              Existing Rules ({existingRules.length})
            </div>
          </button>
        </div>

        {/* Windows Tab */}
        {activeTab === 'windows' && (
        <div className="overflow-y-auto">
            <div className="p-4 border-b mb-4" style={{ borderColor: '#1e272b' }}>
              <div className="flex items-center justify-between gap-2">
                <div className="relative flex-1 mr-2">
                  <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-500" size={16} />
                  <input
                    type="text"
                    placeholder="Search windows by class or title..."
                    value={search}
                    onChange={(e) => setSearch(e.target.value)}
                    className="w-full pl-9 pr-3 py-2 border rounded text-sm focus:outline-none text-gray-200"
                    style={{ backgroundColor: '#141b1e', borderColor: '#2a3439' }}
                  />
                </div>
                <button
                  onClick={loadWindows}
                  disabled={loading}
                  className="px-3 py-2 rounded text-sm transition-colors flex items-center gap-2 hover:opacity-80"
                  style={{ backgroundColor: '#1a2227', color: '#9ca3af' }}
                  title="Reload windows"
                >
                  <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
                </button>
              </div>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
              {filteredWindows.length === 0 ? (
                <div className="col-span-full text-center text-gray-500 mt-8">
                  {windows.length === 0
                    ? 'No windows found. Make sure Hyprland is running.'
                    : 'No windows found matching your search.'}
                </div>
              ) : (
                filteredWindows.map((window, idx) => (
                  <div
                    key={window.address || idx}
                    onClick={() => handleWindowSelect(window)}
                    className={`flex flex-col justify-between p-4 rounded border transition-all cursor-pointer hover:opacity-90 ${
                      selectedWindow?.address === window.address ? 'ring-2 ring-blue-400' : ''
                    }`}
                    style={{
                      backgroundColor: '#141b1e',
                      borderColor: selectedWindow?.address === window.address ? '#3b82f6' : '#1e272b',
                      minHeight: '120px',
                    }}
                  >
                    <div>
                      <div className="flex items-center justify-between mb-2">
                        <span className="text-sm font-medium text-gray-200 truncate">
                          {window.initialClass || window.class}
                        </span>
                        <span
                          className="px-2 py-0.5 rounded text-xs font-medium"
                          style={{
                            backgroundColor: window.floating ? '#1e3a5f' : '#1a2227',
                            color: window.floating ? '#60a5fa' : '#9ca3af',
                          }}
                        >
                          {window.floating ? 'Float' : 'Tile'}
                        </span>
                      </div>
                      <div className="text-xs text-gray-400 space-y-1">
                        <div className="truncate">{window.initialTitle || window.title}</div>
                        <div className="flex items-center gap-3 text-gray-500">
                          <span className="flex items-center gap-1">
                            <Layers size={12} />
                            WS {window.workspace.name}
                          </span>
                          <span className="flex items-center gap-1">
                            <Monitor size={12} />
                            M{window.monitor}
                          </span>
                        </div>
                      </div>
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>
        )}

        {/* Create Rule Tab */}
        {activeTab === 'create' && selectedWindow && (
        <div className="overflow-y-auto">
            {/* Selected Window Info */}
            <div className="p-4 rounded border" style={{ backgroundColor: '#141b1e', borderColor: '#1e272b' }}>
              <div className="flex items-center justify-between mb-3">
                <h3 className="text-sm font-semibold text-gray-300 uppercase tracking-wide">
                  Selected Window
                </h3>
                <button
                  onClick={() => setActiveTab('windows')}
                  className="text-xs text-gray-500 hover:text-gray-400"
                >
                  Change
                </button>
              </div>
              <div className="flex items-start gap-4">
                <div className="flex-1 space-y-2 text-sm">
                  <div className="flex items-start gap-2">
                    <span className="text-gray-500 w-16 flex-shrink-0">Class:</span>
                    <code className="px-2 py-0.5 rounded text-gray-200 break-all" style={{ backgroundColor: '#1a2227' }}>
                      {selectedWindow.initialClass}
                    </code>
                  </div>
                  <div className="flex items-start gap-2">
                    <span className="text-gray-500 w-16 flex-shrink-0">Title:</span>
                    <code className="px-2 py-0.5 rounded text-gray-200 break-all" style={{ backgroundColor: '#1a2227' }}>
                      {selectedWindow.initialTitle}
                    </code>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <span
                    className="px-2 py-1 rounded text-xs font-medium"
                    style={{
                      backgroundColor: selectedWindow.floating ? '#1e3a5f' : '#1a2227',
                      color: selectedWindow.floating ? '#60a5fa' : '#9ca3af',
                    }}
                  >
                    {selectedWindow.floating ? 'Floating' : 'Tiled'}
                  </span>
                </div>
              </div>
            </div>

            {/* Rule Configuration */}
            <div className="p-4 rounded border" style={{ backgroundColor: '#141b1e', borderColor: '#1e272b' }}>
              <h3 className="text-sm font-semibold text-gray-300 mb-4 uppercase tracking-wide">
                Rule Configuration
              </h3>

              <div className="space-y-4">
                {/* Rule Type Selection */}
<div>
  <label className="block text-sm text-gray-400 mb-2">Rule Type</label>

  <Select
    value={ruleType}
    onValueChange={(value) => {
      setRuleType(value);
      setRuleValue('');
    }}
  >
    <SelectTrigger className="w-full bg-[#1a2227] border-[#2a3439] text-gray-200">
      <SelectValue />
    </SelectTrigger>

    <SelectContent className="bg-[#1a2227] border-[#2a3439] max-h-60 overflow-y-auto ">
      {ruleOptions.map((opt) => (
        <SelectItem
          key={opt.value}
          value={opt.value}
          className="text-gray-200"
        >
          <div className="flex flex-col items-start">
            <span>{opt.label}</span>
            <span className="text-xs text-gray-500">{opt.description}</span>
          </div>
        </SelectItem>
      ))}
    </SelectContent>
  </Select>
</div>


                {/* Rule Value Input (if required) */}
                {currentRuleOption?.requiresValue && (
                  <div>
                    <label className="block text-sm text-gray-400 mb-2">
                      Value <span className="text-red-400">*</span>
                    </label>
                    <input
                      type="text"
                      value={ruleValue}
                      onChange={(e) => setRuleValue(e.target.value)}
                      placeholder={currentRuleOption.placeholder}
                      className="w-full px-3 py-2 border rounded text-sm focus:outline-none text-gray-200 focus:border-blue-400"
                      style={{ backgroundColor: '#1a2227', borderColor: '#2a3439' }}
                    />
                    {currentRuleOption.description && (
                      <p className="text-xs text-gray-500 mt-1">{currentRuleOption.description}</p>
                    )}
                  </div>
                )}

                {/* Window Matching Options */}
                <div>
                  <label className="block text-sm text-gray-400 mb-2">Match By</label>
                  <div className="space-y-2">
                    <label className="flex items-center gap-2 text-sm text-gray-300 cursor-pointer p-2 rounded hover:bg-[#1a2227] transition-colors">
                      <input
                        type="checkbox"
                        checked={matchClass}
                        onChange={(e) => setMatchClass(e.target.checked)}
                        className="rounded bg-[#1a2227] border-gray-600 text-blue-500 focus:ring-blue-500"
                      />
                      <div className="flex-1">
                        <div>Window Class</div>
                        <div className="text-xs text-gray-500">
                          {useInitial ? selectedWindow.initialClass : selectedWindow.class}
                        </div>
                      </div>
                    </label>
                    <label className="flex items-center gap-2 text-sm text-gray-300 cursor-pointer p-2 rounded hover:bg-[#1a2227] transition-colors">
                      <input
                        type="checkbox"
                        checked={matchTitle}
                        onChange={(e) => setMatchTitle(e.target.checked)}
                        className="rounded bg-[#1a2227] border-gray-600 text-blue-500 focus:ring-blue-500"
                      />
                      <div className="flex-1">
                        <div>Window Title</div>
                        <div className="text-xs text-gray-500 truncate">
                          {useInitial ? selectedWindow.initialTitle : selectedWindow.title}
                        </div>
                      </div>
                    </label>
                    <label className="flex items-center gap-2 text-sm text-gray-300 cursor-pointer p-2 rounded hover:bg-[#1a2227] transition-colors">
                      <input
                        type="checkbox"
                        checked={useInitial}
                        onChange={(e) => setUseInitial(e.target.checked)}
                        className="rounded bg-[#1a2227] border-gray-600 text-blue-500 focus:ring-blue-500"
                      />
                      <div className="flex-1">
                        <div>Use Initial Values</div>
                        <div className="text-xs text-gray-500">Recommended for static rules</div>
                      </div>
                    </label>
                  </div>
                  {!matchClass && !matchTitle && (
                    <p className="text-xs text-red-400 mt-2 flex items-center gap-1">
                      <X size={12} />
                      You must select at least one matching criteria
                    </p>
                  )}
                </div>

                {/* Preview */}
                <div className="p-3 rounded" style={{ backgroundColor: '#0f1416', borderColor: '#1e272b', border: '1px solid' }}>
                  <div className="flex items-center justify-between mb-2">
                    <div className="text-xs text-gray-500">Rule Preview</div>
                    {canSave && (
                      <div className="flex items-center gap-1 text-xs text-green-400">
                        <Check size={12} />
                        Ready to save
                      </div>
                    )}
                  </div>
                  <code className="text-xs text-blue-400 break-all">
      {rulePreview}
    </code>
                </div>

                {/* Save Button */}
                <button
                  onClick={handleSaveRule}
                  disabled={!canSave}
                  className={`w-full px-4 py-3 rounded text-sm font-medium transition-colors flex items-center justify-center gap-2 ${
                    canSave ? 'hover:opacity-80' : 'opacity-50 cursor-not-allowed'
                  }`}
                  style={{ backgroundColor: '#1e3a5f', color: '#fff' }}
                >
                  <Plus size={16} />
                  Add Rule to WindowRules.conf
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Existing Rules Tab */}
        {activeTab === 'rules' && (
          <div className="overflow-y-auto">
            <div className="p-4 border-b mb-4" style={{ borderColor: '#1e272b' }}>
              <div className="flex items-center justify-between">
                <h3 className="text-sm font-semibold text-gray-300 uppercase tracking-wide">
                  Existing Rules
                </h3>
                <button
                  onClick={loadExistingRules}
                  className="px-3 py-2 rounded text-sm transition-colors flex items-center gap-2 hover:opacity-80"
                  style={{ backgroundColor: '#1a2227', color: '#9ca3af' }}
                >
                  <RefreshCw size={16} />
                </button>
              </div>
            </div>

            <div className="space-y-3">
              {existingRules.length === 0 ? (
                <div className="text-center text-gray-500 mt-8">
                  <p>No window rules found in WindowRules.conf</p>
                  <p className="text-xs text-gray-600 mt-2">~/.config/hypr/configs/WindowRules.conf</p>
                </div>
              ) : (
                existingRules.map((rule, idx) => (
                  <div
                    key={idx}
                    className="flex items-center justify-between p-4 rounded border group hover:border-gray-700 transition-colors"
                    style={{ backgroundColor: '#141b1e', borderColor: '#1e272b' }}
                  >
                    <code className="text-xs text-gray-300 flex-1 break-all">
                      {rule}
                    </code>
                    <button
                      onClick={() => handleRemoveRule(rule)}
                      className="ml-4 p-2 rounded transition-colors opacity-0 group-hover:opacity-100"
                      style={{ color: '#ef4444', backgroundColor: '#1a2227' }}
                      title="Remove rule"
                    >
                      <Trash2 size={16} />
                    </button>
                  </div>
                ))
              )}
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default WindowRulesView;
