#!/usr/bin/env node

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";

import config from "./config.js";
import { executeRScript, cleanupRProcesses } from "./r-executor.js";
import { sessionManager } from "./session-manager.js";
import { handleError, ValidationError } from "./errors.js";

const server = new Server(
  {
    name: "meta-analysis-mvp",
    version: "1.0.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// Define available tools
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: "health_check",
        description: "Check the health status of the meta-analysis server",
        inputSchema: {
          type: "object",
          properties: {
            detailed: { type: "boolean", default: false }
          },
        },
      },
      {
        name: "initialize_meta_analysis",
        description: "Start new meta-analysis project with guided setup",
        inputSchema: {
          type: "object",
          properties: {
            name: {
              type: "string",
              description: "Name for the meta-analysis project"
            },
            study_type: {
              type: "string",
              enum: ["clinical_trial", "observational", "diagnostic"],
            },
            effect_measure: {
              type: "string",
              enum: ["OR", "RR", "MD", "SMD", "HR", "PROP", "MEAN"],
            },
            analysis_model: {
              type: "string",
              enum: ["fixed", "random", "auto"],
            },
          },
          required: ["name", "study_type", "effect_measure", "analysis_model"]
        },
      },
      {
        name: "upload_study_data",
        description: "Upload and validate study data",
        inputSchema: {
          type: "object",
          properties: {
            session_id: { type: "string" },
            data_format: { type: "string", enum: ["csv", "excel", "revman"] },
            data_content: { type: "string" },
            validation_level: {
              type: "string",
              enum: ["basic", "comprehensive"],
            },
          },
          required: ["session_id", "data_format", "data_content", "validation_level"]
        },
      },
      {
        name: "perform_meta_analysis",
        description: "Execute meta-analysis with automated checks",
        inputSchema: {
          type: "object",
          properties: {
            session_id: { type: "string" },
            heterogeneity_test: { type: "boolean", default: true },
            publication_bias: { type: "boolean", default: true },
            sensitivity_analysis: { type: "boolean", default: false },
          },
          required: ["session_id"]
        },
      },
      {
        name: "generate_forest_plot",
        description: "Create publication-ready forest plot",
        inputSchema: {
          type: "object",
          properties: {
            session_id: { type: "string" },
            plot_style: {
              type: "string",
              enum: ["classic", "modern", "journal_specific"],
            },
            confidence_level: { type: "number", default: 0.95 },
            custom_labels: { type: "object" },
          },
          required: ["session_id", "plot_style"]
        },
      },
      {
        name: "assess_publication_bias",
        description: "Perform publication bias assessment",
        inputSchema: {
          type: "object",
          properties: {
            session_id: { type: "string" },
            methods: {
              type: "array",
              items: {
                type: "string",
                enum: ["funnel_plot", "egger_test", "begg_test", "trim_fill"],
              },
            },
          },
          required: ["session_id", "methods"]
        },
      },
      {
        name: "generate_report",
        description: "Create comprehensive meta-analysis report",
        inputSchema: {
          type: "object",
          properties: {
            session_id: { type: "string" },
            format: { type: "string", enum: ["html", "pdf", "word"] },
            include_code: { type: "boolean", default: false },
            journal_template: { type: "string" },
          },
          required: ["session_id", "format"]
        },
      },
      {
        name: "get_session_status",
        description: "Get the current status of a meta-analysis session",
        inputSchema: {
          type: "object",
          properties: {
            session_id: { type: "string" },
          },
          required: ["session_id"]
        },
      },
    ],
  };
});

