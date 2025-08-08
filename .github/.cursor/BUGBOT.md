# Review guidelines for CI workflows (.github)

- Use Buildx cache and linux/amd64 target
- Login to GHCR with GITHUB_TOKEN when pushing images
- Avoid TeX/PDF steps to keep build time reasonable
- Run Node build and (when feasible) R smoke tests
- Ensure Dockerfile uses rocker/r2u and installs required R packages via apt
