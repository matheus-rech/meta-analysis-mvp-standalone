import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

class Config {
  public readonly sessionsDir: string;
  private readonly projectRoot: string;
  
  constructor() {
    this.projectRoot = path.resolve(__dirname, '..');
    // Allow override via env var, fallback to projectRoot/sessions
    const envDir = process.env.SESSIONS_DIR;
    this.sessionsDir = envDir && envDir.trim().length > 0
      ? path.resolve(envDir)
      : path.join(this.projectRoot, 'sessions');
  }
  
  async ensureDirectories(): Promise<void> {
    if (!fs.existsSync(this.sessionsDir)) {
      fs.mkdirSync(this.sessionsDir, { recursive: true });
    }
  }
  
  validate(): void {
    const requiredDirs = [this.sessionsDir];
    for (const dir of requiredDirs) {
      if (!fs.existsSync(dir)) {
        throw new Error(`Required directory not found: ${dir}`);
      }
    }
  }
  
  rScriptPath(): string {
    return path.join(this.projectRoot, 'scripts', 'entry', 'mcp_tools.R');
  }
}

const config = new Config();
export default config;
