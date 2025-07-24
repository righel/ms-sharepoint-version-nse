# ms-sharepoint-version-nse
 Nmap script to detect a Microsoft SharePoint instance version. 

### Usage
```
$ nmap -p 443 --script ms-sharepoint-version.nse example.com
Starting Nmap 7.94SVN ( https://nmap.org ) at 2025-07-21 17:33 CEST
Nmap scan report for example.com (127.0.0.1)
Host is up (0.030s latency).

PORT    STATE SERVICE
443/tcp open  https
| ms-sharepoint-version: 
|   16.0.10416.20050: 
|     build: 16.0.10416.20050
|     release_date: February 2025
|     product: SharePoint Server 2019
|   16.0.10416.20000: 
|     build: 16.0.10416.20000
|     release_date: November 2024
|     product: SharePoint Server 2019
|   16.0.10416.20026: 
|     build: 16.0.10416.20026
|     release_date: December 2024
|     product: SharePoint Server 2019  SharePoint Server 2019 MUI/language patch
|   16.0.10416.20041: 
|     build: 16.0.10416.20041
|     release_date: January 2025
|_    product: SharePoint Server 2019  SharePoint Server 2019 MUI/language patch

Nmap done: 1 IP address (1 host up) scanned in 10.42 seconds

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

