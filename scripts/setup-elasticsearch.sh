#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="$(pwd)"

if [ -f "${SCRIPT_DIR}/.env" ]; then
    ENV_FILE="${SCRIPT_DIR}/.env"
elif [ -f "${WORK_DIR}/.env" ]; then
    ENV_FILE="${WORK_DIR}/.env"
else
    echo "Error: .env file not found in ${SCRIPT_DIR} or ${WORK_DIR}"
    exit 1
fi

echo "Using env file: ${ENV_FILE}"

set -a
source "$ENV_FILE"
set +a

ES_HOST="${ELASTICSEARCH_HOST:-elasticsearch}"
ES_PORT="${ELASTICSEARCH_PORT:-9200}"
ES_URL="http://${ES_HOST}:${ES_PORT}"
ES_USER="${ELASTICSEARCH_USERNAME:-elastic}"
ES_PASS="${ELASTICSEARCH_PASSWORD}"
KIBANA_USER="${ES_KIBANA_USER:-kibana_system}"
KIBANA_PASS="${ES_KIBANA_PASSWORD}"
FLUENT_USER="${ES_LOGSTASH_USER:-fluent_bit}"
FLUENT_PASS="${ES_LOGSTASH_PASSWORD}"

echo "Waiting for Elasticsearch to be ready..."
until curl -s -u "${ES_USER}:${ES_PASS}" "${ES_URL}/_cluster/health" > /dev/null 2>&1; do
    echo "Elasticsearch is not ready yet, waiting..."
    sleep 5
done

echo "Elasticsearch is ready!"

echo "Setting password for ${KIBANA_USER}..."
curl -X POST -u "${ES_USER}:${ES_PASS}" \
    "${ES_URL}/_security/user/${KIBANA_USER}/_password" \
    -H "Content-Type: application/json" \
    -d "{\"password\":\"${KIBANA_PASS}\"}"

echo "Creating logstash_writer role..."
curl -X POST -u "${ES_USER}:${ES_PASS}" \
    "${ES_URL}/_security/role/logstash_writer" \
    -H "Content-Type: application/json" \
    -d '{
        "cluster": ["manage_index_templates", "monitor"],
        "indices": [{
            "names": ["fluent-bit-*", "logstash-*", "logs-aem-*"],
            "privileges": ["write", "create", "create_index", "manage"]
        }]
    }'

echo "Creating ${FLUENT_USER} user..."
curl -X POST -u "${ES_USER}:${ES_PASS}" \
    "${ES_URL}/_security/user/${FLUENT_USER}" \
    -H "Content-Type: application/json" \
    -d "{
        \"password\": \"${FLUENT_PASS}\",
        \"roles\": [\"logstash_writer\"],
        \"full_name\": \"Fluent Bit\"
    }"

echo ""
echo "Setup complete!"
echo "========================================"
echo "Elasticsearch: ${ES_URL}"
echo "Elasticsearch user: ${ES_USER}"
echo "Kibana user: ${KIBANA_USER}"
echo "Fluent Bit user: ${FLUENT_USER}"
echo "========================================"
