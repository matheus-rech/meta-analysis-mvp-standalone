#!/bin/bash

# Setup Git Hooks for Meta-Analysis MVP
# This script sets up helpful git hooks for development

echo "Setting up Git hooks..."

# Create hooks directory if it doesn't exist
mkdir -p .git/hooks

# Create pre-push hook
cat > .git/hooks/pre-push << 'EOF'
#!/bin/bash

echo "Running pre-push checks..."

# Check if TypeScript builds
echo "✓ Checking TypeScript compilation..."
npm run build > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "❌ TypeScript compilation failed. Please fix errors before pushing."
    exit 1
fi

# Run linting
echo "✓ Running ESLint..."
npm run lint > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "⚠️  Linting warnings detected. Consider fixing them."
    # Don't block push for linting warnings
fi

# Check R scripts syntax
echo "✓ Checking R scripts syntax..."
for script in scripts/*.R; do
    Rscript -e "tryCatch(parse(file='$script'), error=function(e) quit(status=1))" > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "❌ R script syntax error in $script"
        exit 1
    fi
done

echo "✅ All pre-push checks passed!"
EOF

# Make hook executable
chmod +x .git/hooks/pre-push

echo "✅ Git hooks setup complete!"
echo ""
echo "The following hook has been installed:"
echo "  • pre-push: Runs TypeScript build, linting, and R syntax checks"
echo ""
echo "To skip hooks temporarily, use: git push --no-verify"
