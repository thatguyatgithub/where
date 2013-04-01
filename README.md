About where
===========

 "where I am", or "where" for short, is, as the name suggests, a webservice that provides information related to the users connection, such as the IP from where the browser is reaching the internet, Reverse IP records, Country, City and some Browser-related information, such as whether its broadcasting non-tracking out-out (known as 'Do-Not-Track', or 'dnt'), user-agent, compression, languages supported, etc.
 "where" software is built upon the high performance [nginx] HTTP server, using the [embedded Lua interpreter](http://wiki.nginx.org/HttpLuaModule). The nginx Lua module, ngx lua, embeds Lua, via the standard Lua interpreter or LuaJIT 2.0, into Nginx and by leveraging Nginx's subrequests, allows the integration of the powerful Lua threads (Lua coroutines) into the Nginx event model.

 "where" is a [PoC](https://en.wikipedia.org/wiki/Proof_of_concept) of how the ngx lua stack can be used to build relatively small yet extremely high performance applications over the very HTTP server stack.


Status
======

 As a PoC application, "where" is a work in progress. Basic functionality is provided, although it should be carefully used.
 

How to use it
=============

As any webservice, you can access it using any web browser. But for facility/scripting reasons, a curl/wget friendly interface is provided as explained below:

>  dererk@ravel:~$ curl where.im.org.ar
>  Place: Vancouver, Canada
>  IP: 206.12.19.5
>  Reverse IP: ravel.debian.org
>  
>  >> Is this output too verbose? You just wanted to know your IP/Place/Country/City/Reverse IP!?
>  $ curl where.im.org.ar/ip 
>  >> Or 
>  $ wget -q -O - where.im.org.ar/ip 
>  >> switch "ip" for "place", "country", "city" or "reverse" && win!
>  
>  /Powered by nginx :: "Where I Am?"/
>  dererk@ravel:~$ curl where.im.org.ar/ip
>  206.12.19.5
>  dererk@ravel:~$ curl where.im.org.ar/place
>  Vancouver, Canada
>  dererk@ravel:~$ curl where.im.org.ar/city
>  Vancouver
>  dererk@ravel:~$ curl where.im.org.ar/reverse
>  ravel.debian.org
>  dererk@ravel:~$ curl where.im.org.ar/country
>  Canada
>  dererk@ravel:~$ 

 
Installation requirements
=========================
 * nginx >= 1.2.4, luajit-enabled support
 * luajit 
 * brilliant agentzh's [lua-resty-dns](https://github.com/agentzh/lua-resty-dns)
 * [lua-geoip](https://github.com/agladysh/lua-geoip)
 * GeoIP library, could be GeoLiteCountry (apt-get install geoip-database on debian systems) or MaxMind's paid one.


License
=======
"where" is released under BSD license


See Also
========
* the ngx lua module: http://wiki.nginx.org/HttpLuaModule


