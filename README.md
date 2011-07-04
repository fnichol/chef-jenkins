# Description

Installs and configures Jenkins CI server & node slaves. Resource providers
to support automation via jenkins-cli, including job create/update.

# Requirements

## Chef

* Chef version 0.9.10 or higher

## Platform

* 'default' - Server installation - currently supports Red Hat/CentOS 5.x and
Ubuntu 8.x/9.x/10.x

* 'node_ssh' - Any platform that is running sshd.

* 'node_jnlp' - Unix platforms. (depends on runit recipe)

* 'node_windows' - Windows platforms only.  Depends on .NET Framework, which can
be installed with the windows::dotnetfx recipe.

## Cookbooks

The `default` recipe has the following cookbook pre-requisites:

* [apt][apt] cookbook from Opscode for Debian/Ubuntu platforms or the
[fnichol github fork][apt_fork] which has chef-solo support
* [java][java] cookbook from Opscode, the [windows::java][win_java] recipe from
the [dougm github repo][dougm_repo], or manually installing Java 1.5 or higher

The `jenkins::node_jnlp` recipe has an additional requirement on:

* [runit][runit] cookbook from Opscode

The `jenkins::node_windows` recipe has an additional requirement on:

* [windows::dotnetfx][dotnet] recipe from the [dougm github repo][dougm_repo]

[apt]:          http://community.opscode.com/cookbooks/apt
[apt_fork]:     https://github.com/fnichol/chef-apt
[java]:         http://community.opscode.com/cookbooks/java
[win_java]:     https://github.com/dougm/site-cookbooks/tree/master/windows
[runit]:        http://community.opscode.com/cookbooks/runit
[dotnet]:       https://github.com/dougm/site-cookbooks/tree/master/windows
[dougm_repo]:   https://github.com/dougm/site-cookbooks/

## Java

Jenkins requires Java 1.5 or higher, which can be installed via the Opscode java
cookbook or windows::java recipe.

## Jenkins node authentication

If your Jenkins instance requires authentication, you'll either need to embed
user:pass in the `server.url` or issue a jenkins-cli.jar login command
prior to using the jenkins::node_* recipes.  For example, define a role like so:

    name "jenkins_ssh_node"
    description "cli login & register ssh slave with Jenkins"
    run_list %w(vmw::jenkins_login jenkins::node_ssh)

Where the jenkins_login recipe is simply:

    jenkins_cli "login --username #{node['jenkins']['username']} --password #{node['jenkins']['password']}"

# Recipes

## default

Installs a Jenkins CI server using a native package where available. The
recipe also generates an ssh private key and stores the ssh public key in the
node `pubkey` attribute for use by the node recipes.

## node_ssh

Creates the user and group for the Jenkins slave to run as and sets
`.ssh/authorized_keys` to the `pubkey` attribute.  The [jenkins-cli.jar][cli] is
downloaded from the Jenkins server and used to manage the nodes via the
[groovy][console] cli command.  Jenkins is configured to launch a slave agent on
the node using its SSH [slave plugin][slave_plugin].

[cli]:          http://wiki.jenkins-ci.org/display/JENKINS/Jenkins+CLI
[console]:      http://wiki.jenkins-ci.org/display/JENKINS/Jenkins+Script+Console
[slave_plugin]: http://wiki.jenkins-ci.org/display/JENKINS/SSH+Slaves+plugin

## node_jnlp

Creates the user and group for the Jenkins slave to run as and
'/jnlpJars/slave.jar' is downloaded from the Jenkins server.  Depends on
runit_service from the runit cookbook.

## node_windows

Creates the home directory for the node slave and sets 'JENKINS_HOME' and
'JENKINS_URL' system environment variables.  The [winsw][winsw] Windows service
wrapper will be downloaded and installed, along with generating
`jenkins-slave.xml` from a template.  Jenkins is configured with the node as a
[jnlp][jnlp] slave and '/jnlpJars/slave.jar' is downloaded from the Jenkins
server.  The 'jenkinsslave' service will be started the first time the recipe is
run or if the service is not running.  The 'jenkinsslave' service will be
restarted if '/jnlpJars/slave.jar' has changed.  The end results is functionally
the same had you chosen the option to [Let Jenkins control this slave as a
Windows service][win_service].

[winsw]:        http://weblogs.java.net/blog/2008/09/29/winsw-windows-service-wrapper-less-restrictive-license
[jnlp]:         http://wiki.jenkins-ci.org/display/JENKINS/Distributed+builds
[win_service]:  http://wiki.jenkins-ci.org/display/JENKINS/Installing+Jenkins+as+a+Windows+service

## proxy_nginx

Uses the nginx::source recipe from the nginx cookbook to install an HTTP
frontend proxy. To automatically activate this recipe set the
`node[:jenkins][:http_proxy][:variant]` to `nginx`.

## proxy_apache2

Uses the apache2 recipe from the apache2 cookbook to install an HTTP frontend
proxy. To automatically activate this recipe set the
`node[:jenkins][:http_proxy][:variant]` to `apache2`.

# Attributes

## `mirror`

Base URL for downloading Jenkins (server)

## `java_home`

Java install path, used for for cli commands

## `server/home`

JENKINS_HOME directory

## `server/user`

