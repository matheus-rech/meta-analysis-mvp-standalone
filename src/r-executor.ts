import { spawn, ChildProcess } from 'child_process';
import { RExecutionError } from './errors.js';
import config from './config.js';

const activeProcesses = new Set<ChildProcess>();

export async function executeRScript(
  args: string[],
  timeout: number = 30000
): Promise<unknown> {
  return new Promise((resolve, reject) => {
    const scriptPath = config.rScriptPath();
    
    const rProcess = spawn('Rscript', ['--vanilla', scriptPath, ...args], {
      env: { ...process.env },
      cwd: process.cwd()
    });
    
    activeProcesses.add(rProcess);
    
    let stdout = '';
    let stderr = '';
    const timeoutHandle = setTimeout(() => {
      rProcess.kill('SIGTERM');
      cleanup();
      reject(new RExecutionError('R script execution timed out'));
    }, timeout);
    
    function cleanup() {
      activeProcesses.delete(rProcess);
      clearTimeout(timeoutHandle);
    }
    
    rProcess.stdout.on('data', (data) => {
      stdout += data.toString();
    });
    
    rProcess.stderr.on('data', (data) => {
      stderr += data.toString();
    });
    
    rProcess.on('close', (code) => {
      cleanup();
      
      if (code !== 0) {
        reject(new RExecutionError(
          `R script failed with code ${code}: ${stderr || stdout}`,
          code || undefined
        ));
        return;
      }
      
      try {
        const trimmed = stdout.trim();
        const result = JSON.parse(trimmed);
        resolve(result);
      } catch (parseError) {
        // Log parse error and return structured fallback
        console.error('Failed to parse R output as JSON:', {
          error: (parseError as Error).message,
          stderr: stderr?.slice(0, 2000),
        });
        resolve({ output: stdout.trim(), stderr: stderr.trim() });
      }
    });
    
    rProcess.on('error', (error) => {
      cleanup();
      reject(new RExecutionError(`Failed to start R process: ${error.message}`));
    });
  });
}

export function cleanupRProcesses(): void {
  activeProcesses.forEach(process => {
    try {
      process.kill('SIGTERM');
    } catch (error) {
      console.error('Error killing R process:', error);
    }
  });
  activeProcesses.clear();
}
