# Local AT Protocol Development Environment

This Docker Compose setup provides a local development environment for AT Protocol services.

## Services

- **PostgreSQL**: Shared database instance for all AT Protocol services
- **PLC Server**: DID PLC Directory Service

## Getting Started

1. Start the services:

   ```bash
   docker compose up -d
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
   docker-compose down -v --rmi all
   ```

7. Stop the services and remove containers (keeps databases and files for later use):

   ```bash
   docker-compose down
   ```
