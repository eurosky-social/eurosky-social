#!/bin/bash

set -ex

git submodule update --init --recursive

docker compose up -d

postgres_container=$(docker ps --filter "name=postgres" --format '{{.Names}}')
plc_container=$(docker ps --filter "name=plc" --format '{{.Names}}')
pds_container=$(docker ps --filter "name=pds.internal" --format '{{.Names}}')
relay_container=$(docker ps --filter "name=relay" --format '{{.Names}}')

until [ "$(docker inspect -f '{{.State.Health.Status}}' ${postgres_container})" = "healthy" ] && \
      [ "$(docker inspect -f '{{.State.Health.Status}}' ${plc_container})" = "healthy" ] && \
      [ "$(docker inspect -f '{{.State.Health.Status}}' ${pds_container})" = "healthy" ] && \
      [ "$(docker inspect -f '{{.State.Health.Status}}' ${relay_container})" = "healthy" ]; do sleep 2; done

# Hacking around some security checks in the relay when adding a host
echo "Adding pds.internal to relay"
docker exec -e PGPASSWORD=postgres  ${postgres_container} psql -h postgres -U postgres -d relay \
    -c "INSERT INTO host (hostname, no_ssl, account_limit, trusted, status, last_seq, account_count, created_at, updated_at) \
            VALUES ('pds.internal', true, 1000, true, 'active', -1, 0, NOW(), NOW()) \
            ON CONFLICT (hostname) DO NOTHING;"

docker compose restart relay

echo "Service ports:"
docker compose ps --format "table {{.Name}}\t{{.Service}}\t{{.Publishers}}"

read -p "Press enter to run PDS+relay tests"

node ./test_pds_relay.mjs