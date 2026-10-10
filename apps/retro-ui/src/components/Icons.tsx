import React from 'react';

// RetroPick brandmark — purple gradient "R" tile used by the top bar.
export function RetroLogo({ className = 'w-7 h-7' }: { className?: string }) {
  return (
    <svg viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg" className={className}>
      <defs>
        <linearGradient id="retroBrandGrad" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stopColor="#b9a8ff" />
          <stop offset="50%" stopColor="#836ef9" />
          <stop offset="100%" stopColor="#5a3bd9" />
        </linearGradient>
      </defs>
      <rect x="2" y="2" width="28" height="28" rx="7" fill="#130a28" stroke="#2a1d55" strokeWidth="1.5" />
      <path
        d="M9 8H17.8C20.8 8 23 10.05 23 12.6C23 14.85 21.3 16.65 19.1 17.05L23.5 24H18.8L14.9 18.2H13.2V24H9V8ZM13.2 11.6V15.2H17.3C18.4 15.2 19.2 14.4 19.2 13.4C19.2 12.4 18.4 11.6 17.3 11.6H13.2Z"
        fill="url(#retroBrandGrad)"
      />
    </svg>
  );
}
