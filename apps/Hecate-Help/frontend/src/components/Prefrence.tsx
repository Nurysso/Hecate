import React, { useState, useEffect } from 'react';
import { Terminal, Globe, Save, RotateCcw, Check, AlertCircle, Info, Copy, CircleUserIcon } from 'lucide-react';
import { GetPreferences, UpdatePreferences, ValidatePreferences } from '../../wailsjs/go/main/App';
import { Toaster } from './ui/sonner';
import { toast } from 'sonner';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from './ui/select';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from './ui/dialog';

interface PreferencesConfig {
  term: string;
  browser: string;
  shell: string;
  profile: string;
}

const PreferencesView: React.FC = () => {
  const [config, setConfig] = useState<PreferencesConfig>({
    term: 'kitty',
    browser: 'firefox',
    shell: 'fish',
    profile: 'minimal'
  });

  const [originalConfig, setOriginalConfig] = useState<PreferencesConfig>(config);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [showShellDialog, setShowShellDialog] = useState(false);
  const [pendingShell, setPendingShell] = useState('');
  const [copiedCommand, setCopiedCommand] = useState(false);
  const [message, setMessage] = useState<{ type: 'success' | 'error' | null; text: string }>({
    type: null,
    text: ''
  });
type BrowserOption = 'firefox' | 'chromium' | 'brave' | 'google-chrome';
  const terminals = [
    { value: 'kitty', label: 'Kitty' },
    { value: 'alacritty', label: 'Alacritty' },
    { value: 'ghostty', label: 'Ghostty' },
    { value: 'foot', label: 'Foot' }
  ];

  const browsers = [
    { value: 'firefox', label: 'Firefox' },
    { value: 'chromium', label: 'Chromium' },
    { value: 'brave-bin', label: 'Brave' },
    { value: 'google-chrome-stable', label: 'Google Chrome' },
    // { value: 'vivaldi', label: 'Vivaldi' }
  ];

  const shells = [
    { value: 'fish', label: 'Fish' },
    { value: 'zsh', label: 'Zsh' },
    { value: 'bash', label: 'Bash' }
  ];

  useEffect(() => {
    loadPreferences();
  }, []);

const loadPreferences = async () => {
  try {
    setLoading(true);
    const prefs = await GetPreferences();
    setConfig(prefs);
    setOriginalConfig(prefs);
  } catch (error) {
    toast.error(`Failed to load preferences: ${error}`);
  } finally {
    setLoading(false);
  }
};

  const handleShellChange = (shell: string) => {
    setPendingShell(shell);
    setShowShellDialog(true);
  };

  const confirmShellChange = () => {
    setConfig({ ...config, shell: pendingShell });
    setShowShellDialog(false);
    setPendingShell('');
  };

  const copyCommand = async () => {
    const command = `chsh -s $(which ${pendingShell})`;
    try {
      await navigator.clipboard.writeText(command);
      setCopiedCommand(true);
      setTimeout(() => setCopiedCommand(false), 2000);
    } catch (err) {
      console.error('Failed to copy command:', err);
    }
  };

const handleSave = async () => {
  try {
    setSaving(true);

    // Validate preferences
    await ValidatePreferences(config);

    // Update preferences
    await UpdatePreferences(config);

    setOriginalConfig(config);
    toast.success('Preferences saved successfully');
  } catch (error) {
    toast.error(`Failed to save preferences: ${error}`);
  } finally {
    setSaving(false);
  }
};

  const handleReset = () => {
    setConfig(originalConfig);
    setMessage({ type: null, text: '' });
  };

  const hasChanges = JSON.stringify(config) !== JSON.stringify(originalConfig);

  if (loading) {
    return (
        <div className="flex items-center justify-center min-h-screen bg-gray-950">
  <div className="text-center">
    <div className="animate-spin rounded-full h-12 w-12 border-2 border-gray-700 border-t-gray-400 mx-auto mb-4"></div>
          <p className="text-gray-400 text-sm">Loading preferences...</p>
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


        {/* Message Banner */}
        {message.type && (
          <div className={`mb-4 p-3 rounded border text-sm flex items-center gap-2 ${
            message.type === 'success'
              ? 'bg-green-950/50 border-green-900 text-green-400'
              : 'bg-red-950/50 border-red-900 text-red-400'
          }`}>
            {message.type === 'success' ? (
              <Check className="w-4 h-4 flex-shrink-0" />
            ) : (
              <AlertCircle className="w-4 h-4 flex-shrink-0" />
            )}
            <span>{message.text}</span>
          </div>
        )}

        <div className="space-y-4 mb-6">
                  <div className="grid grid-cols-2 gap-4">
          {/* Terminal Selection */}
              <div className="bg-[#141b1e] rounded-lg p-3 border border-[#1e272b]">
            <label className="block text-sm font-medium text-gray-300 mb-3">
              <div className="flex items-center gap-2">
                <Terminal className="w-4 h-4" />
                Terminal Emulator
              </div>
            </label>
<Select
  value={config.term}
  onValueChange={(value: string) =>
    setConfig({ ...config, term: value })
  }
>               <SelectTrigger className="flex-1 bg-gray-800/50 rounded-lg p-2 font-semibold text-white border border-gray-700 focus:border-gray-800/50 focus:ring-0">
                <SelectValue />
              </SelectTrigger>
              <SelectContent className="bg-gray-900 border-gray-800">
                {terminals.map((term) => (
                  <SelectItem
                    key={term.value}
                    value={term.value}
                    className="text-gray-300 focus:bg-gray-800 focus:text-gray-100"
                  >
                    {term.label}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          {/* Browser Selection */}
                          <div className="bg-[#141b1e] rounded-lg p-3 border border-[#1e272b]">
            <label className="block text-sm font-medium text-gray-300 mb-3">
              <div className="flex items-center gap-2">
                <Globe className="w-4 h-4" />
                Web Browser
              </div>
            </label>
<Select
  value={config.browser}
  onValueChange={(value: BrowserOption) =>
    setConfig({ ...config, browser: value })
  }
>               <SelectTrigger className="flex-1 bg-gray-800/50 rounded-lg p-2 font-semibold text-white border border-gray-700 focus:border-gray-800/50 focus:ring-0">
                <SelectValue />
              </SelectTrigger>
              <SelectContent className="bg-gray-900 border-gray-800">
                {browsers.map((browser) => (
                  <SelectItem
                    key={browser.value}
                    value={browser.value}
                    className="text-gray-300 focus:bg-gray-800 focus:text-gray-100"
                  >
                    {browser.label}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          {/* Shell Selection with Warning */}
              <div className="bg-[#141b1e] rounded-lg p-3 border border-[#1e272b]">
            <label className="block text-sm font-medium text-gray-300 mb-3">
              <div className="flex items-center gap-2">
                <Terminal className="w-4 h-4" />
                Default Shell
                <div className="ml-auto flex items-center gap-1 text-xs text-yellow-500">
                  <Info className="w-3 h-3" />
                  Requires manual setup
                </div>
              </div>
            </label>
            <Select value={config.shell} onValueChange={handleShellChange}>
               <SelectTrigger className="flex-1 bg-gray-800/50 rounded-lg p-2 font-semibold text-white border border-gray-700 focus:border-gray-800/50 focus:ring-0">
                <SelectValue />
              </SelectTrigger>
              <SelectContent className="bg-gray-900 border-gray-800">
                {shells.map((shell) => (
                  <SelectItem
                    key={shell.value}
                    value={shell.value}
                    className="text-gray-300 focus:bg-gray-800 focus:text-gray-100"
                  >
                    {shell.label}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
            <p className="text-xs text-gray-600 mt-2">
              Shell changes require running a command in your terminal
            </p>
          </div>
          {/* Profile Section */}
              <div className="bg-[#141b1e] rounded-lg p-3 border border-[#1e272b]">
            <label className="block text-sm font-medium text-gray-300 mb-3">
              <div className="flex items-center gap-2">
                <CircleUserIcon className="w-4 h-4" />
                Profile: currently does nothing
              </div>
            </label>
          </div>
        </div>

        {/* Shell Change Dialog */}
        <Dialog open={showShellDialog} onOpenChange={setShowShellDialog}>
          <DialogContent className="bg-gray-900 border-gray-800 text-gray-100">
            <DialogHeader>
              <DialogTitle className="text-gray-100">Change Default Shell</DialogTitle>
              <DialogDescription className="text-gray-400">
                To change your default shell to <span className="font-mono text-gray-300">{pendingShell}</span>,
                you need to run a command in your terminal.
              </DialogDescription>
            </DialogHeader>
            <div className="space-y-4">
              <div>
                <p className="text-sm text-gray-400 mb-2">Run this command in your terminal:</p>
                <div className="bg-gray-950 border border-gray-800 rounded p-3 font-mono text-sm text-gray-300 flex items-center justify-between gap-2">
                  <code>chsh -s $(which {pendingShell})</code>
                  <button
                    onClick={copyCommand}
                    className="p-1.5 hover:bg-gray-800 rounded text-gray-500 hover:text-gray-300 transition-colors flex-shrink-0"
                    title="Copy command"
                  >
                    {copiedCommand ? (
                      <Check className="w-4 h-4 text-green-400" />
                    ) : (
                      <Copy className="w-4 h-4" />
                    )}
                  </button>
                </div>
              </div>
              <div className="text-xs text-gray-500 space-y-1 bg-gray-950 border border-gray-800 rounded p-3">
                <p>• You may need to enter your password</p>
                <p>• Log out and back in for changes to take effect</p>
                <p>• Make sure {pendingShell} is installed on your system</p>
              </div>
              <div className="flex gap-2 justify-end pt-2">
                <button
                  onClick={() => setShowShellDialog(false)}
                  className="px-4 py-2 text-sm bg-gray-800 hover:bg-gray-700 text-gray-300 rounded border border-gray-700 transition-colors"
                >
                  Cancel
                </button>
                <button
                  onClick={confirmShellChange}
                  className="px-4 py-2 text-sm bg-blue-600 hover:bg-blue-700 text-white rounded border border-blue-600 transition-colors"
                >
                  Update Preference
                </button>
              </div>
            </div>
          </DialogContent>
        </Dialog>
</div>
        {/* Action Buttons */}
        <div className="flex items-center justify-end gap-3 pt-4 border-t border-gray-800">
          <button
            onClick={handleReset}
            disabled={!hasChanges || saving}
            className={`flex items-center gap-2 px-4 py-2 text-sm rounded border transition-colors ${
              hasChanges && !saving
                ? 'bg-gray-900 hover:bg-gray-800 text-gray-300 border-gray-800'
                : 'bg-gray-950 text-gray-700 border-gray-900 cursor-not-allowed'
            }`}
          >
            <RotateCcw className="w-4 h-4" />
            Reset
          </button>

          <button
            onClick={handleSave}
            disabled={!hasChanges || saving}
            className={`flex items-center gap-2 px-5 py-2 text-sm rounded border transition-colors ${
              hasChanges && !saving
                ? 'bg-blue-600 hover:bg-blue-700 text-white border-blue-600'
                : 'bg-gray-950 text-gray-700 border-gray-900 cursor-not-allowed'
            }`}
          >
            {saving ? (
              <>
                <div className="animate-spin rounded-full h-4 w-4 border-2 border-gray-700 border-t-white"></div>
                Saving...
              </>
            ) : (
              <>
                <Save className="w-4 h-4" />
                Save
              </>
            )}
          </button>
        </div>
      </div>
    </div>
  );
};

export default PreferencesView;
