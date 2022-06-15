# Script developed to sumarize a Gitleaks json report and output results into a html file

import sys
import json
import hashlib
import argparse
from datetime import datetime
from jinja2 import Environment, FileSystemLoader

# For each secret captured delete the date of the finding (So the hash of the same secret stays the same)
# Calculate the hash using a string representation of the json of a secret
# If this hash matches one of the designated to be ignore then output it as an accepted secret
# If the secret is not to be ignored turn the return value to 1 to fail the pipeline and output it as a secret found
# For either situation append the relavant information to be returnednd
def make_secrets(secret_list,ignore):
    secrets = {"SECRETS":[],"ACCEPTED SECRETS":[]}
    ret = 0
    for s in secret_list:
        date = s["Date"]
        del s["Date"]
        h = hashlib.sha256(str(s).encode()).hexdigest()
        if h in ignore:
            status = "ACCEPTED SECRETS"
        else:
            status = "SECRETS"
            ret = 1
        description = s["Description"]
        match = s["Match"]
        file = s["File"]
        line_start = s["StartLine"]
        line_end = s["EndLine"]
        commit = s["Commit"]
        Author = s["Email"]
        secrets[status].append({"description":description,"match":match,"file":file,"line_start":line_start,"line_end":line_end,"commit":commit,"author":Author,"hash":h,"date":date})

    return secrets,ret

        
# Read from the gitleaks json report and from the IgnoredSecrets.txt file
# Pass these informations to the make_secrets function
# Return 1 if a secret not ignored is found
def main():
    parser = argparse.ArgumentParser(description="Comparing diferences in json file on a certain keyword")
    parser.add_argument('--json', type=str,
                        help='Json to analyse')
    parser.add_argument('--current-path', type=str,
                        help='Current path')
    parser.add_argument('--output-styles', type=str,
                        help='Output style')
    parser.add_argument('--output', type=str,
                        help='File to output the result')
    parser.add_argument('--ignore', type=str,
                        help='Secrets to ignore')       
    args = parser.parse_args()
    config = vars(args)

    with open(config["json"],"r", encoding="UTF-8") as secrets:
        data = json.loads(secrets.read())

    with open(config["ignore"],"r", encoding="UTF-8") as ignore:
        ig = ignore.read().split("\n")

    today = datetime.now().strftime("%d/%m/%Y %H:%M:%S")
    secrets,ret = make_secrets(data,ig)

    styles = config["output_styles"].split(",")
    for s in styles:
        if s == "HTML":
            env = Environment(loader=FileSystemLoader(config["current_path"]+"/templates"),autoescape=True)
            template = env.get_template('SecretsTemplateHTML.jinja2')
            colors = {"SECRETS":"#F3836B","ACCEPTED SECRETS":"#50C878"}
            output_from_parsed_template = template.render(secrets=secrets,today=today,colors=colors)
            with open(config["output"]+".html","w") as f:
                f.write(output_from_parsed_template)
        if s == "MD":
            env = Environment(loader=FileSystemLoader(config["current_path"]+"/templates"))
            template = env.get_template('SecretsTemplateMD.jinja2')
            output_from_parsed_template = template.render(secrets=secrets)
            with open(config["output"]+".md","w") as f:
                f.write(output_from_parsed_template)
    
    sys.exit(ret)

if __name__ == "__main__":
    main()
