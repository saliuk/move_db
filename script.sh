#!/bin/bash -e

if [[ "${DEBUG,,}" == "true" ]]; then
  set -x
fi

DB_TYPE=${1}

SRC_DB_HOST=${2}
SRC_DB_PORT=${3}
SRC_DB_NAME=${4}
SRC_DB_USERNAME="$USERNAME"
SRC_DB_PASSWORD="$PASSWORD"

DST_DB_HOST=${5}
DST_DB_PORT=${6}
DST_DB_NAME=${7}
DST_DB_USERNAME="$USERNAME"
DST_DB_PASSWORD="$PASSWORD"

echo "Data migration for ${DB_TYPE}"

if [[ -z "${SRC_DB_HOST}" || -z "${SRC_DB_PORT}" || -z "${SRC_DB_NAME}" || -z "${DST_DB_HOST}" || -z "${DST_DB_PORT}" || -z "${DST_DB_NAME}" ]]; then
  echo "PLEASE FILL IN ALL FIELDS: $0 <SRC_DB_HOST> <SRC_DB_PORT> <SRC_DB_NAME> <DST_DB_HOST> <DST_DB_PORT> <DST_DB_NAME>"
  exit 1
fi

TMP_DIR=$(mktemp -d)

#----------FOR MYSQL-----------------#
if [[ "$DB_TYPE" == "MYSQL" ]]; then
  # dump data from source database
  mysqldump -h${SRC_DB_HOST} -P${SRC_DB_PORT} -u${SRC_DB_USERNAME} -p${SRC_DB_PASSWORD} "${SRC_DB_NAME}" > "${TMP_DIR}/${SRC_DB_NAME}.sql"
  # databases list
  RESULT_MYSQL=$(mysqlshow -h${DST_DB_HOST} -P${DST_DB_PORT} -u${DST_DB_USERNAME} -p${DST_DB_PASSWORD})
  # create a ne database if it doesnt exist
  if [[ "${RESULT_MYSQL}" =~ "${DST_DB_NAME}" ]]; then
    echo "Database exist"
  else
  mysqladmin -h${DST_DB_HOST} -P${DST_DB_PORT} -u${DST_DB_USERNAME} -p${DST_DB_PASSWORD} create "${DST_DB_NAME}"
  fi
  # move dumped data to destination database
  mysql -h${DST_DB_HOST} -P${DST_DB_PORT} -u${DST_DB_USERNAME} -p${DST_DB_PASSWORD} "${DST_DB_NAME}" < "${TMP_DIR}/${SRC_DB_NAME}.sql"
else
#----------FOR POSTGRESQL-----------------#
# dump data from source database
  PGPASSWORD="${SRC_DB_PASSWORD}" pg_dump -h ${SRC_DB_HOST} -p ${SRC_DB_PORT} -U ${SRC_DB_USERNAME} -d "${SRC_DB_NAME}" > "${TMP_DIR}/${SRC_DB_NAME}.sql"
   # databases list
  RESULT_PGSQL=$(PGPASSWORD="${DST_DB_PASSWORD}" psql -h ${DST_DB_HOST} -p ${DST_DB_PORT} -U ${DST_DB_USERNAME} -l)
  # create a ne database if it doesnt exist
  if [[ "${RESULT_MYSQL}" =~ "${DST_DB_NAME}" ]]; then
    echo "Database exist"
  else
  PGPASSWORD="${DST_DB_PASSWORD}" createdb "${DST_DB_NAME}" -h ${DST_DB_HOST} -p ${DST_DB_PORT} -U ${DST_DB_USERNAME}
  fi
  # move dumped data to destination database
  PGPASSWORD="${DST_DB_PASSWORD}" psql -h ${DST_DB_HOST} -p ${DST_DB_PORT} -U ${DST_DB_USERNAME} -d "${DST_DB_NAME}" < "${TMP_DIR}/${SRC_DB_NAME}.sql"
fi
