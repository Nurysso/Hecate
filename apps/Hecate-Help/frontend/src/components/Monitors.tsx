// MonitorsView.tsx
import React, { useState, useEffect, useRef } from 'react';
import { Monitor, Save, RotateCcw, Play, AlertCircle, Info } from 'lucide-react';
import { Popover, PopoverTrigger, PopoverContent } from './ui/popover';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from './ui/select';
import { toast } from 'sonner';
import { Toaster } from './ui/sonner';
import {
  GetMonitors,
  SaveMonitorConfig,
  ReloadHyprland,
  GetAvailableResolutions,
  TestMonitorConfig,
  ParseMonitorConfig
} from '../../wailsjs/go/main/App';
import { main } from '../../wailsjs/go/models';

// Use the generated types
type HyprctlMonitor = main.HyprctlMonitor;
type MonitorConfig = main.MonitorConfig;

interface DraggableMonitor extends MonitorConfig {
  x: number;
  y: number;
  width: number;
  height: number;
}

const MonitorsView: React.FC = () => {
  const [monitors, setMonitors] = useState<HyprctlMonitor[]>([]);
  const [draggableMonitors, setDraggableMonitors] = useState<DraggableMonitor[]>([]);
  const [selectedMonitor, setSelectedMonitor] = useState<string | null>(null);
  const [availableResolutions, setAvailableResolutions] = useState<string[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const canvasRef = useRef<HTMLDivElement>(null);
  const [dragging, setDragging] = useState<string | null>(null);
  const [dragOffset, setDragOffset] = useState({ x: 0, y: 0 });

  const SCALE = 0.1; // Scale for visualization
  const GRID_SIZE = 20;

  useEffect(() => {
    loadMonitors();
    loadResolutions();
  }, []);

  const loadMonitors = async () => {
    try {
      setLoading(true);
      setError(null);

      const detected = await GetMonitors();

      // Fallback if no monitors detected or empty array
      if (!detected || detected.length === 0) {
        toast.error('No monitors detected. Please check your Hyprland setup.');
        setLoading(false);
        return;
      }

      setMonitors(detected);

      // Try to load existing config
      let existingConfig: MonitorConfig[] = [];
      try {
        existingConfig = await ParseMonitorConfig();
      } catch (err) {
        console.warn('No existing config found, using detected values');
      }

      // Create draggable monitors
      const draggable = detected.map((mon, idx) => {
        // Check if we have existing config for this monitor
        const existing = existingConfig.find(c => c.name === mon.name);

        if (existing) {
          // Parse position
          const positionParts = existing.position.split('x');
          const x = positionParts.length >= 1 ? parseInt(positionParts[0]) : 0;
          const y = positionParts.length >= 2 ? parseInt(positionParts[1]) : 0;

          return {
            name: mon.name,
            resolution: existing.resolution,
            position: existing.position,
            scale: existing.scale,
            refreshRate: existing.refreshRate || mon.refreshRate,
            x: x * SCALE,
            y: y * SCALE,
            width: mon.width * SCALE,
            height: mon.height * SCALE,
          };
        } else {
          // Use current values from hyprctl
          return {
            name: mon.name,
            resolution: `${mon.width}x${mon.height}`,
            position: `${mon.x}x${mon.y}`,
            scale: mon.scale || 1.0,
            refreshRate: mon.refreshRate || 60,
            x: mon.x * SCALE,
            y: mon.y * SCALE,
            width: mon.width * SCALE,
            height: mon.height * SCALE,
          };
        }
      });

      setDraggableMonitors(draggable);
      if (draggable.length > 0) {
        setSelectedMonitor(draggable[0].name);
      }
    } catch (err) {
      toast.error(`Failed to load monitors: ${err}`);
    } finally {
      setLoading(false);
    }
  };

  const loadResolutions = async () => {
    try {
      const resolutions = await GetAvailableResolutions();
      setAvailableResolutions(resolutions || [
        '1920x1080',
        '2560x1440',
        '3840x2160',
        'preferred'
      ]);
    } catch (err) {
      console.error('Failed to load resolutions:', err);
      // Fallback resolutions
      setAvailableResolutions([
        '1920x1080',
        '2560x1440',
        '3840x2160',
        '1920x1200',
        '2560x1600',
        'preferred'
      ]);
    }
  };

  const handleMouseDown = (e: React.MouseEvent, monitorName: string) => {
    if (e.button !== 0) return; // Only left click

    const monitor = draggableMonitors.find(m => m.name === monitorName);
    if (!monitor) return;

    setDragging(monitorName);
    setSelectedMonitor(monitorName);
    setDragOffset({
      x: e.clientX - monitor.x,
      y: e.clientY - monitor.y,
    });
  };

  const handleMouseMove = (e: React.MouseEvent) => {
    if (!dragging) return;

    const newX = Math.round((e.clientX - dragOffset.x) / GRID_SIZE) * GRID_SIZE;
    const newY = Math.round((e.clientY - dragOffset.y) / GRID_SIZE) * GRID_SIZE;

    setDraggableMonitors(prev =>
      prev.map(mon =>
        mon.name === dragging
          ? {
              ...mon,
              x: newX,
              y: newY,
              position: `${Math.round(newX / SCALE)}x${Math.round(newY / SCALE)}`,
            }
          : mon
      )
    );
  };

  const handleMouseUp = () => {
    setDragging(null);
  };

  const updateMonitorProperty = (name: string, property: keyof MonitorConfig, value: any) => {
    setDraggableMonitors(prev =>
      prev.map(mon => {
        if (mon.name === name) {
          const updated = { ...mon, [property]: value };

          // Update width/height if resolution changes
          if (property === 'resolution' && typeof value === 'string' && value !== 'preferred') {
            const [width, height] = value.split('x').map(Number);
            if (width && height) {
              updated.width = width * SCALE;
              updated.height = height * SCALE;
            }
          }

          return updated;
        }
        return mon;
      })
    );
  };

  const handleSave = async () => {
    try {
      setSaving(true);
      setError(null);
      setSuccess(null);

      const configs: MonitorConfig[] = draggableMonitors.map(mon => ({
        name: mon.name,
        resolution: mon.resolution,
        position: mon.position,
        scale: mon.scale,
        refreshRate: mon.refreshRate,
      }));

      await SaveMonitorConfig(configs);
      toast.success('Monitor configuration saved successfully!');

    } catch (err) {
      toast.error(`Failed to save configuration: ${err}`);
    } finally {
      setSaving(false);
    }
  };

  const handleReload = async () => {
    try {
      setError(null);
      await ReloadHyprland();
      toast.success('Hyprland reloaded successfully!');
    //   setTimeout(() => toast.success(null), 3000);
    } catch (err) {
      toast.error(`Failed to reload Hyprland: ${err}`);
    }
  };

  const handleTest = async () => {
    if (!selectedMonitor) return;

    const monitor = draggableMonitors.find(m => m.name === selectedMonitor);
    if (!monitor) return;

    try {
      setError(null);
      const config: MonitorConfig = {
        name: monitor.name,
        resolution: monitor.resolution,
        position: monitor.position,
        scale: monitor.scale,
        refreshRate: monitor.refreshRate,
      };
      await TestMonitorConfig(config);
      toast.success('Configuration applied temporarily. Save to make permanent.');
    //   setTimeout(() => toast.success(null), 3000);
    } catch (err) {
      toast.error(`Failed to test configuration: ${err}`);
    }
  };

  const selectedMonitorData = draggableMonitors.find(m => m.name === selectedMonitor);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-full" style={{ backgroundColor: '#0f1416' }}>
        <div className="text-gray-400">Loading monitors...</div>
      </div>
    );
  }

  if (monitors.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center h-full p-6" style={{ backgroundColor: '#0f1416' }}>
        <Monitor size={48} className="text-gray-600 mb-4" />
        <h3 className="text-lg font-semibold text-gray-300 mb-2">No Monitors Detected</h3>
        <p className="text-sm text-gray-500 text-center max-w-md mb-4">
          Unable to detect any monitors. Make sure Hyprland is running and hyprctl is accessible.
        </p>
        {error && (
          <div className="mt-4 p-3 rounded flex items-center gap-2" style={{ backgroundColor: '#3d1f1f', color: '#ef4444' }}>
            <AlertCircle size={16} />
            {error}
          </div>
        )}
        <button
          onClick={loadMonitors}
          className="mt-4 px-4 py-2 rounded flex items-center gap-2 text-sm transition-colors"
          style={{ backgroundColor: '#1e3a5f', color: 'white' }}
        >
          <RotateCcw size={16} />
          Retry
        </button>
      </div>
    );
  }

  return (
    <div className="flex flex-col h-full" style={{ backgroundColor: '#0f1416' }}>
            <Toaster position="top-center" toastOptions={{
              style: {
                background: '#F8F6F0',
              },
            }} />
      {/* Header */}
      <div className="p-4 border-b border-gray-800">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-semibold text-gray-100 mb-1">Monitor Control</h1>
            <p className="text-sm text-gray-500">
              Manage Monitor Layout
              <Popover>
                <PopoverTrigger asChild>
                  <button className="ml-2 text-gray-600 hover:text-gray-400 inline-flex items-center">
                    <Info className="w-3.5 h-3.5" />
                  </button>
                </PopoverTrigger>
                <PopoverContent className="w-80 bg-gray-900 border-gray-800 text-gray-300 text-sm">
                  <div className="space-y-2">
                    <p className="text-sm text-blue-400/80 mt-1">
                      {draggableMonitors.length === 1
                        ? 'Single monitor detected. Configure resolution and scale below.'
                        : 'Drag monitors to arrange them. Click to select and edit properties.'}
                    </p>
                  </div>
                </PopoverContent>
              </Popover>
            </p>
          </div>
          {/* Action Buttons */}
          <div className="flex gap-2">
            <button
              onClick={handleTest}
              disabled={!selectedMonitor}
              className="px-4 py-2 rounded flex items-center gap-2 text-sm transition-colors disabled:opacity-50 hover:opacity-80"
              style={{ backgroundColor: '#1e3a5f', color: 'white' }}
            >
              <Play size={16} />
              Test
            </button>
            <button
              onClick={handleSave}
              disabled={saving}
              className="px-4 py-2 rounded flex items-center gap-2 text-sm transition-colors disabled:opacity-50 hover:opacity-80"
              style={{ backgroundColor: '#1e3a5f', color: 'white' }}
            >
              <Save size={16} />
              {saving ? 'Saving...' : 'Save'}
            </button>
            <button
              onClick={handleReload}
              className="px-4 py-2 rounded flex items-center gap-2 text-sm transition-colors hover:opacity-80"
              style={{ backgroundColor: '#1e3a5f', color: 'white' }}
            >
              <RotateCcw size={16} />
              Reload Hyprland
            </button>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="flex flex-1 overflow-hidden">
        {/* Canvas Area */}
        <div className="flex-1 p-4 overflow-auto">
          {error && (
            <div className="mb-4 p-3 rounded flex items-center gap-2" style={{ backgroundColor: '#3d1f1f', color: '#ef4444' }}>
              <AlertCircle size={16} />
              {error}
            </div>
          )}

          {success && (
            <div className="mb-4 p-3 rounded" style={{ backgroundColor: '#1f3d2f', color: '#22c55e' }}>
              {success}
            </div>
          )}

          <div
            ref={canvasRef}
            className="relative border rounded-lg"
            style={{
              backgroundColor: '#141b1e',
              borderColor: '#1e272b',
              minHeight: '500px',
              backgroundImage: `
                linear-gradient(rgba(255,255,255,0.05) 1px, transparent 1px),
                linear-gradient(90deg, rgba(255,255,255,0.05) 1px, transparent 1px)
              `,
              backgroundSize: `${GRID_SIZE}px ${GRID_SIZE}px`,
            }}
            onMouseMove={handleMouseMove}
            onMouseUp={handleMouseUp}
            onMouseLeave={handleMouseUp}
          >
            {draggableMonitors.map(mon => (
              <div
                key={mon.name}
                className="absolute border-2 rounded cursor-move transition-all"
                style={{
                  left: mon.x,
                  top: mon.y,
                  width: mon.width,
                  height: mon.height,
                  backgroundColor: selectedMonitor === mon.name ? '#1e3a5f' : '#1e272b',
                  borderColor: selectedMonitor === mon.name ? '#3b82f6' : '#374151',
                  minWidth: '100px',
                  minHeight: '60px',
                }}
                onMouseDown={(e) => handleMouseDown(e, mon.name)}
              >
                <div className="p-2 text-xs h-full flex flex-col justify-center">
                  <div className="font-semibold text-gray-100 truncate">{mon.name}</div>
                  <div className="text-gray-400">{mon.resolution}</div>
                  <div className="text-gray-500">{mon.position}</div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Properties Panel */}
        <div className="p-4 w-80 border-l overflow-y-auto" style={{ backgroundColor: '#141b1e', borderColor: '#1e272b' }}>
          <h3 className="text-lg font-semibold text-gray-100 mb-4 flex items-center gap-2">
            <Monitor size={20} />
            Monitor Properties
          </h3>

          {selectedMonitorData ? (
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-300 mb-1">
                  Monitor Name
                </label>
                <input
                  type="text"
                  value={selectedMonitorData.name}
                  disabled
                  className="w-full px-3 py-2 rounded text-sm border"
                  style={{ backgroundColor: '#0f1416', borderColor: '#1e272b', color: '#9ca3af' }}
                />
              </div>

                <div>
      <label className="block text-sm font-medium text-gray-300 mb-1">
        Resolution
      </label>

      <Select
        value={selectedMonitorData.resolution}
        onValueChange={(value: number) =>
          updateMonitorProperty(selectedMonitorData.name, 'resolution', value)
        }
      >
        <SelectTrigger
          className="w-full bg-[#0f1416] border border-[#1e272b] text-gray-200 text-sm"
        >
          <SelectValue placeholder="Select resolution" />
        </SelectTrigger>
        <SelectContent className="bg-[#0f1416] border border-[#1e272b] text-gray-200">
          {availableResolutions.map((res) => (
            <SelectItem
              key={res}
              value={res}
              className="text-gray-200 hover:bg-[#1a1f22]"
            >
              {res}
            </SelectItem>
          ))}
        </SelectContent>
      </Select>

      {/* <p className="mt-1 text-xs text-gray-500">Or type custom resolution</p>

      <input
        type="text"
        value={selectedMonitorData.resolution}
        onChange={(e) =>
          updateMonitorProperty(selectedMonitorData.name, 'resolution', e.target.value)
        }
        placeholder="1920x1080"
        className="w-full px-3 py-2 rounded text-sm border mt-2 bg-[#0f1416] border-[#1e272b] text-gray-200 placeholder-gray-500"
      /> */}
    </div>

              <div>
                <label className="block text-sm font-medium text-gray-300 mb-1">
                  Refresh Rate (Hz)
                </label>
                <input
                  type="number"
                  value={selectedMonitorData.refreshRate}
                  onChange={(e) => updateMonitorProperty(selectedMonitorData.name, 'refreshRate', parseFloat(e.target.value) || 60)}
                  step="0.01"
                  min="30"
                  max="360"
                  className="w-full px-3 py-2 rounded text-sm border"
                  style={{ backgroundColor: '#0f1416', borderColor: '#1e272b', color: '#e5e7eb' }}
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-300 mb-1">
                  Position
                </label>
                <input
                  type="text"
                  value={selectedMonitorData.position}
                  disabled
                  className="w-full px-3 py-2 rounded text-sm border"
                  style={{ backgroundColor: '#0f1416', borderColor: '#1e272b', color: '#9ca3af' }}
                />
                <p className="mt-1 text-xs text-gray-500">
                  {draggableMonitors.length > 1
                    ? 'Drag monitor on canvas to change position'
                    : 'Position is 0x0 for single monitor'}
                </p>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-300 mb-1">
                  Scale
                </label>
                <input
                  type="number"
                  value={selectedMonitorData.scale}
                  onChange={(e) => updateMonitorProperty(selectedMonitorData.name, 'scale', parseFloat(e.target.value) || 1.0)}
                  step="0.1"
                  min="0.5"
                  max="3"
                  className="w-full px-3 py-2 rounded text-sm border"
                  style={{ backgroundColor: '#0f1416', borderColor: '#1e272b', color: '#e5e7eb' }}
                />
                <p className="mt-1 text-xs text-gray-500">Recommended: 1.0 - 2.0</p>
              </div>

              <div className="pt-4 border-t" style={{ borderColor: '#1e272b' }}>
                <h4 className="text-sm font-medium text-gray-300 mb-2">Preview Config</h4>
                <pre className="text-xs p-3 rounded overflow-x-auto" style={{ backgroundColor: '#0f1416', color: '#9ca3af' }}>
                  {`monitor = ${selectedMonitorData.name}, ${selectedMonitorData.resolution}@${selectedMonitorData.refreshRate.toFixed(2)}, ${selectedMonitorData.position}, ${selectedMonitorData.scale.toFixed(2)}`}
                </pre>
              </div>
            </div>
          ) : (
            <div className="text-sm text-gray-400">
              Select a monitor to edit its properties
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default MonitorsView;
