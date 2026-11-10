local fs = require "nixio.fs"
local uci = luci.model.uci.cursor()

m = Map("slowdns", translate("SlowDNS Configuration"))

s = m:section(NamedSection, "settings", "settings", translate("Settings"))
s.anonymous = false

s:option(Flag, "enabled", translate("Enable"), translate("Enable SlowDNS service"))

ns = s:option(Value, "ns", translate("Nameserver (NS)"), translate("Hostname of the DNS server"))
ns.default = "ns-bosku.agenvpn.web.id"

pubkey = s:option(Value, "pubkey", translate("Public Key"), translate("Base64 public key"))
pubkey.default = "b8fdc42e44c7ab1ebe2258e94cf6"

dns_ip = s:option(Value, "dns_ip", translate("DNS Resolver IP"))

dns_ip.default = "103.253.244.163"

local_port = s:option(Value, "local_port", translate("Local Port"), translate("Port dnstt-client listens locally"))
local_port.default = "2222"

remote_host = s:option(Value, "remote_host", translate("Remote SSH Host"))
remote_host.default = "bosku.agenvpn.web.id"

remote_port = s:option(Value, "remote_port", translate("Remote SSH Port"))
remote_port.default = "443"

function m.on_commit(self)
    if self:formvalue("cbi.apply") then
        luci.sys.call("/etc/init.d/slowdns restart")
    end
end

return m
