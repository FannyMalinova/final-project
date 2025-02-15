#!/bin/bash

set -e

cmd="$@"

# Check if the app is using AWS RDS. The USE_AWS_RDS environment variable is set in your Kubernetes deployment.
if [ "$USE_AWS_RDS" = "true" ]; then
    # If using AWS RDS, output a message and skip the database waiting logic.
    >&2 echo "Using AWS RDS for PostgreSQL. Skipping wait-for-postgres.sh script in the src folder."
else
    # If we are testing the app locally with docker-compose, wait for the PostgreSQL database to become ready.
    until PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -c '\q'; do
        >&2 echo "Postgres is unavailable - sleeping"
        sleep 1
    done
    # Output a message once the database is ready.
    >&2 echo "Postgres is up and ready"
fi

# Execute the command to start the Flask application.
# This line is crucial as it ensures that your Flask app starts regardless of the USE_AWS_RDS setting.
export DATABASE_URI="postgresql://${DB_USER}:${DB_PASS}@${DB_HOST}:5432/${DB_NAME}"
exec $cmd
