#!/bin/bash
set -eu

chown www-data:www-data -R uploads
chown www-data:www-data -R web

exec "$@"
