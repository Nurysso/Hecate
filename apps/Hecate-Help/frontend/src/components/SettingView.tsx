import React, { useEffect, useState } from 'react';
import { GetSystemInfo, LaunchWaypaper } from '../../wailsjs/go/main/App';
import { Image, RefreshCw } from 'lucide-react';

interface SystemInfoData {
  os: string;
  hostname: string;
  cpu: string;
  memory: string;
  uptime: string;
  wallpaperBase64: string;
}

const SettingsView: React.FC = () => {
  const [systemInfo, setSystemInfo] = useState<SystemInfoData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [launchingWaypaper, setLaunchingWaypaper] = useState(false);

  useEffect(() => {
    loadSystemInfo();
  }, []);

  const loadSystemInfo = async () => {
    try {
      setLoading(true);
      const info = await GetSystemInfo();
      setSystemInfo(info);
      setError(null);
    } catch (err) {
      setError('Failed to load system information');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const handleLaunchWaypaper = async () => {
    try {
      setLaunchingWaypaper(true);
      await LaunchWaypaper();
      // Optionally reload after a delay to get new wallpaper
      setTimeout(() => {
        loadSystemInfo();
      }, 1000);
    } catch (err) {
      console.error('Failed to launch waypaper:', err);
    } finally {
      setLaunchingWaypaper(false);
    }
  };

  if (loading) {
    return (
      <div className="min-h-full bg-gray-950 flex items-center justify-center">
        <div className="text-center space-y-3">
          <div className="w-8 h-8 border-2 border-gray-700 border-t-gray-400 rounded-full mx-auto" style={{ animation: 'spin 1s linear infinite' }}></div>
          <p className="text-xs text-gray-600">Loading...</p>
        </div>
      </div>
    );
  }

  if (error || !systemInfo) {
    return (
      <div className="min-h-full bg-gray-950 flex items-center justify-center">
        <div className="text-center space-y-4">
          <p className="text-sm text-gray-500">{error || 'Failed to load'}</p>
          <button
            onClick={loadSystemInfo}
            className="px-4 py-1.5 text-xs bg-[#141b1e] hover:bg-gray-800 text-gray-300 rounded"
          >
            Retry
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen">
      {/* Header */}
      <div className='mb-10 p-5 m-2'>
        {/* <h1 className="font-black text-gray-100 text-5xl mb-6 tracking-tight">System</h1> */}
        <div className="flex items-center gap-4 text-base text-gray-400">
          <span className="font-semibold">{systemInfo.hostname}</span>
          <span>·</span>
          <span className="uppercase">{systemInfo.uptime}</span>
        </div>
      </div>

      <div className="max-w-4xl mx-auto space-y-10">
        {/* Wallpaper Section */}
        <div className="bg-[#141b1e] rounded-lg overflow-hidden shadow-md">
          <div className="p-7 pb-4">
            <div className="flex items-center justify-between mb-4">
              <span className="uppercase font-semibold text-gray-500 text-xs tracking-wide">Current Wallpaper</span>
              <button
                onClick={handleLaunchWaypaper}
                disabled={launchingWaypaper}
                className="px-4 py-2 bg-[#1e3a5f] hover:bg-[#2a4a75] text-gray-100 rounded-lg text-sm font-medium transition-colors flex items-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                <Image size={16} />
                {launchingWaypaper ? 'Launching...' : 'Change Wallpaper'}
              </button>
            </div>
          </div>

          {systemInfo.wallpaperBase64 ? (
            <div className="relative aspect-video bg-gray-900">
              <img
                src={systemInfo.wallpaperBase64}
                alt="Current wallpaper"
                className="w-full h-full object-cover"
              />
              <button
                onClick={loadSystemInfo}
                className="absolute top-4 right-4 p-2 bg-black/50 hover:bg-black/70 text-white rounded-lg backdrop-blur-sm transition-colors"
                title="Refresh wallpaper"
              >
                <RefreshCw size={16} />
              </button>
            </div>
          ) : (
            <div className="aspect-video bg-gray-900 flex items-center justify-center">
              <div className="text-center space-y-2">
                <Image size={28} className="mx-auto text-gray-700" />
                <p className="text-sm text-gray-600">No wallpaper found</p>
              </div>
            </div>
          )}
        </div>

        {/* Grid */}
        <div className="gap-3 grid grid-cols-1 md:grid-cols-2">
          {/* Window Manager */}
          <div className="bg-[#141b1e] p-7 rounded-lg flex flex-col shadow-md">
            <span className="uppercase font-semibold text-gray-500 text-xs mb-3 tracking-wide">Window Manager</span>
            <span className="font-semibold text-xl text-gray-100 mb-1">Hyprland</span>
          </div>

          {/* Operating System */}
          <div className="bg-[#141b1e] p-7 rounded-lg flex flex-col shadow-md">
            <span className="uppercase font-semibold text-gray-500 text-xs mb-3 tracking-wide">Operating System</span>
            <div className="flex items-end gap-3">
              <span className="font-semibold text-xl text-gray-100">{systemInfo.os}</span>
            </div>
          </div>

          {/* CPU */}
          <div className="bg-[#141b1e] p-7 rounded-lg flex flex-col shadow-md col-span-1">
            <span className="uppercase font-semibold text-gray-500 text-xs mb-3 tracking-wide">Processor</span>
            <span className="font-medium text-lg text-gray-100">{systemInfo.cpu}</span>
          </div>

          {/* Memory */}
          <div className="bg-[#141b1e] p-7 rounded-lg flex flex-col shadow-md col-span-1">
            <span className="uppercase font-semibold text-gray-500 text-xs mb-3 tracking-wide">Memory</span>
            <span className="font-semibold text-xl text-gray-100">{systemInfo.memory}</span>
          </div>
        </div>
      </div>
    </div>
  );
};

export default SettingsView;
