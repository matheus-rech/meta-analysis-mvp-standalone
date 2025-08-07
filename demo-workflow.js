#!/usr/bin/env node

/**
 * Meta-Analysis MCP Server Demo Workflow
 * Demonstrates the complete workflow from initialization to report generation
 */

import { spawn } from 'child_process';
import { promises as fs } from 'fs';
import path from 'path';

class MCPClient {
  constructor() {
    this.server = null;
    this.requestId = 0;
  }

  async start() {
    console.log('Starting MCP server...');
    this.server = spawn('node', ['build/index.js'], {
      stdio: ['pipe', 'pipe', 'pipe']
    });

    // Handle server output
    this.server.stdout.on('data', (data) => {
      // Parse and handle server responses
      const lines = data.toString().split('\n').filter(line => line.trim());
      lines.forEach(line => {
        try {
          const response = JSON.parse(line);
          if (response.id === this.currentRequestId) {
            this.currentResolve(response);
          }
        } catch (e) {
          // Ignore non-JSON output
        }
      });
    });

    this.server.stderr.on('data', (data) => {
      console.error('Server error:', data.toString());
    });

    // Wait for server to be ready
    await new Promise(resolve => setTimeout(resolve, 1000));
    console.log('✓ MCP server started\n');
  }

  async callTool(toolName, args) {
    return new Promise((resolve, reject) => {
      this.requestId++;
      this.currentRequestId = this.requestId;
      this.currentResolve = resolve;

      const request = {
        jsonrpc: '2.0',
        id: this.requestId,
        method: 'tools/call',
        params: {
          name: toolName,
          arguments: args
        }
      };

      this.server.stdin.write(JSON.stringify(request) + '\n');

      // Timeout after 30 seconds
      setTimeout(() => {
        reject(new Error(`Request timeout for ${toolName}`));
      }, 30000);
    });
  }

  async stop() {
    if (this.server) {
      this.server.kill();
      console.log('\n✓ MCP server stopped');
    }
  }
}

async function demonstrateWorkflow() {
  console.log('=' + '='.repeat(59));
  console.log('META-ANALYSIS MCP SERVER DEMONSTRATION');
  console.log('=' + '='.repeat(59));

  const client = new MCPClient();
  let sessionId = null;

  try {
    await client.start();

    // Step 1: Initialize meta-analysis session
    console.log('\n1. INITIALIZING META-ANALYSIS SESSION');
    console.log('-'.repeat(40));
    
    const initResponse = await client.callTool('initialize_meta_analysis', {
      name: 'Cardiovascular Interventions Meta-Analysis',
      study_type: 'clinical_trial',
      effect_measure: 'OR',
      analysis_model: 'random'
    });

    const initData = JSON.parse(initResponse.result.content[0].text);
    sessionId = initData.session_id;
    console.log(`✓ Session initialized: ${sessionId}`);
    console.log(`✓ Project: ${initData.message}`);

    // Step 2: Upload study data
    console.log('\n2. UPLOADING STUDY DATA');
    console.log('-'.repeat(25));

    // Read sample data
    const sampleData = await fs.readFile('test-data/sample_data.csv', 'utf8');
    const dataBase64 = Buffer.from(sampleData).toString('base64');

    const uploadResponse = await client.callTool('upload_study_data', {
      session_id: sessionId,
      data_format: 'csv',
      data_content: dataBase64,
      validation_level: 'comprehensive'
    });

    const uploadData = JSON.parse(uploadResponse.result.content[0].text);
    console.log(`✓ Data uploaded: ${uploadData.message}`);
    if (uploadData.validation_summary) {
      console.log(`  - Studies: ${uploadData.validation_summary.total_studies || uploadData.n_studies}`);
      console.log(`  - Data type: ${uploadData.data_type}`);
    }

    // Step 3: Perform meta-analysis
    console.log('\n3. PERFORMING META-ANALYSIS');
    console.log('-'.repeat(30));

    const analysisResponse = await client.callTool('perform_meta_analysis', {
      session_id: sessionId,
      heterogeneity_test: true,
      publication_bias: true,
      sensitivity_analysis: false
    });

    const analysisData = JSON.parse(analysisResponse.result.content[0].text);
    console.log(`✓ Analysis completed`);
    if (analysisData.overall_effect !== undefined) {
      console.log(`  - Pooled effect: ${analysisData.overall_effect.toFixed(3)}`);
      console.log(`  - 95% CI: [${analysisData.confidence_interval.lower.toFixed(3)}, ${analysisData.confidence_interval.upper.toFixed(3)}]`);
      console.log(`  - Heterogeneity (I²): ${analysisData.heterogeneity.i_squared}`);
      console.log(`  - P-value: ${analysisData.p_value.toExponential(2)}`);
    }

    // Step 4: Generate forest plot
    console.log('\n4. GENERATING FOREST PLOT');
    console.log('-'.repeat(30));

    const forestResponse = await client.callTool('generate_forest_plot', {
      session_id: sessionId,
      plot_style: 'modern',
      confidence_level: 0.95
    });

    const forestData = JSON.parse(forestResponse.result.content[0].text);
    console.log(`✓ Forest plot generated`);
    if (forestData.forest_plot_path) {
      console.log(`  - File: ${forestData.forest_plot_path}`);
    }

    // Step 5: Assess publication bias
    console.log('\n5. ASSESSING PUBLICATION BIAS');
    console.log('-'.repeat(35));

    const biasResponse = await client.callTool('assess_publication_bias', {
      session_id: sessionId,
      methods: ['funnel_plot', 'egger_test', 'begg_test']
    });

    const biasData = JSON.parse(biasResponse.result.content[0].text);
    console.log(`✓ Publication bias assessment completed`);
    if (biasData.egger_test) {
      console.log(`  - Egger test p-value: ${biasData.egger_test.p_value.toFixed(3)}`);
      console.log(`  - ${biasData.egger_test.interpretation}`);
    }
    if (biasData.funnel_plot_path) {
      console.log(`  - Funnel plot: Generated`);
    }

    // Step 6: Generate comprehensive report
    console.log('\n6. GENERATING COMPREHENSIVE REPORT');
    console.log('-'.repeat(40));

    const reportResponse = await client.callTool('generate_report', {
      session_id: sessionId,
      format: 'html',
      include_code: false
    });

    const reportData = JSON.parse(reportResponse.result.content[0].text);
    console.log(`✓ Report generated: ${reportData.message}`);
    if (reportData.file_path) {
      console.log(`  - Report: ${reportData.file_path}`);
    }

    // Step 7: Get session status
    console.log('\n7. SESSION STATUS SUMMARY');
    console.log('-'.repeat(30));

    const statusResponse = await client.callTool('get_session_status', {
      session_id: sessionId
    });

    const statusData = JSON.parse(statusResponse.result.content[0].text);
    console.log(`✓ Session status: ${statusData.workflow_stage}`);
    console.log(`✓ Completed steps: ${statusData.completed_steps.join(', ')}`);
    if (statusData.files) {
      console.log('✓ Generated files:');
      Object.entries(statusData.files).forEach(([category, files]) => {
        files.forEach(file => {
          console.log(`  - ${category}: ${file}`);
        });
      });
    }

    console.log('\n' + '='.repeat(60));
    console.log('DEMONSTRATION COMPLETED SUCCESSFULLY!');
    console.log('='.repeat(60));
    console.log(`\nSession ID for further testing: ${sessionId}`);

  } catch (error) {
    console.error('\n❌ Error:', error.message);
  } finally {
    await client.stop();
  }
}

