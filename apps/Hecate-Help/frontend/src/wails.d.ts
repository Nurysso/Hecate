export interface Keybind {
  mods: string;
  key: string;
  action: string;
  description: string;
  category: string;
  isCommented: boolean;
  rawLine: string;
}

declare global {
  interface Window {
    go: {
      main: {
        App: {
          GetKeybinds(): Promise<Keybind[]>;
        };
      };
    };
  }
}

export {};
