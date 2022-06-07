# Script developed to sumarize a trivy json report and output results into a html file

import sys
import json
from datetime import datetime
from jinja2 import Environment, FileSystemLoader


# For each vulnerability get the most important details and add default values if no value is found within the json
def make_vulns(vuln_list):
    vulns_by_severity = {"CRITICAL":{},"HIGH":{},"MEDIUM":{},"LOW":{},"UNKNOWN":{}}
    for v in vuln_list:
        if "VulnerabilityID" in v:
            id = v["VulnerabilityID"]
        else:
            id = "NOT APPLICABLE"
        if "PkgName" in v:
            pkg_name = v["PkgName"]
        else:
            pkg_name = "NOT APPLICABLE"
        if "InstalledVersion" in v:
            installed_version = v["InstalledVersion"]
        else:
            installed_version = "NOT APPLICABLE"
        if "FixedVersion" in v:
            fixed_version = v["FixedVersion"]
        else:
            fixed_version = "STILL NO FIX"
        if "PrimaryURL" in v:
            vuln_url = v["PrimaryURL"]
        else: 
            vuln_url = "NO URL"
        if "Title" in v:
            title = v["Title"]
        else:
            title = "NO TITLE"
        if "Description" in v:
            description = v["Description"]
        else:
            description = "NO DESCRIPTION"
        if "Severity" in v:
            severity = v["Severity"]
        else:
            severity = "NO SEVERITY"
        if "CweIDs" in v:
            cwes = [x.replace("CWE-","") for x in v["CweIDs"]]
        else:
            cwes = []
        count_avg = 0
        if "CVSS" in v:
            cvss = v["CVSS"]
            sum_avg = 0
            for cv in cvss:
                if "V3Score" in cvss[cv]:
                    count_avg += 1
                    sum_avg += cvss[cv]["V3Score"]
        if count_avg > 0:
            avg = round(sum_avg/count_avg,1)
        else:
            avg = "NOT KNOWN"
        if id in vulns_by_severity[severity]:
            vulns_by_severity[severity][id]["pkg_name"].append(pkg_name)
        else:
            vulns_by_severity[severity][id] = {"id":id,"pkg_name":[pkg_name],"installed_version":installed_version,"fixed_version":fixed_version,"vuln_url":vuln_url,"title":title,"description":description,"cwes":cwes,"cvss":avg}
    for key in vulns_by_severity:
        sorted(vulns_by_severity[key])
    return vulns_by_severity


# Read form the json horusec report
# Call the make_vulns functions to output results on the list of vulnerabilities found
def main():
    with open(sys.argv[1],"r",encoding="UTF-8") as trivy:
        data = json.loads(trivy.read())
    today = datetime.now().strftime("%d/%m/%Y %H:%M:%S")
    vuln_list = data[0]["Vulnerabilities"]
    vulns = make_vulns(vuln_list)
    env = Environment(loader=FileSystemLoader(sys.argv[2]),autoescape=True)
    template = env.get_template('TrivyTemplate.jinja2')
    colors = {"CRITICAL":"#F3836B","HIGH":"#F1A36A","MEDIUM":"#F9D703","LOW":"#6AB4F1","UNKNOWN":"#53DAC1"}
    output_from_parsed_template = template.render(vulns=vulns,today=today,colors=colors)
    with open(sys.argv[3],"w") as f:
        f.write(output_from_parsed_template)

if __name__ == "__main__":
    main()