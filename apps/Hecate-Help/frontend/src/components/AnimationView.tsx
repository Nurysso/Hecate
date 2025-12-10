
import React, { useState, useEffect } from 'react';
import { Plus, Trash2, Save, RefreshCw, Edit2 } from 'lucide-react';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from './ui/select';

// Type definitions matching Go backend
interface Animation {
  name: string;
  enabled: boolean;
  speed: string;
  curve: string;
  style: string;
}

interface Bezier {
  name: string;
  x0: string;
  y0: string;
  x1: string;
  y1: string;
}

interface AnimationConfig {
  animations: Animation[];
  beziers: Bezier[];
}

// Animation type definitions
const ANIMATION_TYPES = {
  global: { styles: [] },
  windows: { styles: ['slide', 'popin', 'gnomed'] },
  windowsIn: { styles: ['slide', 'popin', 'gnomed'] },
  windowsOut: { styles: ['slide', 'popin', 'gnomed'] },
  windowsMove: { styles: ['slide', 'popin', 'gnomed'] },
  layers: { styles: ['slide', 'popin', 'fade'] },
  layersIn: { styles: ['slide', 'popin', 'fade'] },
  layersOut: { styles: ['slide', 'popin', 'fade'] },
  fade: { styles: [] },
  fadeIn: { styles: [] },
  fadeOut: { styles: [] },
  fadeSwitch: { styles: [] },
  fadeShadow: { styles: [] },
  fadeDim: { styles: [] },
  fadeLayers: { styles: [] },
  fadeLayersIn: { styles: [] },
  fadeLayersOut: { styles: [] },
  fadePopups: { styles: [] },
  fadePopupsIn: { styles: [] },
  fadePopupsOut: { styles: [] },
  fadeDpms: { styles: [] },
  border: { styles: [] },
  borderangle: { styles: ['once', 'loop'] },
  workspaces: { styles: ['slide', 'slidevert', 'fade', 'slidefade', 'slidefadevert'] },
  workspacesIn: { styles: ['slide', 'slidevert', 'fade', 'slidefade', 'slidefadevert'] },
  workspacesOut: { styles: ['slide', 'slidevert', 'fade', 'slidefade', 'slidefadevert'] },
  specialWorkspace: { styles: ['slide', 'slidevert', 'fade', 'slidefade', 'slidefadevert'] },
  specialWorkspaceIn: { styles: ['slide', 'slidevert', 'fade', 'slidefade', 'slidefadevert'] },
  specialWorkspaceOut: { styles: ['slide', 'slidevert', 'fade', 'slidefade', 'slidefadevert'] },
  zoomFactor: { styles: [] },
  monitorAdded: { styles: [] }
} as const;

const ANIMATION_NAMES = Object.keys(ANIMATION_TYPES);

// Declare global window interface for Go bindings
declare global {
  interface Window {
    go: {
      main: {
        App: {
          ReadAnimations: () => Promise<AnimationConfig>;
          WriteAnimations: (config: AnimationConfig) => Promise<void>;
          GetDefaultAnimations: () => Promise<AnimationConfig>;
          UpdateAnimation: (anim: Animation) => Promise<void>;
          UpdateBezier: (bez: Bezier) => Promise<void>;
          DeleteAnimation: (name: string) => Promise<void>;
          DeleteBezier: (name: string) => Promise<void>;
          ToggleAnimation: (name: string) => Promise<void>;
        };
      };
    };
  }
}