// Tool parameter validation schemas
const toolValidationSchemas: Record<string, (args: any) => void> = {
  health_check: (args: any) => {
    // Optional detailed parameter
    if (args?.detailed !== undefined && typeof args.detailed !== 'boolean') {
      throw new ValidationError("Parameter 'detailed' must be a boolean");
    }
  },
  initialize_meta_analysis: (args: any) => {
    if (!args) throw new ValidationError("Arguments are required");
    if (!args.name || typeof args.name !== 'string') {
      throw new ValidationError("Parameter 'name' is required and must be a string");
    }
    if (!['clinical_trial', 'observational', 'diagnostic'].includes(args.study_type)) {
      throw new ValidationError("Invalid study_type");
    }
    if (!['OR', 'RR', 'MD', 'SMD', 'HR', 'PROP', 'MEAN'].includes(args.effect_measure)) {
      throw new ValidationError("Invalid effect_measure");
    }
    if (!['fixed', 'random', 'auto'].includes(args.analysis_model)) {
      throw new ValidationError("Invalid analysis_model");
    }
  },
  upload_study_data: (args: any) => {
    if (!args) throw new ValidationError("Arguments are required");
    if (!args.session_id || typeof args.session_id !== 'string') {
      throw new ValidationError("Parameter 'session_id' is required and must be a string");
    }
    if (!['csv', 'excel', 'revman'].includes(args.data_format)) {
      throw new ValidationError("Invalid data_format");
    }
    if (!args.data_content || typeof args.data_content !== 'string') {
      throw new ValidationError("Parameter 'data_content' is required and must be a string");
    }
    if (!['basic', 'comprehensive'].includes(args.validation_level)) {
      throw new ValidationError("Invalid validation_level");
    }
  },
  perform_meta_analysis: (args: any) => {
    if (!args) throw new ValidationError("Arguments are required");
    if (!args.session_id || typeof args.session_id !== 'string') {
      throw new ValidationError("Parameter 'session_id' is required and must be a string");
    }
    // Optional boolean parameters
    ['heterogeneity_test', 'publication_bias', 'sensitivity_analysis'].forEach(param => {
      if (args[param] !== undefined && typeof args[param] !== 'boolean') {
        throw new ValidationError(`Parameter '${param}' must be a boolean`);
      }
    });
  },
  generate_forest_plot: (args: any) => {
    if (!args) throw new ValidationError("Arguments are required");
    if (!args.session_id || typeof args.session_id !== 'string') {
      throw new ValidationError("Parameter 'session_id' is required and must be a string");
    }
    if (!['classic', 'modern', 'journal_specific'].includes(args.plot_style)) {
      throw new ValidationError("Invalid plot_style");
    }
    if (args.confidence_level !== undefined) {
      if (typeof args.confidence_level !== 'number' || args.confidence_level <= 0 || args.confidence_level >= 1) {
        throw new ValidationError("Parameter 'confidence_level' must be a number between 0 and 1");
      }
    }
  },
  assess_publication_bias: (args: any) => {
    if (!args) throw new ValidationError("Arguments are required");
    if (!args.session_id || typeof args.session_id !== 'string') {
      throw new ValidationError("Parameter 'session_id' is required and must be a string");
    }
    if (!args.methods || !Array.isArray(args.methods)) {
      throw new ValidationError("Parameter 'methods' is required and must be an array");
    }
    const validMethods = ['funnel_plot', 'egger_test', 'begg_test', 'trim_fill'];
    args.methods.forEach((method: any) => {
      if (!validMethods.includes(method)) {
        throw new ValidationError(`Invalid method: ${method}`);
      }
    });
  },
  generate_report: (args: any) => {
    if (!args) throw new ValidationError("Arguments are required");
    if (!args.session_id || typeof args.session_id !== 'string') {
      throw new ValidationError("Parameter 'session_id' is required and must be a string");
    }
    if (!['html', 'pdf', 'word'].includes(args.format)) {
      throw new ValidationError("Invalid format");
    }
    if (args.include_code !== undefined && typeof args.include_code !== 'boolean') {
      throw new ValidationError("Parameter 'include_code' must be a boolean");
    }
  },
  get_session_status: (args: any) => {
    if (!args) throw new ValidationError("Arguments are required");
    if (!args.session_id || typeof args.session_id !== 'string') {
      throw new ValidationError("Parameter 'session_id' is required and must be a string");
    }
  }
};

