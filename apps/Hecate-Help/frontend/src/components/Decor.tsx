import React, { useState, useEffect } from 'react';
import { RefreshCw, Save, RotateCcw, Info } from 'lucide-react';
import { Popover, PopoverTrigger, PopoverContent } from './ui/popover';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from './ui/select';
import { toast } from 'sonner';
import { Toaster } from './ui/sonner';

interface GeneralConfig {
  border_size: number;
  gaps_in: string;
  gaps_out: string;
  float_gaps: string;
  gaps_workspaces: number;
  col_inactive_border: string;
  col_active_border: string;
  col_nogroup_border: string;
  col_nogroup_border_active: string;
  layout: string;
  no_focus_fallback: boolean;
  resize_on_border: boolean;
  extend_border_grab_area: number;
  hover_icon_on_border: boolean;
  allow_tearing: boolean;
  resize_corner: number;
  modal_parent_blocking: boolean;
  locale: string;
}

interface SnapConfig {
  enabled: boolean;
  window_gap: number;
  monitor_gap: number;
  border_overlap: boolean;
  respect_gaps: boolean;
}

interface BlurConfig {
  enabled: boolean;
  size: number;
  passes: number;
  ignore_opacity: boolean;
  new_optimizations: boolean;
  xray: boolean;
  noise: number;
  contrast: number;
  brightness: number;
  vibrancy: number;
  vibrancy_darkness: number;
  special: boolean;
  popups: boolean;
  popups_ignorealpha: number;
  input_methods: boolean;
  input_methods_ignorealpha: number;
}

interface DecorationConfig {
  rounding: number;
  rounding_power: number;
  active_opacity: number;
  inactive_opacity: number;
  fullscreen_opacity: number;
  dim_modal: boolean;
  dim_inactive: boolean;
  dim_strength: number;
  dim_special: number;
  dim_around: number;
  screen_shader: string;
  border_part_of_window: boolean;
}

interface DecorationsFullConfig {
  general: GeneralConfig;
  snap: SnapConfig;
  decoration: DecorationConfig;
  blur: BlurConfig;
}

const getWailsRuntime = () => {
  if (typeof window !== 'undefined' && (window as any).go?.main?.App) {
    return (window as any).go.main.App;
  }
  return null;
};

