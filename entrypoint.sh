#!/bin/bash

function usage() {
  if [ -n "$1" ]; then
    echo -e "--> $1\n";
  fi
  echo "Usage: $0 [--action-path action-repo-path] [--repo-name scan-repo] [--scan-type scan-type] [Optional parameters]"
  echo "------------------------------------ Required ------------------------------------"
  echo "                                                                    "
  echo "  --action-path                  Full path to the action repository"
  echo "  --repo-name                    Name of the repository to scan"
  echo "  --scan-type                    Type of scan to make"
  echo "                                                                    "

  echo "------------------------------- Container Scanning -------------------------------"
  echo "                                                                    "
  echo "  --build-script                 Script used to build the image"
  echo "  --image-tag                    Tag resultant of the build script"
  echo "  --run-script                   Script used to run the conatiner"
  echo "  --zap-target                   Zap target to analyse"
  echo "                                                                    "


  echo "---------------------------------- Config files ----------------------------------"
  echo "                                                                    "
  echo "  --prosp-filepath               Path to the prospector profile"
  echo "  --horusec-filepath             Path to the horusec config file"
  echo "  --secrets-filepath             Path to the secrets to be ignored file"
  echo "  --dockle-filepath              Path to the dockle vulns to be ignored"
  echo "  --trivy-filepath               Path to the trivy vulns to be ignored"
  echo "  --zap-filepath                 Path to the zap rules file"
  echo "                                                                    "


  echo "-------------------------- Tools Command line arguments --------------------------"
  echo "                                                                    "
  echo "  --prosp-cmd                    Other command line arguments for prospector"
  echo "  --radon-cmd                    Other command line arguments for radon"
  echo "  --horusec-cmd                  Other command line arguments for horusec"
  echo "  --gitleaks-cmd                 Other command line arguments for gitleaks"
  echo "  --dockle-cmd                   Other command line arguments for trivy"
  echo "  --trivy-cmd                    Other command line arguments for trivy"
  echo "  --zap-cmd                      Other command line arguments for zap"
  echo "                                                                    "

  echo "------------------------------------ Blocking ------------------------------------"
  echo "                                                                    "
  echo "  --bp-isblocking                Block the workflow on issues found in bp scan"
  echo "  --vs-isblocking                Block the workflow on issues found in vs scan"
  echo "  --ss-isblocking                Block the workflow on issues found in ss scan"
  echo "  --ds-isblocking                Block the workflow on issues found in ds scan"
  echo "  --ts-isblocking                Block the workflow on issues found in ts scan"
  echo "  --zs-isblocking                Block the workflow on issues found in zs scan"
  echo "                                                                    "

  echo "--------------------------------- Other Arguments --------------------------------"
  echo "                                                                    "
  echo "  --files-toscan                 List of files to lint"
  echo "                                                                    "
  echo "  --debug                        Get raw outputs from the tools ran "

  echo ""
  exit 1
}

# parse params
while [[ "$#" > 0 ]]; do case $1 in
  --debug) DEBUG="$2"; shift;shift;;
  --output-styles) OUTPUT_STYLES="$2"; shift;shift;;
  --action-path) ACTION_PATH="$2"; shift;shift;;
  --repo-name) REPO_NAME="$2"; shift;shift;;
  --scan-type) SCAN_TYPE="$2"; shift;shift;;
  --build-script) BUILD_SCRIPT="$2"; shift;shift;;
  --image-tag) IMAGE_TAG="$2"; shift;shift;;
  --run-script) RUN_SCRIPT="$2"; shift;shift;;
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
  --trivy-filepath) TRIVY_FILEPATH="$2"; shift;shift;;
  --trivy-cmd) TRIVY_CMD="$2"; shift;shift;;
  --ts-isblocking) TS_ISBLOCKING="$2"; shift;shift;;
  --zap-filepath) ZAP_FILEPATH="$2"; shift;shift;;
  --zap-cmd) ZAP_CMD="$2"; shift;shift;;
  --zap-target) ZAP_TARGET="$2"; shift;shift;;
  --zs-isblocking) ZS_ISBLOCKING="$2"; shift;shift;;
  *) usage "Unknown parameter passed: $1"; shift; shift;;
