# Script developed to sumarize prospector and radon json reports and output results into a html file

import sys
import json
from datetime import datetime
from jinja2 import Environment, FileSystemLoader


# Translate the 3 types of structures that radon analyses 
RADON_DICT = {
    "F" : "Function",
    "M" : "Method",
    "C" : "Class"
}

# Provide a legend for clarification purposes
RADON_LEGEND = """

    A	low - simple block
    B	low - well structured and stable block
    C	moderate - slightly complex block
    D	more than moderate - more complex block
    E	high - complex block, alarming
    F	very high - error-prone, unstable block

"""

# Order the issues by line
# Print the most important atributes by issue found
def make_vulns(messages):
    messages = sorted(messages,key=lambda messages:messages["location"]["line"])
    vulns = {"Issues":[]}
    for msg in messages:
        tool = msg["source"]
        code = msg["code"]
        line = msg["location"]["line"]
        m = msg["message"]
        vulns["Issues"].append({"tool":tool,"code":code,"line":line,"message":m})
    
    return vulns

# Print the radon legend
# Parse the radon output by line and extracting all componenents
# Print each structure and their code complexity
def make_radon(radon):
    res = {"F":[],"E":[],"D":[],"C":[],"B":[],"A":[]}
    radon = radon[1:]
    for complexity in radon:
        complexity = complexity.replace("\n","")
        complexity_split = complexity.split(" ")[4:]
        block = RADON_DICT[complexity_split[0]]
        line = complexity_split[1].split(":")[0]
        name = complexity_split[2]
        score = complexity_split[-1]
        res[score].append({"block":block,"line":line,"name":name})
    return res

# Load the prospector and radon reports
# Call the designated functions to output the summaries of both tools
def main():
    with open(sys.argv[1],"r",encoding="UTF-8") as prosp:
        data = json.loads(prosp.read())
    with open(sys.argv[2],"r",encoding="UTF-8") as rad:
        radon = rad.readlines()
    today = datetime.now().strftime("%d/%m/%Y %H:%M:%S")
    vulns = make_vulns(data["messages"])
    radon_cc = make_radon(radon)
    env = Environment(loader=FileSystemLoader(sys.argv[3]))
    template = env.get_template('BadPracticesTemplate.jinja2')
    radon_colors = {"F":"#E12525","E":"#E15625","D":"#E1A525","C":"#E8F307","B":"#81F307","A":"#3DF307"}
    output_from_parsed_template = template.render(vulns=vulns,radon=radon_cc,radon_lengend=RADON_LEGEND,today=today,radon_colors=radon_colors)
    print(output_from_parsed_template)

if __name__ == "__main__":
    main()