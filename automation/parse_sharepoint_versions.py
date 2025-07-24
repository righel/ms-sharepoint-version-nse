#!/usr/bin/env python3

import requests
import re
import lxml.html as lh
import json
import sys
from looseversion import LooseVersion

versions = {}


def parse_ms_docs_versions():
    url = "https://learn.microsoft.com/en-us/officeupdates/sharepoint-updates"
    page = requests.get(url)

    doc = lh.fromstring(page.content)
    tr_elements = doc.xpath("//tr")

    for i in range(1, len(tr_elements)):
        row = tr_elements[i]

        # If row is not of size 4, the //tr data is not from our table
        if (
            len(row) != 4
            or row[0].text_content() == ""
            or row[0].text_content() == "Package Name"
        ):
            continue

        # grab release details url if exists
        url = None
        if len(row[1]) > 0 and row[1][0].tag == "a":
            url = {
                "kb_number": row[1][0].attrib["href"].strip(),
                "kb_title": row[1][0].text_content().strip(),
            }

        build = row[2].text_content().strip().rsplit(".", 1)[0]

        # check build number format and dots
        res = re.finditer(r"((\d+\.)+\d+)", build)

        for match in res:
            if not match:
                continue

            # cells in row
            # 0: Package name -> name
            # 1: KB Number -> kb_numbers
            # 2: Version -> build
            # 3: Release date -> release_date
            v = {
                "name": row[0].text_content().strip(),
                "release_date": row[3].text_content().strip(),
                "build": match.group(1),
                "kb_numbers": [url] if url else [],
            }

            versions[str(v["build"])] = v


def parse_toddklindt_versions():
    sources = [
        {
            "package_name": "​​SharePoint Server 2010",
            "url": "https://www.toddklindt.com/blog/Lists/Posts/Post.aspx?ID=224",
        },
        {
            "package_name": "​​SharePoint Server 2013",
            "url": "https://www.toddklindt.com/blog/Lists/Posts/Post.aspx?ID=346",
        },
        {
            "package_name": "SharePoint Server 2016",
            "url": "https://www.toddklindt.com/blog/Builds/SharePoint-2016-Builds.aspx",
        },
        {
            "package_name": "SharePoint Server 2019",
            "url": "https://www.toddklindt.com/blog/Builds/SharePoint-2019-Builds.aspx",
        },
        {
            "package_name": "SharePoint Server Subscription Edition",
            "url": "https://www.toddklindt.com/blog/Builds/SharePoint-SE-Builds.aspx",
        },
    ]

    for source in sources:
        page = requests.get(source["url"])
        doc = lh.fromstring(page.content)

        tr_elements = doc.xpath("//tr")

        for i in range(1, len(tr_elements)):
            row = tr_elements[i]

            # If row is not of size 6, the //tr data is not from our table
            if (
                len(row) != 6
                or row[0].text_content() == ""
                or row[0].text_content() == "Build Number"
            ):
                continue

            url = None
            if len(row[3]) > 0 and row[3][0].tag == "a":
                url = {
                    "kb_number": row[3][0].attrib["href"].strip(),
                    "kb_title": row[3][0].text_content().strip(),
                }

            build = (
                row[0].text_content().replace("\u200b", "").strip().rsplit(".", 1)[0]
            )

            res = re.match(r"^\d+\.\d+\.\d+$", build)
            if not res:
                continue

            # cells in row
            # 0: Build Number -> build
            # 1: Build Name -> name
            # 2: Component -> _
            # 3: Information Link -> kb_numbers
            # 4: Download Link -> _
            # 5: Notes -> _
            v = {
                "name": source["package_name"] + " - " + row[1].text_content().strip(),
                "release_date": row[1].text_content().strip(),
                "build": build,
                "kb_numbers": [url] if url else [],
            }

            if versions.get(str(v["build"])) is None:
                # only add if the build is not already in the versions dict
                # this avoids overwriting versions from ms docs with toddklindt.com versions
                versions[str(v["build"])] = v
                print(
                    f"Added version: {v['build']} - {v['name']} ({v['release_date']})"
                )


if __name__ == "__main__":

    if len(sys.argv[1:]) < 1:
        exit("output files path missing")
    versions_file = sys.argv[1]

    versions = json.load(open(versions_file, "r")) if versions_file else {}

    parse_ms_docs_versions()

    if (sys.argv[2] and sys.argv[2]) == "--include-toddklindt":
        parse_toddklindt_versions()

    versions = {k: versions[k] for k in sorted(versions, key=LooseVersion)}

    # save files
    with open(versions_file, "w") as output:
        json.dump(versions, output, indent=4)
