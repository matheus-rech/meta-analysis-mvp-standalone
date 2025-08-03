#!/usr/bin/env node

import { spawn } from 'child_process';
import { promises as fs } from 'fs';

// Test the MVP server
async function testMVPServer() {
  console.log('🧪 Testing Meta-Analysis MVP Server...\n');
  
  // Start the server
  const server = spawn('node', ['build/index.js'], {
    stdio: ['pipe', 'pipe', 'pipe']
  });
  
  let sessionId = null;
  const results = {
    passed: 0,
    failed: 0,
    tests: []
  };
  
  // Helper to send request and get response
  async function sendRequest(method, params = {}) {
    return new Promise((resolve, reject) => {
      const request = {
        jsonrpc: '2.0',
        id: Date.now(),
        method,
        params
      };
      
      server.stdin.write(JSON.stringify(request) + '\n');
      
      const timeout = setTimeout(() => {
        reject(new Error('Request timed out'));
      }, 10000);
      
      const handleResponse = (data) => {
        clearTimeout(timeout);
        try {
          const lines = data.toString().split('\n').filter(line => line.trim());
          for (const line of lines) {
            try {
              const response = JSON.parse(line);
              if (response.id === request.id) {
                server.stdout.removeListener('data', handleResponse);
                resolve(response);
                return;
              }
            } catch (e) {
              // Not JSON, skip
            }
          }
        } catch (error) {
          reject(error);
        }
      };
      
      server.stdout.on('data', handleResponse);
    });
  }
  
  // Test function
  async function runTest(name, testFn) {
    console.log(`\n📋 Test: ${name}`);
    try {
      await testFn();
      console.log(`✅ PASSED`);
      results.passed++;
      results.tests.push({ name, status: 'passed' });
    } catch (error) {
      console.log(`❌ FAILED: ${error.message}`);
      results.failed++;
      results.tests.push({ name, status: 'failed', error: error.message });
    }
  }
  
  // Wait for server to start
  await new Promise(resolve => setTimeout(resolve, 2000));
  
  // Test 1: Health Check
  await runTest('Health Check', async () => {
    const response = await sendRequest('tools/call', {
      name: 'health_check',
      arguments: { detailed: false }
    });
    
    const result = JSON.parse(response.result.content[0].text);
    if (result.status !== 'success') {
      throw new Error('Health check failed');
    }
  });
  
  // Test 2: Initialize Meta-Analysis
  await runTest('Initialize Meta-Analysis', async () => {
    const response = await sendRequest('tools/call', {
      name: 'initialize_meta_analysis',
      arguments: {
        name: 'Test Meta-Analysis',
        study_type: 'clinical_trial',
        effect_measure: 'OR',
        analysis_model: 'random'
      }
    });
    
    const result = JSON.parse(response.result.content[0].text);
    if (result.status !== 'success' || !result.session_id) {
      throw new Error('Failed to initialize meta-analysis');
    }
    sessionId = result.session_id;
    console.log(`  Session ID: ${sessionId}`);
  });
  
  // Test 3: Upload Study Data
  await runTest('Upload Study Data', async () => {
    // Create sample CSV data
    const csvData = `study,effect_size,standard_error,sample_size
Study 1,0.5,0.1,100
Study 2,0.3,0.15,150
Study 3,0.6,0.12,120
Study 4,0.4,0.11,130`;
    
    const response = await sendRequest('tools/call', {
      name: 'upload_study_data',
      arguments: {
        session_id: sessionId,
        data_format: 'csv',
        data_content: Buffer.from(csvData).toString('base64'),
        validation_level: 'basic'
      }
    });
    
    const result = JSON.parse(response.result.content[0].text);
    if (result.status !== 'success') {
      throw new Error('Failed to upload study data');
    }
  });
  
  // Test 4: Perform Meta-Analysis
  await runTest('Perform Meta-Analysis', async () => {
    const response = await sendRequest('tools/call', {
      name: 'perform_meta_analysis',
      arguments: {
        session_id: sessionId,
        heterogeneity_test: true,
        publication_bias: true,
        sensitivity_analysis: false
      }
    });
    
    const result = JSON.parse(response.result.content[0].text);
    if (result.status !== 'success') {
      throw new Error('Failed to perform meta-analysis');
    }
  });
  
  // Test 5: Generate Forest Plot
  await runTest('Generate Forest Plot', async () => {
    const response = await sendRequest('tools/call', {
      name: 'generate_forest_plot',
      arguments: {
        session_id: sessionId,
        plot_style: 'classic',
        confidence_level: 0.95
      }
    });
    
    const result = JSON.parse(response.result.content[0].text);
    if (result.status !== 'success') {
      throw new Error('Failed to generate forest plot');
    }
  });
  
  // Test 6: Assess Publication Bias
  await runTest('Assess Publication Bias', async () => {
    const response = await sendRequest('tools/call', {
      name: 'assess_publication_bias',
      arguments: {
        session_id: sessionId,
        methods: ['funnel_plot', 'egger_test']
      }
    });
    
    const result = JSON.parse(response.result.content[0].text);
    if (result.status !== 'success') {
      throw new Error('Failed to assess publication bias');
    }
  });
  
  // Test 7: Generate Report
  await runTest('Generate Report', async () => {
    const response = await sendRequest('tools/call', {
      name: 'generate_report',
      arguments: {
        session_id: sessionId,
        format: 'html',
        include_code: false
      }
    });
    
    const result = JSON.parse(response.result.content[0].text);
    if (result.status !== 'success') {
      throw new Error('Failed to generate report');
    }
  });
  
  // Cleanup
  server.kill();
  
  // Print summary
  console.log('\n' + '='.repeat(50));
  console.log('📊 Test Summary:');
  console.log(`✅ Passed: ${results.passed}`);
  console.log(`❌ Failed: ${results.failed}`);
  console.log(`📋 Total: ${results.passed + results.failed}`);
  console.log('='.repeat(50));
  
  if (results.failed > 0) {
    console.log('\n❌ Some tests failed!');
    process.exit(1);
  } else {
    console.log('\n✅ All tests passed!');
    
    // Clean up test session
    if (sessionId) {
      try {
        await fs.rm(`sessions/${sessionId}`, { recursive: true, force: true });
      } catch (e) {
        // Ignore cleanup errors
      }
    }
  }
}

// Run tests
testMVPServer().catch(error => {
  console.error('Test failed:', error);
  process.exit(1);
});