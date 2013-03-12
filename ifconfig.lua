-- static definitions
--
local uri		   = ngx.var.uri
local headers	   = ngx.req.get_headers()

-- Reverse Resolution
local remote_addr   = ngx.var.remote_addr
local dns			= require 'resolver'
local r, err		= resolver:new{
						nameservers = {"10.10.2.254"},
						retrans = 2,  -- 5 retransmissions on receive timeout
						timeout = 2000,  -- 2 sec
						}

-- initiate GET handler
--
ngx.header.content_type = 'text/html';

-- Debug only
ngx.header['Cache-Control'] = 'no-cache, must-revalidate, max-age=0'
ngx.header['Pragma'] = 'no-cache, must-revalidate, max-age=0'


-- helper functions
--
local function tchelper(first, rest)
  return first:upper()..rest:lower()
end

local function capitalize(str)
  return (str:gsub("(%a)([%w_']*)", tchelper))
end

local function check4Proxy()
    if headers['via'] then
        return '<img src="/img/static/proxy.jpg" class="img-rounded" title="You appear to be behind a proxy" height=150 width=150>' 
    else
        return '<img src="/img/static/direct-connection.jpg" class="img-rounded" title="You appear not to be behind a proxy" height=120 width=120>' 
    end
end

local function check4Compression()
    if headers['accept-encoding'] then
        return '<img src="/img/static/compression.png" class="img-rounded" title="You are using HTTP Compression (' .. headers['accept-encoding'] .. ')" height=120 width=120 >'
    else
        return 'You are NOT using HTTP compression'
    end
end
    
local function check4Lang()
    if headers['accept-language'] then
        local lang = headers['accept-language']:sub(1,2) 
        return '<img src="/img/static/' .. lang .. '.png" class="img-rounded" height=100 width=100 title="Your browser language is ' .. lang:upper() .. '">'
    else
        return ''
    end
end

local function check4DNT()
    if headers['dnt'] == '1' then
        return '<img src="/img/static/do-not-track.jpeg" class="img-rounded" title="You are requesting to be untracked" height=120 width=120>' 
    else
        return '<img src="/img/static/tracking-ads.gif" class="img-rounded" title="You are NOT requesting to be untracked" height=120 width=120 >'
    end
end

local function resolvPTR()
    if not r then
        ngx.say("failed to instantiate the resolver: ", err)
        return
    end

    local reversed = remote_addr:gsub("(%d+).(%d+).(%d+).(%d+)", "%4.%3.%2.%1")
    local ans, err = r:query(reversed .. '.in-addr.arpa', { qtype = r.TYPE_PTR })
    if not ans then
        ngx.say("failed to query: ", err)
        return
    else
        return ans[1].ptrdname
    end
end


-- init HTML buffer write
ngx.say('<html><head><meta charset="utf-8">\n<meta name="Googlebot" content="nofollow" />\n<meta http-equiv="content-Type" content="text/html; charset=utf-8" />\n<meta http-equiv="content-style-type" content="text/css" />\n<meta http-equiv="content-language" content="en" />\n<meta http-equiv="pragma" content="no-cache" />\n<meta http-equiv="cache-control" content="no-cache" />')
ngx.say('<title>Where I Am</title>\n<link rel="stylesheet" href="//cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/2.1.1/css/bootstrap.min.css"> </head>\n<body>')
ngx.say('<h1>Where I Am  :: Display Users Information</h1>')
ngx.say('<center><h2>Your IP is ' .. remote_addr .. '</h2>')
ngx.say('<div text:small>Reverse IP ', resolvPTR(), '</div>')
ngx.say('<br><br><br>')
ngx.say('<a href="" class="btn btn-small btn-primary disabled">Reload</a></center>')
ngx.say('<br><br><br>')
ngx.say('<div align=center><table><caption>Browser And Connection Features</caption>')
ngx.say('<tr>')
ngx.say('<td>' , check4DNT() , '</td>')
ngx.say('<td>' , check4Proxy() , ' </td>')
ngx.say('<td>' , check4Lang(), '</td>')
ngx.say('<td>', check4Compression(), '</td>')
ngx.say('</tr>')
ngx.say('</table></div>')
ngx.say('<br><br><br>')
ngx.say('<table class="table table-condensed"><tr>Raw HTTP Information Starting Here</tr>')
for k, v in pairs(headers) do
		ngx.say('<tr><td><small>', k,': ', v, '</small></td></tr>')
end
ngx.say('</table><div align=right><small><a href="https://github.com/dererk/where">Where I Am</a> is released under BSD license.</div>')
ngx.say('<div align=right><em>Server Time ', os.date("%c",os.time()), '</em></small></div>')
