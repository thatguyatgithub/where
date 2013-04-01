-- static definitions
--
local uri           = ngx.var.uri
local headers       = ngx.req.get_headers()
local find          = string.find

-- Reverse Resolution
local remote_addr   = ngx.var.remote_addr
local dns			= require 'resolver'
local r, err		= resolver:new{
						nameservers = {"10.10.2.254"},
						retrans = 2,  -- 5 retransmissions on receive timeout
						timeout = 2000,  -- 2 sec
						}

                        
-- GeoIP Resolution
-- 
local geoip_city    = require 'geoip.city'
local geodb         = geoip_city.open('./GeoLiteCity.dat')

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
        return '<img src="/img/static/compression.png" class="img-rounded" title="You are using HTTP Compression ('..headers['accept-encoding']..')" height=120 width=120 >'
    else
        return 'You are NOT using HTTP compression'
    end
end
    
local function check4Lang()
    if headers['accept-language'] then
        local lang = headers['accept-language']:sub(1,2) 
        return '<img src="/img/static/'..lang..'.png" class="img-rounded" height=100 width=100 title="Your browser language is '..lang:upper()..'">'
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
    local ans, err = r:query(reversed..'.in-addr.arpa', { qtype = r.TYPE_PTR })
    if not ans then
        ngx.log(ngx.ERR, "failed to query: ", err)
        return
    else
        return ans[1].ptrdname
    end
end

local function getCity()
    return  geodb:query_by_addr(remote_addr)["city"]
end

local function getCountryName()
    return geodb:query_by_addr(remote_addr)["country_name"]
end

local function getCountryCode()
    return geodb:query_by_addr(remote_addr)["country_code"]
end

local function getCountryCode3()
    return geodb:query_by_addr(remote_addr)["country_code3"]
end

if headers['user-agent']:find('curl') or
   headers['user-agent']:find('Wget') then
    -- Dump output in plain format 
    ngx.header.content_type = 'text/plain';

    -- URI resource could have a caching invalidator, use matching pattern instead 
    if      uri:find('ip') then
        ngx.say(remote_addr)

    elseif  uri:find('place') then
        ngx.say(getCity()..', '..getCountryName())

    elseif  uri:find('country') then
        ngx.say(getCountryName())

    elseif  uri:find('city') then
        ngx.say(getCity())

    elseif  uri:find('reverse') or
            uri:find('ptr') then
        ngx.say(resolvPTR())

    else
        ngx.say('Place: ' .. getCity()..', '..getCountryName())
        ngx.say('IP: ' .. remote_addr)
        ngx.say('Reverse IP: ' .. resolvPTR()..'\n')
        ngx.say('>> Is this output too verbose? You just wanted to know your IP/Place/Country/City/Reverse IP!?')
        ngx.say('$ curl where.im.org.ar/ip \n>> Or \n$ wget -q -O - where.im.org.ar/ip \n>> switch "ip" for "place", "country", "city" or "reverse" && win!')
        ngx.say('\n/Powered by nginx :: "Where I Am?"/') 
    end
else

    -- initiate GET handler
    --
    ngx.header.content_type = 'text/html';

    -- init HTML buffer write
    ngx.say('<html><head><meta charset="utf-8">\n<meta name="Googlebot" content="nofollow" />\n<meta http-equiv="content-Type" content="text/html; charset=utf-8" />\n<meta http-equiv="content-style-type" content="text/css" />\n<meta http-equiv="content-language" content="en" />\n<meta http-equiv="pragma" content="no-cache" />\n<meta http-equiv="cache-control" content="no-cache" />')
    ngx.say('<title>Where I Am</title>\n<link rel="stylesheet" href="//cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/2.1.1/css/bootstrap.min.css"> </head>\n<body>')
    ngx.say('<h1>Where I Am  :: Display Users Information</h1>')
    ngx.say('<br>')

    ngx.say('<div align="center"><table>')
    ngx.say('   <tr>')
    ngx.say('       <td style="text-align: center; "colspan="1" rowspan="2"><img src="/img/static/'..getCountryCode():lower()..'.png" class="img-rounded" title="You appear to be coming from '..getCountryName()..'" height="100" width="100"></td>')
    ngx.say('       <td style="vertical-align: top; text-align: center;"><h2>Your IP address is </h2></td>')
    ngx.say('   </tr>')
    ngx.say('   <tr>')
    ngx.say('       <td style="vertical-align: middle; text-align: center><div style="text-align: center;"> </div><h1 style="text-align: center;">'..remote_addr..'</h1></td>')
    ngx.say('   </tr>')
    ngx.say('   <tr>')
    ngx.say('       <td style="vertical-align: top; text-align: center; "><h3>'..getCity()..', '..getCountryName()..'</h3></td>')
    if resolvPTR() then
        ngx.say('       <td style="vertical-align: top;text-align: center; width: 600px;"><small>Reverse IP '..resolvPTR()..'</small></td>')
    end
    ngx.say('   </tr>')
    ngx.say('</table></div>')
    ngx.say('<div align="center"><a href="" class="btn btn-small btn-primary disabled">Reload</a></div><br>')

    ngx.say('<div align=center><table><caption>Browser And Connection Features</caption>')
    ngx.say('   <tr>')
    ngx.say('   <td>' , check4DNT() , '</td>')
    ngx.say('   <td>' , check4Proxy() , ' </td>')
    ngx.say('   <td>' , check4Lang(), '</td>')
    ngx.say('   <td>', check4Compression(), '</td>')
    ngx.say('</tr>')
    ngx.say('</table></div>')
    ngx.say('<br><br><br>')
    ngx.say('<table class="table table-condensed"><tr>Raw HTTP Information Starting Here</tr>')
    for k, v in pairs(headers) do
            ngx.say('<tr><td><small>', k,': ', v, '</small></td></tr>')
    end
    ngx.say('</table>')
    ngx.say('<div><blockquote>Is this output too verbose? You just wanted to know your IP/Place/Country/City/Reverse IP!?<br>')
    ngx.say('$ curl where.im.org.ar/ip<br> Or <br>$ wget -q -O - where.im.org.ar/ip <br> switch "ip" for "place", "country", "city" or "reverse" && win!</blockquote></div>')

    ngx.say('<blockquote class="pull-right"><a href="https://github.com/dererk/where">Powered by nginx :: Where I Am</a> is released under BSD license.')
    ngx.say('<div align=right><em>Server Time ', os.date("%c",os.time()), '</em></blockquote>')
end
