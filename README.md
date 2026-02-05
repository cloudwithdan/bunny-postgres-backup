# Bunny Postgres Backup

A lightweight Docker image for backing up PostgreSQL databases to [Bunny.net](https://bunny.net) storage.

## Features

- Supports PostgreSQL 16, 17, and 18
- Uploads backups directly to Bunny.net storage using their native API
- Timestamped backup files (`dbname-YYYY-MM-DD-HH_MM_SS.sql`)
- Optional webhook heartbeat for monitoring (e.g., WebGazer, Uptime Kuma)
- Designed for Kubernetes CronJobs

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `BUNNY_STORAGE_ZONE` | Yes | - | Your Bunny storage zone name |
| `BUNNY_ACCESS_KEY` | Yes | - | Storage zone password/API key |
| `BUNNY_PATH` | No | - | Subfolder path within the storage zone |
| `POSTGRES_DB` | Yes | - | Database name to backup |
| `POSTGRES_HOST` | No | `postgres` | Database host |
| `POSTGRES_PORT` | No | `5432` | Database port |
| `POSTGRES_USER` | No | `postgres` | Database user |
| `POSTGRES_PASSWORD` | No | - | Database password |
| `POSTGRES_VERSION` | No | `18` | PostgreSQL version (16, 17, 18) |
| `HEARTBEAT_URL` | No | - | Heartbeat URL for monitoring |

## Usage

### Docker
```bash
docker run --rm \
  -e BUNNY_STORAGE_ZONE=my-storage-zone \
  -e BUNNY_ACCESS_KEY=your-access-key \
  -e BUNNY_PATH=backups/myapp \
  -e POSTGRES_DB=mydb \
  -e POSTGRES_HOST=localhost \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=secret \
  -e POSTGRES_VERSION=16 \
  cloudwithdan/bunny-postgres-backup:latest
```

### Kubernetes CronJob
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: myapp-pg-backup
  namespace: myapp
spec:
  schedule: "0 0 * * *"  # daily at midnight
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: postgres-backup
            image: cloudwithdan/bunny-postgres-backup:latest
            env:
            - name: BUNNY_STORAGE_ZONE
              value: "my-storage-zone"
            - name: BUNNY_PATH
              value: "myapp-pg"
            - name: BUNNY_ACCESS_KEY
              valueFrom:
                secretKeyRef:
                  name: bunny-creds
                  key: ACCESS_KEY
            - name: POSTGRES_DB
              value: "myapp"
            - name: POSTGRES_HOST
              value: "myapp-postgresql.myapp.svc.cluster.local"
            - name: POSTGRES_PORT
              value: "5432"
            - name: POSTGRES_USER
              valueFrom:
                secretKeyRef:
                  name: myapp-pg-creds
                  key: username
            - name: POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: myapp-pg-creds
                  key: password
            - name: POSTGRES_VERSION
              value: "16"
          restartPolicy: OnFailure
```

### Creating the Bunny credentials secret
```bash
kubectl create secret generic bunny-creds \
  --namespace myapp \
  --from-literal=ACCESS_KEY=your-storage-zone-password
```

## Backup Format

Backups are created using `pg_dump` with the custom format (`--format=c`), which:

- Compresses the output automatically
- Allows selective restore of tables/schemas
- Supports parallel restore with `pg_restore`

## Restoring a Backup

1. Download the backup from Bunny.net storage
2. Restore using `pg_restore`:
```bash
pg_restore \
  --host=localhost \
  --port=5432 \
  --username=postgres \
  --dbname=mydb \
  --verbose \
  mydb-2025-02-05-00_00_00.sql
```

## Monitoring

Set `HEARTBEAT_URL` to receive a ping after each successful backup. Compatible with:

- [WebGazer](https://webgazer.io)
- [Uptime Kuma](https://uptime.kuma.pet)
- [Healthchecks.io](https://healthchecks.io)
- Any service accepting HTTP GET requests

## License

Copyright © 2026, Daniel Nikoloski. Released under the [GPL License](LICENSE).
