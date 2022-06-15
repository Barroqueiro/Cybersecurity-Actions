# Cybersecurity-Actions

## Author

    Dinis Cruz

## Description

A Github actions package with 6 different types of scans, oriented for cyber-security, it offers:
    
- Bad Practices Scan for python using Prospector and Radon
- Vulnerability Scanning within the code and it's dependencies using Horusec
- Secrets Scanning within the full repositorie's history using Gitleaks
- Docker File Linting to find sub optimal choices using Dockle
- Docker Image Scanning to find vulnerable packages using Trivy
- Dynamic Analysis for a locally ran instance using Zaproxy

## Objectives

This actions was constructed with the following objectives in mind:

- Prefered use of open-source tools
- Keeping everything within Github
- Keep both the actions, and the usage as simple to maintain as possible

## Usage

For a specific version

    - uses: barroqueiro/Cybersecurity-Actions@<Version (v?.?.?)>

To pull directly from main, may be unstable

    - uses: barroqueiro/Cybersecurity-Actions@main

## Configurable options

The following sections include the configurable parameters within this actions, these can be configured using with with keyword on the workflow yaml syntax.

    with:
        <name>:<value>

Note: These parameters must be configured with care, most of them are easy to use, but attention to the option to pass custom arguments to a tool, these arguments must not disrupt the normal flow of the action or there can be unexpected consequences.

### Types of scans

    Name: scan-type
    Required: True
    Default: Not Applicable

Types of scans and what they can offer (Related in a 1 to 1 relationship to the description section):

- Bad Practices Scan: BP
- Vulnerability Scan: VS
- Secrets Scan: SS
- Dockle Scan: DS
- Trivy Scan: TS
- Zap Scan: ZS

These can be used separatly or together passing them separated by commas

#### **Examples**

Using every scan:

    with:
        scan-type: 'BP,VS,SS,DS,TS,ZS'

Using only the vulnerability scan:

    with:
        scan-type: 'VS'

### Docker Related parameters

#### **Build Script**

Path to a script used to build the docker image to analyse

    Name: build-script
    Required: False
    Default: ''


#### **Run Script**

Path to a script used to locally run the instance to analyse

    Name: run-script
    Required: False
    Default: ''

#### **Image tag**

