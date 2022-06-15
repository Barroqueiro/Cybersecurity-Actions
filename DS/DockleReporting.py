# Script developed to sumarize a dockle json report and output results into a html file

import sys
import json
import argparse
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

    with open(config["json"],"r",encoding="UTF-8") as dockle:
        data = json.loads(dockle.read())

    today = datetime.now().strftime("%d/%m/%Y %H:%M:%S")
    vuln_list= data["details"]
    vulns = make_vulns(vuln_list)

    styles = config["output_styles"].split(",")
    for s in styles:
        if s == "HTML":
            env = Environment(loader=FileSystemLoader(config["current_path"]+"/templates"),autoescape=True)
            template = env.get_template('DockleTemplateHTML.jinja2')
            colors = {"FATAL":"#F3836B","WARN":"#FFCD00","INFO":"#53DAC1"}
            output_from_parsed_template = template.render(vulns=vulns,today=today,colors=colors)
            with open(config["output"]+".html","w") as f:
                f.write(output_from_parsed_template)
        if s == "MD":
            env = Environment(loader=FileSystemLoader(config["current_path"]+"/templates"),autoescape=True)
            template = env.get_template('DockleTemplateMD.jinja2')
            output_from_parsed_template = template.render(vulns=vulns)
            with open(config["output"]+".md","w") as f:
                f.write(output_from_parsed_template)

if __name__ == "__main__":
    main()