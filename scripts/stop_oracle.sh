#!/bin/bash
# Stop Oracle 19c container gracefully
IMAGE="oracle19c-db:setup"
CONTAINER_NAME="oracle19c"
ORACLE_HOME="/u01/app/oracle/product/19.3.0.0/db_1"
ORACLE_SID="cdb1"

echo "[$(date)] Shutting down Oracle 19c..."

# Stop database cleanly
docker exec ${CONTAINER_NAME} /bin/sh -c "export ORACLE_HOME=${ORACLE_HOME}; export ORACLE_SID=${ORACLE_SID}; export PATH=\$ORACLE_HOME/bin:\$PATH; dbshut \$ORACLE_HOME" 2>/dev/null || true

# Stop listener
docker exec ${CONTAINER_NAME} /bin/sh -c "export ORACLE_HOME=${ORACLE_HOME}; export PATH=\$ORACLE_HOME/bin:\$PATH; lsnrctl stop" 2>/dev/null || true

# Stop container
docker stop ${CONTAINER_NAME}

echo "[$(date)] Oracle 19c stopped."