To keep track of the images, this parameter keeps the [tag](https://docs.docker.com/engine/reference/commandline/tag/) on the image created

    Name: image-tag
    Required: TS,DS type of scan to pass which image they are analysing
    Default: ''

Notes concerning Docker Related parameters:

- Every path file must be from the repository the action is analysing
- The build script must tag the image with the same tag passed as a parameter
- The run script must run the image locally and expose it's service to localhost so zap can access the instance

#### **Example**

    with:
        build-script: 'ActionFiles/build.sh'
        image-tag: 'scan/scanimage:latest'
        run-script: 'ActionFiles/run.sh'

Use the scripts build.sh and run.sh in the ActionFiles folder of the repository to build and run the image. The image is tagged with: scan/scanimage:latest
The image does not need to be ran during the custom action, it can be build in previous steps fully configurable within the workflow file. Just make sure there is an image to be scanned (DS,TS) or there is an instance to be analysed (ZS). 
Since the build and run scripts are threated as setup options these will run before any scanning starts, having these scripts configured for scans that don't need them will create unecessary overhead.

### Bad Practices Related parameters

#### **Custom Prospector Profile**

Path to a [prospector profile](https://prospector.landscape.io/en/master/profiles.html) to be used by the prospector run

    Name: prosp-filepath
    Required: False
    Default: ''

#### **Prospector Command Line Arguments**

Aditional [command line arguments](https://prospector.landscape.io/en/master/usage.html) to be used during the prospector run

    Name: prosp-cmd
    Required: False
    Default: ''

#### **Radon Command Line Arguments**

Aditional [command line arguments](https://radon.readthedocs.io/en/latest/commandline.html#the-cc-command) to be used during the radon run

    Name: radon-cmd
    Required: False
    Default: ''

#### **Files to scan**

A list separated by spaces of files to be scanned by the bad practices module, this exists because with projects that already started, linting every python file will produce to much output. This can be configured with something like [Get changed files](https://github.com/tj-actions/changed-files) to make sure that the linting process only happens on the pushed files to the repository instead of the full repository.

    Name: files-toscan
    Required: False
    Default: ''

#### **Example**

    prosp-filepath: 'ActionFiles/prospector_profile.yaml'
    prosp-cmd: '-8'
    radon-cmd: '-n B'

This will pass a custom profile to prospector located within the ActionFiles folder and run prospector with the -8 flag (It will ignore styling conventions) and radon with the -n flag (value B) to only care about functions that score lower than A.

#### **Efficient Bad Practices Run**

Using a workflow file to run bad practices like such:

    Code-Security-Checks:
        runs-on: ubuntu-latest
        steps:
        - uses: actions/checkout@v3
            with:
            fetch-depth: 0
        - name: Get changed files using defaults
            id: changed-files
            uses: tj-actions/changed-files@v18.7
        - uses: barroqueiro/Cybersecurity-Actions@v0.5.18
            with:
            scan-type: 'BP'
            prosp-filepath: 'SecurityPipelineAssets/ConfigFiles/prospector_profile.yaml'
            prosp-cmd: '-8'
            radon-cmd: '-n B'
            files-toscan: '${{ steps.changed-files.outputs.all_changed_files }}'

We can pass the changed files that come from the changed-files action to the files-toscan parameter like such

### Vulnerable Scan Related parameters

#### **Custom Horusec Config file**

Path to a [Horusec config file](https://docs.horusec.io/docs/cli/commands-and-flags/#1-configuration-file) to be used by the horusec run

    Name: horusec-filepath
    Required: False
    Default: ''

#### **Prospector Command Line Arguments**

Aditional [command line arguments](https://docs.horusec.io/docs/cli/commands-and-flags/#3-flags) to be used during the horusec run

    Name: horusec-cmd
    Required: False
    Default: ''

#### **Example**

        horusec-filepath: 'ActionFiles/horusec-config.json'
        horusec-cmd: '-p="./app"'
    
This will use the custom horusec file to configure horusec, and when horusec is ran it will only scan the folder /app (-p="./app")

### Secrets Scan Related parameters

#### **Secrets to ignore file**

Path to a secrets ignore file, this is talked about later within the ignoring vulnerabilities section

    Name: secrets-filepath
    Required: False
    Default: ''

#### **Gitleaks Command Line Arguments**

Aditional [command line arguments](https://github.com/zricethezav/gitleaks#usage) to be used during the gitleaks run

    Name: gitleaks-cmd
    Required: False
    Default: ''

#### **Example**

    secrets-filepath: 'ActionFiles/.gitleaksignore'
    gitleaks-cmd: '-v'

This will use the .gitleaksignore file to ignore the secrets inside, and when gitleaks is ran it will run in verbose mode (-v)

### Dockle Scan Related parameters

#### **Dockle vulnerabilities to ignore file**

Path to a [dockle ignore file](https://github.com/goodwithtech/dockle#ignore-the-specified-checkpoints)

    Name: dockle-filepath
    Required: False
    Default: ''

#### **Dockle Command Line Arguments**

Aditional [command line arguments](https://github.com/goodwithtech/dockle#common-examples) to be used during the dockle run

    Name: dockle-cmd
    Required: False
    Default: ''

#### **Example**

    dockle-filepath: 'ActionFiles/.dockleignore'
    dockle-cmd: '--exit-level fatal'

This will use the .dockleignore file to ignore the dockle vulnerabilities specified inside, and when dockle is ran it will only fail if it finds a fatal level vulnerability

### Trivy Scan Related parameters

#### **Trivy vulnerabilities to ignore file**

Path to a [trivy ignore file](https://aquasecurity.github.io/trivy/v0.22.0/vulnerability/examples/filter/)

    Name: trivy-filepath
    Required: False
    Default: ''

#### **Trivy Command Line Arguments**

Aditional [command line arguments](https://aquasecurity.github.io/trivy/v0.27.1/docs/references/cli/image/) to be used during the trivy run

    Name: trivy-cmd
    Required: False
    Default: ''

#### **Example**

    trivy-filepath: 'ActionFiles/.trivyignore'
    trivy-cmd: ' --severity MEDIUM,HIGH,CRITICAL,UNKNOWN'

This will use the .trivyignore file to ignore the trivy vulnerabilities specified inside, and when trivy is ran it will omit low severity vulnerabilities

### Zap Scan Related parameters

#### **Zap rules file**

Path to a [Zap rules file](https://www.zaproxy.org/docs/docker/baseline-scan/#configuration-file) to be used during the OWASP Zap run

    Name: zap-filepath
    Required: False
    Default: ''

#### **Zap Command Line Arguments**

Aditional [command line arguments](https://www.zaproxy.org/docs/docker/full-scan/#usage) to be used during the zaproxy run

    Name: zap-cmd
    Required: False
    Default: ''

#### **Zap Target**

Url to be scanned

    Name: zap-target
    Required: False
    Default: ''

#### **Example**

    zap-filepath: 'ActionFiles/rules.tsv'
    zap-cmd: '-a'
    zap-target: 'http://localhost:5050/'

This will use the rules.tsv file to ignore/pass or fail the zap vulnerabilities specified inside, include the alpha active and passive scan rules (-a) and scan the target at http://localhost:5050/

### Workflow Blocking parameters

Each type of scan can be configured to fail the workflow if any issues are found.

This means there is a blocking parameter for each scan:

    - [bp,vs,ss,ds,ts,zs]-isblocking

These are true by default but if anything different than the string 'true' is passed the blocking will be disabled and even tho reports will still be uploaded the workflow will exit with sucess.

#### **Example**

    ss-isblocking: 'false'

### Debug

    Name: debug
    Required: False
    Default: 'false'

If debug is set to `true`, debug files (jsons directly from each tool) will be included within the artifacts

### Anotations that can be found

#### **Error Messages**

Message indicating some scan found problems and failed the workflow because of them

    [Type of scan] found problems, check the artifacts for more information

#### **Notice Messages**

Message indicating some scan did not find issues

    [Type of scan] did not find any problems

Message indication some scan found problems but non blocking was active

    [Type of scan] found problems but non blocking was active during this run

### Artifacts that can be found

Always a structure like the one bellow

    Reports
    ├── BadPracticesScan
    │   └── Directories of the original repository with html files
    ├── DockleScan
    │   └── DockleReport.html
    ├── SecretScan
    │   └── SecretsReport.html
    ├── TrivyScan
    │   └── TrivyReport.html
    ├── VulnerabilityScan
    │   └── HorusecReport.html
    ├── ZapScan
    │    └── ZapReport.html
    └── Debug
        ├── BadPracticesScan
        │   └── Directories of the original repository with json and txt files
        ├── DockleScan
        │   └── DockleReport.json
        ├── SecretScan
        │   └── SecretsReport.json
        ├── TrivyScan
        │   └── TrivyReport.json
        ├── VulnerabilityScan
        │   └── HorusecReport.json
        └── ZapScan
            └── ZapReport.json

### Ignoring vulnerabilities

#### **Bap practices**

Radon only serves as quality of life information for methods and their complexity so there is no ignoring feature for radon

Prospector allows for ignoring of issues with a custom prospector file already discussed above

#### **Vulnerability Scan**

Within the horusec report, for every vulnerability can be found a hash of said vulnerability. These hases are used to ignore them within the horusec config file.

- horusecCliRiskAcceptHashes: Hashes of vulnerabilities that we have accepted the risk, this is the way to ignore vulnerabilities to stop them from appearing in the output
- horusecCliSeveritiesToIgnore: What severities do we want to ignore, the default is INFO but we can for example ignore LOW
- horusecCliFilesOrPathsToIgnore: We can chose paths to be ignored when checking for vulnerabilities
- horusecCliFalsePositiveHashes: Similar to the risk accept hashes but these will be classified has being false positives (non vulnerabilities)

#### **Secrets Scan**

If at any point we get a false positive the SecretsReporting.py script will output a hash in every secret, taking that hash and adding it to the a text file, will make it so the next run wont block the workflow if we use the secrets-filepath parameter to indicate this path.

#### **Dockle Scan**

Dockle allows for ignoring of issues with a .dockleignore file already discussed above

Note: The file does need to be called .dockleignore

#### **Trivy Scan**

Trivy allows for ignoring of issues with a .dockleignore file already discussed above

Note: The file does need to be called .trivyignore

#### **Zap Scan**

Zap works the other way arround, it will not fail by deafult when finding issues, if we wish to fail on certain problems this must be sepecified within the rules.tsv file (Yes it needs to be .tsv), this file was already referenced above

### Choices Made

Each folder for a type of scan has a README.md inside specifying the choices made and how it works in a more detailed way (Dockle and Trivy scans were initially conceptualized as 1, container scanning, so their file is shared and stored withing the TS folder)

### Jumps

[Bad practices Documentation](BP/README.md)

[Vulnerabilities Scan Documentation](VS/README.md)

[Secrets Scan Documentation](SS/README.md)

[Container Scan Documentation](TS/README.md)

[Zap Scan Documentation](ZS/README.md)

