import { spawn, ChildProcess } from 'child_process';
import config from './config.js';
import { RScriptError, ValidationError } from './errors.js';

// Maximum allowed JSON output size (10MB)
const MAX_JSON_SIZE = 10 * 1024 * 1024;

// Default timeout for R processes (45 seconds)
const DEFAULT_TIMEOUT_MS = 45000;

// Active R processes tracking for graceful shutdown
const activeProcesses = new Set<ChildProcess>();

/**
 * Validate arguments to prevent issues
 * Note: spawn with shell:false already prevents command injection
 */
function validateArguments(args: string[]): void {
  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    
    if (typeof arg !== 'string') {
      throw new ValidationError('All arguments must be strings');
    }
    
    // Check for null bytes which can cause issues
    if (arg.indexOf('\u0000') !== -1 || arg.indexOf('\x00') !== -1) {
      throw new ValidationError('Arguments contain null bytes');
    }
    
    // Validate first argument (tool name) - should be alphanumeric with underscores
    if (i === 0 && !/^[a-zA-Z0-9_]+$/.test(arg)) {
      throw new ValidationError('Invalid tool name format');
    }
    
    // Validate third argument (session path) - should not contain path traversal
    if (i === 2 && arg.includes('..')) {
      throw new ValidationError('Session path cannot contain ".." for security');
    }
    
    // Limit argument length to prevent buffer overflow (10MB for JSON data)
    if (arg.length > 10 * 1024 * 1024) {
      throw new ValidationError('Argument too long (max 10MB)');
    }
  }
}

/**
 * Simple R script executor with security enhancements
 */
export async function executeRScript(args: string[], timeoutMs: number = DEFAULT_TIMEOUT_MS): Promise<any> {
  // Validate arguments to prevent injection
  validateArguments(args);
  
  return new Promise((resolve, reject) => {
    const rProcess = spawn("Rscript", [config.rScriptPath(), ...args], {
      // Prevent shell execution
      shell: false,
      // Limit environment variables
      env: {
        ...process.env,
        // Remove potentially dangerous environment variables
        LD_PRELOAD: undefined,
        LD_LIBRARY_PATH: undefined,
      }
    });
    
    // Track active process
    activeProcesses.add(rProcess);
    
    let stdout = "";
    let stderr = "";
    let outputSize = 0;
    
    // Set up timeout
    const timeoutId = setTimeout(() => {
      console.error(`R process timed out after ${timeoutMs}ms`);
      rProcess.kill('SIGTERM');
      setTimeout(() => {
        if (!rProcess.killed) {
          rProcess.kill('SIGKILL');
        }
      }, 5000); // Force kill after 5 seconds if SIGTERM doesn't work
      reject(new RScriptError(`R process timed out after ${timeoutMs}ms`));
    }, timeoutMs);

    rProcess.stdout.on("data", (data) => {
      const chunk = data.toString();
      outputSize += chunk.length;
      
      // Check output size limit
      if (outputSize > MAX_JSON_SIZE) {
        rProcess.kill();
        reject(new RScriptError(`R script output exceeded maximum size of ${MAX_JSON_SIZE} bytes`));
        return;
      }
      
      stdout += chunk;
    });

    rProcess.stderr.on("data", (data) => {
      stderr += data.toString();
    });

    rProcess.on("close", (code) => {
      clearTimeout(timeoutId);
      activeProcesses.delete(rProcess);
      
      if (code !== 0) {
        console.error(`R script error: ${stderr}`);
        return reject(new RScriptError(`R script exited with code ${code}: ${stderr}`));
      }
      
      try {
        // Validate JSON size before parsing
        if (stdout.length > MAX_JSON_SIZE) {
          throw new Error(`Output size ${stdout.length} exceeds maximum allowed ${MAX_JSON_SIZE}`);
        }
        
        const result = JSON.parse(stdout);
        if (result.status === 'error') {
          return reject(new RScriptError(result.message || 'Unknown R script error'));
        }
        resolve(result);
      } catch (error) {
        const errorMessage = error instanceof Error ? error.message : String(error);
        console.error(`Error parsing R script output: ${errorMessage}`);
        reject(new RScriptError(`Error parsing R script output: ${errorMessage}`));
      }
    });
    
    rProcess.on("error", (error) => {
      clearTimeout(timeoutId);
      activeProcesses.delete(rProcess);
      console.error('Failed to start R process:', error);
      reject(new RScriptError(`Failed to start R process: ${error.message}`));
    });
  });
}

/**
 * Clean up all active R processes (for graceful shutdown)
 */
export function cleanupRProcesses(): void {
  console.log(`Cleaning up ${activeProcesses.size} active R processes...`);
  
  for (const process of activeProcesses) {
    try {
      process.kill('SIGTERM');
      // Give process time to clean up
      setTimeout(() => {
        if (!process.killed) {
          process.kill('SIGKILL');
        }
      }, 5000);
    } catch (error) {
      console.error('Error killing R process:', error);
    }
  }
  
  activeProcesses.clear();
}