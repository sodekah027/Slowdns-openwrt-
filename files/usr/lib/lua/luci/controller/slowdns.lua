module("luci.controller.slowdns", package.seeall)

function index()
    if not nixio.fs.access("/etc/config/slowdns") then
        return
    end

    local page = entry({"admin", "services", "slowdns"}, cbi("slowdns"), _("SlowDNS"), 60)
    page.dependent = true
    page.acl_depends = { "luci-app-slowdns" }

    entry({"admin", "services", "slowdns", "status"}, call("act_status")).leaf = true
    entry({"admin", "services", "slowdns", "start"}, call("act_start")).leaf = true
    entry({"admin", "services", "slowdns", "stop"}, call("act_stop")).leaf = true
    entry({"admin", "services", "slowdns", "restart"}, call("act_restart")).leaf = true
    entry({"admin", "services", "slowdns", "log"}, call("act_log")).leaf = true
end

function act_status()
    local sys = require "luci.sys"
    local running = sys.call("pgrep -x dnstt-client > /dev/null 2>&1") == 0
    luci.http.prepare_content("application/json")
    luci.http.write('{"running":' .. (running and "true" or "false") .. '}')
end

function act_start()
    luci.sys.call("/etc/init.d/slowdns start > /dev/null 2>&1")
    luci.http.redirect(luci.dispatcher.build_url("admin", "services", "slowdns"))
end

function act_stop()
    luci.sys.call("/etc/init.d/slowdns stop > /dev/null 2>&1")
    luci.http.redirect(luci.dispatcher.build_url("admin", "services", "slowdns"))
end

function act_restart()
    luci.sys.call("/etc/init.d/slowdns restart > /dev/null 2>&1")
    luci.http.redirect(luci.dispatcher.build_url("admin", "services", "slowdns"))
end

function act_log()
    local log = luci.sys.exec("logread 2>/dev/null | grep -i slowdns | tail -50")
    luci.http.prepare_content("text/plain")
    luci.http.write(log)
end
