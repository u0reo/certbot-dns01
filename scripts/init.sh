#!/bin/sh

rm -r /config/*  > /dev/null 2>&1
rm -r /rundir/*  > /dev/null 2>&1
rm -r /storage/* > /dev/null 2>&1

# Create knot.conf
echo \
"server:\n\
    listen: $ADDR\n\
\n\
$(keymgr -t acme)\n\
\n\
acl:\n\
  - id: acme\n\
    key: acme\n\
    action: update\n\
\n\
template:\n\
  - id: acme\n\
    acl: acme\n\
    module: mod-onlinesign\n\
\n\
zone:\n\
  - domain: _acme-challenge.$DOMAIN\n\
    template: acme\n\
    storage: /config/\n\
    file: acme.$DOMAIN.zone\n" \
> /config/knot.conf

# Create acme.example.com.zone
echo \
"\$ORIGIN _acme-challenge.$DOMAIN.\n\
@ 86400 IN SOA localhost. nobody. 1 10800 3600 2419200 1200\n\
  86400 IN NS acme.$DOMAIN.\n"\
> /config/acme.$DOMAIN.zone

# Create rfc2136.ini
echo \
"dns_rfc2136_server = $ADDR\n\
dns_rfc2136_name = acme\n\
dns_rfc2136_secret = $(grep '^    secret' /config/knot.conf | awk '{print $2}')\n\
dns_rfc2136_algorithm = HMAC-SHA256\n"\
> /config/rfc2136.ini

# if [ $# > 0 ]; then
#   echo "Execute '${@}'"
#   $@
# fi

./get_ds.sh