const AnimationsView: React.FC = () => {
  const [config, setConfig] = useState<AnimationConfig>({
    animations: [],
    beziers: []
  });
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [activeTab, setActiveTab] = useState<'animations' | 'beziers'>('animations');
  const [editingAnim, setEditingAnim] = useState<Animation | null>(null);
  const [editingBezier, setEditingBezier] = useState<Bezier | null>(null);
  const [customBezierName, setCustomBezierName] = useState('');

  // Load animations on mount
  useEffect(() => {
    loadAnimations();
  }, []);

  const loadAnimations = async () => {
    setLoading(true);
    try {
      if (window.go?.main?.App?.ReadAnimations) {
        const data = await window.go.main.App.ReadAnimations();
        setConfig(data);
      }
    } catch (error) {
      console.error('Failed to load animations:', error);
    } finally {
      setLoading(false);
    }
  };

  const saveConfig = async () => {
    setSaving(true);
    try {
      if (window.go?.main?.App?.WriteAnimations) {
        await window.go.main.App.WriteAnimations(config);
        alert('Configuration saved successfully!');
      }
    } catch (error) {
      console.error('Failed to save configuration:', error);
      alert('Failed to save configuration');
    } finally {
      setSaving(false);
    }
  };

  const addAnimation = () => {
    const defaultCurve = config.beziers.length > 0 ? config.beziers[0].name : 'default';
    setEditingAnim({
      name: ANIMATION_NAMES[0],
      enabled: true,
      speed: '5',
      curve: defaultCurve,
      style: ''
    });
  };

  const addBezier = () => {
    setCustomBezierName('');
    setEditingBezier({
      name: '',
      x0: '0.05',
      y0: '0.9',
      x1: '0.1',
      y1: '1.05'
    });
  };

  const saveAnimation = () => {
    if (!editingAnim || !editingAnim.name) {
      alert('Animation name is required');
      return;
    }

    const existing = config.animations.findIndex(a => a.name === editingAnim.name);
    const newAnimations = [...config.animations];

    if (existing >= 0) {
      newAnimations[existing] = editingAnim;
    } else {
      newAnimations.push(editingAnim);
    }

    setConfig({ ...config, animations: newAnimations });
    setEditingAnim(null);
  };

  const saveBezier = () => {
    if (!editingBezier) {
      return;
    }

    const finalName = editingBezier.name === '' ? customBezierName : editingBezier.name;

    if (!finalName) {
      alert('Bezier name is required');
      return;
    }

    const bezierToSave = { ...editingBezier, name: finalName };
    const existing = config.beziers.findIndex(b => b.name === finalName);
    const newBeziers = [...config.beziers];

    if (existing >= 0) {
      newBeziers[existing] = bezierToSave;
    } else {
      newBeziers.push(bezierToSave);
    }

    setConfig({ ...config, beziers: newBeziers });
    setEditingBezier(null);
    setCustomBezierName('');
  };

  const deleteAnimation = (name: string) => {
    if (confirm(`Delete animation "${name}"?`)) {
      setConfig({
        ...config,
        animations: config.animations.filter(a => a.name !== name)
      });
    }
  };

  const deleteBezier = (name: string) => {
    if (confirm(`Delete bezier curve "${name}"?`)) {
      setConfig({
        ...config,
        beziers: config.beziers.filter(b => b.name !== name)
      });
    }
  };

  const toggleAnimation = async (name: string) => {
    try {
      if (window.go?.main?.App?.ToggleAnimation) {
        await window.go.main.App.ToggleAnimation(name);
        // Reload to get updated state
        await loadAnimations();
      }
    } catch (error) {
      console.error('Failed to toggle animation:', error);
      alert('Failed to toggle animation');
    }
  };

  const getAvailableStyles = (animName: string): readonly string[] => {
    return ANIMATION_TYPES[animName as keyof typeof ANIMATION_TYPES]?.styles || [];
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-full bg-[#0f1416]">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-2 border-gray-700 border-t-gray-400 mx-auto mb-4"></div>
          <p className="text-gray-400 text-sm">Loading animations...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="h-full flex flex-col">
      {/* Sticky Header */}
      <div className="sticky bg-[#0A0E10] top-0 z-40 border-b border-gray-800 rounded-lg">
        <div className="max-w-6xl mx-auto">
          {/* Action Bar */}
          <div
            className="flex items-center justify-between p-3 m-2 rounded-lg"
            style={{ borderColor: '#1e272b', backgroundColor: '#141b1e' }}
          >
            {/* Tabs (left) */}
            <div className="flex gap-1">
              <button
                onClick={() => setActiveTab('animations')}
                className={`px-4 py-2 rounded text-sm transition-colors ${
                  activeTab === 'animations'
                    ? 'text-white'
                    : 'text-gray-400 hover:text-gray-200'
                }`}
                style={{
                  backgroundColor: activeTab === 'animations' ? '#1e3a5f' : '#0f1416',
                }}
              >
                Animations ({config.animations.length})
              </button>
              <button
                onClick={() => setActiveTab('beziers')}
                className={`px-4 py-2 rounded text-sm transition-colors ${
                  activeTab === 'beziers'
                    ? 'text-white'
                    : 'text-gray-400 hover:text-gray-200'
                }`}
                style={{
                  backgroundColor: activeTab === 'beziers' ? '#1e3a5f' : '#0f1416',
                }}
              >
                Bezier Curves ({config.beziers.length})
              </button>
            </div>

            {/* Action buttons (right) */}
            <div className="flex items-center gap-2 ">
              <button
                onClick={activeTab === 'animations' ? addAnimation : addBezier}
                className="flex items-center gap-2 px-3 py-2 rounded text-sm transition-colors hover:opacity-80"
                style={{ backgroundColor: '#1e3a5f', color: '#fff' }}
              >
                <Plus size={16} />
                Add {activeTab === 'animations' ? 'Animation' : 'Bezier'}
              </button>
              <button
                onClick={saveConfig}
                disabled={saving}
                className="flex items-center gap-2 px-3 py-2 rounded text-sm transition-colors disabled:opacity-50 hover:opacity-80"
                style={{ backgroundColor: '#1e3a5f', color: '#fff' }}
              >
                <Save size={16} />
              </button>
              <button
                onClick={loadAnimations}
                className="flex items-center gap-2 px-3 py-2 rounded text-sm transition-colors hover:opacity-80"
                style={{ backgroundColor: '#1a2227', color: '#9ca3af' }}
              >
                <RefreshCw size={16} />
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Scrollable Content */}
      <div className="p-6 flex-1 overflow-y-auto border-b border-gray-800">
        <div className="max-w-6xl mx-auto">
          {activeTab === 'animations' ? (
            <>
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
                {config.animations.map((anim) => (
                  <div
                    key={anim.name}
                    className="rounded-lg p-4 border transition-all hover:shadow-lg relative overflow-hidden"
                    style={{
                      backgroundColor: '#141b1e',
                      borderColor: anim.enabled ? '#1e272b' : '1e272b',
                      borderWidth: '1px',
                    }}
                  >
                    {/* Status indicator */}
                    <div
                      className="absolute top-0 right-0 w-16 h-16 opacity-10"
                      style={{
                        background: anim.enabled
                          ? 'radial-gradient(circle at top right, #1e3a5f 0%, transparent 70%)'
                          : 'radial-gradient(circle at top right, #374151 0%, transparent 70%)'
                      }}
                    />

                    <div className="relative">
                      {/* Header */}
                      <div className="flex items-start justify-between mb-3">
                        <div className="flex-1">
                          <h4 className="font-mono text-sm font-semibold text-gray-100 mb-1 truncate">
                            {anim.name}
                          </h4>
                          <div className="flex items-center gap-2">
                            <span
                              className="text-xs px-2 py-0.5 rounded"
                              style={{
                                backgroundColor: anim.enabled ? '#1e3a5f40' : '#37415140',
                                color: anim.enabled ? '#60a5fa' : '#9ca3af'
                              }}
                            >
                              {anim.enabled ? 'Enabled' : 'Disabled'}
                            </span>
                          </div>
                        </div>

                        {/* Action buttons */}
                        <div className="flex gap-1 ml-2">
                          <button
                            onClick={() => toggleAnimation(anim.name)}
                            className="p-1.5 rounded transition-colors text-xs"
                            style={{
                              backgroundColor: '#1a2227',
                              color: anim.enabled ? '#60a5fa' : '#9ca3af'
                            }}
                            title={anim.enabled ? 'Disable' : 'Enable'}
                          >
                            <div className="w-3 h-3 rounded-full border-2" style={{
                              borderColor: anim.enabled ? '#60a5fa' : '#6b7280',
                              backgroundColor: anim.enabled ? '#60a5fa' : 'transparent'
                            }}/>
                          </button>
                        </div>
                      </div>

                      {/* Details */}
                      {anim.enabled ? (
                        <div className="space-y-2 mb-3">
                          <div className="flex items-center justify-between text-xs">
                            <span className="text-gray-500">Speed</span>
                            <span className="font-mono text-gray-300 bg-[#0f1416] px-2 py-0.5 rounded">
                              {anim.speed}ds
                            </span>
                          </div>
                          <div className="flex items-center justify-between text-xs">
                            <span className="text-gray-500">Curve</span>
                            <span className="font-mono text-gray-300 bg-[#0f1416] px-2 py-0.5 rounded truncate max-w-[120px]">
                              {anim.curve}
                            </span>
                          </div>
                          {anim.style && (
                            <div className="flex items-center justify-between text-xs">
                              <span className="text-gray-500">Style</span>
                              <span className="font-mono text-gray-300 bg-[#0f1416] px-2 py-0.5 rounded truncate max-w-[120px]">
                                {anim.style}
                              </span>
                            </div>
                          )}
                        </div>
                      ) : (
                        <div className="mb-3 text-xs text-gray-600 italic">
                          Animation disabled
                        </div>
                      )}

                      {/* Footer actions */}
                      <div className="flex gap-2 pt-2 border-t" style={{ borderColor: '#1e272b' }}>
                        <button
                          onClick={() => setEditingAnim(anim)}
                          className="flex-1 px-3 py-1.5 rounded text-xs transition-colors hover:opacity-80 flex items-center justify-center gap-1"
                          style={{ backgroundColor: '#1a2227', color: '#9ca3af' }}
                        >
                          <Edit2 size={12} />
                          Edit
                        </button>
                        <button
                          onClick={() => deleteAnimation(anim.name)}
                          className="px-3 py-1.5 rounded transition-colors hover:opacity-80 flex items-center justify-center"
                          style={{ backgroundColor: '#1a2227', color: '#ef4444' }}
                        >
                          <Trash2 size={12} />
                        </button>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </>
          ) : (
            <>
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
                {config.beziers.map((bez) => (
                  <div
                    key={bez.name}
                    className="rounded-lg p-4 border transition-all hover:shadow-lg relative overflow-hidden"
                    style={{
                      backgroundColor: '#141b1e',
                      borderColor: '#1e272b',
                      borderWidth: '1px',
                    }}
                  >
                    {/* Status indicator */}
                    <div
                      className="absolute top-0 right-0 w-16 h-16 opacity-10"
                      style={{
                        background: 'radial-gradient(circle at top right, #374151 0%, transparent 70%)'
                      }}
                    />

                    <div className="relative">
                      {/* Header */}
                      <div className="flex items-start justify-between mb-3">
                        <div className="flex-1">
                          <h4 className="font-mono text-sm font-semibold text-gray-100 mb-1 truncate">
                            {bez.name}
                          </h4>
                          <div className="flex items-center gap-2">
                            <span
                              className="text-xs px-2 py-0.5 rounded"
                              style={{
                                backgroundColor: '#37415140',
                                color: '#9ca3af'
                              }}
                            >
                              Cubic Bezier
                            </span>
                          </div>
                        </div>

                        {/* Action buttons */}
                        <div className="flex gap-1 ml-2">
                          <button
                            className="p-1.5 rounded transition-colors text-xs"
                            style={{
                              backgroundColor: '#1a2227',
                              color: '#9ca3af'
                            }}
                            title="Always Active"
                          >
                            <div className="w-3 h-3 rounded-full border-2" style={{
                              borderColor: '#6b7280',
                              backgroundColor: 'transparent'
                            }}/>
                          </button>
                        </div>
                      </div>

                      {/* Bezier values grid */}
                      <div className="space-y-2 mb-3">
                        <div className="grid grid-cols-2 gap-2">
                          <div className="flex items-center justify-between text-xs">
                            <span className="text-gray-500">X0, Y0</span>
                            <span className="font-mono text-gray-300 bg-[#0f1416] px-2 py-0.5 rounded">
                              {bez.x0}, {bez.y0}
                            </span>
                          </div>
                          <div className="flex items-center justify-between text-xs">
                            <span className="text-gray-500">X1, Y1</span>
                            <span className="font-mono text-gray-300 bg-[#0f1416] px-2 py-0.5 rounded">
                              {bez.x1}, {bez.y1}
                            </span>
                          </div>
                        </div>

                        {/* Visual representation */}
                        <div className="bg-[#0f1416] rounded p-2 h-12 relative overflow-hidden">
                          <svg viewBox="0 0 100 40" className="w-full h-full" preserveAspectRatio="none">
                            <path
                              d={`M 0,40 C ${parseFloat(bez.x0) * 100},${40 - parseFloat(bez.y0) * 40} ${parseFloat(bez.x1) * 100},${40 - parseFloat(bez.y1) * 40} 100,0`}
                              stroke="#60a5fa"
                              strokeWidth="2"
                              fill="none"
                              opacity="0.6"
                            />
                          </svg>
                        </div>
                      </div>

                      {/* Footer actions */}
                      <div className="flex gap-2 pt-2 border-t" style={{ borderColor: '#1e272b' }}>
                        <button
                          onClick={() => setEditingBezier(bez)}
                          className="flex-1 px-3 py-1.5 rounded text-xs transition-colors hover:opacity-80 flex items-center justify-center gap-1"
                          style={{ backgroundColor: '#1a2227', color: '#9ca3af' }}
                        >
                          <Edit2 size={12} />
                          Edit
                        </button>
                        <button
                          onClick={() => deleteBezier(bez.name)}
                          className="px-3 py-1.5 rounded transition-colors hover:opacity-80 flex items-center justify-center"
                          style={{ backgroundColor: '#1a2227', color: '#ef4444' }}
                        >
                          <Trash2 size={12} />
                        </button>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </>
          )}
        </div>
      </div>

      {/* Animation Edit Modal */}
      {editingAnim && (
        <div className="fixed inset-0 flex items-center justify-center p-6 z-50" style={{ backgroundColor: 'rgba(0, 0, 0, 0.8)' }}>
          <div className="rounded-lg p-6 max-w-2xl w-full border" style={{ backgroundColor: '#141b1e', borderColor: '#1e272b' }}>
            <h3 className="text-xl font-semibold text-gray-100 mb-4">
              {config.animations.find(a => a.name === editingAnim.name) ? 'Edit' : 'Add'} Animation
            </h3>
            <div className="space-y-4">
              <div>
                <label className="block text-sm text-gray-400 mb-2">Name</label>
                <Select
                  value={editingAnim.name}
                  onValueChange={(newName) => {
                    setEditingAnim({
                      ...editingAnim,
                      name: newName,
                      style: ''
                    });
                  }}
                >
                  <SelectTrigger className="w-full bg-[#1e272b] border border-[#374151] text-gray-200 text-sm">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent
                    className="bg-[#0f1419] border border-[#374151] text-gray-200 max-h-[300px] overflow-y-auto"
                    position="popper"
                    side="bottom"
                    align="start"
                  >
                    {ANIMATION_NAMES.map(name => (
                      <SelectItem
                        key={name}
                        value={name}
                        className="cursor-pointer hover:bg-[#1e272b] focus:bg-[#1e272b]"
                      >
                        {name}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div>
                <label className="flex items-center gap-2 text-sm text-gray-400">
                  <input
                    type="checkbox"
                    checked={editingAnim.enabled}
                    onChange={(e) => setEditingAnim({ ...editingAnim, enabled: e.target.checked })}
                    className="w-4 h-4 rounded"
                  />
                  Enabled
                </label>
              </div>
              {editingAnim.enabled && (
                <>
                  <div>
                    <label className="block text-sm font-medium text-gray-300 mb-1">Speed</label>
                    <input
                      type="text"
                      value={editingAnim.speed}
                      onChange={(e) => setEditingAnim({ ...editingAnim, speed: e.target.value })}
                      className="w-full px-3 py-2 rounded text-sm border"
                      style={{ backgroundColor: '#1e272b', borderColor: '#374151', color: '#e5e7eb' }}
                      placeholder="e.g., 5, 10"
                    />
                  </div>
                  <div>
                    <label className="block text-sm text-gray-400 mb-2">Curve</label>
                    <Select
                      value={editingAnim.curve}
                      onValueChange={(value) => setEditingAnim({ ...editingAnim, curve: value })}
                    >
                      <SelectTrigger className="w-full bg-[#1e272b] border border-[#374151] text-gray-200 text-sm">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent
                        className="bg-[#0f1419] border border-[#374151] text-gray-200 max-h-[300px] overflow-y-auto"
                        position="popper"
                        side="bottom"
                        align="start"
                      >
                        {config.beziers.map(b => (
                          <SelectItem
                            key={b.name}
                            value={b.name}
                            className="cursor-pointer hover:bg-[#1e272b] focus:bg-[#1e272b]"
                          >
                            {b.name}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                  <div>
                    <label className="block text-sm text-gray-400 mb-2">
                      Style (optional)
                      {getAvailableStyles(editingAnim.name).length > 0 && (
                        <span className="ml-2 text-xs text-gray-500">
                          Available: {getAvailableStyles(editingAnim.name).join(', ')}
                        </span>
                      )}
                    </label>
                    {getAvailableStyles(editingAnim.name).length > 0 ? (
                      <Select
                        value={editingAnim.style}
                        onValueChange={(value) => setEditingAnim({ ...editingAnim, style: value })}
                      >
                        <SelectTrigger className="w-full bg-[#1e272b] border border-[#374151] text-gray-200 text-sm">
                          <SelectValue placeholder="None" />
                        </SelectTrigger>
                        <SelectContent
                          className="bg-[#0f1419] border border-[#374151] text-gray-200 max-h-[300px] overflow-y-auto"
                          position="popper"
                          side="bottom"
                          align="start"
                        >
                          <SelectItem value="" className="cursor-pointer hover:bg-[#1e272b] focus:bg-[#1e272b]">
                            None
                          </SelectItem>
                          {getAvailableStyles(editingAnim.name).map(style => (
                            <SelectItem
                              key={style}
                              value={style}
                              className="cursor-pointer hover:bg-[#1e272b] focus:bg-[#1e272b]"
                            >
                              {style}
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                    ) : (
                      <input
                        type="text"
                        value={editingAnim.style}
                        onChange={(e) => setEditingAnim({ ...editingAnim, style: e.target.value })}
                        className="w-full px-3 py-2 rounded text-sm border"
                        style={{ backgroundColor: '#1e272b', borderColor: '#374151', color: '#e5e7eb' }}
                        placeholder="No predefined styles for this animation"
                        disabled
                      />
                    )}
                  </div>
                </>
              )}
            </div>
            <div className="flex gap-2 mt-6">
              <button
                onClick={saveAnimation}
                className="flex-1 rounded px-4 py-2 text-sm transition-colors hover:opacity-80"
                style={{ backgroundColor: '#1e3a5f', color: '#fff' }}
              >
                Save
              </button>
              <button
                onClick={() => setEditingAnim(null)}
                className="flex-1 rounded px-4 py-2 text-sm transition-colors hover:opacity-80"
                style={{ backgroundColor: '#1a2227', color: '#9ca3af' }}
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Bezier Edit Modal */}
      {editingBezier && (
        <div className="fixed inset-0 flex items-center justify-center p-6 z-50" style={{ backgroundColor: 'rgba(0, 0, 0, 0.8)' }}>
          <div className="rounded-lg p-6 max-w-2xl w-full border" style={{ backgroundColor: '#141b1e', borderColor: '#1e272b' }}>
            <h3 className="text-xl font-semibold text-gray-100 mb-4">
              {config.beziers.find(b => b.name === editingBezier.name) ? 'Edit' : 'Add'} Bezier Curve
            </h3>
            <div className="space-y-4">
              <div>
                <label className="block text-sm text-gray-400 mb-2">Name</label>
                <Select
                  value={editingBezier.name}
                  onValueChange={(value) => {
                    setEditingBezier({ ...editingBezier, name: value });
                    if (value !== '') {
                      setCustomBezierName('');
                    }
                  }}
                >
                  <SelectTrigger className="w-full bg-[#1e272b] border border-[#374151] text-gray-200 text-sm">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent
                    className="bg-[#0f1419] border border-[#374151] text-gray-200 max-h-[300px] overflow-y-auto"
                    position="popper"
                    side="bottom"
                    align="start"
                  >
                    {config.beziers.map(b => (
                      <SelectItem
                        key={b.name}
                        value={b.name}
                        className="cursor-pointer hover:bg-[#1e272b] focus:bg-[#1e272b]"
                      >
                        {b.name}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              {/* Visual curve preview */}
              <div className="bg-[#0f1416] rounded p-4 border" style={{ borderColor: '#1e272b' }}>
                <div className="text-xs text-gray-400 mb-2 text-center">Preview</div>
                <div className="h-32 relative">
                  <svg viewBox="0 0 100 100" className="w-full h-full" preserveAspectRatio="none">
                    {/* Grid */}
                    <defs>
                      <pattern id="grid" width="10" height="10" patternUnits="userSpaceOnUse">
                        <path d="M 10 0 L 0 0 0 10" fill="none" stroke="#2a3439" strokeWidth="0.5"/>
                      </pattern>
                    </defs>
                    <rect width="100" height="100" fill="url(#grid)" />

                    {/* Bezier curve */}
                    <path
                      d={`M 0,100 C ${parseFloat(editingBezier.x0 || '0') * 100},${100 - parseFloat(editingBezier.y0 || '0') * 100} ${parseFloat(editingBezier.x1 || '1') * 100},${100 - parseFloat(editingBezier.y1 || '1') * 100} 100,0`}
                      stroke="#60a5fa"
                      strokeWidth="2"
                      fill="none"
                    />
                  </svg>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm text-gray-400 mb-2">
                    X0 <span className="text-xs text-gray-500">(0.0 - 1.0)</span>
                  </label>
                  <input
                    type="range"
                    min="0"
                    max="1"
                    step="0.01"
                    value={editingBezier.x0}
                    onChange={(e) => setEditingBezier({ ...editingBezier, x0: e.target.value })}
                    className="w-full mb-2"
                  />
                  <input
                    type="text"
                    value={editingBezier.x0}
                    onChange={(e) => setEditingBezier({ ...editingBezier, x0: e.target.value })}
                    className="w-full px-3 py-2 rounded text-sm border"
                    style={{ backgroundColor: '#1e272b', borderColor: '#374151', color: '#e5e7eb' }}
                    placeholder="0.0"
                  />
                </div>
                <div>
                  <label className="block text-sm text-gray-400 mb-2">
                    Y0 <span className="text-xs text-gray-500">(0.0 - 1.0)</span>
                  </label>
                  <input
                    type="range"
                    min="0"
                    max="1"
                    step="0.01"
                    value={editingBezier.y0}
                    onChange={(e) => setEditingBezier({ ...editingBezier, y0: e.target.value })}
                    className="w-full mb-2"
                  />
                  <input
                    type="text"
                    value={editingBezier.y0}
                    onChange={(e) => setEditingBezier({ ...editingBezier, y0: e.target.value })}
                    className="w-full px-3 py-2 rounded text-sm border"
                    style={{ backgroundColor: '#1e272b', borderColor: '#374151', color: '#e5e7eb' }}
                    placeholder="0.0"
                  />
                </div>
                <div>
                  <label className="block text-sm text-gray-400 mb-2">
                    X1 <span className="text-xs text-gray-500">(0.0 - 1.0)</span>
                  </label>
                  <input
                    type="range"
                    min="0"
                    max="1"
                    step="0.01"
                    value={editingBezier.x1}
                    onChange={(e) => setEditingBezier({ ...editingBezier, x1: e.target.value })}
                    className="w-full mb-2"
                  />
                  <input
                    type="text"
                    value={editingBezier.x1}
                    onChange={(e) => setEditingBezier({ ...editingBezier, x1: e.target.value })}
                    className="w-full px-3 py-2 rounded text-sm border"
                    style={{ backgroundColor: '#1e272b', borderColor: '#374151', color: '#e5e7eb' }}
                    placeholder="1.0"
                  />
                </div>
                <div>
                  <label className="block text-sm text-gray-400 mb-2">
                    Y1 <span className="text-xs text-gray-500">(0.0 - 1.0)</span>
                  </label>
                  <input
                    type="range"
                    min="0"
                    max="1"
                    step="0.01"
                    value={editingBezier.y1}
                    onChange={(e) => setEditingBezier({ ...editingBezier, y1: e.target.value })}
                    className="w-full mb-2"
                  />
                  <input
                    type="text"
                    value={editingBezier.y1}
                    onChange={(e) => setEditingBezier({ ...editingBezier, y1: e.target.value })}
                    className="w-full px-3 py-2 rounded text-sm border"
                    style={{ backgroundColor: '#1e272b', borderColor: '#374151', color: '#e5e7eb' }}
                    placeholder="1.0"
                  />
                </div>
              </div>
            </div>
            <div className="flex gap-2 mt-6">
              <button
                onClick={saveBezier}
                className="flex-1 rounded px-4 py-2 text-sm transition-colors hover:opacity-80"
                style={{ backgroundColor: '#1e3a5f', color: '#fff' }}
              >
                Save
              </button>
              <button
                onClick={() => {
                  setEditingBezier(null);
                  setCustomBezierName('');
                }}
                className="flex-1 rounded px-4 py-2 text-sm transition-colors hover:opacity-80"
                style={{ backgroundColor: '#1a2227', color: '#9ca3af' }}
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}

    </div>
  );
};

export default AnimationsView;
