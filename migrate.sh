#!/bin/bash

set -e

if [ -f migration.sql ]; then
  rm migration.sql
fi

PSQL="psql --single-transaction --set AUTOCOMMIT=off --set ON_ERROR_STOP=on --no-align -t --field-separator , --quiet"

echo "Read the latest orderables (the reference data database)"
${PSQL} -c "SELECT id AS orderableId, MAX(versionNumber) AS orderableVersionNumber FROM referencedata.orderables GROUP BY id" > orderables.csv

echo "Read the latest facility type approved products (the reference data database)"
${PSQL} -c "SELECT id AS approvedProductId, MAX(versionNumber) AS approvedProductVersionNumber, orderableId AS approvedProductOrderableId FROM referencedata.facility_type_approved_products GROUP BY id, orderableId" > facility_type_approved_products.csv

echo "Create migration file"
echo "Add steps to update orderable details in requisition line items (the requisition database)"
while IFS=, read -r orderableId orderableVersionNumber; do
  echo "UPDATE requisition.requisition_line_items SET orderableVersionNumber='${orderableVersionNumber}' WHERE orderableId = '${orderableId}';" >> migration.sql
  echo "UPDATE requisition.available_products SET orderableVersionNumber='${orderableVersionNumber}' WHERE orderableId = '${orderableId}' ;" >> migration.sql
done < orderables.csv

echo "Add steps to update facility type approved products details in requisition line items (the requisition database)"
while IFS=, read -r  approvedProductId approvedProductVersionNumber approvedProductOrderableId; do
  echo "UPDATE requisition.requisition_line_items SET facilityTypeApprovedProductId='${approvedProductId}', facilityTypeApprovedProductVersionNumber='${approvedProductVersionNumber}' WHERE orderableId = '${approvedProductOrderableId}';" >> migration.sql
  echo "UPDATE requisition.available_products SET facilityTypeApprovedProductId='${approvedProductId}', facilityTypeApprovedProductVersionNumber = '${approvedProductVersionNumber}' WHERE orderableId = '${approvedProductOrderableId}' ;" >> migration.sql
done < facility_type_approved_products.csv

echo "Add steps to update orderable details in order line items (the fulfillment database)"
while IFS=, read -r orderableId orderableVersionNumber; do
  echo "UPDATE fulfillment.order_line_items SET orderableVersionNumber = '${orderableVersionNumber}' WHERE orderableId = '${orderableId}';" >> migration.sql
done < orderables.csv

echo "Add steps to update orderable details in shipment line items (the fulfillment database)"
while IFS=, read -r orderableId orderableVersionNumber; do
  echo "UPDATE fulfillment.shipment_line_items SET orderableVersionNumber = '${orderableVersionNumber}' WHERE orderableId = '${orderableId}';" >> migration.sql
done < orderables.csv

echo "Add steps to update orderable details in proof of delivery line items (the fulfillment database)"
while IFS=, read -r orderableId orderableVersionNumber; do
  echo "UPDATE fulfillment.proof_of_delivery_line_items SET orderableVersionNumber = '${orderableVersionNumber}' WHERE orderableId = '${orderableId}';" >> migration.sql
done < orderables.csv

echo "Apply migration (the requisition database)"
${PSQL} < migration.sql
