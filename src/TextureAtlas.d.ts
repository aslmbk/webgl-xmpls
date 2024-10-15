export class TextureAtlas {
  constructor();
  Load(name: string, paths: string[]): void;
  onLoad: () => void;
  Info: Record<string, { atlas: any }>;
}
