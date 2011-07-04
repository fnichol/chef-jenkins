maintainer       "Fletcher Nichol"
maintainer_email "fnichol@nichol.ca"
license          "Apache 2.0"
description      "Installs and configures Jenkins CI server & slaves"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.5"

recipe "jenkins",                 "Installs a Jenkins CI server"
recipe "jenkins::node_ssh",       ""
recipe "jenkins::node_jnlp",      ""
recipe "jenkins::node_windows",   ""
recipe "jenkins::iptables",       ""
recipe "jenkins::proxy_apache2",  ""
recipe "jenkins::proxy_nginx",    ""

%w{ debian ubuntu centos redhat }.each do |os|
  supports os
end

%w{ runit java }.each do |cb|
  depends cb
end

recommends "iptables"