// Handle tool calls
server.setRequestHandler(CallToolRequestSchema, async (request: any) => {
  try {
    const { name, arguments: args } = request.params;
    // Route debug logs to stderr to avoid contaminating stdout JSON-RPC
    console.error(`Processing tool request: ${name}`);
    
    // Validate tool exists
    if (!toolValidationSchemas[name]) {
      throw new ValidationError(`Unknown tool: ${name}`);
    }
    
    // Validate tool parameters
    toolValidationSchemas[name](args);
    
    switch (name) {
      case "health_check": {
        // Probe R availability with a tiny script
        let rAvailable = false;
        try {
          const probe = await executeRScript(["get_session_status", JSON.stringify({ session_id: "00000000-0000-4000-8000-000000000000" }), sessionManager.getSessionPath("00000000-0000-4000-8000-000000000000")], 2000);
          // If it ran without throwing, R is available (we do not require valid session for probe)
          rAvailable = true;
        } catch {
          // Fallback: try a no-op R call that should fail gracefully
          try {
            await executeRScript(["health_check", JSON.stringify({}), process.cwd()], 2000);
            rAvailable = true;
          } catch {
            rAvailable = false;
          }
        }

        return {
          content: [{
            type: "text",
            text: JSON.stringify({
              status: 'success',
              message: 'Meta-analysis MVP server is healthy',
              version: '1.0.0',
              r_available: rAvailable
            }, null, 2)
          }]
        };
      }
      
      case "initialize_meta_analysis": {
        // args is validated by toolValidationSchemas above
        const session = await sessionManager.createSession({
          name: args!.name as string,
          studyType: args!.study_type as string,
          effectMeasure: args!.effect_measure as string,
          analysisModel: args!.analysis_model as string,
          config: args!
        });
        
        return {
          content: [{
            type: "text",
            text: JSON.stringify({
              status: 'success',
              session_id: session.id,
              message: `Initialized meta-analysis session: ${session.id}`
            }, null, 2)
          }]
        };
      }
      
      default: {
        // All other tools require session_id (already validated)
        const sessionId = args!.session_id as string;
        
        // Verify session exists
        if (!await sessionManager.sessionExists(sessionId)) {
          throw new ValidationError(`Session not found: ${sessionId}`);
        }
        
        // Get session path
        const sessionPath = sessionManager.getSessionPath(sessionId);
        
        // Execute R script with timeout
        const result = await executeRScript([name, JSON.stringify(args), sessionPath]);
        
        return {
          content: [{
            type: "text",
            text: JSON.stringify(result, null, 2)
          }]
        };
      }
    }
  } catch (error) {
    const errorResponse = handleError(error);
    return {
      content: [{
        type: "text",
        text: JSON.stringify(errorResponse, null, 2)
      }]
    };
  }
});

// Main entry point
async function main() {
  try {
    // Initialize configuration
    await config.ensureDirectories();
    config.validate();
    
    // Route informational logs to stderr so stdout remains JSON-RPC only
    console.error(`Starting meta-analysis MVP server v1.0.0`);
    console.error(`R script path: ${config.rScriptPath()}`);
    console.error(`Sessions directory: ${config.sessionsDir}`);
    
    // Connect to transport
    const transport = new StdioServerTransport();
    await server.connect(transport);
    
    console.error('Server ready to process requests');
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

// Graceful shutdown handler
let isShuttingDown = false;

async function shutdown(signal: string) {
  if (isShuttingDown) {
    console.error('Shutdown already in progress...');
    return;
  }
  
  isShuttingDown = true;
  console.error(`\nReceived ${signal}, shutting down gracefully...`);
  
  try {
    // Clean up R processes
    cleanupRProcesses();
    
    // Wait a bit for processes to clean up
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    console.error('Cleanup completed');
    process.exit(0);
  } catch (error) {
    console.error('Error during shutdown:', error);
    process.exit(1);
  }
}

// Register shutdown handlers
process.on('SIGINT', () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));

// Handle uncaught errors
process.on('uncaughtException', (error: Error) => {
  console.error('Uncaught exception:', error);
  shutdown('uncaughtException');
});

process.on('unhandledRejection', (reason: unknown, promise: Promise<unknown>) => {
  console.error('Unhandled rejection at:', promise, 'reason:', reason);
  shutdown('unhandledRejection');
});

// Start the server
main().catch((error) => {
  console.error("Fatal server error:", error);
  process.exit(1);
});