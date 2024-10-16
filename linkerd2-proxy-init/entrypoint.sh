#!/bin/bash

setcap cap_net_raw,cap_net_admin+eip /sbin/xtables-legacy-multi
setcap cap_net_raw,cap_net_admin+eip /sbin/xtables-nft-multi

exec /usr/local/bin/proxy-init
