# Requisition Orderable Versioning Migration (Cross-Service)

Cross service migration of orderable versioning used by the requisition service.

## Pre-requisites

* Already using OpenLMIS 3.6.X.
* Hosting OpenLMIS inside Docker with Docker Compose, and using PostgreSQL or AWS RDS as the database, with all OpenLMIS services using the same database instance.
* Requires administrator-level server access.

It is **strongly** suggested to run the migration on a staging/test server with a copy of production data first in order to verify the migration before running on production server.

## Migration instructions

Pre-planning: Schedule downtime to perform the upgrade; do the upgrade on a Test/Staging server in advance before Production.

1. Bring server offline (so no more edits to data will be accepted from users). Stop the OpenLMIS services (docker-compose down).
2. Take full database backup. (And make sure you have a backup of the code/services deployed as well so you could roll back if necessary.)
3. Upgrade to OpenLMIS 3.7 components (usual steps to change versions of components used in your ref-distro docker-compose.yml).
4. Start the server to run OpenLMIS and apply components migrations (docker-compose up).
5. After successful start bring server offline one more time (wait about 5 min to ensure that all migrations were applied).
6. Run the migration script. See section below for details.
7. Start the server to run OpenLMIS again (docker-compose up).
8. Run some manual tests to ensure the system is in good health (try viewing a requisition template, check if each template is related with all facility types).
9. Bring server online (begin accepting outside traffic from users again).


## Usage

This image is based off of openlmis/run-sql, and so the environment variables needed for that image are needed here. In particular, you need the configuration file found [here](https://github.com/OpenLMIS/openlmis-ref-distro/blob/master/settings-sample.env).

Next simply run the migration script using Docker:

```bash
docker run --rm --env-file settings.env openlmis/requisition-orderable-versioning-migration
```

That's it - the migration will run and give you output about its progress.

## Building

The Docker image is built on Docker Hub. In order to build it locally, simply run:

```bash
docker build -t openlmis/requisition-orderable-versioning-migration .
```

## Script details

This script performs the migration to handle orderable versioning in the requisition service. The migration firstly retrieve the latest version of all orderables in the system. Then it sets a correct orderable version id for each orderable used in any requisition.

See further information:

JIRA Ticket: [OLMIS-6413](https://openlmis.atlassian.net/browse/OLMIS-6413)

## Error reporting

If the script is run twice, it should not corrupt the data, since it does not modify the schema - we only set orderable versionId field in requisition line items. Any additional data that was added in the meantime will be migrated.
