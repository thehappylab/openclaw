---
name: new_project
description: Scaffold a new project from the thehappylab/app-template, deploy it on Coolify, and set up Umami analytics tracking. Use when the user wants to create a new project, start a new app, or bootstrap a new website.
---

# New Project – Full Setup

Create a new project from the `thehappylab/app-template` GitHub template, deploy it to Coolify with a Docker Compose buildpack, and wire up Umami analytics.

## Prerequisites

- `gh` CLI authenticated (`GH_TOKEN` env var or `gh auth status`)
- `coolify` CLI configured — see the **coolify_cli** skill for setup and usage
- Umami API access configured — see the **umami_api** skill for setup and usage
- Access to the `thehappylab` GitHub organization

## Template tech stack

The template `thehappylab/app-template` ships with:

- Next.js (App Router)
- Better Auth
- Tailwind CSS
- shadcn/ui
- SQLite database

No manual setup of these is needed — they come from the template.

## UI implementation rule

When the user asks to build an application/website and implementation starts:

- Remove unnecessary template components, pages, sections, and demo content as early as possible.
- Keep only what is needed for the requested product scope.
- Use the **frontend-desin** skill to design and polish an awesome-looking UI before finalizing.
- Prefer a clean, focused, visually strong interface over shipping template leftovers.

## Step 1: Get the project name

Ask the user for a **project name** if not already provided. Validate the name:

- Lowercase alphanumeric with hyphens (e.g. `my-cool-app`)
- No spaces, no underscores, no uppercase

This name is used everywhere:

| Derived value | Pattern |
|---------------|---------|
| GitHub repo | `thehappylab/<projectname>` |
| Domain | `<projectname>.thehappylab.com` |
| Coolify project | `<projectname as nice looking>` |
| Coolify app | `<projectname as nice looking>` |
| Umami website | `<projectname>.thehappylab.com` |

## Step 2: Create GitHub repository from template

> **Important:** Always create the repository as **private**. Never use `--public`.

```bash
gh repo create "thehappylab/<projectname>" \
  --template thehappylab/app-template \
  --private \
  --clone
cd <projectname>
```

Verify:

```bash
gh repo view "thehappylab/<projectname>" --json name,url --jq '.url'
```

## Step 3: Set up Coolify project

Use the **coolify_cli** skill for CLI command details.

### 3a. Look up required UUIDs

Use `coolify server list` to find the server named **coolify-apps** and note its UUID.

Use `coolify github list` to find the existing GitHub App integration and note its UUID.

### 3b. Create a new Coolify project

 Make it a nice looking name and meaningfull description


```bash
curl -s -X POST "${COOLIFY_API_URL}/api/v1/projects" \
  -H "Authorization: Bearer ${COOLIFY_API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"name":"<name>", "description":"<description>"}' | jq
```

Note the `uuid` from the response.

### 3c. Create the Coolify application (Docker Compose buildpack)

Make the name nice looking name and meaningfull description


```bash
curl -s -X POST "${COOLIFY_API_URL}/api/v1/applications/private-github-app" \
  -H "Authorization: Bearer ${COOLIFY_API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "<name>",
    "description": "<description>",
    "server_uuid": "<server-uuid>",
    "project_uuid": "<project-uuid>",
    "environment_name": "production",
    "type": "dockercompose",
    "git_repository": "thehappylab/<projectname>",
    "git_branch": "main",
    "github_app_uuid": "<github-app-uuid>",
    "domains": "<projectname>.thehappylab.com:3000",
    "instant_deploy": true
  }' | jq
```

Note the Coolify application `uuid` from the response.

### 3d. Verify

Use `coolify app list` to confirm the app exists.

## Step 4: Create Umami website and inject tracking

Use the **umami_api** skill for API command details.

### 4a. Create the website in Umami

Create a new website with name `<projectname>` and domain `<projectname>.thehappylab.com` using the Umami "Create a website" API (`POST /api/websites`).

Note the `id` from the response — this is the **Umami website ID**.

### 4b. Inject the Umami tracking script

In the cloned repository, edit `src/app/layout.tsx` (or `app/layout.tsx`, whichever exists). Add the Umami `<script>` tag inside the `<head>` element:

```tsx
<script
  defer
  src="<UMAMI_API_URL value>/script.js"
  data-website-id="<umami-website-id>"
/>
```

Use the actual `UMAMI_API_URL` value (not the env var reference) and the website ID from step 4a.

> **Next.js note:** If the layout uses `next/script`, use the `Script` component instead:
> ```tsx
> import Script from "next/script";
>
> <Script
>   defer
>   src="<UMAMI_API_URL value>/script.js"
>   data-website-id="<umami-website-id>"
>   strategy="afterInteractive"
> />
> ```

### 4c. Commit and push

```bash
git add .
git commit -m "Add Umami analytics tracking"
git push origin main
```

## Step 5: Deploy

Use `coolify deploy name <projectname>` to trigger a deployment and monitor with `coolify app deployments logs <app-uuid> --follow`. See the **coolify_cli** skill for details.

Wait for the deployment to complete successfully.

## Step 6: Verify everything works

Run these checks and report the results to the user:

1. **GitHub repo** exists — `gh repo view "thehappylab/<projectname>"`
2. **Coolify app** is running — `coolify app get <app-uuid>`
3. **Umami website** is registered — list websites and filter by domain `<projectname>.thehappylab.com`
4. **Site is live** at `https://<projectname>.thehappylab.com`

Present a summary to the user:

```
New project "<projectname>" is ready!

  GitHub:  https://github.com/thehappylab/<projectname>
  Website: https://<projectname>.thehappylab.com
  Coolify: <app-uuid>
  Umami:   <umami-website-id>
```

## Troubleshooting

For Coolify issues (auth, deployment failures, server problems), see the **coolify_cli** skill troubleshooting section.

For Umami issues (auth, empty responses, 404s), see the **umami_api** skill troubleshooting section.

| Issue | Resolution |
|-------|-----------|
| `gh` auth fails | Check `GH_TOKEN` or run `gh auth login` |
| Template repo not found | Verify `thehappylab/app-template` exists: `gh repo view thehappylab/app-template` |
| Umami tracking not appearing | Verify `data-website-id` matches; check browser Network tab for `script.js` |
| Domain not resolving | DNS for `*.thehappylab.com` must be configured to point at the Coolify server |
