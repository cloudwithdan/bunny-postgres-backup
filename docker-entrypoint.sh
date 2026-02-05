#!/bin/bash
set -eo pipefail

# bunny
: "${BUNNY_STORAGE_ZONE:?Please set the environment variable.}"
: "${BUNNY_ACCESS_KEY:?Please set the environment variable.}"
BUNNY_PATH="${BUNNY_PATH:-}"

# postgres
: "${POSTGRES_DB:?Please set the environment variable.}"
POSTGRES_HOST="${POSTGRES_HOST:-postgres}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
POSTGRES_USER="${POSTGRES_USER:-postgres}"
POSTGRES_VERSION="${POSTGRES_VERSION:-18}"

POSTGRES_VERSIONS=(16 17 18)
if [[ ! " ${POSTGRES_VERSIONS[*]} " =~ " ${POSTGRES_VERSION} " ]]; then
  printf "error: POSTGRES_VERSION should be one of these: %s\n" "${POSTGRES_VERSIONS[*]}"
  exit 1
fi

# logic starts here
BACKUP_FILE_NAME=$(date +"${POSTGRES_DB}-%F-%H_%M_%S.sql")

# dump command
DUMP_CMD=""
if [[ -n "${POSTGRES_PASSWORD}" ]]; then
  DUMP_CMD+="PGPASSWORD=\"${POSTGRES_PASSWORD}\" "
fi
DUMP_CMD+="/usr/libexec/postgresql${POSTGRES_VERSION}/pg_dump "
DUMP_CMD+="--dbname=\"${POSTGRES_DB}\" "
DUMP_CMD+="--file=\"${BACKUP_FILE_NAME}\" "
DUMP_CMD+="--format=c "
DUMP_CMD+="--host=\"${POSTGRES_HOST}\" "
DUMP_CMD+="--port=\"${POSTGRES_PORT}\" "
DUMP_CMD+="--username=\"${POSTGRES_USER}\" "

# upload command
BUNNY_URL="https://storage.bunnycdn.com/${BUNNY_STORAGE_ZONE}"
if [[ -n "${BUNNY_PATH}" ]]; then
  BUNNY_URL+="/${BUNNY_PATH}"
fi
BUNNY_URL+="/${BACKUP_FILE_NAME}"

UPLOAD_CMD="curl --fail --silent --request PUT "
UPLOAD_CMD+="--url \"${BUNNY_URL}\" "
UPLOAD_CMD+="--header \"AccessKey: ${BUNNY_ACCESS_KEY}\" "
UPLOAD_CMD+="--header \"Content-Type: application/octet-stream\" "
UPLOAD_CMD+="--upload-file \"./${BACKUP_FILE_NAME}\""

# let's go
SECONDS=0

printf "Dumping the database..."
eval "${DUMP_CMD}"
printf " Done.\n"

printf "Uploading to Bunny.net..."
eval "${UPLOAD_CMD}"
printf " Done.\n"

# cleanup
rm -f "./${BACKUP_FILE_NAME}"

printf "Backup completed in %s seconds.\n" "${SECONDS}"
