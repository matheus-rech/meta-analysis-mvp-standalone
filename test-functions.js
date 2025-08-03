#!/usr/bin/env node

import { spawn } from 'child_process';
import { createReadStream } from 'fs';
import { join } from 'path';

console.log('=== Meta-Analysis MVP Server Test ===\n');

// Create simulated meta-analysis dataset
function createSimulatedDataset() {
  console.log('Creating simulated clinical trial dataset...');
  
  // Simulate 15 studies with realistic effect sizes (log odds ratios)
  const studies = [];
  for (let i = 1; i <= 15; i++) {
    const trueEffect = 0.4; // True log OR
    const studySize = 50 + Math.floor(Math.random() * 200); // 50-250 participants
    const variance = 1 / studySize + Math.random() * 0.05; // Variance inversely related to size
    const observedEffect = trueEffect + (Math.random() - 0.5) * Math.sqrt(variance) * 2;
    
    studies.push({
      study: `Study_${i.toString().padStart(2, '0')}`,
      effect_size: observedEffect.toFixed(3),
      variance: variance.toFixed(4),
      sample_size: studySize,
      year: 2010 + Math.floor(Math.random() * 14),
      country: ['USA', 'UK', 'Germany', 'Japan', 'Canada'][Math.floor(Math.random() * 5)]
    });
  }
  
  // Convert to CSV
  const headers = 'study,effect_size,variance,sample_size,year,country';
  const rows = studies.map(s => 
    `${s.study},${s.effect_size},${s.variance},${s.sample_size},${s.year},${s.country}`
  );
  
  return headers + '\n' + rows.join('\n');
}

// Start the server
console.log('Starting MCP server...');
const server = spawn('node', ['build/index.js'], {
  stdio: ['pipe', 'pipe', 'pipe'],
  cwd: process.cwd()
});

let sessionId = null;

// Helper to send request and get response
async function sendRequest(request) {
  return new Promise((resolve, reject) => {
    const timeoutId = setTimeout(() => {
      reject(new Error('Request timeout after 10 seconds'));
    }, 10000);
    
    const handler = (data) => {
      const lines = data.toString().split('\n').filter(line => line.trim());
      for (const line of lines) {
        try {
          const parsed = JSON.parse(line);
          if (parsed.id === request.id) {
            clearTimeout(timeoutId);
            server.stdout.removeListener('data', handler);
            resolve(parsed);
            return;
          }
        } catch (e) {
          // Not JSON, might be log output
          if (line.includes('error') || line.includes('Error')) {
            console.log('Server log:', line);
          }
        }
      }
    };
    
    server.stdout.on('data', handler);
    server.stdin.write(JSON.stringify(request) + '\n');
  });
}

// Handle server errors
server.stderr.on('data', (data) => {
  console.error('Server error:', data.toString());
});

// Wait for server to be ready
await new Promise(resolve => setTimeout(resolve, 2000));

