#!/bin/bash

# To help debugging
set -x

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
  --build-script) BUILD_SCRIPT="$2"; shift;shift;;
  --image-tag) IMAGE_TAG="$2"; shift;shift;;
  --prosp-filepath) PROSP_FILEPATH="$2"; shift;shift;;
  --prosp-cmd) PROSP_CMD="$2"; shift;shift;;
  --radon-cmd) RADON_CMD="$2"; shift;shift;;
  --files-toscan) FILES_TOSCAN="$2"; shift;shift;;
  --bp-isblocking) BP_ISBLOCKING="$2"; shift;shift;;
  --horusec-filepath) HORUSEC_FILEPATH="$2"; shift;shift;;
  --horusec-cmd) HORUSEC_CMD="$2"; shift;shift;;
  --vs-isblocking) VS_ISBLOCKING="$2"; shift;shift;;
  --secrets-filepath) SECRETS_FILEPATH="$2"; shift;shift;;
  --gitleaks-cmd) GITLEAKS_CMD="$2"; shift;shift;;
  --ss-isblocking) SS_ISBLOCKING="$2"; shift;shift;;
  --dockle-filepath) DOCKLE_FILEPATH="$2"; shift;shift;;
  --dockle-cmd) DOCKLE_CMD="$2"; shift;shift;;
  --ds-isblocking) DS_ISBLOCKING="$2"; shift;shift;;
  *) usage "Unknown parameter passed: $1"; shift; shift;;
esac; done

ret=0

IFS=',' read -ra scan_type <<< "$SCAN_TYPE"

for st in "${scan_type[@]}"; do
    if [ $st = "BP" ] 
    then
        ASSETS=$ACTION_PATH/$st
        $ASSETS/InstallAndRunProspectorAndRadon.sh $ASSETS $PROSP_FILEPATH $PROSP_CMD "$RADON_CMD" "$FILES_TOSCAN"
        if [ $? = 1 ]
        then
            if [ $BP_ISBLOCKING = "true" ]
            then
                echo "::error::Bad Practices found problems, check the artifacts for more information"
                ret=1
            else
                echo "::notice::Bad Practices found problems but non blocking was active during this run"
            fi
        else
            echo "::notice::Bad Practices did not find any problems"
        fi
    fi

    if [ $st = "VS" ] 
    then
        ASSETS=$ACTION_PATH/$st
        $ASSETS/InstallAndRunHorusec.sh $ASSETS $HORUSEC_FILEPATH $HORUSEC_CMD
        if [ $? = 1 ]
        then
            if [ $VS_ISBLOCKING = "true" ]
            then
                echo "::error::Vulnerability Scan found problems, check the artifacts for more information"
                ret=1
            else
                echo "::notice::Vulnerability Scan found problems but non blocking was active during this run"
            fi
        else
            echo "::notice::Vulnerability Scan did not find any problems"
        fi
    fi

    if [ $st = "SS" ] 
    then
        ASSETS=$ACTION_PATH/$st
        $ASSETS/InstallAndRunGitleaks.sh $ASSETS $REPO_NAME $GITLEAKS_CMD $SECRETS_FILEPATH
        if [ $? = 1 ]
        then
            if [ $SS_ISBLOCKING = "true" ]
            then
                echo "::error::Secrets Scan found problems, check the artifacts for more information"
                ret=1
            else
                echo "::notice::Secrets Scan found problems but non blocking was active during this run"
            fi
        else
            echo "::notice::Secrets Scan did not find any problems"
        fi
    fi

    if [ $st = "DS" ] 
    then
        if [ $BUILD_SCRIPT != "" ] || [ $IMAGE_TAG != "" ]
        then
            ./$BUILD_SCRIPT
            ASSETS=$ACTION_PATH/$st
            $ASSETS/InstallAndRunDockle.sh $ASSETS $DOCKLE_FILEPATH "$DOCKLE_CMD" "$IMAGE_TAG"
            if [ $? = 1 ]
            then
                if [ $SS_ISBLOCKING = "true" ]
                then
                    echo "::error::Dockle Scan found problems, check the artifacts for more information"
                    ret=1
                else
                    echo "::notice::Dockle Scan found problems but non blocking was active during this run"
                fi
            else
                echo "::notice::Dockle Scan did not find any problems"
            fi
        else
            echo "::error::For a Container type scan there needs to be a build script and a image tag passed as arguments"
        fi
    fi
done

exit $ret