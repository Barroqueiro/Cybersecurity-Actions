# Script developed to sumarize a Zap json report and output results into a html file

import sys
import os
import json
from datetime import datetime
from jinja2 import Environment, FileSystemLoader

# For each vulnerability get the most important details
def make_vulns(sites):
    ret_sites = []
    for s in sites:
        if s["alerts"] == []:
            continue
        site={}
        site["name"] = s["@name"]
        site["host"] = s["@host"]
        site["port"] = s["@port"]
        site["ssl"] = s["@ssl"]
        vulns_by_severity = {"HIGH":[],"MEDIUM":[],"LOW":[],"INFORMATIONAL":[],"IGNORED":[]}
        for a in s["alerts"]:
            id = a["alertRef"]
            name = a["name"]
            risk = a["riskdesc"].split(" ")
            severity = risk[0]
            confidence = risk[1].replace("(","")
            confidence.replace(")","")
            instances = a["instances"]
            solution = a["solution"]
            references = a["reference"].split("<p>")[1:]
            if "cweid" in a:
                cwe = a["cweid"]
            else:
                cwe = "NOT APPLICABLE"
            vulns_by_severity[severity.upper()].append({"id":id,"name":name,"confidence":confidence,"instances":instances,"solution":solution,"references":references,"cwe":cwe})
        site["vulns"] = vulns_by_severity    
        if "ignoredAlerts" in s:
            for a in s["ignoredAlerts"]:
                id = a["alertRef"]
                name = a["name"]
                risk = a["riskdesc"].split(" ")
                severity = "IGNORED"
                confidence = "HIGH"
                instances = a["instances"]
                solution = a["solution"]
                references = a["reference"].split("<p>")[1:]
                if "cweid" in a:
                    cwe = a["cweid"]
                else:
                    cwe = "NOT APPLICABLE"
                vulns_by_severity[severity.upper()].append({"id":id,"name":name,"confidence":confidence,"instances":instances,"solution":solution,"references":references,"cwe":cwe})
        ret_sites.append(site)
    return ret_sites

# Read form the json horusec report
# Call the make_vulns function to get results on the list of vulnerabilities found
def main():
    with open(sys.argv[1],"r",encoding="UTF-8") as zap:
        data = json.loads(zap.read())
    today = datetime.now().strftime("%d/%m/%Y %H:%M:%S")
    sites = data["site"]
    vulns = make_vulns(sites)
    env = Environment(loader=FileSystemLoader(sys.argv[2]))
    template = env.get_template('ZapTemplate.jinja2')
    colors = {"HIGH":"#F1A36A","MEDIUM":"#F9D703","LOW":"#6AB4F1","INFORMATIONAL":"#53DAC1","IGNORED":"#50C878"}
    output_from_parsed_template = template.render(vulns=vulns,today=today,colors=colors)
    with open(sys.argv[3],"w") as f:
        f.write(output_from_parsed_template)

if __name__ == "__main__":
    main()