const DecorationsView: React.FC = () => {
  const [config, setConfig] = useState<DecorationsFullConfig | null>(null);
  const [originalConfig, setOriginalConfig] = useState<DecorationsFullConfig | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    loadConfig();
  }, []);

  const loadConfig = async (silent = false) => {
    if (!silent) {
      setLoading(true);
    }

    try {
      const wailsApp = getWailsRuntime();
      if (wailsApp && wailsApp.GetDecorationsConfig) {
        const data = await wailsApp.GetDecorationsConfig();
        setConfig(data);
        setOriginalConfig(JSON.parse(JSON.stringify(data)));
      } else {
        toast.error('Wails runtime not available. Please run with Wails.');
      }
    } catch (err) {
      toast.error('Failed to load decorations config.');
    } finally {
      if (!silent) {
        setLoading(false);
      }
    }
  };

  const saveConfig = async () => {
    if (!config) return;

    setSaving(true);

    try {
      const wailsApp = getWailsRuntime();
      if (wailsApp && wailsApp.SaveDecorationsConfig) {
        await wailsApp.SaveDecorationsConfig(config);
        setOriginalConfig(JSON.parse(JSON.stringify(config)));
        toast.success('Configuration saved successfully!');
      } else {
        toast.error('Wails backend not available');
      }
    } catch (err) {
      toast.error(`Failed to save config: ${err}`);
    } finally {
      setSaving(false);
    }
  };

  const resetToOriginal = () => {
    if (originalConfig) {
      setConfig(JSON.parse(JSON.stringify(originalConfig)));
      toast.info('Configuration reset to last saved state');
    }
  };

  const hasChanges = () => {
    return JSON.stringify(config) !== JSON.stringify(originalConfig);
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen bg-gray-950">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-2 border-gray-700 border-t-gray-400 mx-auto mb-4"></div>
          <p className="text-gray-400 text-sm">Loading decorations config...</p>
        </div>
      </div>
    );
  }

  if (!config) {
    return (
      <div className="flex-1 flex items-center justify-center" style={{ backgroundColor: '#0f1416' }}>
        <div className="text-center max-w-md">
          <div className="text-red-400 mb-4 px-4">Failed to load configuration</div>
          <button
            onClick={() => loadConfig()}
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
      <div className="sticky bg-[#0A0E10] top-0 z-40 border-b border-gray-800 rounded-lg mb-2">
          <div className="flex items-center justify-between p-2 rounded-lg">
            <div>
              <h1 className="text-2xl font-bold text-gray-100 mb-1">Decorations & Effects</h1>
              <p className="text-sm text-gray-400">Configure window decorations, blur, and visual effects</p>
            </div>
            <div className="flex items-center gap-2">
              {hasChanges() && (
                <button
                  onClick={resetToOriginal}
                  className="px-4 py-2 rounded text-sm text-gray-300 transition-colors hover:opacity-80 flex items-center gap-2"
                  style={{ backgroundColor: '#1a2227' }}
                >
                  <RotateCcw size={16} />
                  Reset
                </button>
              )}
              <button
                onClick={saveConfig}
                disabled={saving || !hasChanges()}
                className={`px-4 py-2 rounded text-sm text-white transition-colors flex items-center gap-2 ${
                  !hasChanges() ? 'opacity-50 cursor-not-allowed' : 'hover:opacity-80'
                }`}
                style={{ backgroundColor: '#1e3a5f' }}
              >
                <Save size={16} />
                {saving ? 'Saving...' : 'Save Changes'}
              </button>
            </div>
          </div>
        </div>

      <div className="max-w-6xl mx-auto">
        {/* General Section */}
        <div className="mb-6">
          <h2 className="text-lg font-semibold text-gray-200 mb-4">General</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            <SettingCard
              label="Border Size"
              description="Size of the border around windows"
              type="number"
              value={config.general.border_size}
              onChange={(value) => setConfig({
                ...config,
                general: { ...config.general, border_size: parseInt(value) || 0 }
              })}
            />
            <SettingCard
              label="Gaps In"
              description="Gaps between windows (supports CSS style)"
              type="number"
              value={config.general.gaps_in}
              onChange={(value) => setConfig({
                ...config,
                general: { ...config.general, gaps_in: value }
              })}
            />
            <SettingCard
              label="Gaps Out"
              description="Gaps between windows and monitor edges"
              type="number"
              value={config.general.gaps_out}
              onChange={(value) => setConfig({
                ...config,
                general: { ...config.general, gaps_out: value }
              })}
            />
            <SettingCard
              label="Float Gaps"
              description="Gaps for floating windows (-1 = default)"
              type="number"
              value={config.general.float_gaps}
              onChange={(value) => setConfig({
                ...config,
                general: { ...config.general, float_gaps: value }
              })}
            />
            <SettingCard
              label="Gaps Workspaces"
              description="Gaps between workspaces"
              type="number"
              value={config.general.gaps_workspaces}
              onChange={(value) => setConfig({
                ...config,
                general: { ...config.general, gaps_workspaces: parseInt(value) || 0 }
              })}
            />
            <SettingCard
              label="Inactive Border Color"
              description="Border color for inactive windows"
              type="color"
              value={config.general.col_inactive_border}
              onChange={(value) => setConfig({
                ...config,
                general: { ...config.general, col_inactive_border: value }
              })}
            />
            <SettingCard
              label="Active Border Color"
              description="Border color for active window"
              type="color"
              value={config.general.col_active_border}
              onChange={(value) => setConfig({
                ...config,
                general: { ...config.general, col_active_border: value }
              })}
            />
            <SettingCard
              label="Layout"
              description="Window layout algorithm"
              type="select"
              value={config.general.layout}
              options={['dwindle', 'master']}
              onChange={(value) => setConfig({
                ...config,
                general: { ...config.general, layout: value }
              })}
            />
            <SettingCard
              label="Resize on Border"
              description="Enable resizing by clicking borders"
              type="boolean"
              value={config.general.resize_on_border}
              onChange={(value) => setConfig({
                ...config,
                general: { ...config.general, resize_on_border: value === 'true' }
              })}
            />
            <SettingCard
              label="Extend Border Grab Area"
              description="Extend clickable border area"
              type="number"
              value={config.general.extend_border_grab_area}
              onChange={(value) => setConfig({
                ...config,
                general: { ...config.general, extend_border_grab_area: parseInt(value) || 0 }
              })}
            />
            <SettingCard
              label="Hover Icon on Border"
              description="Show cursor icon on borders"
              type="boolean"
              value={config.general.hover_icon_on_border}
              onChange={(value) => setConfig({
                ...config,
                general: { ...config.general, hover_icon_on_border: value === 'true' }
              })}
            />
            <SettingCard
              label="Allow Tearing"
              description="Master switch for tearing"
              type="boolean"
              value={config.general.allow_tearing}
              onChange={(value) => setConfig({
                ...config,
                general: { ...config.general, allow_tearing: value === 'true' }
              })}
            />
          </div>
        </div>

        {/* Snap Section */}
        <div className="mb-6">
          <h2 className="text-lg font-semibold text-gray-200 mb-4">Snap (Floating Windows)</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            <SettingCard
              label="Enabled"
              description="Enable snapping for floating windows"
              type="boolean"
              value={config.snap.enabled}
              onChange={(value) => setConfig({
                ...config,
                snap: { ...config.snap, enabled: value === 'true' }
              })}
            />
            <SettingCard
              label="Window Gap"
              description="Min gap before snapping (pixels)"
              type="number"
              value={config.snap.window_gap}
              onChange={(value) => setConfig({
                ...config,
                snap: { ...config.snap, window_gap: parseInt(value) || 0 }
              })}
            />
            <SettingCard
              label="Monitor Gap"
              description="Min gap from edges (pixels)"
              type="number"
              value={config.snap.monitor_gap}
              onChange={(value) => setConfig({
                ...config,
                snap: { ...config.snap, monitor_gap: parseInt(value) || 0 }
              })}
            />
            <SettingCard
              label="Border Overlap"
              description="Snap with border overlap"
              type="boolean"
              value={config.snap.border_overlap}
              onChange={(value) => setConfig({
                ...config,
                snap: { ...config.snap, border_overlap: value === 'true' }
              })}
            />
            <SettingCard
              label="Respect Gaps"
              description="Respect gaps_in when snapping"
              type="boolean"
              value={config.snap.respect_gaps}
              onChange={(value) => setConfig({
                ...config,
                snap: { ...config.snap, respect_gaps: value === 'true' }
              })}
            />
          </div>
        </div>

        {/* Decoration Section */}
        <div className="mb-6">
          <h2 className="text-lg font-semibold text-gray-200 mb-4">Decoration</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            <SettingCard
              label="Rounding"
              description="Rounded corners radius (px)"
              type="number"
              value={config.decoration.rounding}
              onChange={(value) => setConfig({
                ...config,
                decoration: { ...config.decoration, rounding: parseInt(value) || 0 }
              })}
            />
            <SettingCard
              label="Rounding Power"
              description="Corner curve (1.0-10.0, 2.0=circle)"
              type="number"
              step="0.1"
              value={config.decoration.rounding_power}
              onChange={(value) => setConfig({
                ...config,
                decoration: { ...config.decoration, rounding_power: parseFloat(value) || 2.0 }
              })}
            />
            <SettingCard
              label="Active Opacity"
              description="Opacity of active windows (0.0-1.0)"
              type="number"
              step="0.1"
              value={config.decoration.active_opacity}
              onChange={(value) => setConfig({
                ...config,
                decoration: { ...config.decoration, active_opacity: parseFloat(value) || 1.0 }
              })}
            />
            <SettingCard
              label="Inactive Opacity"
              description="Opacity of inactive windows (0.0-1.0)"
              type="number"
              step="0.1"
              value={config.decoration.inactive_opacity}
              onChange={(value) => setConfig({
                ...config,
                decoration: { ...config.decoration, inactive_opacity: parseFloat(value) || 1.0 }
              })}
            />
            <SettingCard
              label="Fullscreen Opacity"
              description="Opacity of fullscreen windows (0.0-1.0)"
              type="number"
              step="0.1"
              value={config.decoration.fullscreen_opacity}
              onChange={(value) => setConfig({
                ...config,
                decoration: { ...config.decoration, fullscreen_opacity: parseFloat(value) || 1.0 }
              })}
            />
            <SettingCard
              label="Dim Inactive"
              description="Dim inactive windows"
              type="boolean"
              value={config.decoration.dim_inactive}
              onChange={(value) => setConfig({
                ...config,
                decoration: { ...config.decoration, dim_inactive: value === 'true' }
              })}
            />
            <SettingCard
              label="Dim Strength"
              description="How much to dim (0.0-1.0)"
              type="number"
              step="0.1"
              value={config.decoration.dim_strength}
              onChange={(value) => setConfig({
                ...config,
                decoration: { ...config.decoration, dim_strength: parseFloat(value) || 0.5 }
              })}
            />
            <SettingCard
              label="Dim Special"
              description="Dim when special workspace open (0.0-1.0)"
              type="number"
              step="0.1"
              value={config.decoration.dim_special}
              onChange={(value) => setConfig({
                ...config,
                decoration: { ...config.decoration, dim_special: parseFloat(value) || 0.2 }
              })}
            />
          </div>
        </div>

        {/* Blur Section */}
        <div className="mb-6">
          <h2 className="text-lg font-semibold text-gray-200 mb-4">Blur</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            <SettingCard
              label="Enabled"
              description="Enable kawase window blur"
              type="boolean"
              value={config.blur.enabled}
              onChange={(value) => setConfig({
                ...config,
                blur: { ...config.blur, enabled: value === 'true' }
              })}
            />
            <SettingCard
              label="Size"
              description="Blur size/distance (min: 1)"
              type="number"
              value={config.blur.size}
              onChange={(value) => setConfig({
                ...config,
                blur: { ...config.blur, size: Math.max(1, parseInt(value) || 1) }
              })}
            />
            <SettingCard
              label="Passes"
              description="Amount of passes (min: 1)"
              type="number"
              value={config.blur.passes}
              onChange={(value) => setConfig({
                ...config,
                blur: { ...config.blur, passes: Math.max(1, parseInt(value) || 1) }
              })}
            />
            <SettingCard
              label="Ignore Opacity"
              description="Ignore window opacity"
              type="boolean"
              value={config.blur.ignore_opacity}
              onChange={(value) => setConfig({
                ...config,
                blur: { ...config.blur, ignore_opacity: value === 'true' }
              })}
            />
            <SettingCard
              label="New Optimizations"
              description="Enable optimizations (recommended)"
              type="boolean"
              value={config.blur.new_optimizations}
              onChange={(value) => setConfig({
                ...config,
                blur: { ...config.blur, new_optimizations: value === 'true' }
              })}
            />
            <SettingCard
              label="X-Ray"
              description="Floating windows ignore tiled blur"
              type="boolean"
              value={config.blur.xray}
              onChange={(value) => setConfig({
                ...config,
                blur: { ...config.blur, xray: value === 'true' }
              })}
            />
            <SettingCard
              label="Noise"
              description="Noise amount (0.0-1.0)"
              type="number"
              step="0.0001"
              value={config.blur.noise}
              onChange={(value) => setConfig({
                ...config,
                blur: { ...config.blur, noise: parseFloat(value) || 0 }
              })}
            />
            <SettingCard
              label="Contrast"
              description="Contrast modulation (0.0-2.0)"
              type="number"
              step="0.01"
              value={config.blur.contrast}
              onChange={(value) => setConfig({
                ...config,
                blur: { ...config.blur, contrast: parseFloat(value) || 0 }
              })}
            />
            <SettingCard
              label="Brightness"
              description="Brightness modulation (0.0-2.0)"
              type="number"
              step="0.01"
              value={config.blur.brightness}
              onChange={(value) => setConfig({
                ...config,
                blur: { ...config.blur, brightness: parseFloat(value) || 0 }
              })}
            />
            <SettingCard
              label="Vibrancy"
              description="Saturation increase (0.0-1.0)"
              type="number"
              step="0.01"
              value={config.blur.vibrancy}
              onChange={(value) => setConfig({
                ...config,
                blur: { ...config.blur, vibrancy: parseFloat(value) || 0 }
              })}
            />
            <SettingCard
              label="Popups"
              description="Blur popups (e.g. menus)"
              type="boolean"
              value={config.blur.popups}
              onChange={(value) => setConfig({
                ...config,
                blur: { ...config.blur, popups: value === 'true' }
              })}
            />
            <SettingCard
              label="Special"
              description="Blur special workspace (expensive)"
              type="boolean"
              value={config.blur.special}
              onChange={(value) => setConfig({
                ...config,
                blur: { ...config.blur, special: value === 'true' }
              })}
            />
          </div>
        </div>
      </div>
    </div>
  );
};

