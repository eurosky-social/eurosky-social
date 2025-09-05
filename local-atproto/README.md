# Local AT Protocol Development Environment

This Docker Compose setup provides a local development environment for AT Protocol services.

## Services

- **PostgreSQL**: Shared database instance for all AT Protocol services
- **PLC Server**: DID PLC Directory Service
- **PDS Server**: Personal Data Server
- **Relay Server**: Real-time message relay service

## Getting Started

1. Start the services:

   ```bash
   ./atproto-up.sh
   ```

2. Check service health:

   ```bash
   docker compose ps
   ```

3. View logs:

   ```bash
   docker compose logs -f plc
   ```

4. View exposed ports:

   ```bash
   docker compose port plc 3000
   ```

5. Connect to PostgreSQL:

   ```bash
   docker compose exec postgres psql -U atproto -d atproto
   ```

6. Stop the services, remove the containers, and clean up volumes and images (deletes databases and files):

   ```bash
   docker-compose down -v
   ```

7. Stop the services and remove containers (keeps databases and files for later use):

   ```bash
   docker-compose down
   ```

8. Connect to the relay using the [listen_to_relay](../listen_to_relay) script:  
  _NOTE: listen_to_relay it's not working properly ATM, still some events are visible..._

   ```bash
   PORT=$(docker compose port relay 2470)
   echo "Relay port: $PORT"

   cd ../listen_to_relay
   node index.mjs ws://localhost:$PORT
   ```