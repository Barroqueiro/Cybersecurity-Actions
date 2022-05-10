#!/bin/bash

# Exit codes:
# Vulnerability Scan --> 

function usage() {
  if [ -n "$1" ]; then
    echo -e "--> $1\n";
  fi
  echo "Usage: $0 [-l locust-file] [-i interface] [-h host] [-u users] [-s spawn-rate] [-r run-time] [-w number-of-wrokers]"
  echo "  -l, --locust-file              The locust file"
  echo "  -i, --interface                true if no interface"
  echo "  -h, --host                     The host to swarm"
  echo "  -u, --users                    Number max of users to spawn"

  echo "  -s, --spawn-rate               How many users to spawn per second"
  echo "  -r, --run-time                 Run for how much time"
  echo "  -w, --number-of-workers        The locust file"
  echo "  -n, --no_workers               Run the master without the workers"
  echo ""
  echo "Example: $0 -l locust_test.py -i false -h 'http://localhost:8080' -u 10000 -s 500 -r 1m -w 10"
  exit 1
}

# parse params
while [[ "$#" > 0 ]]; do case $1 in
  --action-path) ACTION_PATH="$2"; shift;shift;;
  --repo-name) REPO_NAME="$2"; shift;shift;;
  --scan-type) SCAN_TYPE="$2"; shift;shift;;
  --horusec-filepath) HORUSEC_FILEPATH="$2"; shift;shift;;
  --horusec-cmd) HORUSEC_CMD="$2"; shift;shift;;
  --gitleaks-cmd) GITLEAKS_CMD="$2"; shift;shift;;
  --secrets-filepath) SECRETS_FILEPATH="$2"; shift;shift;;
  *) usage "Unknown parameter passed: $1"; shift; shift;;
esac; done

IFS=',' read -ra scan_type <<< "$SCAN_TYPE"

for st in "${scan_type[@]}"; do
    if [ $st = "VS" ] 
    then
        ASSETS=$ACTION_PATH/$st
        $ASSETS/InstallAndRunHorusec.sh $ASSETS $HORUSEC_FILEPATH $HORUSEC_CMD
        if [ $? = 1 ]
        then
            echo "::error::Game Over"
            exit 5
        fi
    fi

    if [ $st = "SS" ] 
    then
        ASSETS=$ACTION_PATH/$st
        $ASSETS/InstallAndRunGitleaks.sh $ASSETS $REPO_NAME $GITLEAKS_CMD $SECRETS_FILEPATH
    fi
done