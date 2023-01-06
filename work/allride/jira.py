# issue.sh
#
# Hit F12 to open the developer console (Mac: Cmd+Opt+J)
# Look at the Network tab.
# Do whatever you need to on the web site to trigger the action you're interested in
# Right click the relevant request, and select "Copy as cURL"
# save into issue.sh


import os
import pathlib
import signal
import time
from urllib.parse import quote_plus

import click
from requests_html import HTMLSession
from tendo import singleton

BUG_DIR = "/data/youbin/bugs"
USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36"
OSSUTIL64 = "/usr/local/bin/ossutil64"
JQL = 'status in ("In Progress", "To Do", Backlog, Pending) AND component = Prediction AND labels = S AND created >= 2022-04-18 AND created <= 2022-12-08 ORDER BY priority DESC, summary ASC, created DESC'

# 车辆：ID6009

# 版本：547-demo_suzhoubei

# bag:oss://allride-sharing-archive/bags/220804/ID6009/biandaoshache/

# 50s
def extract_issue_desc(desc):
    lines = [x.strip() for x in desc.split("\n")]

    res = {"bags": []}
    for line in lines:
        if line.startswith("bag") or "bag:" in line or "bag：" in line:
            tmp = line[line.find("oss://") :].split()[0]
            if tmp.endswith(".bag"):
                res["bagdir"] = os.path.dirname(tmp)
                res["bags"].append(tmp)
            else:
                res["bagdir"] = tmp
        elif line.startswith("版本"):
            res["branch"] = line[3:].strip()
        elif line.startswith("log") or "log:" in line or "log：" in line:
            res["log"] = line[line.find("oss://") :].split()[0]
        elif line.find(".bag") != -1:
            bags = list(filter(lambda x: x.find(".bag") != -1, line.split()))
            res["bags"] += bags
        else:
            for line_part in line.replace("：", " ").split():
                if not line_part.startswith("oss://"):
                    continue
                if line_part.endswith(".bag"):
                    res["bags"].append(line_part)
                elif "/bag/" in line_part or "/bags/" in line_part:
                    res["bagdir"] = line_part
                elif (
                    "/log/" in line_part
                    or "/logs/" in line_part
                    or line_part.endswith("log.gz")
                ):
                    res["log"] = line_part

    for i, bag in enumerate(res["bags"]):
        if not bag.startswith("oss://"):
            res["bags"][i] = res["bagdir"].rstrip("/") + "/" + bag

    if "bagdir" not in res or not res["bagdir"]:
        print(f"@@@@ bad res {res}")
    # print(res)
    return res