interface SettingCardProps {
  label: string;
  description: string;
  type: 'text' | 'number' | 'boolean' | 'color' | 'select';
  value: any;
  onChange: (value: string) => void;
  options?: string[];
  step?: string;
}

const SettingCard: React.FC<SettingCardProps> = ({
  label,
  description,
  type,
  value,
  onChange,
  options = [],
  step = '1',
}) => {
  return (
    <div
      className="p-4 rounded border transition-all"
      style={{
        backgroundColor: '#141b1e',
        borderColor: '#1e272b',
      }}
    >
      <div className="flex items-start justify-between mb-2">
        <div className="flex-1">
          <label className="block text-sm font-medium text-gray-200 mb-1">{label}</label>
          <p className="text-xs text-gray-400 mb-3">{description}</p>
        </div>
        <Popover>
          <PopoverTrigger asChild>
            <button className="text-gray-500 hover:text-gray-300 transition-colors ml-2">
              <Info size={14} />
            </button>
          </PopoverTrigger>
          <PopoverContent className="bg-[#1a2227] border border-[#2a3439] text-gray-300 text-xs max-w-xs">
            {description}
          </PopoverContent>
        </Popover>
      </div>

      {type === 'boolean' && (
        <label className="flex items-center gap-2 cursor-pointer">
          <input
            type="checkbox"
            checked={value === true}
            onChange={(e) => onChange(e.target.checked ? 'true' : 'false')}
            className="rounded"
            style={{
              accentColor: '#1e3a5f',
            }}
          />
          <span className="text-sm text-gray-300">{value ? 'Enabled' : 'Disabled'}</span>
        </label>
      )}

      {type === 'number' && (
        <input
          type="number"
          value={value}
          step={step}
          onChange={(e) => onChange(e.target.value)}
          className="w-full bg-[#1a2227] text-gray-200 border border-[#2a3439] rounded px-3 py-2 text-sm focus:outline-none focus:border-[#1e3a5f]"
        />
      )}

      {type === 'text' && (
        <input
          type="text"
          value={value}
          onChange={(e) => onChange(e.target.value)}
          className="w-full bg-[#1a2227] text-gray-200 border border-[#2a3439] rounded px-3 py-2 text-sm focus:outline-none focus:border-[#1e3a5f]"
        />
      )}

      {type === 'color' && (
        <div className="flex gap-2">
          <input
            type="text"
            value={value}
            onChange={(e) => onChange(e.target.value)}
            placeholder="0xffffffff"
            className="flex-1 bg-[#1a2227] text-gray-200 border border-[#2a3439] rounded px-3 py-2 text-sm focus:outline-none focus:border-[#1e3a5f] font-mono"
          />
          <div
            className="w-10 h-10 rounded border border-[#2a3439]"
            style={{
              backgroundColor: value.startsWith('0x')
                ? `#${value.slice(4)}`
                : value,
            }}
          />
        </div>
      )}

      {type === 'select' && (
        <Select value={value} onValueChange={onChange}>
          <SelectTrigger className="w-full bg-[#1a2227] text-gray-200 border border-[#2a3439] rounded px-3 py-2 text-sm focus:outline-none focus:ring-0">
            <SelectValue />
          </SelectTrigger>
          <SelectContent className="bg-[#1a2227] border border-[#2a3439]">
            {options.map((opt) => (
              <SelectItem
                key={opt}
                value={opt}
                className="text-gray-200 focus:bg-[#2a3439] focus:text-gray-100"
              >
                {opt}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      )}
    </div>
  );
};

export default DecorationsView;
