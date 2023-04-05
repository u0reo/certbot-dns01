#!/bin/sh

knotd -d && sleep 1

keymgr _acme-challenge.$DOMAIN ds | grep ' 2 ' | sed -e "s/.* DS \(.* 2 .*\)/\1/g"

knotc stop > /dev/null