// Test error handling
async function testErrorHandling() {
  console.log('\n' + '='.repeat(60));
  console.log('TESTING ERROR HANDLING');
  console.log('='.repeat(60));

  const client = new MCPClient();

  try {
    await client.start();

    console.log('\n1. Testing invalid session ID...');
    try {
      const response = await client.callTool('get_session_status', {
        session_id: 'invalid-session-id'
      });
      const data = JSON.parse(response.result.content[0].text);
      console.log(`✓ Error handling works: ${data.message || 'Session not found'}`);
    } catch (e) {
      console.log(`✓ Exception caught: ${e.message}`);
    }

    console.log('\n2. Testing missing required parameters...');
    try {
      const response = await client.callTool('initialize_meta_analysis', {
        name: 'Test Project'
        // Missing required parameters
      });
      const data = JSON.parse(response.result.content[0].text);
      console.log(`✓ Parameter validation works: ${data.message || 'Missing parameters'}`);
    } catch (e) {
      console.log(`✓ Exception caught: ${e.message}`);
    }

  } finally {
    await client.stop();
  }
}

// Copy sample data if not exists
async function ensureSampleData() {
  const testDataDir = 'test-data';
  const sampleDataPath = path.join(testDataDir, 'sample_data.csv');
  
  try {
    await fs.access(sampleDataPath);
  } catch {
    // Create test data directory
    await fs.mkdir(testDataDir, { recursive: true });
    
    // Create sample data
    const sampleData = `study_id,events_treatment,n_treatment,events_control,n_control,effect_size,se
Study_1,15,100,25,100,0.6,0.25
Study_2,8,50,12,50,0.67,0.35
Study_3,22,150,35,150,0.63,0.22
Study_4,5,75,10,75,0.5,0.45
Study_5,18,120,28,120,0.64,0.28
Study_6,12,80,20,80,0.6,0.32
Study_7,30,200,45,200,0.67,0.18
Study_8,7,60,15,60,0.47,0.38
`;
    
    await fs.writeFile(sampleDataPath, sampleData);
    console.log('✓ Created sample data file');
  }
}

// Main execution
async function main() {
  try {
    // Ensure we have sample data
    await ensureSampleData();
    
    // Run the demo workflow
    await demonstrateWorkflow();
    
    // Test error handling
    await testErrorHandling();
    
  } catch (error) {
    console.error('Fatal error:', error);
    process.exit(1);
  }
}

// Run if executed directly
if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}