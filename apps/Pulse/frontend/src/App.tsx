import React, { useState, useEffect } from 'react';
import { Activity, Cpu, HardDrive, Thermometer, Zap, Clock, List, LucideIcon } from 'lucide-react';

// Type definitions
interface GTKColors {
  accentColor: string;
  windowBgColor: string;
  windowFgColor: string;
  cardBgColor: string;
}

interface CPUStats {
  usage: number;
  model: string;
  cores: number;
}

interface RAMStats {
  percent: number;
  used: number;
  total: number;
}

interface SwapStats {
  percent: number;
  used: number;
  total: number;
}

interface GPUStats {
  usage: number;
  name: string;
  temp: number;
  memory: number;
}

interface TempStats {
  cpu: number;
  max: number;
}

interface NetworkStats {
  down: string;
  up: string;
}

interface DiskStats {
  mountPoint: string;
  device: string;
  total: number;
  used: number;
  percent: number;
  fileSystem: string;
}

interface SystemStats {
  uptime: string;
  processCount: number;
  cpu: CPUStats;
  ram: RAMStats;
  swap: SwapStats;
  gpu: GPUStats;
  temp: TempStats;
  network: NetworkStats;
  disks: DiskStats[];
}

// Extend Window interface
declare global {
  interface Window {
    go: {
      main: {
        App: {
          GetEnhancedSystemStats: () => Promise<SystemStats>;
          GetGTKColors: () => Promise<GTKColors>;
        };
      };
    };
  }
}

// Component prop types
interface CircularProgressProps {
  value: number;
  size?: number;
  strokeWidth?: number;
  color?: string;
  children: React.ReactNode;
}

interface StatCardProps {
  title: string;
  icon: LucideIcon;
  children: React.ReactNode;
  color?: string;
}

interface ProgressBarProps {
  value: number;
  color?: string;
  label: string;
}

