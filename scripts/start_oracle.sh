#!/bin/bash
# Start Oracle 19c container with database
# Container runs as root internally, SSH on port 2222
# Data stored at /opt/oracle19c/oradata (bind mount from host)
# Image: oracle19c-db:running (db pre-created as orcl SID, pdb1 PDB)

set -e

IMAGE="oracle19c-db:running"
CONTAINER_NAME="oracle19c"
ORACLE_SID="orcl"
ORACLE_PDB="pdb1"
ORACLE_HOME="/u01/app/oracle/product/19.3.0.0/db_1"
ORACLE_BASE="/u01/app/oracle"
DATA_DIR="/u02/oradata"
ORADATA_LOCAL="/opt/oracle19c/oradata"

mkdir -p "${ORADATA_LOCAL}"
chmod 777 "${ORADATA_LOCAL}"

echo "[$(date)] Stopping existing container..."
docker stop -t 5 ${CONTAINER_NAME} 2>/dev/null && docker rm ${CONTAINER_NAME} 2>/dev/null || true

echo "[$(date)] Starting Oracle 19c container..."
docker run --shm-size=2g \
  --name ${CONTAINER_NAME} \
  -p 2222:22 \
  --user root \
  -e ORACLE_SID=${ORACLE_SID} \
  -e PDB_NAME=${ORACLE_PDB} \
  -e ORACLE_HOME=${ORACLE_HOME} \
  -e ORACLE_BASE=${ORACLE_BASE} \
  -e DATA_DIR=${DATA_DIR} \
  -v "${ORADATA_LOCAL}:${DATA_DIR}:rw" \
  -d ${IMAGE} \
  /bin/sh -c 'mkdir -p /var/run/sshd /run && chmod 600 /etc/ssh/ssh_host_*_key && /usr/sbin/sshd -D -f /dev/null'

echo "[$(date)] Waiting for SSH..."
sleep 3

echo "[$(date)] Setting passwords..."
docker exec ${CONTAINER_NAME} /bin/sh -c "echo 'oracle:oracle' | chpasswd && echo 'root:oracle' | chpasswd" 2>/dev/null || true

echo "[$(date)] Ensuring listener diag directories exist..."
docker exec ${CONTAINER_NAME} /bin/sh -c "
  chmod 777 /u01/app/oracle/product/19.3.0.0/db_1/network/log /u01/app/oracle/product/19.3.0.0/db_1/network/trace 2>/dev/null
  mkdir -p /u01/app/oracle/diag/tnslsnr/\$HOSTNAME/listener
  chmod 777 /u01/app/oracle/diag/tnslsnr/\$HOSTNAME/listener 2>/dev/null
" 2>/dev/null || true

echo "[$(date)] Starting TNS listener..."
docker exec ${CONTAINER_NAME} /bin/sh -c "ORACLE_HOME=${ORACLE_HOME}; PATH=\$ORACLE_HOME/bin:\$PATH; export LD_LIBRARY_PATH=\$ORACLE_HOME/lib; lsnrctl start" 2>&1 | grep -E "TNSLSNR|Listening|STATUS|services|completed" | grep -v "^$"

echo "[$(date)] Verifying database is open..."
docker exec ${CONTAINER_NAME} /bin/sh -c "ORACLE_HOME=${ORACLE_HOME}; ORACLE_SID=${ORACLE_SID}; PATH=\$ORACLE_HOME/bin:\$PATH; echo 'SELECT status FROM v\$instance; SELECT name, open_mode FROM v\$pdbs;' | sqlplus / as sysdba" 2>&1 | grep -E "^(STATUS|NAME|OPEN|----|SQL>)" | grep -v "^$"

echo ""
echo "=== Oracle 19c is ready! ==="
echo "  SSH:     localhost:2222  (oracle:oracle / root:oracle)"
echo "  SQL*:    docker exec ${CONTAINER_NAME} sqlplus / as sysdba"
echo "  SID:     ${ORACLE_SID}  |  PDB: ${ORACLE_PDB}"
echo "  Data:    ${DATA_DIR} (→ ${ORADATA_LOCAL})"
echo "  TNS:     localhost:1521"
echo "  DB files: /opt/oracle19c/oradata/ORCL/"