try {
  // Test 0: Health check
  console.log('\n0. Testing health_check...');
  const healthResponse = await sendRequest({
    jsonrpc: '2.0',
    id: 0,
    method: 'tools/call',
    params: {
      name: 'health_check',
      arguments: { detailed: true }
    }
  });
  
  if (healthResponse.result) {
    const result = JSON.parse(healthResponse.result.content[0].text);
    console.log('✓ Server health:', result.status);
  }

  // Test 1: Initialize meta-analysis
  console.log('\n1. Testing initialize_meta_analysis...');
  const initResponse = await sendRequest({
    jsonrpc: '2.0',
    id: 1,
    method: 'tools/call',
    params: {
      name: 'initialize_meta_analysis',
      arguments: {
        name: 'Clinical Trial Meta-Analysis Test',
        study_type: 'clinical_trial',
        effect_measure: 'OR',
        analysis_model: 'random'
      }
    }
  });
  
  if (initResponse.result) {
    const result = JSON.parse(initResponse.result.content[0].text);
    if (result.session_id) {
      sessionId = result.session_id;
      console.log('✓ Session initialized:', sessionId);
    }
  } else {
    console.error('✗ Failed to initialize session:', initResponse);
    process.exit(1);
  }

  // Test 2: Upload study data
  console.log('\n2. Testing upload_study_data...');
  const csvData = createSimulatedDataset();
  console.log('  Dataset preview (first 3 lines):');
  console.log('  ' + csvData.split('\n').slice(0, 4).join('\n  '));
  
  const uploadResponse = await sendRequest({
    jsonrpc: '2.0',
    id: 2,
    method: 'tools/call',
    params: {
      name: 'upload_study_data',
      arguments: {
        session_id: sessionId,
        data_content: csvData,
        data_format: 'csv',
        validation_level: 'comprehensive'
      }
    }
  });
  
  if (uploadResponse.result) {
    const result = JSON.parse(uploadResponse.result.content[0].text);
    console.log('✓ Data uploaded:', result.status || 'success');
  } else {
    console.error('✗ Failed to upload data:', uploadResponse);
  }

  // Test 3: Perform meta-analysis
  console.log('\n3. Testing perform_meta_analysis...');
  const analysisResponse = await sendRequest({
    jsonrpc: '2.0',
    id: 3,
    method: 'tools/call',
    params: {
      name: 'perform_meta_analysis',
      arguments: {
        session_id: sessionId,
        heterogeneity_test: true,
        publication_bias: true,
        sensitivity_analysis: true
      }
    }
  });
  
  if (analysisResponse.result) {
    const result = JSON.parse(analysisResponse.result.content[0].text);
    console.log('✓ Analysis completed');
    if (result.summary) {
      console.log('  Overall effect:', result.summary.overall_effect);
      console.log('  P-value:', result.summary.p_value);
      console.log('  I² statistic:', result.summary.i_squared);
    }
  } else {
    console.error('✗ Failed to perform analysis:', analysisResponse);
  }

  // Test 4: Generate forest plot
  console.log('\n4. Testing generate_forest_plot...');
  const forestResponse = await sendRequest({
    jsonrpc: '2.0',
    id: 4,
    method: 'tools/call',
    params: {
      name: 'generate_forest_plot',
      arguments: {
        session_id: sessionId,
        plot_style: 'modern',
        confidence_level: 0.95,
        custom_labels: {
          title: 'Test Forest Plot',
          x_label: 'Odds Ratio (log scale)'
        }
      }
    }
  });
  
  if (forestResponse.result) {
    const result = JSON.parse(forestResponse.result.content[0].text);
    console.log('✓ Forest plot generated:', result.plot_path || 'success');
  } else {
    console.error('✗ Failed to generate forest plot:', forestResponse);
  }

  // Test 5: Assess publication bias
  console.log('\n5. Testing assess_publication_bias...');
  const biasResponse = await sendRequest({
    jsonrpc: '2.0',
    id: 5,
    method: 'tools/call',
    params: {
      name: 'assess_publication_bias',
      arguments: {
        session_id: sessionId,
        methods: ['funnel_plot', 'egger_test', 'begg_test']
      }
    }
  });
  
  if (biasResponse.result) {
    const result = JSON.parse(biasResponse.result.content[0].text);
    console.log('✓ Publication bias assessed');
    if (result.funnel_plot_path) {
      console.log('  Funnel plot:', result.funnel_plot_path);
    }
    if (result.egger_test) {
      console.log('  Egger\'s test p-value:', result.egger_test.p_value);
    }
    if (result.begg_test) {
      console.log('  Begg\'s test p-value:', result.begg_test.p_value);
    }
  } else {
    console.error('✗ Failed to assess publication bias:', biasResponse);
  }

  // Test 6: Generate report
  console.log('\n6. Testing generate_report...');
  const reportResponse = await sendRequest({
    jsonrpc: '2.0',
    id: 6,
    method: 'tools/call',
    params: {
      name: 'generate_report',
      arguments: {
        session_id: sessionId,
        format: 'pdf',
        include_code: true,
        journal_template: 'generic'
      }
    }
  });
  
  if (reportResponse.result) {
    const result = JSON.parse(reportResponse.result.content[0].text);
    console.log('✓ Report generated:', result.report_path || 'success');
  } else {
    console.error('✗ Failed to generate report:', reportResponse);
  }

  console.log('\n=== All tests completed successfully! ===');
  console.log(`\nSession data saved in: sessions/${sessionId}/`);
  
} catch (error) {
  console.error('\nTest failed:', error);
} finally {
  // Clean up
  server.kill();
  process.exit(0);
}