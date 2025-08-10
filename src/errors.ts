export class ValidationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'ValidationError';
  }
}

export class SessionError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'SessionError';
  }
}

export class RExecutionError extends Error {
  constructor(message: string, public readonly code?: number) {
    super(message);
    this.name = 'RExecutionError';
  }
}

export function handleError(error: unknown): { status: string; error: string; details?: any } {
  console.error('Error occurred:', error);
  
  if (error instanceof ValidationError) {
    return {
      status: 'error',
      error: error.message,
      details: { type: 'validation' }
    };
  }
  
  if (error instanceof SessionError) {
    return {
      status: 'error',
      error: error.message,
      details: { type: 'session' }
    };
  }
  
  if (error instanceof RExecutionError) {
    return {
      status: 'error',
      error: error.message,
      details: { type: 'r_execution', code: error.code }
    };
  }
  
  if (error instanceof Error) {
    return {
      status: 'error',
      error: error.message
    };
  }
  
  return {
    status: 'error',
    error: 'An unknown error occurred'
  };
}
