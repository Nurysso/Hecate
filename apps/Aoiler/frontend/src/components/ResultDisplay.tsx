// ResultDisplay.tsx
interface QueryResponse {
  success: boolean;
  service: string;
  result: any;
  error?: string;
}

interface ResultDisplayProps {
  response: QueryResponse;
}

const ResultDisplay: React.FC<ResultDisplayProps> = ({ response }) => {
  const renderResult = () => {
    if (!response.success) {
      return (
        <div className="p-4 bg-red-900/20 border border-red-800 rounded-lg">
          <p className="text-red-400 font-medium mb-1">Error</p>
          <p className="text-red-300 text-sm">{response.error}</p>
        </div>
      );
    }

    // Handle different result types
    if (response.service === 'filesearch') {
      const result = response.result;
      if (result.found) {
        return (
          <div className="p-4 bg-green-900/20 border border-green-800 rounded-lg">
            <p className="text-green-400 font-medium mb-2">File Found</p>
            <p className="text-white mb-1">
              <span className="text-slate-400">Path:</span> {result.path}
            </p>
            <p className="text-sm text-slate-400">Type: {result.type}</p>
          </div>
        );
      } else {
        return (
          <div className="p-4 bg-yellow-900/20 border border-yellow-800 rounded-lg">
            <p className="text-yellow-400">File not found</p>
          </div>
        );
      }
    }

    if (response.service === 'organizer') {
      const result = response.result;
      return (
        <div className="p-4 bg-blue-900/20 border border-blue-800 rounded-lg">
          <p className="text-blue-400 font-medium mb-2">Organization Complete</p>
          <pre className="text-sm text-slate-300 whitespace-pre-wrap">{result.output}</pre>
        </div>
      );
    }

    if (response.service === 'linter') {
      const result = response.result;
      return (
        <div className="p-4 bg-purple-900/20 border border-purple-800 rounded-lg">
          <p className="text-purple-400 font-medium mb-2">
            {result.fixed ? 'Formatting Complete' : 'Formatting Failed'}
          </p>
          <p className="text-white mb-1">
            <span className="text-slate-400">File:</span> {result.filePath}
          </p>
          {result.output && (
            <pre className="text-sm text-slate-300 mt-2 whitespace-pre-wrap">{result.output}</pre>
          )}
        </div>
      );
    }

    if (response.service === 'ocr') {
      const result = response.result;
      return (
        <div className="p-4 bg-indigo-900/20 border border-indigo-800 rounded-lg">
          <p className="text-indigo-400 font-medium mb-2">Extracted Text</p>
          <div className="bg-slate-900 p-3 rounded border border-slate-700">
            <pre className="text-sm text-slate-200 whitespace-pre-wrap">{result.text}</pre>
          </div>
        </div>
      );
    }

    if (response.service === 'converter') {
      const result = response.result;
      return (
        <div className="p-4 bg-cyan-900/20 border border-cyan-800 rounded-lg">
          <p className="text-cyan-400 font-medium mb-2">Conversion Complete</p>
          <p className="text-white">
            <span className="text-slate-400">Output:</span> {result.outputPath}
          </p>
        </div>
      );
    }

    if (response.service === 'llm') {
      const result = response.result;
      return (
        <div className="p-4 bg-pink-900/20 border border-pink-800 rounded-lg">
          <p className="text-pink-400 font-medium mb-2">LLM Response</p>
          <p className="text-slate-200">{result.response}</p>
        </div>
      );
    }

    // Generic result display
    return (
      <div className="p-4 bg-slate-800 border border-slate-700 rounded-lg">
        <p className="text-slate-300 font-medium mb-2">Service: {response.service}</p>
        <pre className="text-sm text-slate-400 whitespace-pre-wrap overflow-x-auto">
          {JSON.stringify(response.result, null, 2)}
        </pre>
      </div>
    );
  };

  return (
    <div className="animate-fadeIn">
      {renderResult()}
    </div>
  );
};

export default ResultDisplay;
