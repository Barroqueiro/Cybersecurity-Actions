# Script developed to sumarize a horusec json report and output results into a html file

import sys
import os
import json
from datetime import datetime
from jinja2 import Environment, FileSystemLoader

# For each vulnerability get the most important details
def make_vulns(vuln_list):
    vulns_by_severity = {"CRITICAL":{},"HIGH":{},"MEDIUM":{},"LOW":{},"UNKNOWN":{}}
    if vuln_list is None:
        return vulns_by_severity
    for v in vuln_list:
        vuln = v["vulnerabilities"]
        file = vuln["file"]
        hash = vuln["vulnHash"]
        severity = vuln["severity"]
        line = vuln["line"]
        details = vuln["details"]
        if details in vulns_by_severity[severity]:
            vulns_by_severity[severity][details].append({"file":file,"line":line,"hash":hash})
        else: 
            vulns_by_severity[severity][details] = [{"file":file,"line":line,"hash":hash}]
    return vulns_by_severity

# Read form the json horusec report
# Call the make_vulns function to get results on the list of vulnerabilities found
def main():
    with open(sys.argv[1],"r",encoding="UTF-8") as horu:
        data = json.loads(horu.read())
    today = datetime.now().strftime("%d/%m/%Y %H:%M:%S")
    vuln_list = data["analysisVulnerabilities"]
    vulns = make_vulns(vuln_list)
    env = Environment(loader=FileSystemLoader(sys.argv[2]),autoescape=True)
    template = env.get_template('HorusecTemplate.jinja2')
    colors = {"CRITICAL":"#F3836B","HIGH":"#F1A36A","MEDIUM":"#F9D703","LOW":"#6AB4F1","UNKNOWN":"#53DAC1"}
    output_from_parsed_template = template.render(vulns=vulns,today=today,colors=colors)
    with open(sys.argv[3],"w") as f:
        f.write(output_from_parsed_template)

if __name__ == "__main__":
    main()