import React, { useEffect, useState } from 'react';
import { GetSystemInfo, OpenFileDialog, SetWallpaper, SetLockscreenWallpaper, GetThemeConfig, UpdateThemeMode, ApplyTheme, GetWaybarConfig, ApplyWaybarConfig, CreateWaybarBackup } from '../../wailsjs/go/main/App';
import { RefreshCw, FolderOpen, AlertCircle, Palette, Sparkles, Check, Save, Archive, Info } from 'lucide-react';
import { toast } from 'sonner';
import { Toaster } from './ui/sonner';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from './ui/select';

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

  useEffect(() => {
    loadAllData();
  }, []);

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

  const handleBackup = async () => {
    try {
      const backupName = await CreateWaybarBackup();
      toast.success(`Backup created: ${backupName}`);
    } catch (error) {
      toast.error('Failed to create backup', { description: String(error) });
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
          <button onClick={loadAllData} className="px-4 py-2 text-sm bg-gray-800 hover:bg-gray-700 text-gray-300 rounded">
            Retry
          </button>
        </div>
      </div>
    );
  }

  const memoryPercent = systemInfo.memoryTotal > 0 ? (systemInfo.memoryUsed / systemInfo.memoryTotal) * 100 : 0;

  return (
    <div className="min-h-screen bg-gray-950 overflow-y-auto">
      <Toaster position="top-center" toastOptions={{
                    style: {
                      background: '#F8F6F0',
                    },
                  }} />

                  <div>
        <div className="max-w-6xl mx-auto flex items-center p-2 justify-between">
          <div className="flex items-center gap-6">
            {/* User Avatar */}
            <div className="w-20 h-20 rounded-full bg-gradient-to-br from-blue-400 to-blue-600 flex items-center justify-center text-white text-2xl font-bold shadow-lg overflow-hidden">
              {systemInfo.userPfpBase64 ? (
                <img
                  src={systemInfo.userPfpBase64}
                  alt="User"
                  className="w-full h-full object-cover"
                />
              ) : (
                systemInfo.hostname.charAt(0).toUpperCase()
              )}
            </div>

            <div>
              <h1 className="text-4xl font-bold text-white mb-2">{systemInfo.hostname}</h1>
              <div className="flex items-center gap-3 text-sm text-gray-300">
                <span> {systemInfo.os} ✦ Hyprland ✦ {systemInfo.uptime}</span>
                {/* <span></span> */}
              </div>
            </div>
          </div>

          {/* RAM Dial */}
          <div className="relative w-20 h-20">
  <svg className="w-full h-full transform -rotate-90">
    {/* Background circle */}
    <circle
      cx="40"
      cy="40"
      r="36"
      stroke="rgba(75, 85, 99, 0.3)"
      strokeWidth="6"
      fill="none"
    />
    {/* Progress circle */}
    <circle
      cx="40"
      cy="40"
      r="36"
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
        </div>
      </div>

      <div className="max-w-6xl mx-auto px-8 py-8 space-y-8">
        {/* Wallpapers Section */}
        <section>
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-xl font-semibold text-white">Wallpapers</h2>
            <button onClick={loadAllData} className="p-2 bg-gray-800 hover:bg-gray-700 text-white rounded-lg transition-colors">
              <RefreshCw size={16} />
            </button>
          </div>
          <div className="grid grid-cols-2 gap-6">
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <p className="text-sm text-gray-400 font-medium">Homescreen</p>
                <button
                  onClick={handleSelectWallpaper}
                  disabled={settingWallpaper}
                  className="px-3 py-1.5 bg-blue-600 hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed text-white rounded-md text-xs font-medium transition-colors flex items-center gap-2"
                >
                  <FolderOpen size={14} />
                  {settingWallpaper ? 'Setting...' : 'Change'}
                </button>
              </div>
              <div className="relative aspect-video bg-gray-800/50 rounded-lg overflow-hidden border border-gray-800 shadow-lg">
                {systemInfo.wallpaperBase64 ? (
                  <img src={systemInfo.wallpaperBase64} alt="Homescreen" className="w-full h-full object-cover" />
                ) : (
                  <div className="w-full h-full flex items-center justify-center text-gray-600 text-sm">No wallpaper</div>
                )}
                {settingWallpaper && (
                  <div className="absolute inset-0 flex items-center justify-center bg-black/60 backdrop-blur-sm">
                    <div className="w-8 h-8 border-2 border-gray-300 border-t-white rounded-full animate-spin"></div>
                  </div>
                )}
              </div>
            </div>
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <p className="text-sm text-gray-400 font-medium">Lockscreen</p>
                <button
                  onClick={handleSelectLockscreen}
                  disabled={settingLockscreen}
                  className="px-3 py-1.5 bg-blue-600 hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed text-white rounded-md text-xs font-medium transition-colors flex items-center gap-2"
                >
                  <FolderOpen size={14} />
                  {settingLockscreen ? 'Setting...' : 'Change'}
                </button>
              </div>
              <div className="relative aspect-video bg-gray-800/50 rounded-lg overflow-hidden border border-gray-800 shadow-lg">
                {systemInfo.lockscreenBase64 ? (
                  <img src={systemInfo.lockscreenBase64} alt="Lockscreen" className="w-full h-full object-cover" />
                ) : (
                  <div className="w-full h-full flex items-center justify-center text-gray-600 text-sm">No wallpaper</div>
                )}
                {settingLockscreen && (
                  <div className="absolute inset-0 flex items-center justify-center bg-black/60 backdrop-blur-sm">
                    <div className="w-8 h-8 border-2 border-gray-300 border-t-white rounded-full animate-spin"></div>
                  </div>
                )}
              </div>
            </div>
          </div>
        </section>

        {/* Theme Manager Section */}
        {themeConfig && (
          <section className="border-t border-gray-800 pt-8">
            <div className="mb-4">
              <h2 className="text-xl font-semibold text-white">Theme Manager</h2>
              <p className="text-sm text-gray-500 mt-1">Configure color themes for your system</p>
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
                  <p className="text-xs text-gray-400">Colors from wallpaper via Pywal</p>
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
                  <p className="text-xs text-gray-400">Choose from preset themes</p>
                </button>
              </div>
              {selectedMode === 'static' && (
                <>
                  <Select value={selectedTheme} onValueChange={setSelectedTheme}>
                    <SelectTrigger className="bg-gray-800/50 border-gray-700 text-white">
                      <SelectValue placeholder="Select a theme..." />
                    </SelectTrigger>
                    <SelectContent className="bg-gray-800 border-gray-700">
                      {themeConfig.availableThemes.map((theme) => (
                        <SelectItem key={theme.name} value={theme.name} className="text-gray-300">
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
                    <div className="bg-gray-800/50 rounded-lg p-4 border border-gray-700">
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
                <button
                  onClick={() => { setSelectedMode(originalMode); setSelectedTheme(originalTheme); }}
                  disabled={!themeHasChanges || applyingTheme}
                  className={`px-4 py-2 text-sm rounded-lg transition-colors ${
                    themeHasChanges && !applyingTheme ? 'bg-gray-800 hover:bg-gray-700 text-gray-300' : 'bg-gray-900 text-gray-600 cursor-not-allowed'
                  }`}
                >
                  Reset
                </button>
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
                    <><Save className="w-4 h-4" />Apply Theme</>
                  )}
                </button>
              </div>
            </div>
          </section>
        )}

        {/* Waybar Configuration Section */}
        {waybarConfig && (
          <section className="border-t border-gray-800 pt-8">
            <div className="flex items-center justify-between mb-4">
              <div>
                <h2 className="text-xl font-semibold text-white">Waybar Configuration</h2>
                <p className="text-sm text-gray-500 mt-1">Manage layout and styling</p>
              </div>
              <button onClick={handleBackup} className="flex items-center gap-2 px-3 py-2 text-sm bg-gray-800 hover:bg-gray-700 text-gray-300 rounded-lg transition-colors">
                <Archive className="w-4 h-4" />
                Backup
              </button>
            </div>
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-400 mb-2">Layout Configuration</label>
                  <Select value={selectedConfig} onValueChange={setSelectedConfig}>
                    <SelectTrigger className="bg-gray-800/50 border-gray-700 text-white">
                      <SelectValue placeholder="Select config..." />
                    </SelectTrigger>
                    <SelectContent className="bg-gray-800 border-gray-700">
                      {waybarConfig.availableConfigs.map((cfg) => (
                        <SelectItem key={cfg} value={cfg} className="text-gray-300 font-mono">{cfg}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-400 mb-2">Style</label>
                  <Select value={selectedStyle} onValueChange={setSelectedStyle}>
                    <SelectTrigger className="bg-gray-800/50 border-gray-700 text-white">
                      <SelectValue placeholder="Select style..." />
                    </SelectTrigger>
                    <SelectContent className="bg-gray-800 border-gray-700">
                      {waybarConfig.availableStyles.map((style) => (
                        <SelectItem key={style} value={style} className="text-gray-300 font-mono">{style}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              </div>
              <div className="flex justify-end gap-3 pt-2">
                <button
                  onClick={() => { setSelectedConfig(originalWaybar.config); setSelectedStyle(originalWaybar.style); }}
                  disabled={!waybarHasChanges || applyingWaybar}
                  className={`px-4 py-2 text-sm rounded-lg transition-colors ${
                    waybarHasChanges && !applyingWaybar ? 'bg-gray-800 hover:bg-gray-700 text-gray-300' : 'bg-gray-900 text-gray-600 cursor-not-allowed'
                  }`}
                >
                  Reset
                </button>
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
                    <><Save className="w-4 h-4" />Apply</>
                  )}
                </button>
              </div>
            </div>
          </section>
        )}
      </div>
    </div>
  );
};

export default SettingsView;
