import React from 'react';
import { LucideIcon } from 'lucide-react';

interface DummyPageProps {
  title: string;
  icon: LucideIcon;
}

const DummyPage: React.FC<DummyPageProps> = ({ title, icon: Icon }) => (
  <div className="flex-1 flex items-center justify-center" style={{ backgroundColor: '#0f1416' }}>
    <div className="text-center">
      <div
        className="inline-flex items-center justify-center w-16 h-16 rounded-full mb-3"
        style={{ backgroundColor: '#1a2227' }}
      >
        <Icon size={32} className="text-gray-500" />
      </div>
      <h2 className="text-lg font-medium text-gray-200 mb-1">{title}</h2>
      <p className="text-sm text-gray-500">Coming soon...</p>
    </div>
  </div>
);

export default DummyPage;
