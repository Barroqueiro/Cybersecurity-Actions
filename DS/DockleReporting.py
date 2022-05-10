# Script developed to sumarize a dockle json report and output results into a html file

import sys
import json
from datetime import datetime
from jinja2 import Environment, FileSystemLoader


# For each vulnerability get the most important details
def make_vulns(vuln_list):
    vulns_by_severity = {"FATAL":[],"WARN":[],"INFO":[]}
    for v in vuln_list:
        code = v["code"]
        title = v["title"]
        level = v["level"]
        alerts = v["alerts"]
        vulns_by_severity[level].append({"code":code,"title":title,"alerts":alerts})
    return vulns_by_severity

# Read form the json dockle report
# Call the make_vulns functions to create a list of vulnerabilities for jinja
def main():
    with open(sys.argv[1],"r",encoding="UTF-8") as dockle:
        data = json.loads(dockle.read())
    today = datetime.now().strftime("%d/%m/%Y %H:%M:%S")
    vuln_list= data["details"]
    vulns = make_vulns(vuln_list)
    env = Environment(loader=FileSystemLoader('./SecurityPipelineAssets/Templates'))
    template = env.get_template('DockleTemplate.jinja2')
    colors = {"FATAL":"#F3836B","WARN":"#FFCD00","INFO":"#53DAC1"}
    output_from_parsed_template = template.render(vulns=vulns,today=today,colors=colors)
    print(output_from_parsed_template)

if __name__ == "__main__":
    main()