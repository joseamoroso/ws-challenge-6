#!/bin/bash

# Set the environment variable
export INGRESS_HOSTNAME="local.jamoroso.com"

# Add the domain to the /etc/hosts file
if ! grep -q "127.0.0.1 local.jamoroso.com" /etc/hosts; then
    echo "127.0.0.1 local.jamoroso.com" | sudo tee -a /etc/hosts > /dev/null
fi

echo "Environment variable INGRESS_HOSTNAME set to $INGRESS_HOSTNAME"
echo "Added local.jamoroso.com to /etc/hosts resolving to 127.0.0.1"