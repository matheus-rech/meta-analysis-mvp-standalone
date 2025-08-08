import * as dotenv from 'dotenv';
import * as path from 'path';
import { fileURLToPath } from 'url';
import * as fs from 'fs';

// Load .env file
dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Function to resolve paths relative to project root
function resolveProjectPath(relativePath: string): string {
  const projectRoot = path.resolve(__dirname, '..');
  return path.resolve(projectRoot, relativePath);
}

// Simple configuration
const config = {
  // Server settings
  environment: process.env.NODE_ENV || 'development',
  
  // Paths
  sessionsDir: resolveProjectPath(process.env.SESSIONS_DIR || 'sessions'),
  scriptsDir: resolveProjectPath(process.env.SCRIPTS_DIR || 'scripts'),
  
  // R script path
  rScriptPath: function(): string {
    return path.join(this.scriptsDir, 'entry', 'mcp_tools.R');
  },
  
  // Ensure necessary directories exist
  ensureDirectories: async function(): Promise<void> {
    const dirs = [this.sessionsDir];
    for (const dir of dirs) {
      await fs.promises.mkdir(dir, { recursive: true });
    }
  },
  
  // Validate configuration
  validate: function(): void {
    if (!fs.existsSync(this.rScriptPath())) {
      throw new Error(`R script not found at: ${this.rScriptPath()}`);
    }
  }
};

export default config;