---
name: coolify_cli
description: Manage Coolify applications, projects, and deployments using the coolify CLI. Use when the user wants to deploy apps, manage projects, configure GitHub integrations, handle environment variables, or interact with Coolify resources from the terminal.
---

# Coolify CLI – Apps, Projects & Deployment

Manage applications, projects, and deployments on a Coolify instance using the `coolify` CLI.

## Prerequisites

- The `coolify` CLI must be installed and available in `$PATH`
- A valid API token from the Coolify dashboard (`/security/api-tokens`)

## Safety Rule

- If a user wants to delete something, always ask for explicit confirmation before running the delete command.

## Context Setup

The CLI context is **auto-configured at container startup** when the `COOLIFY_API_TOKEN` environment variable is set. The entrypoint creates a `default` context pointing at:

- **URL**: `COOLIFY_API_URL` (defaults to `https://app.coolify.io`)
- **Token**: `COOLIFY_API_TOKEN`

To verify the auto-configured context:

```bash
coolify context verify
coolify context version
```

### Manual context setup (if not using the env var)

```bash
# Self-hosted instance
coolify context add <name> <url> <token> --default

# Cloud-hosted
coolify context set-token cloud <token>

# Verify connection
coolify context verify
```

## Application Workflows

### List and inspect apps

```bash
# List all applications
coolify app list

# Get details for a specific app
coolify app get <uuid>

# View logs
coolify app logs <uuid>
```

### Deploy an application

```bash
# Deploy by UUID
coolify deploy uuid <uuid>

# Deploy by name (easier)
coolify deploy name <app-name>

# Deploy multiple at once
coolify deploy batch app1,app2,app3

# Force re-deploy
coolify deploy name <app-name> --force
```

### Application lifecycle

```bash
coolify app start <uuid>
coolify app stop <uuid>
coolify app restart <uuid>
```

### Update application configuration

```bash
coolify app update <uuid> \
  --name "my-app" \
  --git-branch main \
  --git-repository https://github.com/org/repo \
  --domains "app.example.com" \
  --build-command "npm run build" \
  --start-command "npm start"
```

### Delete an application

```bash
coolify app delete <uuid> --force
```

## Deploying from Private GitHub Repositories

To deploy from private GitHub repos, a **GitHub App integration** must be configured in Coolify.

### Step 1: List existing GitHub App integrations

```bash
coolify github list
```

### Step 2: Create a GitHub App integration (if needed)

A GitHub App must first be created on GitHub (Settings > Developer settings > GitHub Apps), then registered in Coolify:

```bash
coolify github create \
  --name "My GitHub App" \
  --api-url "https://api.github.com" \
  --html-url "https://github.com" \
  --app-id <github-app-id> \
  --installation-id <installation-id> \
  --client-id <client-id> \
  --client-secret <client-secret> \
  --private-key-uuid <key-uuid>
```

The `--private-key-uuid` references a private key previously added to Coolify:

```bash
# Add the GitHub App's private key
coolify private-key add github-app-key @/path/to/private-key.pem

# List keys to get the UUID
coolify private-key list
```

### Step 3: Verify repo access

```bash
# List repos the GitHub App can access
coolify github repos <app-uuid>

# List branches for a specific repo
coolify github branches <app-uuid> owner/repo
```

### Step 4: Configure app to use the private repo

Use `coolify app update` to point the application at the private repository and branch:

```bash
coolify app update <app-uuid> \
  --git-repository "https://github.com/org/private-repo" \
  --git-branch "main"
```

Then deploy:

```bash
coolify deploy uuid <app-uuid>
```

## Environment Variables

### List and inspect

```bash
coolify app env list <app-uuid>
coolify app env get <app-uuid> <env-key-or-uuid>
```

### Create a variable

```bash
coolify app env create <app-uuid> \
  --key API_KEY \
  --value "secret123" \
  --build-time \
  --preview
```

### Sync from a .env file

Updates existing variables, creates missing ones. Does **not** delete variables absent from the file.

```bash
coolify app env sync <app-uuid> --file .env
coolify app env sync <app-uuid> --file .env.production --build-time --preview
```

### Delete a variable

```bash
coolify app env delete <app-uuid> <env-uuid>
```

## Projects

```bash
# List all projects
coolify projects list

# Get project environments
coolify projects get <uuid>
```

## Deployment Monitoring

```bash
# List all deployments
coolify deploy list

# View deployment details
coolify deploy get <deployment-uuid>

# View deployment logs (latest)
coolify app deployments logs <app-uuid>

# View specific deployment logs
coolify app deployments logs <app-uuid> <deployment-uuid>

# Follow logs in real time
coolify app deployments logs <app-uuid> --follow

# Cancel a deployment
coolify deploy cancel <deployment-uuid> --force
```

## Multi-Environment Workflow

Use contexts to manage staging and production:

```bash
# Add environments
coolify context add prod https://prod.coolify.io <prod-token>
coolify context add staging https://staging.coolify.io <staging-token>

# Deploy to staging
coolify --context=staging deploy name my-app

# Deploy to production
coolify --context=prod deploy name my-app

# Compare resources across environments
coolify --context=staging app list
coolify --context=prod app list
```

## Output Formats

All commands support `--format`:

```bash
# Human-readable table (default)
coolify app list

# JSON (for scripting / piping)
coolify app list --format=json

# Pretty-printed JSON (for debugging)
coolify app list --format=pretty
```

## Common Troubleshooting

| Issue | Resolution |
|-------|-----------|
| `context not found` | Run `coolify context list` and `coolify context use <name>` |
| `401 Unauthorized` | Token expired or invalid — generate a new one at `/security/api-tokens` |
| `connection refused` | Check the Coolify instance URL with `coolify context verify` |
| Deployment stuck | Check logs with `coolify app deployments logs <uuid> --follow` or cancel with `coolify deploy cancel <uuid>` |
| Private repo not accessible | Verify GitHub App with `coolify github repos <app-uuid>` |

## Additional Resources

- For the full CLI command reference (servers, databases, services, backups, teams, private keys), see [reference.md](reference.md)
- Coolify CLI repository: https://github.com/coollabsio/coolify-cli