const SystemMonitor = () => {
  const [stats, setStats] = useState<SystemStats | null>(null);
  const [gtkColors, setGtkColors] = useState<GTKColors | null>(null);

  useEffect(() => {
    const fetchGTKColors = async () => {
      try {
        const colors = await window.go.main.App.GetGTKColors();
        setGtkColors(colors);
      } catch (err) {
        console.error('Failed to fetch GTK colors:', err);
      }
    };
    fetchGTKColors();
    const colorInterval = setInterval(fetchGTKColors, 5000);
    return () => clearInterval(colorInterval);
  }, []);

  useEffect(() => {
    const fetchStats = async () => {
      try {
        const data = await window.go.main.App.GetEnhancedSystemStats();
        setStats(data);
      } catch (err) {
        console.error('Failed to fetch stats:', err);
      }
    };
    fetchStats();
    const statsInterval = setInterval(fetchStats, 1000);
    return () => clearInterval(statsInterval);
  }, []);

  if (!stats || !gtkColors) {
    return (
      <div className="w-full h-screen flex items-center justify-center"
           style={{ backgroundColor: '#0f1416', color: '#dee3e6' }}>
        Loading...
      </div>
    );
  }

  const accent = gtkColors.accentColor;
  const bg = gtkColors.windowBgColor;
  const fg = gtkColors.windowFgColor;
  const cardBg = gtkColors.cardBgColor;

  const CircularProgress: React.FC<CircularProgressProps> = ({
    value,
    size = 120,
    strokeWidth = 8,
    color = accent,
    children
  }) => {
    const radius = (size - strokeWidth) / 2;
    const circumference = 2 * Math.PI * radius;
    const offset = circumference - (value / 100) * circumference;

    return (
      <div className="relative" style={{ width: size, height: size }}>
        <svg width={size} height={size} className="transform -rotate-90">
          <circle
            cx={size / 2}
            cy={size / 2}
            r={radius}
            stroke="rgba(255,255,255,0.1)"
            strokeWidth={strokeWidth}
            fill="none"
          />
          <circle
            cx={size / 2}
            cy={size / 2}
            r={radius}
            stroke={color}
            strokeWidth={strokeWidth}
            fill="none"
            strokeDasharray={circumference}
            strokeDashoffset={offset}
            strokeLinecap="round"
            style={{ transition: 'stroke-dashoffset 0.5s ease' }}
          />
        </svg>
        <div className="absolute inset-0 flex items-center justify-center">
          {children}
        </div>
      </div>
    );
  };

  const StatCard: React.FC<StatCardProps> = ({ title, icon: Icon, children, color = accent }) => (
    <div
      className="rounded-lg p-4 backdrop-blur-sm"
      style={{
        backgroundColor: `${cardBg}cc`,
        border: `1px solid ${color}30`
      }}
    >
      <div className="flex items-center gap-2 mb-3">
        <Icon size={18} style={{ color }} />
        <h3 className="font-semibold text-sm" style={{ color: fg }}>{title}</h3>
      </div>
      {children}
    </div>
  );

  const ProgressBar: React.FC<ProgressBarProps> = ({ value, color = accent, label }) => (
    <div className="space-y-1">
      <div className="flex justify-between text-xs" style={{ color: `${fg}cc` }}>
        <span>{label}</span>
        <span>{Math.round(value)}%</span>
      </div>
      <div className="h-2 rounded-full overflow-hidden" style={{ backgroundColor: 'rgba(255,255,255,0.1)' }}>
        <div
          className="h-full rounded-full transition-all duration-500"
          style={{
            width: `${value}%`,
            backgroundColor: color,
            boxShadow: `0 0 10px ${color}80`
          }}
        />
      </div>
    </div>
  );

  return (
    <div className="w-full min-h-screen p-6 overflow-auto" style={{ backgroundColor: bg, color: fg }}>
      {/* Header */}
      <div className="mb-6">
        <h1 className="text-3xl font-bold mb-2" style={{ color: accent }}>System Monitor</h1>
        <div className="flex gap-4 text-sm" style={{ color: `${fg}99` }}>
          <div className="flex items-center gap-2">
            <Clock size={14} />
            <span>Uptime: {stats.uptime}</span>
          </div>
          <div className="flex items-center gap-2">
            <List size={14} />
            <span>Processes: {stats.processCount}</span>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* CPU Section */}
        <StatCard title="Processor" icon={Cpu} color={accent}>
          <div className="flex items-center justify-between">
            <CircularProgress value={stats.cpu.usage} color={accent} size={100}>
              <div className="text-center">
                <div className="text-2xl font-bold" style={{ color: fg }}>
                  {Math.round(stats.cpu.usage)}%
                </div>
                <div className="text-xs" style={{ color: `${fg}80` }}>CPU</div>
              </div>
            </CircularProgress>
            <div className="flex-1 ml-4 space-y-2">
              <div className="text-xs" style={{ color: `${fg}cc` }}>
                <div className="font-medium">{stats.cpu.model}</div>
                <div className="mt-1" style={{ color: `${fg}80` }}>{stats.cpu.cores} Cores</div>
              </div>
            </div>
          </div>
        </StatCard>

        {/* Memory Section */}
        <StatCard title="Memory" icon={Activity} color="#8b5cf6">
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <CircularProgress value={stats.ram.percent} color="#8b5cf6" size={100}>
                <div className="text-center">
                  <div className="text-2xl font-bold" style={{ color: fg }}>
                    {Math.round(stats.ram.percent)}%
                  </div>
                  <div className="text-xs" style={{ color: `${fg}80` }}>RAM</div>
                </div>
              </CircularProgress>
              <div className="flex-1 ml-4">
                <div className="text-xs space-y-1" style={{ color: `${fg}cc` }}>
                  <div>Used: {Math.round(stats.ram.used)} MB</div>
                  <div>Total: {Math.round(stats.ram.total)} MB</div>
                  {stats.swap.total > 0 && (
                    <div className="mt-2 pt-2" style={{ borderTop: `1px solid ${fg}20` }}>
                      <div className="font-medium mb-1">Swap</div>
                      <ProgressBar
                        value={stats.swap.percent}
                        color="#10b981"
                        label={`${Math.round(stats.swap.used)} / ${Math.round(stats.swap.total)} MB`}
                      />
                    </div>
                  )}
                </div>
              </div>
            </div>
          </div>
        </StatCard>

        {/* GPU Section */}
        <StatCard title="Graphics" icon={Zap} color="#ec4899">
          <div className="flex items-center justify-between">
            <CircularProgress value={stats.gpu.usage} color="#ec4899" size={100}>
              <div className="text-center">
                <div className="text-2xl font-bold" style={{ color: fg }}>
                  {Math.round(stats.gpu.usage)}%
                </div>
                <div className="text-xs" style={{ color: `${fg}80` }}>GPU</div>
              </div>
            </CircularProgress>
            <div className="flex-1 ml-4 space-y-2">
              <div className="text-xs" style={{ color: `${fg}cc` }}>
                <div className="font-medium">{stats.gpu.name}</div>
                {stats.gpu.temp > 0 && (
                  <div className="mt-1" style={{ color: `${fg}80` }}>
                    Temp: {Math.round(stats.gpu.temp)}°C
                  </div>
                )}
                {stats.gpu.memory > 0 && (
                  <div style={{ color: `${fg}80` }}>
                    VRAM: {Math.round(stats.gpu.memory)} MB
                  </div>
                )}
              </div>
            </div>
          </div>
        </StatCard>

        {/* Temperature */}
        <StatCard title="Temperature" icon={Thermometer} color="#f43f5e">
          <div className="flex items-center justify-between">
            <CircularProgress value={(stats.temp.cpu / stats.temp.max) * 100} color="#f43f5e" size={100}>
              <div className="text-center">
                <div className="text-2xl font-bold" style={{ color: fg }}>
                  {Math.round(stats.temp.cpu)}°
                </div>
                <div className="text-xs" style={{ color: `${fg}80` }}>CPU</div>
              </div>
            </CircularProgress>
            <div className="flex-1 ml-4">
              <div className="text-xs space-y-2" style={{ color: `${fg}cc` }}>
                <div>Current: {Math.round(stats.temp.cpu)}°C</div>
                <div>Max Safe: {Math.round(stats.temp.max)}°C</div>
                <div className="mt-2">
                  <ProgressBar
                    value={(stats.temp.cpu / stats.temp.max) * 100}
                    color="#f43f5e"
                    label="Temperature"
                  />
                </div>
              </div>
            </div>
          </div>
        </StatCard>

        {/* Network */}
        <StatCard title="Network" icon={Activity} color="#06b6d4">
          <div className="space-y-3">
            <div className="flex justify-between items-center text-sm">
              <span style={{ color: `${fg}cc` }}>↓ Download</span>
              <span className="font-mono font-bold" style={{ color: accent }}>
                {stats.network.down}
              </span>
            </div>
            <div className="flex justify-between items-center text-sm">
              <span style={{ color: `${fg}cc` }}>↑ Upload</span>
              <span className="font-mono font-bold" style={{ color: accent }}>
                {stats.network.up}
              </span>
            </div>
          </div>
        </StatCard>

        {/* Storage Devices */}
        <StatCard title="Storage Devices" icon={HardDrive} color="#f59e0b">
          <div className="space-y-3">
            {stats.disks.map((disk: DiskStats, idx: number) => (
              <div key={idx} className="space-y-1">
                <div className="flex justify-between text-xs" style={{ color: `${fg}cc` }}>
                  <span className="font-medium">{disk.mountPoint}</span>
                  <span>{Math.round(disk.used)} / {Math.round(disk.total)} GB</span>
                </div>
                <ProgressBar
                  value={disk.percent}
                  color={disk.percent > 90 ? '#f43f5e' : '#f59e0b'}
                  label={disk.device}
                />
                <div className="text-xs" style={{ color: `${fg}60` }}>
                  {disk.fileSystem}
                </div>
              </div>
            ))}
          </div>
        </StatCard>
      </div>
    </div>
  );
};

export default SystemMonitor;
