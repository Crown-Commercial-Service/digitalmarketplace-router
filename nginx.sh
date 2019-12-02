#!/bin/bash

export DM_CLOUDFRONT_IPS=$(/app/venv/bin/python3 /app/scripts/get-cloudfront-ips.py)
export DM_RESOLVER_IP=$(awk '/nameserver/{ print $2; exit}' /etc/resolv.conf)

if [[ $DM_MODE == 'maintenance' ]]; then
    templates="maintenance healthcheck metrics"
else
    templates="api assets www healthcheck metrics"
fi

for template in $templates; do
    echo "Compiling $template" >&2
    /app/venv/bin/python3 /app/scripts/render-template.py /app/templates/$template.j2 > /etc/nginx/sites-enabled/$template.conf
done

# generate nginx.conf last so its existence can be used to detect readiness by e.g. tests
/app/venv/bin/python3 /app/scripts/render-template.py /app/templates/nginx.conf.j2 > /etc/nginx/nginx.conf

exec /usr/sbin/nginx
