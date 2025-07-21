# ms-sharepoint-version-nse
 Nmap script to detect a Microsoft SharePoint instance version. 

### Usage
```
$ nmap -p 443 --script ms-sharepoint-version.nse easydocx.lu
Starting Nmap 7.94SVN ( https://nmap.org ) at 2025-07-21 17:33 CEST
Nmap scan report for REDACTED (REDACTED)
Host is up (0.030s latency).

PORT    STATE SERVICE
443/tcp open  https
| ms-sharepoint-version: 
|   16.0.10376: 
|     product: SharePoint Server 2019  SharePoint Server 2019 MUI/language patch
|     build: 16.0.10376
|_    release_date: July 2021

Nmap done: 1 IP address (1 host up) scanned in 0.81 seconds
```

* `--script-args=browser`:
Mimic a browser (Chrome) headers to avoid WAF filtering.
```
$ nmap -p 443 --script ms-sharepoint-version.nse --script-args=browser <target>
...
```

#### Multiple targets
If you plan to scan multiple targets, add the following argument: `http.max-cache-size=10000000`

```
$ nmap -p 443 --script ms-sharepoint-version.nse --script-args=http.max-cache-size=10000000 <target>
```

### Automation
Everyday a Github action is run to check if there are new Microsoft SharePoint versions published in this Microsoft docs page: 
* https://learn.microsoft.com/en-us/officeupdates/sharepoint-updates

If so, the file [ms-sharepoint_versions-dict.json](./ms-sharepoint_versions-dict.json) is automatically updated so the nmap script can detect these new versions.