esac; done

if [ $DEBUG = "true" ]
then
    set -x
fi

mkdir "Reports"

ret=0

IFS=',' read -ra scan_type <<< "$SCAN_TYPE"

# Setup

if [ $BUILD_SCRIPT != "" ]
then
    ./$BUILD_SCRIPT
fi

if [ $RUN_SCRIPT != "" ]
then
    ./$RUN_SCRIPT
fi


for st in "${scan_type[@]}"; do
    if [ $st = "BP" ] 
    then
        if [ $FILES_TOSCAN = "all" ]
        then
            FILES_TOSCAN=$(find . -type f | grep "^.*\.py$" | cut -c 3-)
        fi
        ASSETS=$ACTION_PATH/$st
        $ASSETS/InstallAndRunProspectorAndRadon.sh "$ASSETS" "$PROSP_FILEPATH" "$PROSP_CMD" "$RADON_CMD" "$DEBUG" "$FILES_TOSCAN"
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
        $ASSETS/InstallAndRunHorusec.sh "$ASSETS" "$HORUSEC_FILEPATH" "$HORUSEC_CMD" "$DEBUG" "$OUTPUT_STYLES"
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
        $ASSETS/InstallAndRunGitleaks.sh "$ASSETS" "$REPO_NAME" "$GITLEAKS_CMD" "$SECRETS_FILEPATH" "$DEBUG" "$OUTPUT_STYLES"
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
        if [ $IMAGE_TAG != "" ]
        then
            ASSETS=$ACTION_PATH/$st
            $ASSETS/InstallAndRunDockle.sh "$ASSETS" "$DOCKLE_FILEPATH" "$DOCKLE_CMD" "$IMAGE_TAG" "$DEBUG" "$OUTPUT_STYLES"
            if [ $? = 1 ]
            then
                if [ $DS_ISBLOCKING = "true" ]
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
            echo "::error::For a Dockle type scan there needs to be a image tag passed as arguments"
            ret=1
        fi
    fi

    if [ $st = "TS" ] 
    then
        if [ $IMAGE_TAG != "" ]
        then
            ASSETS=$ACTION_PATH/$st
            $ASSETS/InstallAndRunTrivy.sh "$ASSETS" "$TRIVY_FILEPATH" "$TRIVY_CMD" "$IMAGE_TAG" "$DEBUG" "$OUTPUT_STYLES"
            if [ $? = 1 ]
            then
                if [ $TS_ISBLOCKING = "true" ]
                then
                    echo "::error::Trivy Scan found problems, check the artifacts for more information"
                    ret=1
                else
                    echo "::notice::Trivy Scan found problems but non blocking was active during this run"
                fi
            else
                echo "::notice::Trivy Scan did not find any problems"
            fi
        else
            echo "::error::For a Container type scan there needs to be a build script and a image tag passed as arguments"
            ret=1
        fi
    fi

    if [ $st = "ZS" ] 
    then
        if [ $ZAP_TARGET != "" ]
        then
            ASSETS=$ACTION_PATH/$st
            $ASSETS/InstallAndRunZaproxy.sh "$ASSETS" "$ZAP_FILEPATH" "$ZAP_CMD" "$ZAP_TARGET" "$DEBUG" "$OUTPUT_STYLES"
            if [ $? = 1 ]
            then
                if [ $ZS_ISBLOCKING = "true" ]
                then
                    echo "::error::Zap Scan found problems, check the artifacts for more information"
                    ret=1
                else
                    echo "::notice::Zap Scan found problems but non blocking was active during this run"
                fi
            else
                echo "::notice::Zap Scan did not find any problems"
            fi
        else
            echo "::error::For a Dynamic scan there needs to be a target passed as argument"
            ret=1
        fi
    fi
done

exit $ret