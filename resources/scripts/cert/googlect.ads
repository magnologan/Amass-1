-- Copyright 2020-2021 Jeff Foley. All rights reserved.
-- Use of this source code is governed by Apache 2 LICENSE that can be found in the LICENSE file.

local url = require("url")
local json = require("json")

name = "GoogleCT"
type = "cert"

function start()
    set_rate_limit(1)
end

function vertical(ctx, domain)
    local token = ""
    local hdrs={
        Connection="close",
        Referer="https://transparencyreport.google.com/https/certificates",
    }

    while(true) do
        local page, err = request(ctx, {
            ['url']=build_url(domain, token),
            headers=hdrs,
        })
        if (err ~= nil and err ~= "") then
            log(ctx, "vertical request to service failed: " .. err)
            break
        end

        local j = json.decode("{\"results\": " .. page:gsub('^.*\n\n', "") .. " }")
        if (j == nil or #(j.results[1][2]) == 0) then
            break
        end

        for _, cert in pairs(j.results[1][2]) do
            get_cert_details(ctx, cert[5])
        end

        token = get_token(page)
        if (token == "") then
            break
        end
    end
end

function build_url(domain, token)
    local base = "https://www.google.com/transparencyreport/api/v3/httpsreport/ct/certsearch"
    if token ~= "" then
        base = base .. "/page"
    end

    local params = {
        ['domain']=domain,
        ['include_expired']="true",
        ['include_subdomains']="true",
    }
    if token ~= "" then
        params['p'] = token
    end

    return base .. "?" .. url.build_query_string(params)
end

function get_token(content)
    local token = ""
    local pattern = '\\[(null|"[a-zA-Z0-9]+"),"([a-zA-Z0-9]+)",null,([0-9]+),([0-9]+)\\]'

    local matches = submatch(content, pattern)
    if (matches == nil or #matches == 0) then
        return token
    end

    local match = matches[1]
    if (match ~= nil and #match == 5 and (match[4] < match[5])) then
        token = match[3]
    end

    return token
end

function get_cert_details(ctx, hash)
    local base = "https://www.google.com/transparencyreport/api/v3/httpsreport/ct/certbyhash"

    local u = base .. "?" .. url.build_query_string({['hash']=hash})
    local resp, err = request(ctx, {['url']=u})
    if (err ~= nil and err ~= "") then
        log(ctx, "get_cert_details request to service failed: " .. err .. ", URL: " .. u)
        return
    end

    local j = json.decode("{\"results\": " .. resp:gsub('^.*\n\n', "") .. " }")
    if (j == nil or #(j.results[1][2][6]) == 0) then
        return
    end

    for _, name in pairs(j.results[1][2][6]) do
        new_name(ctx, name)
    end
end
