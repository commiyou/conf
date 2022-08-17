# issue.sh
#
# Hit F12 to open the developer console (Mac: Cmd+Opt+J)
# Look at the Network tab.
# Do whatever you need to on the web site to trigger the action you're interested in
# Right click the relevant request, and select "Copy as cURL"
# save into issue.sh


import os
import pathlib
import re
import subprocess

from requests_html import HTML


def get_status(doc):
    #doc = open("z").read()
    html = HTML(html=doc)
    try:
        code= html.find("#status-val")[0].text
    except:
        return ""
    return code.strip()


def curl_issue(issue):
    url = "http://jira.allride-ai.cn:8080/issues/?filter=10793"
    curl_cmd = open(url).read()
    curl_cmd = re.sub(r'PV4-\d\d\d\d', 'PV4-'+ str(issue), curl_cmd)
    #print(curl_cmd)
    result = subprocess.run(curl_cmd,stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    if result.returncode != 0:
        print(result.stderr)
        return "ERROR"
    doc = result.stdout.decode("utf-8")
    return doc
    #print(doc)

if __name__ == "__main__":
    bug_dir = "~/bugs"
    p = pathlib.Path(os.path.expanduser(bug_dir))
    issues = [x for x in p.iterdir() if x.is_dir()]
    for issue in issues:
        print("processing {} ...".format(issue))
        name = issue.name
        if "-" in name:
            name = name.split("-")[-1]
        if name.isdigit():
            doc = curl_issue(name)
            status  = get_status(doc)
            print(status)
            if status == "Done":
                print("rm -rf {}/{}".format(bug_dir, issue.name))
                os.system("rm -rf {}/{}".format(bug_dir, issue.name))
                print("rm -rf {}/*{}*".format('~/Videos', issue.name))
                os.system("rm -rf {}/*{}*".format('~/Videos', issue.name))
