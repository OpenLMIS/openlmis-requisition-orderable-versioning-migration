#!/bin/bash

set -e

if [ -f migration.sql ]; then
  rm migration.sql
fi

PSQL="psql --single-transaction --set AUTOCOMMIT=off --set ON_ERROR_STOP=on --no-align -t --field-separator , --quiet"

echo "Read the latest orderables (the reference data database)"
${PSQL} -c "SELECT id, MAX(versionId) AS versionId FROM referencedata.orderables GROUP BY id" > orderables.csv

echo "Create migration file"
echo "Add steps to update orderable details in requisition line items (the requisition database)"
while IFS=, read -r id versionId ; do
  echo "UPDATE requisition.requisition_line_items SET orderableVersionId='${versionId}' WHERE orderableId = '${id}';" >> migration.sql
  echo "UPDATE requisition.available_products SET versionId='${versionId}' WHERE id = '${id}';" >> migration.sql
done < orderables.csv

echo "Apply migration (the requisition database)"
${PSQL} < migration.sql
