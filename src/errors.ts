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

/**
 * Represents an error that occurred during R code execution.
 * 
 * @property {number | undefined} code - Optional error code returned by the R process.
 *   This code is typically set when the R process returns a specific error code.
 *   Possible values depend on the R execution context, and may be undefined if no code is provided.
 */
export class RExecutionError extends Error {
  constructor(message: string, public readonly code?: number) {
    super(message);
    this.name = 'RExecutionError';
  }
}

export function handleError(error: unknown): { status: string; error: string; details?: any; stack?: string } {
  console.error('Error occurred:', error);

  const isDev = process.env.NODE_ENV === 'development';
  let stack: string | undefined;

  if (isDev && error instanceof Error) {
    stack = error.stack;
  }

  return {
    status: 'error',
    error: error instanceof Error ? error.message : String(error),
    ...(stack ? { stack } : {}),
    details: error instanceof Error && (error as any).details ? (error as any).details : undefined,
  };
}
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
