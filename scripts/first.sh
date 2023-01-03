#!/bin/sh

# Start Knot DNS
knotd -d && sleep 1

# Notify Approval
echo -n 'Submitting DS Record Registration...'
knotc zone-ksk-submitted _acme-challenge.${DOMAIN}

# Stop Knot DNS
knotc stop > /dev/null

# Workaround: Unsafe permissions on credentials configuration file: /config/rfc2136.ini
chmod 700 /config/rfc2136.ini

# Set additional argument in test mode
if [ "${TEST}" = "true" ]; then
  add_args="--test-cert --break-my-certs"
else
  add_args=""
fi

# Get Certificate
certbot certonly -d "${DOMAIN}" -d "*.${DOMAIN}" \
  --key-type ecdsa --dns-rfc2136 --dns-rfc2136-credentials /config/rfc2136.ini --dns-rfc2136-propagation-seconds 5 \
  --pre-hook "knotd -d" --post-hook "knotc stop > /dev/null" --no-eff-email --agree-tos -m ${EMAIL} ${add_args} $@
