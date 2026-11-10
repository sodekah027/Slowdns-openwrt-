module("luci.controller.slowdns", package.seeall)

function index()
    if not nixio.fs.access("/etc/config/slowdns") then
        return
    end

    local page = entry({"admin", "services", "slowdns"}, alias("admin", "services", "slowdns", "dashboard"), _("SlowDNS"), 60)
    page.dependent = true
    page.acl_depends = { "luci-app-slowdns" }

    entry({"admin", "services", "slowdns", "dashboard"}, call("act_dashboard"), _("Dashboard")).leaf = true
    entry({"admin", "services", "slowdns", "config"}, cbi("slowdns"), _("Configuration")).leaf = true
    entry({"admin", "services", "slowdns", "status"}, call("act_status")).leaf = true
    entry({"admin", "services", "slowdns", "start"}, call("act_start")).leaf = true
    entry({"admin", "services", "slowdns", "stop"}, call("act_stop")).leaf = true
    entry({"admin", "services", "slowdns", "restart"}, call("act_restart")).leaf = true
    entry({"admin", "services", "slowdns", "log"},     call("act_log")).leaf = true
end

function act_dashboard()
    luci.template.render("slowdns/dashboard")
end

function act_status()
    local sys = require "luci.sys"
    local uci = require "luci.model.uci".cursor()

    local dnstt_running = sys.call("pgrep -f dnstt-client > /dev/null 2>&1") == 0
    local ssh_running   = sys.call("pgrep -f 'ssh.*127.0.0.1' > /dev/null 2>&1") == 0
    local local_port    = uci:get("slowdns", "settings", "local_port") or "2222"
    local port_open     = sys.call("nc -z 127.0.0.1 " .. local_port .. " > /dev/null 2>&1") == 0

    local pid       = sys.exec("pgrep -f dnstt-client 2>/dev/null | head -1"):gsub("%s+", "")
    local ssh_count = sys.exec("pgrep -c -f 'ssh.*127.0.0.1' 2>/dev/null"):gsub("%s+", "")
    local uptime    = ""
    if pid ~= "" then
        uptime = sys.exec("ps -o pid,etime | awk '$1==" .. pid .. "{print $2}' 2>/dev/null"):gsub("%s+", "")
    end

    local ns         = uci:get("slowdns", "settings", "ns")         or "-"
    local dns_ip     = uci:get("slowdns", "settings", "dns_ip")     or "-"
    local remote_host= uci:get("slowdns", "settings", "remote_host")or "-"
    local remote_port= uci:get("slowdns", "settings", "remote_port")or "-"

    luci.http.prepare_content("application/json")
    luci.http.write(string.format(
        '{"dnstt":%s,"ssh":%s,"port":%s,"pid":"%s","ssh_count":"%s","uptime":"%s","local_port":"%s","ns":"%s","dns_ip":"%s","remote_host":"%s:%s"}',
        dnstt_running and "true" or "false",
        ssh_running   and "true" or "false",
        port_open     and "true" or "false",
        pid, ssh_count ~= "" and ssh_count or "0",
        uptime ~= "" and uptime or "-",
        local_port, ns, dns_ip, remote_host, remote_port
    ))
end

function act_start()
    luci.sys.call("/etc/init.d/slowdns start > /dev/null 2>&1")
    luci.http.redirect(luci.dispatcher.build_url("admin", "services", "slowdns", "dashboard"))
end

function act_stop()
    luci.sys.call("/etc/init.d/slowdns stop > /dev/null 2>&1")
    luci.http.redirect(luci.dispatcher.build_url("admin", "services", "slowdns", "dashboard"))
end

function act_restart()
    luci.sys.call("/etc/init.d/slowdns restart > /dev/null 2>&1")
    luci.http.redirect(luci.dispatcher.build_url("admin", "services", "slowdns", "dashboard"))
end

function act_log()
    local log = luci.sys.exec("logread 2>/dev/null | grep -i -E 'slowdns|dnstt|ssh' | tail -80")
    luci.http.prepare_content("text/plain")
    luci.http.write(log ~= "" and log or "(log kosong)")
end
