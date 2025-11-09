import React, { useState, useEffect } from 'react';
import { Save, RotateCcw, Check, AlertCircle, Eye, Archive, Info } from 'lucide-react';
import { Toaster } from './ui/sonner';
import { toast } from 'sonner';
import { GetWaybarConfig, ApplyWaybarConfig, GetWaybarPreview, CreateWaybarBackup } from '../../wailsjs/go/main/App';

import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from './ui/popover';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from './ui/select';

interface WaybarConfig {
  currentConfig: string;
  currentStyle: string;
  availableConfigs: string[];
  availableStyles: string[];
}

interface WaybarSelection {
  config: string;
  style: string;
}

const WaybarView: React.FC = () => {
  const [config, setConfig] = useState<WaybarConfig | null>(null);
  const [selectedConfig, setSelectedConfig] = useState<string>('');
  const [selectedStyle, setSelectedStyle] = useState<string>('');
  const [originalSelection, setOriginalSelection] = useState<WaybarSelection>({ config: '', style: '' });
  const [loading, setLoading] = useState(true);
  const [applying, setApplying] = useState(false);
  const [preview, setPreview] = useState<{ type: string; name: string; content: string } | null>(null);

  useEffect(() => {
    loadConfig();
  }, []);

  const loadConfig = async () => {
    try {
      setLoading(true);
      const waybarConfig = await GetWaybarConfig();
      setConfig(waybarConfig);
      setSelectedConfig(waybarConfig.currentConfig);
      setSelectedStyle(waybarConfig.currentStyle);
      setOriginalSelection({
        config: waybarConfig.currentConfig,
        style: waybarConfig.currentStyle
      });
    } catch (error) {
      toast.error(`Failed to load waybar config: ${error}`);
    } finally {
      setLoading(false);
    }
  };

  const handleApply = async () => {
    if (!selectedConfig || !selectedStyle) {
      toast.error('Please select both a config and a style');
      return;
    }

    try {
      setApplying(true);

      await ApplyWaybarConfig({
        config: selectedConfig,
        style: selectedStyle
      });

      setOriginalSelection({
        config: selectedConfig,
        style: selectedStyle
      });

      toast.success('Configuration applied successfully');
    } catch (error) {
      toast.error(`Failed to apply configuration: ${error}`);
    } finally {
      setApplying(false);
    }
  };

  const handleReset = () => {
    setSelectedConfig(originalSelection.config);
    setSelectedStyle(originalSelection.style);
  };

  const handlePreview = async (type: 'config' | 'style', name: string) => {
    try {
      const content = await GetWaybarPreview(type, name);
      setPreview({ type, name, content });
    } catch (error) {
      toast.error(`Failed to load preview: ${error}`);
    }
  };

  const handleBackup = async () => {
    try {
      const backupName = await CreateWaybarBackup();
      toast.success(`Backup created: ${backupName}`);
    } catch (error) {
      toast.error(`Failed to create backup: ${error}`);
    }
  };

  const hasChanges = selectedConfig !== originalSelection.config ||
                     selectedStyle !== originalSelection.style;

  if (loading) {
    return (
      <div className="flex items-center justify-center h-full bg-[#141b1e]">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-2 border-gray-700 border-t-gray-400 mx-auto mb-4"></div>
          <p className="text-gray-400 text-sm">Loading preferences...</p>
        </div>
      </div>
    );
  }

  if (!config) {
    return (
      <div className="flex items-center justify-center h-full bg-[#141b1e]">
        <div className="text-center">
          <AlertCircle className="w-12 h-12 text-red-500 mx-auto mb-4" />
          <p className="text-gray-300">Failed to load waybar configuration</p>
        </div>
      </div>
    );
  }

  return (
    <>
            <Toaster position="top-center" toastOptions={{
              style: {
                background: '#F8F6F0',
              },
            }} />
      <div className="h-full overflow-y-auto">
        <div className="p-6 max-w-4xl mx-auto">
          {/* Header */}
          <div className="mb-6 pb-4 border-b border-gray-800">
            <div className="flex items-center justify-between">
              <div>
                <h1 className="text-2xl font-semibold text-gray-100 mb-1">Waybar Configuration</h1>
                <p className="text-sm text-gray-500">
                  Manage layout and styling
                  <Popover>
                    <PopoverTrigger asChild>
                      <button className="ml-2 text-gray-600 hover:text-gray-400 inline-flex items-center">
                        <Info className="w-3.5 h-3.5" />
                      </button>
                    </PopoverTrigger>
                    <PopoverContent className="w-80 bg-gray-900 border-gray-800 text-gray-300 text-sm">
                      <div className="space-y-2">
                        <p>Select a config and style, then apply to update the symlinks at:</p>
                        <ul className="space-y-0.5 text-blue-400/80">
                          <li>~/.config/waybar/config</li>
                          <li>~/.config/waybar/style.css</li>
                        </ul>
                        <p className="text-xs">Waybar will reload automatically.</p>
                      </div>
                    </PopoverContent>
                  </Popover>
                </p>
              </div>
              <button
                onClick={handleBackup}
                className="flex items-center gap-2 px-4 py-2 text-sm bg-[#141b1e] hover:bg-gray-800 text-gray-300 rounded border border-gray-800 transition-colors"
              >
                <Archive className="w-4 h-4" />
                Backup
              </button>
            </div>
          </div>

          {/* Selection Form */}
          <div className="space-y-4 mb-6">
            <div className="grid grid-cols-2 gap-4">
              {/* Config Selection Box */}
              <div className="bg-[#141b1e] rounded-lg p-3 border border-gray-700">
                <label className="block font-semibold text-white mb-3">
                  Layout Configuration
                </label>
                <div className="flex gap-2">
                  <Select value={selectedConfig} onValueChange={setSelectedConfig}>
                    <SelectTrigger className="flex-1 bg-[#141b1e] rounded-lg p-2 font-semibold text-white border border-gray-700 focus:border-gray-800/50 focus:ring-0">
                      <SelectValue placeholder="Select a config..." />
                    </SelectTrigger>
                    <SelectContent className="bg-[#141b1e] border border-gray-800 rounded-lg">
                      {config.availableConfigs.length === 0 ? (
                        <div className="px-2 py-6 text-center font-semibold text-red-800">
                          No configs found in ~/.config/waybar/configs/
                        </div>
                      ) : (
                        config.availableConfigs.map((configName) => (
                          <SelectItem
                            key={configName}
                            value={configName}
                            className="text-gray-300 font-mono text-sm px-3 py-2 focus:border-gray-800/50 focus:text-gray-100"
                          >
                            {configName}
                          </SelectItem>
                        ))
                      )}
                    </SelectContent>
                  </Select>
                </div>
              </div>

              {/* Style Selection Box */}
              <div className="bg-[#141b1e] rounded-lg p-3 border border-gray-700">
                <label className="block font-semibold text-white mb-3">
                  Style
                </label>
                <div className="flex gap-2">
                  <Select value={selectedStyle} onValueChange={setSelectedStyle}>
                    <SelectTrigger className="flex-1 bg-[#141b1e] rounded-lg p-2 font-semibold text-white border border-gray-700 focus:border-gray-800/50 focus:ring-0">
                      <SelectValue placeholder="Select a style..." />
                    </SelectTrigger>
                    <SelectContent className="bg-[#141b1e] border border-gray-800 rounded-lg">
                      {config.availableStyles.length === 0 ? (
                        <div className="px-2 py-6 text-center text-sm text-gray-600">
                          No styles found in ~/.config/waybar/style/
                        </div>
                      ) : (
                        config.availableStyles.map((styleName) => (
                          <SelectItem
                            key={styleName}
                            value={styleName}
                            className="text-gray-300 font-mono text-sm px-3 py-2 focus:border-gray-800/50 focus:text-gray-100"
                          >
                            {styleName}
                          </SelectItem>
                        ))
                      )}
                    </SelectContent>
                  </Select>
                </div>
              </div>
            </div>
          </div>

          {/* Action Buttons */}
          <div className="flex items-center justify-end gap-3 pt-4 border-t border-gray-800">
            <button
              onClick={handleReset}
              disabled={!hasChanges || applying}
              className={`flex items-center gap-2 px-4 py-2 text-sm rounded border transition-colors ${
                hasChanges && !applying
                  ? 'bg-[#141b1e] hover:bg-gray-800 text-gray-300 border-gray-800'
                  : 'bg-[#141b1e] text-gray-700 border-gray-900 cursor-not-allowed'
              }`}
            >
              <RotateCcw className="w-4 h-4" />
              Reset
            </button>

            <button
              onClick={handleApply}
              disabled={!hasChanges || applying || !selectedConfig || !selectedStyle}
              className={`flex items-center gap-2 px-5 py-2 text-sm rounded border transition-colors ${
                hasChanges && !applying && selectedConfig && selectedStyle
                  ? 'bg-blue-600 hover:bg-blue-700 text-white border-blue-600'
                  : 'bg-[#141b1e] text-gray-700 border-gray-900 cursor-not-allowed'
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
                  Apply
                </>
              )}
            </button>
          </div>
        </div>
      </div>
    </>
  );
};

export default WaybarView;
