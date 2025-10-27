import React, { useEffect, useState } from 'react';
import { RefreshCw, Monitor, Cpu, HardDrive, Terminal, Clock, Box, Activity } from 'lucide-react';
import { GetSystemInfo } from '../../wailsjs/go/main/App';


interface SystemInfoData {
  hyprlandVersion: string;
  kernel: string;
  os: string;
  hostname: string;
  cpu: string;
  memory: string;
  gpu: string;
  gpuDriver: string;
  uptime: string;
//   architecture: string;
  shell: string;
//   resolution: string;
}

const SettingsView: React.FC = () => {
  const [systemInfo, setSystemInfo] = useState<SystemInfoData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

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
<div className="min-h-screen bg-gray-950 px-12 py-16">
    {/* Header */}
        <div className='mb-10'>
      <h1 className="font-black text-gray-100 text-5xl mb-6 tracking-tight">System</h1>
      <div className="flex items-center gap-4 text-base text-gray-400">
        <span className="font-semibold">{systemInfo.hostname}</span>
        <span>·</span>
        <span className="uppercase">{systemInfo.uptime}</span>
      </div>
    </div>
  <div className="max-w-4xl mx-auto space-y-10">
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
          {/* <span className="text-sm text-gray-500">{systemInfo.kernel}</span> */}
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
    {/* GPU, Shell, Arch, Resolution */}
    {/* <div className="flex gap-4 mt-4">
      <div>
        <span className="uppercase text-xs text-gray-500 font-semibold block mb-2 tracking-wider">Graphics</span>
        <span className="font-medium text-gray-100 text-base">{systemInfo.gpu}</span>
        <div className="text-gray-500 text-xs">{systemInfo.gpuDriver}</div>
      </div>
      <div>
        <span className="uppercase text-xs text-gray-500 font-semibold block mb-2 tracking-wider">Shell</span>
        <span className="font-medium text-gray-100 text-base">{systemInfo.shell}</span>
      </div>
    //   NO LONGER SUPPORTED
      <div>
        <span className="uppercase text-xs text-gray-500 font-semibold block mb-2 tracking-wider">Arch</span>
        <span className="font-medium text-gray-100 text-base">{systemInfo.architecture}</span>
      </div>
      <div>
        <span className="uppercase text-xs text-gray-500 font-semibold block mb-2 tracking-wider">Resolution</span>
        <span className="font-medium text-gray-100 text-base">{systemInfo.resolution}</span>
      </div>
    </div> */}
  </div>
</div>

  );
};

export default SettingsView;