User the Jenkins server runs as

## `server/group`

Jenkins user primary group

## `server/port`

TCP listen port for the Jenkins server

## `server/url`

Base URL of the Jenkins server

## `server/plugins`

Download the latest version of plugins in this list, bypassing update center

## `node/name`

Name of the node within Jenkins

## `node/description`

Jenkins node description

## `node/executors`

Number of node executors

## `node/home`

Home directory ("Remote FS root") of the node

## `node/labels`

Node labels

## `node/mode`

Node usage mode, "normal" or "exclusive" (tied jobs only)

## `node/launcher`

Node launch method, "jnlp", "ssh" or "command"

## `node/availability`

"always" keeps node on-line, "demand" off-lines when idle

## `node/in_demand_delay`

Number of minutes for which jobs must be waiting in the queue before
attempting to launch this slave.

## `node/idle_delay`

Number of minutes that this slave must remain idle before taking it off-line.

## `node/env`

"Node Properties" -> "Environment Variables"

## `node/user`

user the slave runs as

## `node/ssh_host`

Hostname or IP Jenkins should connect to when launching an SSH slave

## `node/ssh_port`

SSH slave port

## `node/ssh_user`

SSH slave user name (only required if jenkins server and slave user is
different)

## `node/ssh_pass`

SSH slave password (not required when server is installed via default recipe)

## `node/ssh_private_key`

jenkins master defaults to: `~/.ssh/id_rsa` (created by the default recipe)

## `node/jvm_options`

SSH slave JVM options

## `iptables_allow`

if iptables is enabled, add a rule passing 'jenkins[:server][:port]'

## `http_proxy/variant`

Use `nginx` or `apache2` to proxy traffic to jenkins backend (`nil` by default)

## `http_proxy/www_redirect`

Add a redirect rule for 'www.*' URL requests ("disable" by default)

## `http_proxy/listen_ports`

List of HTTP ports for the HTTP proxy to listen on ([80] by default)

## `http_proxy/host_name`

Primary vhost name for the HTTP proxy to respond to (`node[:fqdn]` by default)

## `http_proxy/host_aliases`

Optional list of other host aliases to respond to (empty by default)

## `http_proxy/client_max_body_size`

Max client upload size ("1024m" by default, nginx only)

# Resources & Providers

## jenkins_cli

This resource can be used to execute the Jenkins cli from your recipes. For
example, install plugins via update center and restart Jenkins:

    %w(git URLSCM build-publisher).each do |plugin|
      jenkins_cli "install-plugin #{plugin}"
      jenkins_cli "safe-restart"
    end

## jenkins_node

This resource can be used to configure nodes as the 'node_ssh' and
'node_windows' recipes do or "Launch slave via execution of command on the
Master".

    jenkins_node node[:fqdn] do
      description  "My node for things, stuff and whatnot"
      executors    5
      remote_fs    "/var/jenkins"
      launcher     "command"
      command      "ssh -i my_key #{node[:fqdn]} java -jar #{remote_fs}/slave.jar"
      env          "ANT_HOME" => "/usr/local/ant", "M2_REPO" => "/dev/null"
    end

## jenkins_job

This resource manages jenkins jobs, supporting the following actions:

    :create, :update, :delete, :build, :disable, :enable

The 'create' and 'update' actions require a jenkins job config.xml.  Example:

    git_branch = 'master'
    job_name = "sigar-#{branch}-#{node[:os]}-#{node[:kernel][:machine]}"

    job_config = File.join(node[:jenkins][:node][:home], "#{job_name}-config.xml")

    jenkins_job job_name do
      action :nothing
      config job_config
    end

    template job_config do
      source "sigar-jenkins-config.xml"
      variables :job_name => job_name, :branch => git_branch, :node => node[:fqdn]
      notifies :update, resources(:jenkins_job => job_name), :immediately
      notifies :build, resources(:jenkins_job => job_name), :immediately
    end

# Usage

## 'manage_node' library

The script to generate groovy that manages a node can be used standalone. For
example:

    % ruby manage_node.rb name slave-hostname remote_fs /home/jenkins ... | \
        java -jar jenkins-cli.jar -s http://jenkins:8080/ groovy =

# Issues

* CLI authentication - http://issues.jenkins-ci.org/browse/JENKINS-3796
* CLI *-node commands fail with "No argument is allowed: nameofslave" - http://issues.jenkins-ci.org/browse/JENKINS-5973

# Development

* Source hosted at [GitHub][repo]
* Report issues/Questions/Feature requests on [GitHub Issues][issues]

Pull requests are very welcome! Make sure your patches are well tested.
Ideally create a topic branch for every seperate change you make.

[repo]:   https://github.com/fnichol/chef-jenkins
[issues]: https://github.com/fnichol/chef-jenkins/issues

# License & Author

This is a downstream fork of Doug MacEachern's Hudson cookbook
(https://github.com/dougm/site-cookbooks) and therefore deserves all the glory.

Author:: Doug MacEachern (<dougm@vmware.com>)

Contributor:: Fletcher Nichol <fnichol@nichol.ca>

Contributor:: Roman Kamyk <rkj@go2.pl>

Contributor:: Darko Fabijan <darko@renderedtext.com>

Copyright:: 2010, VMware, Inc

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
