#!/bin/bash
set -e

# Install dbt if not already installed
if ! python -c "import dbt" 2>/dev/null; then
    echo "Installing dbt-core and dbt-postgres..."
    pip install --no-cache-dir dbt-postgres~=1.9.0 dbt-core~=1.9.0
fi

# Install dbt packages
if [ -d /opt/dbt ] && [ -f /opt/dbt/packages.yml ]; then
    echo "Installing dbt packages..."
    cd /opt/dbt && dbt deps || true
fi
