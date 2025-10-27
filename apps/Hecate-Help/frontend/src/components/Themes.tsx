import React, { useState, useEffect } from 'react';
import { Palette, Save, Check, AlertCircle, Sparkles, Info } from 'lucide-react';
import { toast } from 'sonner';
import { Toaster } from './ui/sonner';
import { GetThemeConfig, UpdateThemeMode, ApplyTheme } from '../../wailsjs/go/main/App';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from './ui/select';
import { Popover, PopoverContent, PopoverTrigger } from './ui/popover';

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

const ThemeView: React.FC = () => {
  const [config, setConfig] = useState<ThemeConfig | null>(null);
  const [selectedMode, setSelectedMode] = useState<string>('dynamic');
  const [selectedTheme, setSelectedTheme] = useState<string>('');
  const [originalMode, setOriginalMode] = useState<string>('dynamic');
  const [originalTheme, setOriginalTheme] = useState<string>('');
  const [loading, setLoading] = useState(true);
  const [applying, setApplying] = useState(false);

  useEffect(() => {
    loadConfig();
  }, []);

  const loadConfig = async () => {
    try {
      setLoading(true);
      const themeConfig = await GetThemeConfig();
      setConfig(themeConfig);
      setSelectedMode(themeConfig.mode);
      setSelectedTheme(themeConfig.currentTheme || '');
      setOriginalMode(themeConfig.mode);
      setOriginalTheme(themeConfig.currentTheme || '');
    } catch (error) {
      toast.error('Failed to load theme config', {
        description: String(error),
      });
    } finally {
      setLoading(false);
    }
  };

  const handleModeChange = async (mode: string) => {
    setSelectedMode(mode);
    if (mode === 'dynamic') {
      setSelectedTheme('');
    }
  };

  const handleApply = async () => {
    try {
      setApplying(true);

      if (selectedMode !== originalMode) {
        await UpdateThemeMode(selectedMode);
      }

      if (selectedMode === 'static' && selectedTheme) {
        await ApplyTheme(selectedTheme);
      }

      setOriginalMode(selectedMode);
      setOriginalTheme(selectedTheme);

      toast.success('Theme applied successfully');
    } catch (error) {
      toast.error('Failed to apply theme', {
        description: String(error),
      });
    } finally {
      setApplying(false);
    }
  };

  const handleReset = () => {
    setSelectedMode(originalMode);
    setSelectedTheme(originalTheme);
  };

  const hasChanges = selectedMode !== originalMode ||
                     (selectedMode === 'static' && selectedTheme !== originalTheme);

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

  if (!config) {
    return (
      <div className="flex items-center justify-center h-full bg-gray-950">
        <div className="text-center">
          <AlertCircle className="w-12 h-12 text-red-500 mx-auto mb-4" />
          <p className="text-gray-300">Failed to load theme configuration</p>
        </div>
      </div>
    );
  }

  return (
    <div className="h-full overflow-y-auto bg-gray-950">
      <Toaster position="top-center" toastOptions={{
        style: {
          background: '#F8F6F0',
        },
      }} />
      <div className="p-6 max-w-4xl mx-auto">
        {/* Header */}
        <div className="mb-6 pb-4 border-b border-gray-800">
          <h1 className="text-2xl font-semibold text-gray-100 mb-1">Theme Manager</h1>
          <p className="text-sm text-gray-500">Configure dynamic or static color themes
          <Popover>
    <PopoverTrigger asChild>
        <button className="ml-2 text-gray-600 hover:text-gray-400 inline-flex items-center">
            <Info className="w-3.5 h-3.5" />
        </button>
    </PopoverTrigger>
    <PopoverContent className="w-80 bg-gray-900 border-gray-800 text-gray-300 text-sm">
        <div className="space-y-2">
              <ul className="space-y-0.5 text-blue-400/80">
                <li>• Terminal and browser preferences are saved immediately</li>
                <li>• Shell changes require running a command in your terminal</li>
                <li>• You may need to restart applications or log back in for changes to take effect</li>
              </ul>
            </div>
    </PopoverContent>
</Popover>
</p>
        </div>

        {/* Current Status */}
        <div className="bg-gray-800/50 rounded-lg p-3 border border-gray-700 mb-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <p className="text-xs text-gray-600 mb-1">Active Mode</p>
              <p className="text-sm font-medium text-gray-300 capitalize">{originalMode}</p>
            </div>
            {originalMode === 'static' && (
              <div>
                <p className="text-xs text-gray-600 mb-1">Active Theme</p>
                <p className="text-sm font-medium text-gray-300">{originalTheme || 'None'}</p>
              </div>
            )}
          </div>
        </div>

        <div className="space-y-4 mb-6">
          {/* Mode Selection */}
          <div className="bg-gray-800/50 rounded-lg p-3 border border-gray-700">
            <label className="block text-sm font-medium text-gray-300 mb-3">
              Theme Mode
            </label>
            <div className="grid grid-cols-2 gap-3">
              <button
                onClick={() => handleModeChange('dynamic')}
                className={`p-4 rounded border-2 transition-all text-left ${
                  selectedMode === 'dynamic'
                    ? 'border-blue-500 bg-blue-500/10'
                    : 'border-gray-700 bg-gray-800/30 hover:border-gray-600'
                }`}
              >
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center gap-2">
                    <Sparkles className="w-5 h-5 text-blue-400" />
                    <span className="font-semibold text-white">Dynamic</span>
                  </div>
                  {selectedMode === 'dynamic' && (
                    <Check className="w-5 h-5 text-blue-400" />
                  )}
                </div>
                <p className="text-xs text-gray-400">
                  Colors generated from wallpaper using Pywal
                </p>
              </button>

              <button
                onClick={() => handleModeChange('static')}
                className={`p-4 rounded border-2 transition-all text-left ${
                  selectedMode === 'static'
                    ? 'border-purple-500 bg-purple-500/10'
                    : 'border-gray-700 bg-gray-800/30 hover:border-gray-600'
                }`}
              >
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center gap-2">
                    <Palette className="w-5 h-5 text-purple-400" />
                    <span className="font-semibold text-white">Static</span>
                  </div>
                  {selectedMode === 'static' && (
                    <Check className="w-5 h-5 text-purple-400" />
                  )}
                </div>
                <p className="text-xs text-gray-400">
                  Choose from preset color themes
                </p>
              </button>
            </div>
          </div>

          {/* Theme Selection (only in static mode) */}
          {selectedMode === 'static' && (
            <div className="bg-gray-800/50 rounded-lg p-3 border border-gray-700">
              <label className="block text-sm font-medium text-gray-300 mb-3">
                Select Theme
              </label>
              <Select value={selectedTheme} onValueChange={setSelectedTheme}>
               <SelectTrigger className="flex-1 bg-gray-800/50 rounded-lg p-2 font-semibold text-white border border-gray-700 focus:border-gray-800/50 focus:ring-0">
                  <SelectValue placeholder="Choose a theme..." />
                </SelectTrigger>
                <SelectContent className="bg-gray-900 border-gray-800">
                  {config.availableThemes.map((theme) => (
                    <SelectItem
                      key={theme.name}
                      value={theme.name}
                      className="text-gray-300 focus:bg-gray-800 focus:text-gray-100"
                    >
                      <div className="flex items-center gap-3">
                        <div className="flex gap-1">
                          {['color1', 'color2', 'color3', 'color4'].map((c) => (
                            <div
                              key={c}
                              className="w-3 h-3 rounded-full"
                              style={{ backgroundColor: theme.colors[c] }}
                            />
                          ))}
                        </div>
                        <div>
                          <div className="font-medium">{theme.name}</div>
                          <div className="text-xs text-gray-500">{theme.description}</div>
                        </div>
                      </div>
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          )}

          {/* Theme Preview */}
          {selectedMode === 'static' && selectedTheme && (
            <div className="bg-gray-800/50 rounded-lg p-3 border border-gray-700">
              <p className="text-sm font-medium text-gray-300 mb-3">Color Preview</p>
              <div className="grid grid-cols-8 gap-2">
                {config.availableThemes
                  .find((t) => t.name === selectedTheme)
                  ?.colors &&
                  Object.entries(
                    config.availableThemes.find((t) => t.name === selectedTheme)!.colors
                  )
                    .filter(([key]) => key.startsWith('color') && key.length <= 7)
                    .slice(0, 16)
                    .map(([key, value]) => (
                      <div key={key} className="group relative">
                        <div
                          className="w-full aspect-square rounded border border-gray-700 cursor-pointer transition-transform hover:scale-110"
                          style={{ backgroundColor: value }}
                          title={`${key}: ${value}`}
                        />
                        <div className="absolute -bottom-5 left-1/2 transform -translate-x-1/2 opacity-0 group-hover:opacity-100 transition-opacity">
                          <span className="text-[10px] text-gray-500 whitespace-nowrap">
                            {key.replace('color', '')}
                          </span>
                        </div>
                      </div>
                    ))}
              </div>
            </div>
          )}
        </div>

        {/* Info Box */}
        {selectedMode === 'dynamic' && (
          <div className="mb-6 p-3 bg-blue-950/30 border border-blue-900/50 rounded text-xs text-blue-300">
            <p className="font-medium mb-1">Dynamic Mode</p>
            <p className="text-blue-400/80">
              Colors are automatically generated from your wallpaper using Pywal.
              Run <code className="bg-gray-950 px-1 py-0.5 rounded">wal -i /path/to/wallpaper</code> to update colors.
            </p>
          </div>
        )}

        {/* Action Buttons */}
        <div className="flex items-center justify-end gap-3 pt-4 border-t border-gray-800">
          <button
            onClick={handleReset}
            disabled={!hasChanges || applying}
            className={`flex items-center gap-2 px-4 py-2 text-sm rounded border transition-colors ${
              hasChanges && !applying
                ? 'bg-gray-900 hover:bg-gray-800 text-gray-300 border-gray-800'
                : 'bg-gray-950 text-gray-700 border-gray-900 cursor-not-allowed'
            }`}
          >
            Reset
          </button>

          <button
            onClick={handleApply}
            disabled={!hasChanges || applying || (selectedMode === 'static' && !selectedTheme)}
            className={`flex items-center gap-2 px-5 py-2 text-sm rounded border transition-colors ${
              hasChanges && !applying && (selectedMode === 'dynamic' || selectedTheme)
                ? 'bg-blue-600 hover:bg-blue-700 text-white border-blue-600'
                : 'bg-gray-950 text-gray-700 border-gray-900 cursor-not-allowed'
            }`}
          >
            {applying ? (
              <>
                <div className="animate-spin rounded-full h-4 w-4 border-2 border-gray-700 border-t-white"></div>
                Applying...
              </>
            ) : (
              <>
                <Save className="w-4 h-4" />
                Apply Theme
              </>
            )}
          </button>
        </div>

      </div>
    </div>
  );
};

export default ThemeView;
