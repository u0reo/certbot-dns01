FROM cznic/knot:3.2

# Add Certbot
RUN apt-get update && apt-get install -y certbot=1.12.0-2 python3-certbot-dns-rfc2136=1.10.1-1

COPY ./scripts /

LABEL maintainer="ureo <zero@ureo.jp>"

VOLUME /etc/letsencrypt
# VOLUME /certificate
