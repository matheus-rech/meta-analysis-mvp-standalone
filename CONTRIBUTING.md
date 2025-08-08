# Contributing to Meta-Analysis MVP

Thank you for your interest in contributing to the Meta-Analysis MVP project! 

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/meta-analysis-mvp.git`
3. Create a feature branch: `git checkout -b feature/your-feature-name`
4. Make your changes
5. Run tests and linting
6. Commit your changes: `git commit -m "Add your feature"`
7. Push to your fork: `git push origin feature/your-feature-name`
8. Create a Pull Request

## Development Setup

### Prerequisites
- Node.js 18+
- R 4.3.2+
- Docker (optional, for containerized development)

### Local Development

```bash
# Install dependencies
npm install

# Install R packages
Rscript scripts/install_packages.R

# Build TypeScript
npm run build

# Run linting
npm run lint

# Start development server
npm run dev
```

### Docker Development

```bash
# Build the Docker image
docker build -t meta-analysis-mvp:dev .

# Run with volume mounts for development
docker run -it --rm \
  -v $(pwd)/src:/app/src \
  -v $(pwd)/scripts:/app/scripts \
  meta-analysis-mvp:dev
```

## Code Style

### TypeScript/JavaScript
- Use ESLint configuration provided
- Follow existing code patterns
- Add JSDoc comments for public functions

### R Scripts
- Use consistent indentation (2 spaces)
- Comment complex logic
- Handle errors gracefully

## Testing

Before submitting a PR, ensure:

1. **TypeScript compiles**: `npm run build`
2. **Linting passes**: `npm run lint`
3. **R scripts parse**: `for f in scripts/*.R; do Rscript -e "parse(file='$f')"; done`
4. **Tests pass**: `node test-functions.js`

## Pull Request Process

1. Update README.md with details of changes if applicable
2. Ensure all CI checks pass
3. Request review from maintainers
4. Address review feedback
5. Squash commits if requested

## Commit Messages

Follow conventional commits format:

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Code style changes
- `refactor:` Code refactoring
- `test:` Test additions/changes
- `chore:` Maintenance tasks

Example: `feat: add subgroup analysis to meta-analysis function`

## Reporting Issues

Use GitHub Issues to report bugs or request features:

1. Check existing issues first
2. Use issue templates if available
3. Provide clear description and steps to reproduce
4. Include relevant logs or error messages

## Code of Conduct

- Be respectful and inclusive
- Welcome newcomers
- Focus on constructive criticism
- Help others learn and grow

## Questions?

Feel free to open an issue for questions or reach out to maintainers.

Thank you for contributing! 🎉
