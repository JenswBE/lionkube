# Load me with "source" command of Bash

# Get config dir
CONFIG_DIR="${BASH_SOURCE%/*}"

# Load general config
CONF_GEN=${CONFIG_DIR}/10-general.sh
echo "Loading ${CONF_GEN} ..."
source "${CONF_GEN}"

# Load components config
CONF_COMP=${CONFIG_DIR}/20-components.sh
echo "Loading ${CONF_COMP} ..."
source "${CONF_COMP}"

# Load services config
CONF_SVC=${CONFIG_DIR}/30-services.sh
echo "Loading ${CONF_SVC} ..."
source "${CONF_SVC}"
