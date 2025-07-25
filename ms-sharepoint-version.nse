local http = require "http"
local nmap = require "nmap"
local shortport = require "shortport"
local json = require "json"
local stdnse = require "stdnse"
local string = require "string"

description = [[
  Check for Microsoft Sharepoint Server version.

  References:
    - https://learn.microsoft.com/en-us/officeupdates/sharepoint-updates
    - https://www.toddklindt.com/blog/Builds/SharePoint-SE-Builds.aspx
    - https://www.toddklindt.com/blog/Builds/SharePoint-2019-Builds.aspx
    - https://www.toddklindt.com/blog/Builds/SharePoint-2016-Builds.aspx
    - https://www.toddklindt.com/blog/Lists/Posts/Post.aspx?ID=346
    - https://www.toddklindt.com/blog/Lists/Posts/Post.aspx?ID=224
]]

author = "Luciano Righetti"
license = "GPLv3"
categories = {"version", "safe"}

portrule = shortport.service({"http", "https"})

local function get_http_options(host, port)
    
    local headers = {
        ["User-Agent"] = "nmap: ms-sharepoint-version.nse",
        ["Content-Type"] = "text/html; charset=utf-8"
    }

    if stdnse.get_script_args("browser") then
        headers = {
            ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
            ["Content-Type"] = "text/html; charset=utf-8",
            ["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
            ["Accept-Language"] = "en-US,en;q=0.5",
            ["Accept-Encoding"] = "gzip, deflate, br",
            ["Connection"] = "keep-alive"
        }
    end
    
    return {
        scheme = port.service,
        max_body_size = -1,
        header = headers,
    }
end

local function get_versions_map()
    local response = http.get_url("https://raw.githubusercontent.com/righel/ms-sharepoint-version-nse/refs/heads/main/ms-sharepoint_versions-dict.json", {max_body_size = -1})
    if response.status == 200 then
        _, versions = json.parse(response.body)
        return versions
    end

    return nil
end

local function get_sharepoint_build(host, port, build_version_map)
    local build = nil
    local http_options = get_http_options(host, port)

    -- method 1: get build from MicrosoftSharePointTeamServices header
    local response = http.generic_request(host.targetname or host.ip, port, "GET", "/", http_options)
    if response.header["MicrosoftSharePointTeamServices"] ~= nil then
        return response.header["MicrosoftSharePointTeamServices"]
    end

    if response.header["microsoftsharepointteamservices"] ~= nil then
        return response.header["microsoftsharepointteamservices"]
    end

    -- method 2: get build from /_vti_pvt/service.cnf
    local response = http.generic_request(host.targetname or host.ip, port, "GET", "/_vti_pvt/service.cnf", http_options)
    build = string.match(response.body, 'vti_extenderversion:SR|(%d+%.%d+%.%d+%.%d+)')
    if (build ~= nil) then
        return build
    end

    return nil
end

local function get_version_output(build, version)
    local output = {}

    output[build] = {
        product = version.name,
        build = version.build,
        release_date = version.release_date
    }

    return output
end

local function guess_sharepoint_build_info(version)
    local major, minor, build = version:match("^(%d+)%.(%d+)%.(%d+)")
    local product = "Unknown"
    local release_date = "Unknown"

    if major and minor and build then
        major = tonumber(major)
        minor = tonumber(minor)
        build = tonumber(build)

        if major == 14 then
            product = "SharePoint Server 2010"
        elseif major == 15 then
            product = "SharePoint Server 2013"
        elseif major == 16 then
            if build < 10000 then
                product = "SharePoint Server 2016"
            elseif build < 14000 then
                product = "SharePoint Server 2019"
            elseif build >= 14000 then
                product = "SharePoint Server Subscription Edition"
            end
        end
    end

    local output = {
        [version] = {
            product = product,
            build = version,
            release_date = release_date
        }
    }

    return output
end

action = function(host, port)
    local build_version_map = get_versions_map()
    local build = get_sharepoint_build(host, port, build_version_map)
    if build == nil then return "ERROR: Host not running MS SharePoint or could not get version" end
    build = string.gsub(build, "0.0", "0")

    local version = build_version_map[build]

    local exact_match = build_version_map[build]
    if exact_match ~= nil then
        return get_version_output(host, port, build, exact_match)
    end

    local matches = {}
    local pattern = "^" .. build:gsub("%.", "%%.") .. "%."

    for full_build, data in pairs(build_version_map) do
        if full_build:find(pattern) then
            matches[full_build] = data
        end
    end

    if next(matches) ~= nil then
        local output = {}
        for v, data in pairs(matches) do
            output[v] = get_version_output(v, data)[v]
        end
        return output
    else
        return guess_sharepoint_build_info(build)
    end
end
