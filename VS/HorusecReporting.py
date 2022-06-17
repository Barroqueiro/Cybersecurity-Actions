# Script developed to sumarize a horusec json report and output results into a html file

import sys
from modules.tree import start
import json
import argparse
from datetime import datetime
from jinja2 import Environment, FileSystemLoader

# For each vulnerability get the most important details
def make_vulns(vuln_list):
    vulns_by_severity = {"CRITICAL":{},"HIGH":{},"MEDIUM":{},"LOW":{},"UNKNOWN":{}}
    if vuln_list is None:
        return vulns_by_severity
    for v in vuln_list:
        vuln = v["vulnerabilities"]
        location = vuln["file"] + " at line " + vuln["line"]
        hash = vuln["vulnHash"]
        severity = vuln["severity"]
        details = vuln["details"].replace("* Possible vulnerability detected: ","\n\n")
        if details in vulns_by_severity[severity]:
            vulns_by_severity[severity][details]["list_instances"].append({"location":location,"hash":hash})
        else: 
            vulns_by_severity[severity][details] = {"list_instances":[{"location":location,"hash":hash}]}
    l = []
    for key in vulns_by_severity:
        for k in vulns_by_severity[key]:
            l = []
            for instance in vulns_by_severity[key][k]["list_instances"]:
                l.append(instance["location"])
            vulns_by_severity[key][k]["tree"] = start(l)
    for key in vulns_by_severity:
        sorted(vulns_by_severity[key])
    return vulns_by_severity

# Read form the json horusec report
# Call the make_vulns function to get results on the list of vulnerabilities found
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
    args = parser.parse_args()
    config = vars(args)

    with open(config["json"],"r",encoding="UTF-8") as horu:
        data = json.loads(horu.read())

    today = datetime.now().strftime("%d/%m/%Y %H:%M:%S")
    vuln_list = data["analysisVulnerabilities"]
    vulns = make_vulns(vuln_list)

    styles = config["output_styles"].split(",")
    for s in styles:
        if s == "HTML":
            env = Environment(loader=FileSystemLoader(config["current_path"]+"/templates"),autoescape=True)
            template = env.get_template('HorusecTemplateHTML.jinja2')
            colors = {"CRITICAL":"#F3836B","HIGH":"#F1A36A","MEDIUM":"#F9D703","LOW":"#6AB4F1","UNKNOWN":"#53DAC1"}
            output_from_parsed_template = template.render(vulns=vulns,today=today,colors=colors)
            with open(config["output"]+".html","w") as f:
                f.write(output_from_parsed_template)
        if s == "MD":
            env = Environment(loader=FileSystemLoader(config["current_path"]+"/templates"),autoescape=True)
            template = env.get_template('HorusecTemplateMD.jinja2')
            appendix = env.get_template('HorusecTemplateAppendixMD.jinja2')
            output_from_parsed_template = template.render(vulns=vulns)
            output_from_parsed_template_appendix = appendix.render(vulns=vulns)
            with open(config["output"]+".md","w") as f:
                f.write(output_from_parsed_template)
            with open(config["output"]+"Appendix"+".md","w") as f:
                f.write(output_from_parsed_template_appendix)

if __name__ == "__main__":
    main()