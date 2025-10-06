# Eurosky

Development monorepo for AT Protocol (Bluesky) tools, services, and ecosystem projects.

## Overview

This repository consolidates Eurosky development work, combining upstream submodules with custom tools and services for building and operating within the AT Protocol ecosystem.

## Getting Started

### Clone with Submodules

```bash
git clone --recurse-submodules https://github.com/eurosky-social/eurosky-social.git
cd eurosky-social
```

If already cloned, initialize submodules:

```bash
git submodule update --init --recursive
```

### Working with Submodules

Update all submodules to latest:

```bash
git submodule update --remote --merge
```

Update specific submodule:

```bash
cd <submodule-name>
git pull origin main
```

## License

TBD