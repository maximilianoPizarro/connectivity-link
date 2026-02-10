#!/bin/bash
set -a  # automatically export all variables
source user-values.env
set +a

# Conditionally set NODE_TLS_ENV_BLOCK if NODE_TLS_REJECT_UNAUTHORIZED is "0"
if [ "${NODE_TLS_REJECT_UNAUTHORIZED}" = "0" ]; then
    export NODE_TLS_ENV_BLOCK="- name: NODE_TLS_REJECT_UNAUTHORIZED
              value: '0'"
else
    export NODE_TLS_ENV_BLOCK=""
fi

# Overwrite secret YAML files from templates (domain-dependent values are in cluster-config.env;
# run ./update-cluster-domain.sh from repo root to change cluster domain).
for template in backend-secret.yaml.template postgres-secret.yaml.template litellm-secret.yaml.template; do
    if [ -f "$template" ]; then
        envsubst < "$template" > "${template%.template}.yaml"
        echo "Generated ${template%.template}.yaml"
    fi
done
