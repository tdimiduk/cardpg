---
name: dev_server
description: Manage the CardPG development server (check status, start, check logs)
---

# Skill: dev_server

This skill helps you manage the `process-compose` based development server used for the CardPG project.

## Capabilities

1.  **Check Status**: Verify if the development server is running.
2.  **Start Server**: Start the server if it is not running.
3.  **Check Logs**: Inspect the logs for compilation errors or runtime issues.

## Instructions

### 1. Check/Start Server

The `./scripts/dev` script is idempotent. To ensure the server is running, simply execute it in the background:

**Command:**

```bash
nohup ./scripts/dev > /dev/null 2>&1 &
```

Wait a few seconds for it to initialize if it wasn't already running.

### 2. Check Logs

To check for compilation errors (Reflex or Haskell) or runtime logs, look at the main log file.

**Log Path:**
`./scratch/logs/process-compose.log`

**Command to Read (last 50 lines):**

```bash
tail -n 50 ./scratch/logs/process-compose.log
```

**Common Patterns to Look For:**

- **Compiling...**: The server is rebuilding. Wait if you see this.
- **error:** / **warning:**: GHC compilation errors.
- **Ok, modules loaded:**: Compilation successful.

## Usage in Workflows

- Use this skill at the beginning of `haskell` or `reflex` coding sessions to ensure the environment is ready.
- Use the **Check Logs** capability after making code changes to verify successful compilation.
