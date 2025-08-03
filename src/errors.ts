/**
 * Enhanced error classes with better context preservation
 */

export class AppError extends Error {
  public timestamp: string;
  public context?: Record<string, any>;
  
  constructor(
    message: string,
    public code: string = 'UNKNOWN_ERROR',
    public statusCode: number = 500,
    context?: Record<string, any>
  ) {
    super(message);
    this.name = 'AppError';
    this.timestamp = new Date().toISOString();
    this.context = context;
    
    // Ensure proper stack trace in V8
    if (Error.captureStackTrace) {
      Error.captureStackTrace(this, this.constructor);
    }
  }
  
  toJSON() {
    return {
      name: this.name,
      message: this.message,
      code: this.code,
      statusCode: this.statusCode,
      timestamp: this.timestamp,
      context: this.context,
      stack: this.stack
    };
  }
}

export class ValidationError extends AppError {
  constructor(message: string, context?: Record<string, any>) {
    super(message, 'VALIDATION_ERROR', 400, context);
    this.name = 'ValidationError';
  }
}

export class RScriptError extends AppError {
  constructor(message: string, context?: Record<string, any>) {
    super(message, 'R_SCRIPT_ERROR', 500, context);
    this.name = 'RScriptError';
  }
}

export class SessionError extends AppError {
  constructor(message: string, context?: Record<string, any>) {
    super(message, 'SESSION_ERROR', 404, context);
    this.name = 'SessionError';
  }
}

/**
 * Enhanced error handler with context preservation
 */
export function handleError(error: any): {
  status: string;
  message: string;
  code?: string;
  timestamp?: string;
  context?: Record<string, any>;
  stack?: string;
} {
  // Log full error details including stack trace
  console.error('Error details:', {
    message: error.message,
    code: error.code,
    stack: error.stack,
    context: error.context,
    timestamp: new Date().toISOString()
  });
  
  if (error instanceof AppError) {
    // In production, omit stack trace from response
    const response: any = {
      status: 'error',
      message: error.message,
      code: error.code,
      timestamp: error.timestamp
    };
    
    // Include context if available
    if (error.context) {
      response.context = error.context;
    }
    
    // Include stack trace only in development
    if (process.env.NODE_ENV === 'development') {
      response.stack = error.stack;
    }
    
    return response;
  }
  
  // Handle unexpected errors
  const timestamp = new Date().toISOString();
  const response: any = {
    status: 'error',
    message: error.message || 'An unexpected error occurred',
    code: 'INTERNAL_ERROR',
    timestamp
  };
  
  // Include stack trace only in development
  if (process.env.NODE_ENV === 'development' && error.stack) {
    response.stack = error.stack;
  }
  
  return response;
}