class AllrideJira:
    def __init__(self):
        self._session = HTMLSession()

    def login(self, name, pw):
        print(f"login jira by {name} {pw}")
        url = "http://jira.allride-ai.cn:8080/login.jsp"

        header = {
            "User-Agent": USER_AGENT,
            "Content-Type": "application/x-www-form-urlencoded",
        }

        post_data = f"os_username={name}&os_password={quote_plus(pw)}&os_cookie=true&os_destination=&user_role=&atl_token=&login=Log+In"

        res = self._session.post(url, data=post_data, headers=header)

        if res.status_code == 200:
            print(f"Login succeed \n {self._session.cookies} \n {res.request.headers}")

            return True
        else:
            print(f"status code = {res.status_code}")
            return False

    def get_todo_issues(self):
        # jql = 'labels = 变道 AND createdDate >= 2022-07-01 AND status in ("To Do", "In Progress") AND component = Planning ORDER BY priority, createdDate DESC'
        url = f"http://jira.allride-ai.cn:8080/issues/?jql={quote_plus(JQL)}"
        header = {
            "User-Agent": USER_AGENT,
            "Host": "jira.allride-ai.cn:8080",
            "Upgrade-Insecure-Requests": "1",
        }

        print(f"request {url}")

        try:
            res = self._session.get(url, headers=header)
        except Exception as e:
            print(f"Error \n {e}")
            return
        # print(dir(res.html))
        res.html.render(send_cookies_session=True, wait=4, sleep=2)
        # print(f"headers {res.request.headers} {res.cookies} ")

        if res.status_code == 200:
            # attrs  {'title': '【planning】自车变道时，右前方目标车道有车，自车急刹车一下', 'data-key': 'PV4-4558', 'class': ('focused',)}
            issues = [
                (x.attrs["data-key"], x.attrs["title"])
                for x in res.html.find("ol.issue-list li")
            ]
            return issues
        else:
            return []

    def get_issue(self, issue_key):
        url = f"http://jira.allride-ai.cn:8080/browse/{issue_key}"
        print(f"getting {url} ...")

        try:
            res = self._session.get(url)
        except Exception as e:
            print(f"Error \n {e}")
            return

        if res.status_code == 200:
            status = res.html.find("#status-val")[0].text
            desc = res.html.find("#descriptionmodule div.user-content-block")[0].text
            # {'key': 'PV4-4558', 'url': 'http://jira.allride-ai.cn:8080/browse/PV4-4558', 'status': 'To Do',
            # 'desc': '车辆：ID6009\n版本：547-demo_suzhoubei\nbag:oss://allride-sharing-archive/bags/220804/ID6009/biandaoshache/\n50s'}

            issue = dict(
                key=issue_key,
                url=url,
                status=status,
                desc=desc,
                **extract_issue_desc(desc),
            )
            print(issue)

            return issue
        else:
            print(f"issue {issue_key} get error {res.status_code}")
            return []


def clean_issue(jira):
    bug_dir = BUG_DIR
    p = pathlib.Path(os.path.expanduser(bug_dir))
    issues = [x for x in p.iterdir() if x.is_dir()]
    for issue in issues:
        print("processing {} ...".format(issue))
        name = issue.name
        if "-" in name:
            name = name.split("-")[-1]
        if name.isdigit():
            issue_res = jira.get_issue("PV4-" + name)
            if issue_res["status"] in ("Done", "Pending", "In Testing"):
                print("\nrm -rf {}/{}".format(bug_dir, issue.name))
                os.system("rm -rf {}/{}".format(bug_dir, issue.name))
                print("\nrm -rf {}/*{}*".format("~/Videos", issue.name))
                os.system("rm -rf {}/*{}*".format("~/Videos", issue.name))


def run_sh(ncmd):
    print("\n" + ncmd + "\n")
    ret = os.system(ncmd)
    if ret == signal.SIGINT:
        exit(1)


def download_todo_issues(jira):
    bug_dir = BUG_DIR
    p = pathlib.Path(os.path.expanduser(bug_dir))

    issues = jira.get_todo_issues()
    print(f"get {len(issues)} issues")
    for issue in issues:
        issue_res = jira.get_issue(issue[0])
        print(f"\nget {issue_res} ...\n")
        name = issue_res["key"].split("-")[1]
        # if (p/name).exists():
        #    continue
        cmd = (
            f"mkdir -p {p / name} && cd { p / name } && {OSSUTIL64} cp --recursive -u "
        )
        if issue_res["bags"]:
            for bag in issue_res["bags"]:
                ncmd = f"{cmd} {bag} ."
                run_sh(ncmd)
        elif "bagdir" in issue_res:
            ncmd = f'{cmd} {issue_res["bagdir"]} .'
            run_sh(ncmd)
        else:
            print("bad issue ", issue[0])
        time.sleep(2)


@click.command()
@click.option("-n", "--name", required=True, help="jira username")
@click.option("-p", "--passwd", required=True, help="jira passwd")
def main(name, passwd):
    jira = AllrideJira()
    if not jira.login(name, passwd):
        return False
    # clean_issue(jira)
    download_todo_issues(jira)
    # issues = jira.get_todo_issues()


if __name__ == "__main__":
    me = singleton.SingleInstance()
    main()
