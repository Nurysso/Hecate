import React, { useEffect, useState } from 'react';
import { GetSystemInfo, OpenFileDialog, SetWallpaper, SetLockscreenWallpaper, GetThemeConfig, UpdateThemeMode, ApplyTheme, GetWaybarConfig, ApplyWaybarConfig, CreateWaybarBackup } from '../../wailsjs/go/main/App';
import { RefreshCw, FolderOpen, AlertCircle, Palette, Terminal, Globe, RotateCcw, Copy, Sparkles, Check, Save, Archive, Info } from 'lucide-react';
import { toast } from 'sonner';
import { Toaster } from './ui/sonner';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from './ui/select';
import { GetPreferences, UpdatePreferences, ValidatePreferences } from '../../wailsjs/go/main/App';

import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from './ui/dialog';

interface PreferencesConfig {
  term: string;
  browser: string;
  shell: string;
  profile: string;
}

interface SystemInfoData {
  os: string;
  hostname: string;
  cpu: string;
  memory: string;
  memoryUsed: number;
  memoryTotal: number;
  uptime: string;
  wallpaperBase64: string;
  lockscreenBase64: string;
  userPfpBase64: string;
}

interface ThemeConfig {
  mode: string;
  currentTheme: string;
  colors: Record<string, string>;
  availableThemes: ThemePreset[];
}

interface ThemePreset {
  name: string;
  description: string;
  colors: Record<string, string>;
}

interface WaybarConfig {
  currentConfig: string;
  currentStyle: string;
  availableConfigs: string[];
  availableStyles: string[];
}

type BrowserOption = 'firefox' | 'chromium' | 'brave' | 'google-chrome';

