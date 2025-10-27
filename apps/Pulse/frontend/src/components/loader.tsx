import React from 'react';

const HecateLoader: React.FC = () => {
  return (
    <div className="flex flex-col items-center justify-center gap-4">
      {/* Cat Eyes */}
      <div className="flex items-center gap-6">
        {/* Left Eye */}
        <div className="relative w-16 h-12">
          {/* Eye background */}
          <div
            className="absolute inset-0 rounded-full"
            style={{
              background: 'radial-gradient(circle, #fbbf24 20%, #f59e0b 60%, #d97706 100%)',
              animation: 'blink 3s ease-in-out infinite'
            }}
          />
          {/* Pupil */}
          <div
            className="absolute top-1/2 left-1/2 w-3 h-10 bg-black rounded-full"
            style={{
              transform: 'translate(-50%, -50%)',
              animation: 'lookAround 4s ease-in-out infinite'
            }}
          />
          {/* Shine effect */}
          <div
            className="absolute top-2 left-4 w-2 h-3 bg-white rounded-full opacity-60"
            style={{
              animation: 'blink 3s ease-in-out infinite'
            }}
          />
        </div>

        {/* Right Eye */}
        <div className="relative w-16 h-12">
          {/* Eye background */}
          <div
            className="absolute inset-0 rounded-full"
            style={{
              background: 'radial-gradient(circle, #fbbf24 20%, #f59e0b 60%, #d97706 100%)',
              animation: 'blink 3s ease-in-out infinite'
            }}
          />
          {/* Pupil */}
          <div
            className="absolute top-1/2 left-1/2 w-3 h-10 bg-black rounded-full"
            style={{
              transform: 'translate(-50%, -50%)',
              animation: 'lookAround 4s ease-in-out infinite'
            }}
          />
          {/* Shine effect */}
          <div
            className="absolute top-2 left-4 w-2 h-3 bg-white rounded-full opacity-60"
            style={{
              animation: 'blink 3s ease-in-out infinite'
            }}
          />
        </div>
      </div>

      {/* Optional loading text */}
      <div className="text-gray-400 text-sm animate-pulse">
        Loading...
      </div>

      <style>
        {`
          @keyframes blink {
            0%, 40%, 100% {
              transform: scaleY(1);
              opacity: 1;
            }
            45%, 50% {
              transform: scaleY(0.1);
              opacity: 0.8;
            }
          }

          @keyframes lookAround {
            0%, 100% {
              transform: translate(-50%, -50%) translateX(0);
            }
            25% {
              transform: translate(-50%, -50%) translateX(-8px);
            }
            50% {
              transform: translate(-50%, -50%) translateX(8px);
            }
            75% {
              transform: translate(-50%, -50%) translateX(-4px);
            }
          }
        `}
      </style>
    </div>
  );
};

export default HecateLoader;
