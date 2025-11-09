// ServiceCard.tsx
interface ServiceInfo {
  name: string;
  description: string;
}

interface ServiceCardProps {
  service: ServiceInfo;
  onClick: () => void;
}

const ServiceCard: React.FC<ServiceCardProps> = ({ service, onClick }) => {
  const getServiceIcon = (name: string) => {
    const icons: Record<string, string> = {
      filesearch: '🔍',
      organizer: '📁',
      linter: '✨',
      ocr: '📸',
      converter: '🔄',
      llm: '🤖',
    };
    return icons[name] || '⚡';
  };

  return (
    <button
      onClick={onClick}
      className="p-4 bg-slate-800/50 hover:bg-slate-800 border border-slate-700 hover:border-blue-600 rounded-lg transition-all text-left group"
    >
      <div className="flex items-start gap-3">
        <span className="text-2xl">{getServiceIcon(service.name)}</span>
        <div>
          <h3 className="font-semibold text-white group-hover:text-blue-400 transition-colors capitalize">
            {service.name}
          </h3>
          <p className="text-sm text-slate-400 mt-1">{service.description}</p>
        </div>
      </div>
    </button>
  );
};

export default ServiceCard ;
