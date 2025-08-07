# Meta-Analysis MVP

A minimal, functional MVP for running meta-analysis through the Model Context Protocol (MCP).

## Quick Start

```bash
docker pull mmrech/meta-analysis-mvp:latest
docker run -it --rm -v $(pwd)/sessions:/app/sessions mmrech/meta-analysis-mvp:latest
```

## Available Tags

- `latest` - Latest stable release
- `dev` - Development version
- `v1.0.0` - Specific version tags

## Features

- ✅ Complete meta-analysis workflow
- ✅ R integration with meta and metafor packages
- ✅ File-based session management
- ✅ Forest and funnel plot generation
- ✅ Publication bias assessment
- ✅ HTML/PDF report generation

## Environment Variables

- `NODE_ENV` - Set to `production` or `development`
- `SESSIONS_DIR` - Directory for session data (default: `/app/sessions`)
- `SCRIPTS_DIR` - Directory for R scripts (default: `/app/scripts`)

## Volumes

Mount your local sessions directory to persist data:
```bash
-v /path/to/local/sessions:/app/sessions
```

## Supported Platforms

- `linux/amd64` - Intel/AMD 64-bit
- `linux/arm64` - ARM 64-bit (Apple Silicon, AWS Graviton)

## Health Check

The container includes a health check that verifies both Node.js and R are functional:

```bash
docker inspect --format='{{.State.Health.Status}}' <container_id>
```

## Source Code

GitHub: [https://github.com/mmrech/meta-analysis-mvp](https://github.com/mmrech/meta-analysis-mvp)

## License

MIT
