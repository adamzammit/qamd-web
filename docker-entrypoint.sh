#!/bin/bash
set -eu

chown www-data:www-data -R uploads

exec "$@"
