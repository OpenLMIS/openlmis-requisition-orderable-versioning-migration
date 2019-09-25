#!/bin/bash

set -e

PSQL="psql --single-transaction --set AUTOCOMMIT=off --set ON_ERROR_STOP=on --no-align -t --field-separator ,"

echo "Apply migration (the requisition database)"
${PSQL} < migration.sql

echo "Migration finished!"