const SettingsView: React.FC = () => {
  const [systemInfo, setSystemInfo] = useState<SystemInfoData | null>(null);
  const [themeConfig, setThemeConfig] = useState<ThemeConfig | null>(null);
  const [waybarConfig, setWaybarConfig] = useState<WaybarConfig | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [settingWallpaper, setSettingWallpaper] = useState(false);
  const [settingLockscreen, setSettingLockscreen] = useState(false);

  // Theme states
  const [selectedMode, setSelectedMode] = useState<string>('dynamic');
  const [selectedTheme, setSelectedTheme] = useState<string>('');
  const [originalMode, setOriginalMode] = useState<string>('dynamic');
  const [originalTheme, setOriginalTheme] = useState<string>('');
  const [applyingTheme, setApplyingTheme] = useState(false);

  // Waybar states
  const [selectedConfig, setSelectedConfig] = useState<string>('');
  const [selectedStyle, setSelectedStyle] = useState<string>('');
  const [originalWaybar, setOriginalWaybar] = useState({ config: '', style: '' });
  const [applyingWaybar, setApplyingWaybar] = useState(false);

  // Preference states
  const [config, setConfig] = useState<PreferencesConfig>({
    term: 'kitty',
    browser: 'firefox',
    shell: 'fish',
    profile: 'minimal'
  });

  const [originalConfig, setOriginalConfig] = useState<PreferencesConfig>(config);
  const [saving, setSaving] = useState(false);
  const [showShellDialog, setShowShellDialog] = useState(false);
  const [pendingShell, setPendingShell] = useState('');
  const [copiedCommand, setCopiedCommand] = useState(false);
  const [message, setMessage] = useState<{ type: 'success' | 'error' | null; text: string }>({
    type: null,
    text: ''
  });

  const terminals = [
    { value: 'kitty', label: 'Kitty' },
    { value: 'alacritty', label: 'Alacritty' },
    { value: 'ghostty', label: 'Ghostty' },
    { value: 'foot', label: 'Foot' }
  ];

  const browsers = [
    { value: 'firefox', label: 'Firefox' },
    { value: 'chromium', label: 'Chromium' },
    { value: 'brave-bin', label: 'Brave' },
    { value: 'google-chrome-stable', label: 'Google Chrome' }
  ];

  const shells = [
    { value: 'fish', label: 'Fish' },
    { value: 'zsh', label: 'Zsh' },
    { value: 'bash', label: 'Bash' }
  ];

  useEffect(() => {
    loadPreferences();
    loadAllData();
  }, []);

  const loadPreferences = async () => {
    try {
      const prefs = await GetPreferences();
      setConfig(prefs);
      setOriginalConfig(prefs);
    } catch (error) {
      toast.error(`Failed to load preferences: ${error}`);
    }
  };

  const handleShellChange = (shell: string) => {
    setPendingShell(shell);
    setShowShellDialog(true);
  };

  const confirmShellChange = () => {
    setConfig({ ...config, shell: pendingShell });
    setShowShellDialog(false);
    setPendingShell('');
  };

  const copyCommand = async () => {
    const command = `chsh -s $(which ${pendingShell})`;
    try {
      await navigator.clipboard.writeText(command);
      setCopiedCommand(true);
      setTimeout(() => setCopiedCommand(false), 2000);
    } catch (err) {
      console.error('Failed to copy command:', err);
    }
  };

  const handleSave = async () => {
    try {
      setSaving(true);
      await ValidatePreferences(config);
      await UpdatePreferences(config);
      setOriginalConfig(config);
      toast.success('Preferences saved successfully');
    } catch (error) {
      toast.error(`Failed to save preferences: ${error}`);
    } finally {
      setSaving(false);
    }
  };

//   const handleReset = () => {
//     setConfig(originalConfig);
//     setMessage({ type: null, text: '' });
//   };

  const hasChanges = JSON.stringify(config) !== JSON.stringify(originalConfig);

  const loadAllData = async () => {
    try {
      setLoading(true);
      const [info, theme, waybar] = await Promise.all([
        GetSystemInfo(),
        GetThemeConfig(),
        GetWaybarConfig()
      ]);

      setSystemInfo(info);
      setThemeConfig(theme);
      setWaybarConfig(waybar);

      setSelectedMode(theme.mode);
      setSelectedTheme(theme.currentTheme || '');
      setOriginalMode(theme.mode);
      setOriginalTheme(theme.currentTheme || '');

      setSelectedConfig(waybar.currentConfig);
      setSelectedStyle(waybar.currentStyle);
      setOriginalWaybar({ config: waybar.currentConfig, style: waybar.currentStyle });

      setError(null);
    } catch (err) {
      setError('Failed to load settings');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const handleSelectWallpaper = async () => {
    try {
      setSettingWallpaper(true);
      const selectedPath = await OpenFileDialog();
      if (selectedPath) {
        await SetWallpaper(selectedPath);
        setTimeout(async () => {
          const info = await GetSystemInfo();
          setSystemInfo(info);
        }, 1500);
        toast.success('Wallpaper updated');
      }
    } catch (err: any) {
      toast.error('Failed to set wallpaper', { description: err?.toString() });
    } finally {
      setSettingWallpaper(false);
    }
  };

  const handleSelectLockscreen = async () => {
    try {
      setSettingLockscreen(true);
      const selectedPath = await OpenFileDialog();
      if (selectedPath) {
        await SetLockscreenWallpaper(selectedPath);
        setTimeout(async () => {
          const info = await GetSystemInfo();
          setSystemInfo(info);
        }, 1500);
        toast.success('Lockscreen wallpaper updated');
      }
    } catch (err: any) {
      toast.error('Failed to set lockscreen', { description: err?.toString() });
    } finally {
      setSettingLockscreen(false);
    }
  };

  const handleModeChange = (mode: string) => {
    setSelectedMode(mode);
    if (mode === 'dynamic') setSelectedTheme('');
  };

  const handleApplyTheme = async () => {
    try {
      setApplyingTheme(true);
      if (selectedMode !== originalMode) await UpdateThemeMode(selectedMode);
      if (selectedMode === 'static' && selectedTheme) await ApplyTheme(selectedTheme);
      setOriginalMode(selectedMode);
      setOriginalTheme(selectedTheme);
      toast.success('Theme applied');
    } catch (error) {
      toast.error('Failed to apply theme', { description: String(error) });
    } finally {
      setApplyingTheme(false);
    }
  };

  const handleApplyWaybar = async () => {
    if (!selectedConfig || !selectedStyle) {
      toast.error('Select both config and style');
      return;
    }
    try {
      setApplyingWaybar(true);
      await ApplyWaybarConfig({ config: selectedConfig, style: selectedStyle });
      setOriginalWaybar({ config: selectedConfig, style: selectedStyle });
      toast.success('Waybar configuration applied');
    } catch (error) {
      toast.error('Failed to apply waybar', { description: String(error) });
    } finally {
      setApplyingWaybar(false);
    }
  };


  const themeHasChanges = selectedMode !== originalMode || (selectedMode === 'static' && selectedTheme !== originalTheme);
  const waybarHasChanges = selectedConfig !== originalWaybar.config || selectedStyle !== originalWaybar.style;

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen bg-gray-950">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-2 border-gray-700 border-t-gray-400 mx-auto mb-4"></div>
          <p className="text-gray-400 text-sm">Loading Settings...</p>
        </div>
      </div>
    );
  }

  if (error || !systemInfo) {
    return (
      <div className="min-h-full bg-gray-950 flex items-center justify-center">
        <div className="text-center space-y-4">
          <AlertCircle className="w-12 h-12 text-red-500 mx-auto" />
          <p className="text-sm text-gray-500">{error || 'Failed to load'}</p>
        </div>
      </div>
    );
  }

  const memoryPercent = systemInfo.memoryTotal > 0 ? (systemInfo.memoryUsed / systemInfo.memoryTotal) * 100 : 0;

  return (
    <div className="min-h-screen bg-gray-950 overflow-y-auto">
      <Toaster
              position="top-center"
              toastOptions={{
                style: {
                  background: '#1a2227',
                  color: '#e5e7eb',
                  border: '1px solid #2a3439',
                },
              }}
            />

      {/* Header */}
      <div className="max-w-7xl mx-auto flex items-center p-6 justify-between border-b border-gray-800/50">
        <div className="flex items-center gap-6">
          <div className="w-20 h-20 rounded-full bg-gradient-to-br from-blue-400 to-blue-600 flex items-center justify-center text-white text-2xl font-bold shadow-lg overflow-hidden">
            {systemInfo.userPfpBase64 ? (
              <img src={systemInfo.userPfpBase64} alt="User" className="w-full h-full object-cover" />
            ) : (
              systemInfo.hostname.charAt(0).toUpperCase()
            )}
          </div>
          <div>
            <h1 className="text-4xl font-bold text-white mb-2">{systemInfo.hostname}</h1>
            <div className="flex items-center gap-3 text-sm text-gray-400">
              <span>{systemInfo.os} ✦ Hyprland ✦ {systemInfo.uptime}</span>
            </div>
          </div>
        </div>

        <div className="flex items-center gap-4">
          <div className="relative w-20 h-20">
            <svg className="w-full h-full transform -rotate-90">
              <circle cx="40" cy="40" r="36" stroke="rgba(75, 85, 99, 0.3)" strokeWidth="6" fill="none" />
              <circle
                cx="40" cy="40" r="36"
                stroke="rgb(59, 130, 246)"
                strokeWidth="6"
                fill="none"
                strokeDasharray={`${2 * Math.PI * 36}`}
                strokeDashoffset={`${2 * Math.PI * 36 * (1 - memoryPercent / 100)}`}
                strokeLinecap="round"
                style={{ transition: 'stroke-dashoffset 0.5s ease' }}
              />
            </svg>
            <div className="absolute inset-0 flex items-center justify-center">
              <div className="text-center">
                <div className="text-sm font-bold text-white">RAM</div>
                <div className="text-[10px] text-gray-400">{Math.round(memoryPercent)}%</div>
              </div>
            </div>
          </div>
          <button onClick={loadAllData} className="p-3 bg-[#141b1e] hover:bg-gray-800 text-white rounded-lg transition-colors">
            <RefreshCw size={18} />
          </button>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-6 py-8">
        {/* Wallpapers Section */}
        <div className="mb-8">
          <h2 className="text-2xl font-semibold text-white mb-4">Wallpapers</h2>
          <div className="grid grid-cols-2 gap-6">
            <button
              onClick={handleSelectWallpaper}
              disabled={settingWallpaper}
              className="group relative aspect-video bg-gray-800/30 rounded-xl overflow-hidden border border-gray-800 hover:border-gray-700 transition-all disabled:cursor-not-allowed"
            >
              {systemInfo.wallpaperBase64 ? (
                <img src={systemInfo.wallpaperBase64} alt="Homescreen" className="w-full h-full object-cover" />
              ) : (
                <div className="w-full h-full flex items-center justify-center text-gray-600 text-sm">No wallpaper</div>
              )}
              <div className="absolute inset-0 bg-black/0 group-hover:bg-black/40 transition-colors flex items-center justify-center">
                <div className="opacity-0 group-hover:opacity-100 transition-opacity flex flex-col items-center gap-2 text-white">
                  <FolderOpen size={32} />
                  <span className="text-sm font-medium">Change Homescreen</span>
                </div>
              </div>
              {settingWallpaper && (
                <div className="absolute inset-0 flex items-center justify-center bg-black/60 backdrop-blur-sm">
                  <div className="w-8 h-8 border-2 border-gray-300 border-t-white rounded-full animate-spin"></div>
                </div>
              )}
              <div className="absolute top-3 left-3 px-3 py-1.5 bg-gray-900/80 backdrop-blur-sm rounded-lg text-xs font-medium text-gray-300">
                Homescreen
              </div>
            </button>

            <button
              onClick={handleSelectLockscreen}
              disabled={settingLockscreen}
              className="group relative aspect-video bg-gray-800/30 rounded-xl overflow-hidden border border-gray-800 hover:border-gray-700 transition-all disabled:cursor-not-allowed"
            >
              {systemInfo.lockscreenBase64 ? (
                <img src={systemInfo.lockscreenBase64} alt="Lockscreen" className="w-full h-full object-cover" />
              ) : (
                <div className="w-full h-full flex items-center justify-center text-gray-600 text-sm">No wallpaper</div>
              )}
              <div className="absolute inset-0 bg-black/0 group-hover:bg-black/40 transition-colors flex items-center justify-center">
                <div className="opacity-0 group-hover:opacity-100 transition-opacity flex flex-col items-center gap-2 text-white">
                  <FolderOpen size={32} />
                  <span className="text-sm font-medium">Change Lockscreen</span>
                </div>
              </div>
              {settingLockscreen && (
                <div className="absolute inset-0 flex items-center justify-center bg-black/60 backdrop-blur-sm">
                  <div className="w-8 h-8 border-2 border-gray-300 border-t-white rounded-full animate-spin"></div>
                </div>
              )}
              <div className="absolute top-3 left-3 px-3 py-1.5 bg-gray-900/80 backdrop-blur-sm rounded-lg text-xs font-medium text-gray-300">
                Lockscreen
              </div>
            </button>
          </div>
        </div>

        {/* Bento Grid Layout */}
        <div className="grid grid-cols-3 gap-6">
          {/* Left Column - Theme & Waybar */}
          <div className="col-span-2 space-y-6">
            {/* Theme Manager */}
            {themeConfig && (
              <div className="bg-[#0f1416] border border-gray-800 rounded-xl p-6">
                <div className="flex items-center justify-between mb-6">
                  <div>
                    <h3 className="text-xl font-semibold text-white">Theme Manager</h3>
                    <p className="text-sm text-gray-500 mt-1">Configure color themes</p>
                  </div>
                </div>

                <div className="space-y-4">
                  <div className="grid grid-cols-2 gap-4">
                    <button
                      onClick={() => handleModeChange('dynamic')}
                      className={`p-4 rounded-lg border-2 transition-all text-left ${
                        selectedMode === 'dynamic' ? 'border-blue-500 bg-blue-500/10' : 'border-gray-700 bg-gray-800/30 hover:border-gray-600'
                      }`}
                    >
                      <div className="flex items-center justify-between mb-2">
                        <div className="flex items-center gap-2">
                          <Sparkles className="w-5 h-5 text-blue-400" />
                          <span className="font-semibold text-white">Dynamic</span>
                        </div>
                        {selectedMode === 'dynamic' && <Check className="w-5 h-5 text-blue-400" />}
                      </div>
                      <p className="text-xs text-gray-400">Colors from wallpaper</p>
                    </button>
                    <button
                      onClick={() => handleModeChange('static')}
                      className={`p-4 rounded-lg border-2 transition-all text-left ${
                        selectedMode === 'static' ? 'border-purple-500 bg-purple-500/10' : 'border-gray-700 bg-gray-800/30 hover:border-gray-600'
                      }`}
                    >
                      <div className="flex items-center justify-between mb-2">
                        <div className="flex items-center gap-2">
                          <Palette className="w-5 h-5 text-purple-400" />
                          <span className="font-semibold text-white">Static</span>
                        </div>
                        {selectedMode === 'static' && <Check className="w-5 h-5 text-purple-400" />}
                      </div>
                      <p className="text-xs text-gray-400">Preset themes</p>
                    </button>
                  </div>

                  {selectedMode === 'static' && (
                    <>
                      <Select value={selectedTheme} onValueChange={setSelectedTheme}>
                    <SelectTrigger className="bg-[#141b1e] border-gray-700 text-white">
                          <SelectValue placeholder="Select a theme..." />
                        </SelectTrigger>
<SelectContent className="bg-[#141b1e] border-gray-800">                          {themeConfig.availableThemes.map((theme) => (
                            <SelectItem key={theme.name} value={theme.name} className="text-gray-300 focus:bg-gray-800 focus:text-gray-100">
                              <div className="flex items-center gap-3">
                                <div className="flex gap-1">
                                  {['color1', 'color2', 'color3', 'color4'].map((c) => (
                                    <div key={c} className="w-3 h-3 rounded-full" style={{ backgroundColor: theme.colors[c] }} />
                                  ))}
                                </div>
                                <span>{theme.name}</span>
                              </div>
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                      {selectedTheme && (
                        <div className="bg-[#141b1e] rounded-lg p-4 border border-gray-700">
                          <p className="text-sm font-medium text-gray-300 mb-3">Color Preview</p>
                          <div className="grid grid-cols-8 gap-2">
                            {themeConfig.availableThemes.find((t) => t.name === selectedTheme)?.colors &&
                              Object.entries(themeConfig.availableThemes.find((t) => t.name === selectedTheme)!.colors)
                                .filter(([key]) => key.startsWith('color') && key.length <= 7)
                                .slice(0, 16)
                                .map(([key, value]) => (
                                  <div key={key} className="w-full aspect-square rounded border border-gray-600" style={{ backgroundColor: value }} title={`${key}: ${value}`} />
                                ))}
                          </div>
                        </div>
                      )}
                    </>
                  )}

                  <div className="flex justify-end gap-3 pt-2">
                    {/* <button
                      onClick={() => { setSelectedMode(originalMode); setSelectedTheme(originalTheme); }}
                      disabled={!themeHasChanges || applyingTheme}
                      className={`px-4 py-2 text-sm rounded-lg transition-colors ${
                        themeHasChanges && !applyingTheme ? 'bg-gray-800 hover:bg-gray-700 text-gray-300' : 'bg-gray-900 text-gray-600 cursor-not-allowed'
                      }`}
                    >
                      Reset
                    </button> */}
                    <button
                      onClick={handleApplyTheme}
                      disabled={!themeHasChanges || applyingTheme || (selectedMode === 'static' && !selectedTheme)}
                      className={`flex items-center gap-2 px-5 py-2 text-sm rounded-lg transition-colors ${
                        themeHasChanges && !applyingTheme && (selectedMode === 'dynamic' || selectedTheme)
                          ? 'bg-blue-600 hover:bg-blue-700 text-white' : 'bg-gray-900 text-gray-600 cursor-not-allowed'
                      }`}
                    >
                      {applyingTheme ? (
                        <><div className="animate-spin rounded-full h-4 w-4 border-2 border-gray-700 border-t-white"></div>Applying...</>
                      ) : (
                        <><Save className="w-4 h-4" /></>
                      )}
                    </button>
                  </div>
                </div>
              </div>
            )}

            {/* Waybar Configuration */}
            {waybarConfig && (
              <div className="bg-[#0f1416] border border-gray-800 rounded-xl p-6">
                <div className="flex items-center justify-between mb-6">
                  <div>
                    <h3 className="text-xl font-semibold text-white">Waybar Configuration</h3>
                    <p className="text-sm text-gray-500 mt-1">Manage layout and styling</p>
                  </div>
                  {/* <button onClick={handleBackup} className="flex items-center gap-2 px-3 py-2 text-sm bg-gray-800 hover:bg-gray-700 text-gray-300 rounded-lg transition-colors">
                    <Archive className="w-4 h-4" />
                    Backup
                  </button> */}
                </div>

                <div className="space-y-4">
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-400 mb-2">Layout</label>
                      <Select value={selectedConfig} onValueChange={setSelectedConfig}>
                    <SelectTrigger className="bg-[#141b1e] border-gray-700 text-white">
                          <SelectValue placeholder="Select config..." />
                        </SelectTrigger>
                        <SelectContent className="bg-[#141b1e] border-gray-800">
                          {waybarConfig.availableConfigs.map((cfg) => (
                            <SelectItem key={cfg} value={cfg} className="text-gray-300 focus:bg-gray-800 focus:text-gray-100">{cfg}</SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-400 mb-2">Style</label>
                      <Select value={selectedStyle} onValueChange={setSelectedStyle}>
                    <SelectTrigger className="bg-[#141b1e] border-gray-700 text-white">
                          <SelectValue placeholder="Select style..." />
                        </SelectTrigger>
                        <SelectContent className="bg-[#141b1e] border-gray-800">
                          {waybarConfig.availableStyles.map((style) => (
                            <SelectItem key={style} value={style} className="text-gray-300 focus:bg-gray-800 focus:text-gray-100">{style}</SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                    </div>
                  </div>

                  <div className="flex justify-end gap-3 pt-2">
                    {/* <button
                      onClick={() => { setSelectedConfig(originalWaybar.config); setSelectedStyle(originalWaybar.style); }}
                      disabled={!waybarHasChanges || applyingWaybar}
                      className={`px-4 py-2 text-sm rounded-lg transition-colors ${
                        waybarHasChanges && !applyingWaybar ? 'bg-gray-800 hover:bg-gray-700 text-gray-300' : 'bg-gray-900 text-gray-600 cursor-not-allowed'
                      }`}
                    >
                      Reset
                    </button> */}
                    <button
                      onClick={handleApplyWaybar}
                      disabled={!waybarHasChanges || applyingWaybar || !selectedConfig || !selectedStyle}
                      className={`flex items-center gap-2 px-5 py-2 text-sm rounded-lg transition-colors ${
                        waybarHasChanges && !applyingWaybar && selectedConfig && selectedStyle
                          ? 'bg-blue-600 hover:bg-blue-700 text-white' : 'bg-gray-900 text-gray-600 cursor-not-allowed'
                      }`}
                    >
                      {applyingWaybar ? (
                        <><div className="animate-spin rounded-full h-4 w-4 border-2 border-gray-700 border-t-white"></div>Applying...</>
                      ) : (
                        <><Save className="w-4 h-4" /></>
                      )}
                    </button>
                  </div>
                </div>
              </div>
            )}
          </div>

          {/* Right Column - Preferences */}
          <div className="col-span-1">
            <div className="bg-[#0f1416] border border-gray-800 rounded-xl p-6 sticky top-6">
              <div className="mb-6">
                <h3 className="text-xl font-semibold text-white">Preferences</h3>
                <p className="text-sm text-gray-500 mt-1">System defaults</p>
              </div>

              <div className="space-y-4">
                {/* Terminal */}
                <div>
                  <label className="flex items-center gap-2 text-sm font-medium text-gray-400 mb-2">
                    <Terminal className="w-4 h-4" />
                    Terminal
                  </label>
                  <Select value={config.term} onValueChange={(value: string) => setConfig({ ...config, term: value })}>
                    <SelectTrigger className="bg-[#141b1e] border-gray-700 text-white">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent className="bg-[#141b1e] border-gray-800">
                      {terminals.map((term) => (
                        <SelectItem key={term.value} value={term.value} className="text-gray-300 focus:bg-gray-800 focus:text-gray-100">
                          {term.label}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                {/* Browser */}
                <div>
                  <label className="flex items-center gap-2 text-sm font-medium text-gray-400 mb-2">
                    <Globe className="w-4 h-4" />
                    Browser
                  </label>
                  <Select value={config.browser} onValueChange={(value: BrowserOption) => setConfig({ ...config, browser: value })}>
                    <SelectTrigger className="bg-[#141b1e] border-gray-700 text-white">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent className="bg-[#141b1e] border-gray-800">
                      {browsers.map((browser) => (
                        <SelectItem key={browser.value} value={browser.value} className="text-gray-300 focus:bg-gray-800 focus:text-gray-100">
                          {browser.label}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                {/* Shell */}
                <div>
                  <label className="flex items-center gap-2 text-sm font-medium text-gray-400 mb-2">
                    <Terminal className="w-4 h-4" />
                    Shell
                    <div className="ml-auto flex items-center gap-1 text-xs text-yellow-500">
                      <Info className="w-3 h-3" />
                      Manual
                    </div>
                  </label>
                  <Select value={config.shell} onValueChange={handleShellChange}>
                    <SelectTrigger className="bg-[#141b1e] border-gray-700 text-white">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent className="bg-[#141b1e] border-gray-800">
                      {shells.map((shell) => (
                        <SelectItem key={shell.value} value={shell.value} className="text-gray-300 focus:bg-gray-800 focus:text-gray-100">
                          {shell.label}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              </div>

              {/* Action Buttons */}
              <div className="flex flex-col items-end gap-3 pt-6 mt-6 border-t border-gray-800">

                <button
  onClick={handleSave}
  disabled={!hasChanges || saving}
  className={`flex flex-row-reverse items-center gap-2 px-5 py-2 text-sm rounded-lg transition-colors ${
    hasChanges && !saving
? 'bg-blue-600 hover:bg-blue-700 text-white' : 'bg-gray-900 text-gray-600 cursor-not-allowed'

  }`}
>
  {saving ? (
    <div className="animate-spin rounded-full h-4 w-4 border-2 border-white/80 border-t-transparent"></div>
  ) : (
    <Save className="w-4 h-4" />
  )}
</button>

              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Shell Change Dialog */}
      <Dialog open={showShellDialog} onOpenChange={setShowShellDialog}>
        <DialogContent className="m-3 p-5 rounded-lg bg-opacity-20 bg-[#0f1416]">
          <DialogHeader>
            <DialogTitle className="text-gray-100">Change Default Shell</DialogTitle>
            <DialogDescription className="text-gray-400">
              To change your default shell to <span className="font-mono text-gray-300">{pendingShell}</span>,
              you need to run a command in your terminal.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div>
              <p className="text-sm text-gray-400 mb-2">Run this command in your terminal:</p>
              <div className="bg-gray-950 border border-gray-800 rounded p-3 font-mono text-sm text-gray-300 flex items-center justify-between gap-2">
                <code>chsh -s $(which {pendingShell})</code>
                <button
                  onClick={copyCommand}
                  className="p-1.5 hover:bg-gray-800 rounded text-gray-500 hover:text-gray-300 transition-colors flex-shrink-0"
                  title="Copy command"
                >
                  {copiedCommand ? (
                    <Check className="w-4 h-4 text-green-400" />
                  ) : (
                    <Copy className="w-4 h-4" />
                  )}
                </button>
              </div>
            </div>
            <div className="text-xs text-gray-500 space-y-1 bg-gray-950 border border-gray-800 rounded p-3">
              <p>• You may need to enter your password</p>
              <p>• Log out and back in for changes to take effect</p>
              <p>• Make sure {pendingShell} is installed on your system</p>
            </div>
            <div className="flex gap-2 justify-end pt-2">
              <button
                onClick={() => setShowShellDialog(false)}
                className="px-4 py-2 text-sm bg-gray-800 hover:bg-gray-700 text-gray-300 rounded border border-gray-700 transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={confirmShellChange}
                className="px-4 py-2 text-sm bg-blue-600 hover:bg-blue-700 text-white rounded border border-blue-600 transition-colors"
              >
                Update Preference
              </button>
            </div>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
};

export default SettingsView;
