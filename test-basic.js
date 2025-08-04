
/**
 * Basic unit tests that don't require R environment
 * These tests focus on the Node.js/TypeScript components
 */

import { readFileSync, statSync } from 'fs';

console.log('=== Meta-Analysis MVP - Basic Unit Tests ===\n');

let testsPassed = 0;
let testsTotal = 0;

function test(name, testFunc) {
  testsTotal++;
  try {
    testFunc();
    console.log(`✅ ${name}`);
    testsPassed++;
  } catch (error) {
    console.log(`❌ ${name}: ${error.message}`);
  }
}

// Test 1: Check if main files exist
test('Main files exist', () => {
  const requiredFiles = [
    'build/index.js',
    'package.json',
    'tsconfig.json',
    '.eslintrc.json',
    'sonar-project.properties'
  ];
  
  requiredFiles.forEach(file => {
    try {
      const stats = statSync(file);
      if (!stats.isFile()) {
        throw new Error(`${file} is not a file`);
      }
    } catch (error) {
      throw new Error(`Required file ${file} not found`);
    }
  });
});

// Test 2: Check package.json structure
test('Package.json has required scripts', () => {
  const pkg = JSON.parse(readFileSync('package.json', 'utf8'));
  
  const requiredScripts = ['build', 'start', 'lint', 'test'];
  requiredScripts.forEach(script => {
    if (!pkg.scripts[script]) {
      throw new Error(`Missing script: ${script}`);
    }
  });
});

// Test 3: Check TypeScript compilation
test('TypeScript compilation works', () => {
  // This test passes if we got here, since build was successful
  const stats = statSync('build/index.js');
  if (!stats.isFile()) {
    throw new Error('TypeScript compilation failed - no build output');
  }
});

// Test 4: Check ESLint configuration
test('ESLint configuration is valid', () => {
  const eslintConfig = JSON.parse(readFileSync('.eslintrc.json', 'utf8'));
  
  if (!eslintConfig.parser) {
    throw new Error('ESLint parser not configured');
  }
  
  if (!eslintConfig.plugins || !eslintConfig.plugins.includes('@typescript-eslint')) {
    throw new Error('TypeScript ESLint plugin not configured');
  }
});

// Test 5: Check SonarCloud configuration
test('SonarCloud configuration exists', () => {
  const sonarConfig = readFileSync('sonar-project.properties', 'utf8');
  
  if (!sonarConfig.includes('sonar.projectKey=')) {
    throw new Error('SonarCloud project key not configured');
  }
  
  if (!sonarConfig.includes('sonar.sources=')) {
    throw new Error('SonarCloud sources not configured');
  }
});

// Test 6: Check GitHub Actions workflow
test('GitHub Actions workflow exists', () => {
  const workflowPath = '.github/workflows/ci.yml';
  const stats = statSync(workflowPath);
  
  if (!stats.isFile()) {
    throw new Error('GitHub Actions workflow file not found');
  }
  
  const workflow = readFileSync(workflowPath, 'utf8');
  
  const requiredJobs = ['nodejs-lint-test', 'r-check', 'sonarcloud'];
  requiredJobs.forEach(job => {
    if (!workflow.includes(job + ':')) {
      throw new Error(`GitHub Actions job '${job}' not found in workflow`);
    }
  });
});

// Summary
console.log('\n' + '='.repeat(50));
console.log(`📊 Test Summary:`);
console.log(`✅ Passed: ${testsPassed}`);
console.log(`❌ Failed: ${testsTotal - testsPassed}`);
console.log(`📋 Total: ${testsTotal}`);
console.log('='.repeat(50));

if (testsPassed === testsTotal) {
  console.log('🎉 All basic unit tests passed!');
  process.exit(0);
} else {
  console.log('❌ Some tests failed!');
  process.exit(1);
}