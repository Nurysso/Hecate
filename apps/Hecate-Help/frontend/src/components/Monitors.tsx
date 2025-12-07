import React, { useState, useEffect, useRef } from 'react';
import { Monitor, RotateCcw, AlertCircle } from 'lucide-react';
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
  const canvasRef = useRef<HTMLDivElement>(null);
  const [dragging, setDragging] = useState<string | null>(null);
  const [dragOffset, setDragOffset] = useState({ x: 0, y: 0 });

const SCALE_FACTOR = 0.15;
const GRID_SIZE = 20;
const CANVAS_SIZE = 600;
const PIXEL_SNAP = 10; // Snap to nearest 10 pixels in actual coordinates

// Convert monitor PIXEL coordinates to canvas coordinates (centered on canvas)
const monitorToCanvas = (x: number, y: number): { x: number; y: number } => {
  return {
    x: (CANVAS_SIZE / 2) + (x * SCALE_FACTOR),
    y: (CANVAS_SIZE / 2) + (y * SCALE_FACTOR)  // Keep Y standard (down is positive)
  };
};

// Convert canvas coordinates back to monitor PIXEL coordinates
const canvasToMonitor = (x: number, y: number): { x: number; y: number } => {
  return {
    x: Math.round((x - CANVAS_SIZE / 2) / SCALE_FACTOR),
    y: Math.round((y - CANVAS_SIZE / 2) / SCALE_FACTOR)
  };
};

  // Check if two monitors overlap
  const checkOverlap = (
    x1: number, y1: number, w1: number, h1: number,
    x2: number, y2: number, w2: number, h2: number
  ): boolean => {
    return !(x1 + w1 <= x2 || x2 + w2 <= x1 || y1 + h1 <= y2 || y2 + h2 <= y1);
  };

  // Constrain position to keep monitor within canvas bounds
  const constrainToCanvas = (x: number, y: number, width: number, height: number): { x: number; y: number } => {
    return {
      x: Math.max(0, Math.min(x, CANVAS_SIZE - width)),
      y: Math.max(0, Math.min(y, CANVAS_SIZE - height))
    };
  };

  useEffect(() => {
    loadMonitors();
    loadResolutions();
  }, []);

  const loadMonitors = async (): Promise<void> => {
    try {
      setLoading(true);
      setError(null);

      const detected = await GetMonitors();

      if (!detected || detected.length === 0) {
        toast.error('No monitors detected. Please check your Hyprland setup.');
        setLoading(false);
        return;
      }

      setMonitors(detected);

      let existingConfig: MonitorConfig[] = [];
      try {
        existingConfig = await ParseMonitorConfig();
      } catch (err) {
        console.warn('No existing config found, using detected values');
      }

      const draggable: DraggableMonitor[] = detected.map((mon) => {
        const existing = existingConfig.find(c => c.name === mon.name);

        if (existing) {
          const positionParts = existing.position.split('x');
          const actualX = positionParts.length >= 1 ? parseInt(positionParts[0]) : 0;
          const actualY = positionParts.length >= 2 ? parseInt(positionParts[1]) : 0;

          const canvasPos = monitorToCanvas(actualX, actualY);
          const width = mon.width * SCALE_FACTOR;
          const height = mon.height * SCALE_FACTOR;

          // Center the monitor box on the position
          const centeredX = canvasPos.x - width / 2;
          const centeredY = canvasPos.y - height / 2;

          const constrained = constrainToCanvas(centeredX, centeredY, width, height);

          return {
            name: mon.name,
            resolution: existing.resolution,
            position: existing.position,
            scale: existing.scale,
            refreshRate: existing.refreshRate || mon.refreshRate,
            x: constrained.x,
            y: constrained.y,
            width,
            height,
          };
        } else {
          const canvasPos = monitorToCanvas(mon.x, mon.y);
          const width = mon.width * SCALE_FACTOR;
          const height = mon.height * SCALE_FACTOR;

          const centeredX = canvasPos.x - width / 2;
          const centeredY = canvasPos.y - height / 2;

          const constrained = constrainToCanvas(centeredX, centeredY, width, height);

          return {
            name: mon.name,
            resolution: `${mon.width}x${mon.height}`,
            position: `${mon.x}x${mon.y}`,
            scale: mon.scale || 1.0,
            refreshRate: mon.refreshRate || 60,
            x: constrained.x,
            y: constrained.y,
            width,
            height,
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

  const loadResolutions = async (): Promise<void> => {
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

  const handleMouseDown = (e: React.MouseEvent<HTMLDivElement>, monitorName: string): void => {
    e.preventDefault();
    const monitor = draggableMonitors.find(m => m.name === monitorName);
    if (!monitor) return;

    setDragging(monitorName);
    setSelectedMonitor(monitorName);

    // Calculate offset from center of monitor
    const centerX = monitor.x + monitor.width / 2;
    const centerY = monitor.y + monitor.height / 2;
    const rect = canvasRef.current?.getBoundingClientRect();
    if (!rect) return;

    const clickX = e.clientX - rect.left;
    const clickY = e.clientY - rect.top;

    setDragOffset({
      x: clickX - centerX,
      y: clickY - centerY
    });
  };

const handleMouseMove = (e: React.MouseEvent<HTMLDivElement>): void => {
  if (!dragging || !canvasRef.current) return;

  const rect = canvasRef.current.getBoundingClientRect();
  const mouseX = e.clientX - rect.left;
  const mouseY = e.clientY - rect.top;

  const monitor = draggableMonitors.find(m => m.name === dragging);
  if (!monitor) return;

  // Calculate new center position
  let centerX = mouseX - dragOffset.x;
  let centerY = mouseY - dragOffset.y;

  // Convert to pixel coordinates and snap to PIXEL_SNAP (e.g., 100 pixels)
  const tempPixelCoords = canvasToMonitor(centerX, centerY);
  const snappedPixelX = Math.round(tempPixelCoords.x / PIXEL_SNAP) * PIXEL_SNAP;
  const snappedPixelY = Math.round(tempPixelCoords.y / PIXEL_SNAP) * PIXEL_SNAP;

  // Convert back to canvas coordinates
  const snappedCanvas = monitorToCanvas(snappedPixelX, snappedPixelY);
  centerX = snappedCanvas.x;
  centerY = snappedCanvas.y;

  // Convert center to top-left corner
  let newX = centerX - monitor.width / 2;
  let newY = centerY - monitor.height / 2;

  // Constrain to canvas
  const constrained = constrainToCanvas(newX, newY, monitor.width, monitor.height);

  // Check for overlaps with other monitors
  let hasOverlap = false;

  for (const other of draggableMonitors) {
    if (other.name === dragging) continue;

    if (checkOverlap(
      constrained.x, constrained.y, monitor.width, monitor.height,
      other.x, other.y, other.width, other.height
    )) {
      hasOverlap = true;
      break;
    }
  }

  // Only update if no overlap
  if (!hasOverlap) {
    setDraggableMonitors(prev =>
      prev.map(m =>
        m.name === dragging
          ? {
              ...m,
              x: constrained.x,
              y: constrained.y,
              position: `${snappedPixelX}x${snappedPixelY}` // Store as pixel coordinates
            }
          : m
      )
    );
  }
};

  const handleMouseUp = (): void => {
    setDragging(null);
  };

  const updateMonitorProperty = (name: string, property: keyof MonitorConfig, value: any): void => {
    setDraggableMonitors(prev =>
      prev.map(mon => {
        if (mon.name === name) {
          const updated = { ...mon, [property]: value };

          if (property === 'resolution' && typeof value === 'string' && value !== 'preferred') {
            const [width, height] = value.split('x').map(Number);
            if (width && height) {
              updated.width = width * SCALE_FACTOR;
              updated.height = height * SCALE_FACTOR;
            }
          }

          return updated;
        }
        return mon;
      })
    );
  };

  const handleSave = async (): Promise<void> => {
    try {
      setSaving(true);
      setError(null);

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

  const handleReload = async (): Promise<void> => {
    try {
      setError(null);
      await ReloadHyprland();
      toast.success('Hyprland reloaded successfully!');
    } catch (err) {
      toast.error(`Failed to reload Hyprland: ${err}`);
    }
  };

  const handleTest = async (): Promise<void> => {
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
    } catch (err) {
      toast.error(`Failed to test configuration: ${err}`);
    }
  };

  const selectedMonitorData = draggableMonitors.find(m => m.name === selectedMonitor);

  if (loading) {
    return (
        <div className="flex items-center justify-center min-h-screen bg-gray-950">
  <div className="text-center">
    <div className="animate-spin rounded-full h-12 w-12 border-2 border-gray-700 border-t-gray-400 mx-auto mb-4"></div>
    <p className="text-gray-400 text-sm">Loading Monitors...</p>
  </div>
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
    <div className="flex flex-col h-full">
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

          <div
            ref={canvasRef}
            className="relative border rounded-lg mx-auto"
            style={{
              backgroundColor: '#141b1e',
              borderColor: '#1e272b',
              width: `${CANVAS_SIZE}px`,
              height: `${CANVAS_SIZE}px`,
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
            {/* Center crosshair */}
            <div
              className="absolute"
              style={{
                left: `${CANVAS_SIZE / 2}px`,
                top: 0,
                width: '1px',
                height: '100%',
                backgroundColor: 'rgba(59, 130, 246, 0.3)',
                pointerEvents: 'none'
              }}
            />
            <div
              className="absolute"
              style={{
                left: 0,
                top: `${CANVAS_SIZE / 2}px`,
                width: '100%',
                height: '1px',
                backgroundColor: 'rgba(59, 130, 246, 0.3)',
                pointerEvents: 'none'
              }}
            />
            {/* Origin marker */}
            <div
              className="absolute text-xs"
              style={{
                left: `${CANVAS_SIZE / 2 + 4}px`,
                top: `${CANVAS_SIZE / 2 + 4}px`,
                color: 'rgba(59, 130, 246, 0.5)',
                pointerEvents: 'none'
              }}
            >
              0,0
            </div>

            {draggableMonitors.map(mon => {
              // Calculate center position for display
              const centerX = mon.x + mon.width / 2;
              const centerY = mon.y + mon.height / 2;

              return (
                <div key={mon.name}>
                  {/* Monitor box */}
                  <div
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

                  {/* Center point indicator */}
                  {/* <div
                    className="absolute pointer-events-none"
                    style={{
                      left: centerX - 4,
                      top: centerY - 4,
                      width: '8px',
                      height: '8px',
                      backgroundColor: selectedMonitor === mon.name ? '#3b82f6' : '#6b7280',
                      borderRadius: '50%',
                      border: '2px solid #141b1e'
                    }}
                  /> */}
                </div>
              );
            })}
          </div>
        </div>

        {/* Properties Panel */}
        <div className="w-80 border-l p-4 overflow-auto" style={{ borderColor: '#1e272b', backgroundColor: '#0f1419' }}>
          <h2 className="text-lg text-gray-100 font-semibold mb-4">Monitor Details</h2>

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
                  style={{ backgroundColor: '#1e272b', borderColor: '#374151', color: '#9ca3af' }}
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-300 mb-1">
                  Resolution
                </label>
                <Select
                  value={selectedMonitorData.resolution}
                  onValueChange={(value: string) =>
                    updateMonitorProperty(selectedMonitorData.name, 'resolution', value)
                  }
                >
                  <SelectTrigger className="w-full bg-[#1e272b] border border-[#374151] text-gray-200 text-sm">
                    <SelectValue placeholder="Select resolution" />
                  </SelectTrigger>
                  <SelectContent className="bg-[#0f1419] border border-[#374151] text-gray-200">
                    {availableResolutions.map((res) => (
                      <SelectItem
                        key={res}
                        value={res}
                        className="text-gray-200 hover:bg-[#1e272b]"
                      >
                        {res}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
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
                  style={{ backgroundColor: '#1e272b', borderColor: '#374151', color: '#e5e7eb' }}
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
                  style={{ backgroundColor: '#1e272b', borderColor: '#374151', color: '#9ca3af' }}
                />
                <p className="mt-1 text-xs text-gray-500">
  {draggableMonitors.length > 1
    ? 'Drag monitor center on canvas to change (snaps to 100px increments)'
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
                  style={{ backgroundColor: '#1e272b', borderColor: '#374151', color: '#e5e7eb' }}
                />
                <p className="mt-1 text-xs text-gray-500">Recommended: 1.0 - 2.0</p>
              </div>

              <div className="pt-4 border-t" style={{ borderColor: '#1e272b' }}>
                <h4 className="text-sm font-medium text-gray-300 mb-2">Preview Config</h4>
                <pre className="text-xs p-3 rounded overflow-x-auto" style={{ backgroundColor: '#1e272b', color: '#9ca3af' }}>
                  {`monitor = ${selectedMonitorData.name}, ${selectedMonitorData.resolution}@${selectedMonitorData.refreshRate.toFixed(2)}, ${selectedMonitorData.position}, ${selectedMonitorData.scale.toFixed(2)}`}
                </pre>
              </div>
            </div>
          ) : (
            <div className="text-gray-500 text-sm">
              Select a monitor to view details
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default MonitorsView;
