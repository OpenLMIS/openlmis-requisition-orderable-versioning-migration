FROM openlmis/run-sql

COPY migration.sql /migration.sql
COPY migrate.sh /migrate.sh
RUN chmod u+x /migrate.sh

CMD /migrate.sh