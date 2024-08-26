#!/bin/bash
#Usage ./extract.sh directory_name

set -e
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN="\033[0;36m"
ERROR='\033[41m'
NC='\033[0m'

############################## Checking Arguments ##############################
if [ -z "$1" ]; then
  echo "No directory name provided. Usage: $0 <directory_name>"
  exit 1
fi

DIR_NAME=$1

if [ ! -d "$DIR_NAME" ]; then
  echo "Directory '$DIR_NAME' does not exist."
  exit 1
fi
############################ End Checking Arguments ############################


#################################### Setup #####################################
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'catch' EXIT
catch() {
if [ $? -ne 0 ]; then
        printf "${ERROR}${last_command} command failed with exit code $?.${NC}\n"
fi
}

printf "\n${GREEN}Extracting measurements from : ${FOLDER}.${NC}\n"
SUFFIX="_results.json"
################################## End Setup ###################################

########################### Extracting iperf results ###########################
# Iterate over files with the specific prefix and suffix
echo "================================================================================"
echo "Extracting results for IPERF files."
for FILE in "$DIR_NAME"/"iperf"*".json"; do
  # Check if any files match the pattern
  if [ -e "$FILE" ]; then
    echo "----------------------------------------------------------------------"
    echo "Extracting results for '$FILE' file."
    RESULTS_FILE="${FILE%.json}${SUFFIX}"

    BITS_PER_SECOND_SUM=$(jq '[.intervals[].sum.bits_per_second] | add' "$FILE")
    # echo "    Sum of Mbps: $bps"

    MBITS_PER_SECOND_SUM=$(echo "$BITS_PER_SECOND_SUM / 1000000" | bc -l)
    # echo "    Sum of Mbps: $mbps"

    TOTAL_INTERVALS=$(jq '.intervals | length' "$FILE")
    # echo "    Total number of intervals: $TOTAL_INTERVALS"

    # Calculate average mbps
    if [ "$TOTAL_INTERVALS" -gt 0 ]; then
      AVERAGE_BANDWIDTH_MBPS=$(echo "$MBITS_PER_SECOND_SUM / $TOTAL_INTERVALS" | bc -l)
      echo "    Average Bandwidth: $AVERAGE_BANDWIDTH_MBPS mbps"
      # Calculate standard deviation of bimbps 
      SUM_SQUARE_DIFF=0
      for (( i=0; i<$TOTAL_INTERVALS; i++ )); do
        BITS_PER_SECOND=$(jq --argjson idx "$i" '.intervals[$idx].sum.bits_per_second' "$FILE")
        MBITS_PER_SECOND=$(echo "$BITS_PER_SECOND / 1000000" | bc -l)
        DIFF=$(echo "$MBITS_PER_SECOND - $AVERAGE_BANDWIDTH_MBPS" | bc -l)
        SQUARE_DIFF=$(echo "$DIFF * $DIFF" | bc -l)
        SUM_SQUARE_DIFF=$(echo "$SUM_SQUARE_DIFF + $SQUARE_DIFF" | bc -l)
      done

      VARIANCE=$(echo "$SUM_SQUARE_DIFF / $TOTAL_INTERVALS" | bc -l)
      DEVIATION_BANDWIDTH_MBPS=$(echo "sqrt($VARIANCE)" | bc -l)
      echo "    Standard Bandwidth Deviation: $DEVIATION_BANDWIDTH_MBPS mbps"

      json_results=$(cat <<EOF
      {"average_bandwidth_mbps": "${AVERAGE_BANDWIDTH_MBPS}","standard_deviation_bandwidth_mbps": "${DEVIATION_BANDWIDTH_MBPS}"}
EOF
      )
      echo "${json_results}" | jq > "$RESULTS_FILE"
    else
      echo "    No intervals found in the JSON file."
    fi
  fi
done

######################### End Extracting ipefr results #########################


########################### Extracting ping results ###########################
# Iterate over files with the specific prefix and suffix
echo "================================================================================"
echo "Extracting results for PING files."
for FILE in "$DIR_NAME"/"ping"*".json"; do
  # Check if any files match the pattern
  if [ -e "$FILE" ]; then
    echo "----------------------------------------------------------------------"
    echo "Extracting results for '$FILE' file."
    RESULTS_FILE="${FILE%.json}${SUFFIX}"

    rtt_line=$(grep "rtt min/avg/max/mdev" "$FILE")

    # Extract avg and mdev values from the RTT statistics line
    AVERAGE_LATENCY_MS=$(echo "$rtt_line" | awk -F'/' '{print $5}')
    DEVIATION_LATENCY_MS=$(echo "$rtt_line" | awk -F'/' '{print $7}' | sed 's/ ms.*//')

    # Output the results
    echo "    Average Latency: $AVERAGE_LATENCY_MS ms"
    echo "    Standard Latency Deviation: $DEVIATION_LATENCY_MS ms"

    echo "Average Latency: $AVERAGE_LATENCY_MS ms" > "$RESULTS_FILE"
    echo "Standard Latency Deviation: $DEVIATION_LATENCY_MS ms" >> "$RESULTS_FILE"


      json_results=$(cat <<EOF
      {"average_latency_ms": "${AVERAGE_LATENCY_MS}","standard_deviation_latency_ms": "${DEVIATION_LATENCY_MS}"}
EOF
      )
      echo "${json_results}" | jq > "$RESULTS_FILE"
  fi
done

######################### End Extracting ping results #########################
