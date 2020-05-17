#! /bin/bash
# Generate Key
NEWKEY=$(nano_node --key_create | awk '/Private/ {print $2}')

# Use bootstrap to generate an open block and pull info from output
echo "Generating Genesis block"
nano_node --debug_bootstrap_generate --key=${NEWKEY} > openlog &
PROCESS_ID=$!
timeout 120 grep -q 'open' <(tail -f openlog)
kill -9 $PROCESS_ID

# Parse env from logfile
GENESIS_PUB=$(cat openlog | grep -A 5 open | awk -F\" '/"source"/ {print $4}')
GENESIS_ACCOUNT=$(cat openlog | grep -A 5 open | awk -F\" '/"account"/ {print $4}')
GENESIS_WORK=$(cat openlog | grep -A 5 open | awk -F\" '/"work"/ {print $4}')
GENESIS_SIG=$(cat openlog | grep -A 5 open | awk -F\" '/"signature"/ {print $4}')

# Show to build output and sleep
echo "!!!!!!! ACCOUNT INFO SAVE THIS INFORMATION IT WILL NOT BE SHOWN AGAIN !!!!!!!!
Private Key: ${NEWKEY}
Public Key:  ${GENESIS_PUB}
Account:     ${GENESIS_ACCOUNT}
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"

echo "Container Environment Values:
 -e LIVE_GENESIS_PUB=${GENESIS_PUB} \\
 -e LIVE_GENESIS_ACCOUNT=${GENESIS_ACCOUNT} \\
 -e LIVE_GENESIS_WORK=${GENESIS_WORK} \\
 -e LIVE_GENESIS_SIG=${GENESIS_SIG} \\"
