# Script developed to sumarize a Gitleaks json report and output results into a html file

import sys
import json
import hashlib
import subprocess
from datetime import datetime
from jinja2 import Environment, FileSystemLoader

# For each secret captured delete the date of the finding (So the hash of the same secret stays the same)
# Calculate the hash using a string representation of the json of a secret
# If this hash matches one of the designated to be ignore then output it as an accepted secret
# If the secret is not to be ignored turn the return value to 1 to fail the pipeline and output it as a secret found
# For either situation append the relavant information to be returnednd
def make_secrets(secret_list,ignore):
    secrets = {"SECRET":[],"ACCEPTED SECRET":[]}
    ret = 0
    for s in secret_list:
        del s["Date"]
        h = hashlib.sha256(str(s).encode()).hexdigest()
        if h in ignore:
            status = "ACCEPTED SECRET"
        else:
            status = "SECRET"
            ret = 1
        description = s["Description"]
        match = s["Match"]
        file = s["File"]
        line_start = s["StartLine"]
        line_end = s["EndLine"]
        commit = s["Commit"]
        Author = s["Email"]
        secrets[status].append({"description":description,"match":match,"file":file,"line_start":line_start,"line_end":line_end,"commit":commit,"author":Author,"hash":h})

    return secrets,ret

        
# Read from the gitleaks json report and from the IgnoredSecrets.txt file
# Pass these informations to the make_secrets function
# Return 1 if a secret not ignored is found
def main():
    with open(sys.argv[1],"r", encoding="UTF-8") as secrets:
        data = json.loads(secrets.read())
    with open(sys.argv[2],"r", encoding="UTF-8") as ignore:
        ig = ignore.read().split("\n")
    today = datetime.now().strftime("%d/%m/%Y %H:%M:%S")
    secrets,ret = make_secrets(data,ig)
    env = Environment(loader=FileSystemLoader(sys.argv[3]))
    template = env.get_template('SecretsTemplate.jinja2')
    colors = {"SECRET":"#F3836B","ACCEPTED SECRET":"#50C878"}
    output_from_parsed_template = template.render(secrets=secrets,today=today,colors=colors)
    with open(sys.argv[4],"w") as f:
        f.write(output_from_parsed_template)
    exit(ret)

if __name__ == "__main__":
    main()
