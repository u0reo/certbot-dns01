#!/bin/sh

# Keep the md5 hash of current fullchain.pem before renew
before_cert_md5=`md5sum /etc/letsencrypt/live/${DOMAIN}/fullchain.pem | cut -d ' ' -f 1`

# Set additional argument in test mode
if [ "${TEST}" = "true" ]; then
  add_args="--test-cert --break-my-certs --no-eff-email --agree-tos -m ${EMAIL}"
else
  add_args=""
fi

# RUN
certbot renew --no-random-sleep-on-renew ${add_args} $@

# Get the md5 hash of current fullchain.pem after renew
after_cert_md5=`md5sum /etc/letsencrypt/live/${DOMAIN}/fullchain.pem | cut -d ' ' -f 1`

echo "\n"

# Check if updated or not
if [ "${before_cert_md5}" = "${after_cert_md5}" ]; then
  echo "\nThe certificate for the domain (${DOMAIN}) has not been renewed.\n"
  exit
fi


# BASE_PATH=/etc/letsencrypt/live/example.com (Original)
if [ -z $BASE_PATH ]; then
  BASE_PATH="/etc/letsencrypt/live/${DOMAIN}"
fi

# CERT_PATH=/certificate -> /usr/syno/etc/certificate
if [ -z $CERT_PATH ]; then
  CERT_PATH="/certificate"
fi

# Get internal domain id
# for cert_file in `find ${CERT_PATH}/_archive/ -name fullchain.pem`; do
#   cert_md5=`md5sum ${cert_file} | cut -d ' ' -f 1`
#   if [ "${cert_md5}" != "${before_cert_md5}" ]; then
#     continue
#   fi

#   # When the md5 hash of fullchain.pem match
#   domain_id=`echo "${cert_file}" | rev | cut -d '/' -f 2 | rev`
#   echo "ID of the domain (${DOMAIN}) is ${domain_id}"
#   break
# done

# if [ -z $domain_id ]; then
#   echo "\nNo certificate file found for the domain (${DOMAIN}).\n"
#   exit
# fi

# echo "\n"

for cert_file in `find ${CERT_PATH}/ -name fullchain.pem`; do
  target_cert_md5=`md5sum "${cert_file}" | cut -d ' ' -f 1`
  if [ "${target_cert_md5}" != "${before_cert_md5}" ]; then
    continue
  fi

  # When the md5 hash of fullchain.pem match
  target_path=`dirname ${cert_file}`
  # Copy three pem files to target path
  cp ${BASE_PATH}/* ${target_path}/

  echo "Generated certificate file copied to ${target_path}."
done

echo "\nThe certificate for the domain (${DOMAIN}) successfully renewed & replaced!!\n"
