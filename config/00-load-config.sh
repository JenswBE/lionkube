#!/usr/bin/env bash

cd "${BASH_SOURCE%/*}/" || exit 1 # BASH_SOURCE not set

source ./10-general.sh
source ./20-components.sh
source ./30-services.sh
