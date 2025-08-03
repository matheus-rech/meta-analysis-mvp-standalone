import * as fs from 'fs/promises';
import * as path from 'path';
import { v4 as uuidv4, validate as uuidValidate } from 'uuid';
import config from './config.js';
import { SessionError, ValidationError } from './errors.js';

interface Session {
  id: string;
  name: string;
  studyType: string;
  effectMeasure: string;
  analysisModel: string;
  createdAt: string;
  config?: any;
}

/**
 * Simple file-based session manager
 */
export class SessionManager {
  private sessionsDir: string;

  constructor() {
    this.sessionsDir = config.sessionsDir;
  }

  /**
   * Create a new session
   */
  async createSession(data: {
    name: string;
    studyType: string;
    effectMeasure: string;
    analysisModel: string;
    config?: any;
  }): Promise<Session> {
    const sessionId = uuidv4();
    const session: Session = {
      id: sessionId,
      name: data.name,
      studyType: data.studyType,
      effectMeasure: data.effectMeasure,
      analysisModel: data.analysisModel,
      createdAt: new Date().toISOString(),
      config: data.config || {}
    };

    // Create session directory
    const sessionPath = path.join(this.sessionsDir, sessionId);
    await fs.mkdir(sessionPath, { recursive: true });
    
    // Create subdirectories
    await fs.mkdir(path.join(sessionPath, 'data'), { recursive: true });
    await fs.mkdir(path.join(sessionPath, 'results'), { recursive: true });
    await fs.mkdir(path.join(sessionPath, 'processing'), { recursive: true });

    // Save session metadata
    await fs.writeFile(
      path.join(sessionPath, 'session.json'),
      JSON.stringify(session, null, 2)
    );

    console.log(`Created session: ${sessionId}`);
    return session;
  }

  /**
   * Get session by ID
   */
  async getSession(sessionId: string): Promise<Session> {
    // Validate session ID is a valid UUID
    if (!this.isValidSessionId(sessionId)) {
      throw new ValidationError(`Invalid session ID format: ${sessionId}`);
    }
    
    const sessionPath = path.join(this.sessionsDir, sessionId);
    
    try {
      const sessionFile = path.join(sessionPath, 'session.json');
      const data = await fs.readFile(sessionFile, 'utf-8');
      return JSON.parse(data);
    } catch (error) {
      throw new SessionError(`Session not found: ${sessionId}`);
    }
  }

  /**
   * Get session path
   */
  getSessionPath(sessionId: string): string {
    // Validate session ID is a valid UUID to prevent path traversal
    if (!this.isValidSessionId(sessionId)) {
      throw new ValidationError(`Invalid session ID format: ${sessionId}`);
    }
    
    return path.join(this.sessionsDir, sessionId);
  }

  /**
   * Check if session exists
   */
  async sessionExists(sessionId: string): Promise<boolean> {
    // Validate session ID is a valid UUID
    if (!this.isValidSessionId(sessionId)) {
      return false;
    }
    
    try {
      await fs.access(path.join(this.sessionsDir, sessionId));
      return true;
    } catch {
      return false;
    }
  }

  /**
   * List all sessions
   */
  async listSessions(): Promise<Session[]> {
    try {
      const dirs = await fs.readdir(this.sessionsDir);
      const sessions: Session[] = [];

      for (const dir of dirs) {
        // Only process valid UUID directories
        if (this.isValidSessionId(dir)) {
          try {
            const session = await this.getSession(dir);
            sessions.push(session);
          } catch {
            // Skip invalid session directories
          }
        }
      }

      return sessions.sort((a, b) =>
        new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
      );
    } catch {
      return [];
    }
  }

  /**
   * Validate session ID is a valid UUID v4
   */
  private isValidSessionId(sessionId: string): boolean {
    return typeof sessionId === 'string' && uuidValidate(sessionId) && sessionId.length === 36;
  }
}

// Export singleton instance
export const sessionManager = new SessionManager();