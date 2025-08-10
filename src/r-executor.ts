import { spawn, ChildProcess } from 'child_process';
import * as path from 'path';
import { RExecutionError } from './errors.js';
import config from './config.js';

const activeProcesses = new Set<ChildProcess>();

export async function executeRScript(
  args: string[],
  timeout: number = 30000
): Promise<any> {
  return new Promise((resolve, reject) => {
    const scriptPath = config.rScriptPath();
    
    const rProcess = spawn('Rscript', ['--vanilla', scriptPath, ...args], {
      env: { ...process.env },
      cwd: process.cwd()
    });
    
    activeProcesses.add(rProcess);
    
    let stdout = '';
    let stderr = '';
    let timeoutHandle: NodeJS.Timeout;
    
    const cleanup = () => {
      activeProcesses.delete(rProcess);
      if (timeoutHandle) clearTimeout(timeoutHandle);
    };
    
    timeoutHandle = setTimeout(() => {
      rProcess.kill('SIGTERM');
      cleanup();
      reject(new RExecutionError('R script execution timed out'));
    }, timeout);
    
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
        const result = JSON.parse(stdout.trim());
        resolve(result);
      } catch (parseError) {
        // If not JSON, return raw output
        resolve({ output: stdout.trim() });
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
