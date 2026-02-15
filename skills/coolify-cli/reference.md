# Coolify CLI – Full Command Reference

Complete reference for all `coolify` CLI commands. The main [SKILL.md](SKILL.md) covers app/project/deployment workflows. This file documents the remaining commands.

## Global Flags

All commands support these flags:

| Flag | Description |
|------|-------------|
| `--context <name>` | Use a specific context instead of default |
| `--host <fqdn>` | Override the Coolify instance hostname |
| `--token <token>` | Override the authentication token |
| `--format <format>` | Output format: `table` (default), `json`, `pretty` |
| `-s, --show-sensitive` | Show sensitive information (tokens, IPs) |
| `-f, --force` | Force operation (skip confirmations) |
| `--debug` | Enable debug mode |

## Servers

Commands accept `server` or `servers` interchangeably.

```bash
coolify server list
coolify server get <uuid>
coolify server get <uuid> --resources    # includes resource status
coolify server add <name> <ip> <key-uuid> [-p port] [-u user] [--validate]
coolify server remove <uuid>
coolify server validate <uuid>
coolify server domains <uuid>
```

## Databases

```bash
coolify database list
coolify database get <uuid>
coolify database start <uuid>
coolify database stop <uuid>
coolify database restart <uuid>
coolify database delete <uuid> [--delete-volumes] [--docker-cleanup]
```

### Create database

Supported types: `postgresql`, `mysql`, `mariadb`, `mongodb`, `redis`, `keydb`, `clickhouse`, `dragonfly`

```bash
coolify database create postgresql \
  --server-uuid <uuid> \
  --project-uuid <uuid> \
  --environment-name production \
  --name mydb \
  --instant-deploy
```

### Database backups

```bash
coolify database backup list <db-uuid>
coolify database backup create <db-uuid> \
  --frequency "0 2 * * *" \
  --enabled \
  --save-s3 \
  --s3-storage-uuid <uuid> \
  --retention-days-local 7
coolify database backup trigger <db-uuid> <backup-uuid>
coolify database backup executions <db-uuid> <backup-uuid>
coolify database backup delete <db-uuid> <backup-uuid>
```

## Services

```bash
coolify service list
coolify service get <uuid>
coolify service start <uuid>
coolify service stop <uuid>
coolify service restart <uuid>
coolify service delete <uuid>
```

### Service environment variables

```bash
coolify service env list <svc-uuid>
coolify service env get <svc-uuid> <env-key-or-uuid>
coolify service env create <svc-uuid> --key KEY --value val
coolify service env update <svc-uuid> <env-uuid> --value newval
coolify service env delete <svc-uuid> <env-uuid>
coolify service env sync <svc-uuid> --file .env
```

## Teams

```bash
coolify team list
coolify team get <team-id>
coolify team current
coolify team members list [team-id]
```

## Private Keys

Commands accept `private-key`, `private-keys`, `key`, or `keys`.

```bash
coolify private-key list
coolify private-key add <name> <key>         # inline key
coolify private-key add <name> @~/.ssh/id_rsa  # from file
coolify private-key remove <uuid>
```

## Resources

```bash
coolify resources list
```

## Configuration & Updates

```bash
coolify config          # show config file location
coolify update          # update CLI to latest version
coolify completion bash # generate shell completions (bash/zsh/fish/powershell)
```
