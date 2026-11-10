local fs = require "nixio.fs"
local uci = luci.model.uci.cursor()

m = Map("slowdns", translate("SlowDNS Configuration"))

-- =====================
-- DNS Tunnel Settings
-- =====================
s = m:section(NamedSection, "settings", "settings", translate("DNS Tunnel Settings"))
s.anonymous = false

s:option(Flag, "enabled", translate("Enable"), translate("Enable SlowDNS service"))

ns = s:option(Value, "ns", translate("Nameserver (NS)"), translate("Hostname of the DNS nameserver"))
ns.default = "ns-bosku.agenvpn.web.id"

pubkey = s:option(Value, "pubkey", translate("Public Key"), translate("Harus 64 karakter hex digit dari server dnstt"))
pubkey.default = ""

dns_ip = s:option(Value, "dns_ip", translate("DNS Resolver IP"), translate("IP address DNS resolver"))
dns_ip.default = "103.253.244.163"

local_port = s:option(Value, "local_port", translate("Local Tunnel Port"), translate("Port lokal dnstt-client (default: 5300)"))
local_port.default = "5300"

-- =====================
-- SSH Account Settings
-- =====================
s2 = m:section(NamedSection, "settings", "settings", translate("SSH Account Settings"))
s2.anonymous = false

remote_host = s2:option(Value, "remote_host", translate("SSH Host"), translate("Hostname atau IP server SSH"))
remote_host.default = "bosku.agenvpn.web.id"

remote_port = s2:option(Value, "remote_port", translate("SSH Port"))
remote_port.default = "443"

ssh_user = s2:option(Value, "ssh_user", translate("Username SSH"), translate("Username akun SSH kamu"))
ssh_user.default = "root"

ssh_pass = s2:option(Value, "ssh_pass", translate("Password SSH"), translate("Password akun SSH kamu"))
ssh_pass.password = true

function m.on_commit(self)
    if self:formvalue("cbi.apply") then
        luci.sys.call("/etc/init.d/slowdns restart")
    end
end

return m
