import * as fs from 'fs';
import * as path from 'path';
import config from './config.js';
import { v4 as uuidv4 } from 'uuid';
import { SessionError } from './errors.js';

interface Session {
  id: string;
  name: string;
  studyType: string;
  effectMeasure: string;
  analysisModel: string;
  config: any;
  createdAt: string; // ISO string for persistence
  updatedAt: string; // ISO string for persistence
  status: 'initialized' | 'data_uploaded' | 'analysis_complete' | 'error';
}

class SessionManager {
  private sessionsDir: string;
  private sessions: Map<string, Session>;
  
  constructor() {
    this.sessionsDir = config.sessionsDir;
    this.sessions = new Map();
    this.loadSessions();
  }
  
  private loadSessions(): void {
    if (!fs.existsSync(this.sessionsDir)) {
      fs.mkdirSync(this.sessionsDir, { recursive: true });
    }
    
    // Load existing sessions from disk if needed
    const sessionFiles = fs.readdirSync(this.sessionsDir)
      .filter(file => file.endsWith('.json'));
    
    for (const file of sessionFiles) {
      try {
        const sessionPath = path.join(this.sessionsDir, file);
        const sessionData = JSON.parse(fs.readFileSync(sessionPath, 'utf-8'));
        this.sessions.set(sessionData.id, sessionData);
      } catch (error) {
        console.error(`Failed to load session ${file}:`, error);
      }
    }
  }
  
  async createSession(params: {
    name: string;
    studyType: string;
    effectMeasure: string;
    analysisModel: string;
    config: any;
  }): Promise<Session> {
    const nowIso = new Date().toISOString();
    const session: Session = {
      id: uuidv4(),
      name: params.name,
      studyType: params.studyType,
      effectMeasure: params.effectMeasure,
      analysisModel: params.analysisModel,
      config: params.config,
      createdAt: nowIso,
      updatedAt: nowIso,
      status: 'initialized'
    };
    
    // Save session to memory
    this.sessions.set(session.id, session);
    
    // Create session directory and expected subdirectories
    const sessionDir = this.getSessionPath(session.id);
    if (!fs.existsSync(sessionDir)) {
      fs.mkdirSync(sessionDir, { recursive: true });
    }
    ['data', 'processing', 'results', 'input'].forEach((sub) => {
      const subdir = path.join(sessionDir, sub);
      if (!fs.existsSync(subdir)) fs.mkdirSync(subdir, { recursive: true });
    });
    
    // Save session metadata
    const metadataPath = path.join(sessionDir, 'session.json');
    fs.writeFileSync(metadataPath, JSON.stringify(session, null, 2));
    
    return session;
  }
  
  async sessionExists(sessionId: string): Promise<boolean> {
    if (this.sessions.has(sessionId)) return true;
    const sessionDir = this.getSessionPath(sessionId);
    if (!fs.existsSync(sessionDir)) return false;
    const metadataPath = path.join(sessionDir, 'session.json');
    return fs.existsSync(metadataPath);
  }
  
  getSessionPath(sessionId: string): string {
    return path.join(this.sessionsDir, sessionId);
  }
  
  getSession(sessionId: string): Session {
    const session = this.sessions.get(sessionId);
    if (!session) {
      throw new SessionError(`Session with ID ${sessionId} not found.`);
    }
    return session;
  }
  
  updateSessionStatus(sessionId: string, status: Session['status']): void {
    const session = this.sessions.get(sessionId);
    if (session) {
      session.status = status;
      session.updatedAt = new Date().toISOString();
      
      // Save updated session
      const metadataPath = path.join(this.getSessionPath(sessionId), 'session.json');
      fs.writeFileSync(metadataPath, JSON.stringify(session, null, 2));
    }
  }
}

export const sessionManager = new SessionManager();
