# Puppet Module for Arista CloudVision

#### Table of Contents

1. [Overview](#overview)
2. [Module Description](#module-description)
3. [Setup](#setup)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
6. [Limitations - OS compatibility, etc.](#limitations)
7. [Development - Guide for getting started developing the module](#development)
8. [Contributing - Contributing to this project](#contributing)
9. [License](#license)
10. [Release Notes](#release-notes)

## Overview

The CloudVision module for Puppet provides a set of resource types for managing
content within Arista CloudVision Portal.  The initial goal is to enable
self-service updates of CloudVision configlets from a Puppet wrapper class.

The CloudVision Puppet module is freely provided to the open source community
for automating CloudVision configurations.  Support for the module is provided
on a best effort basis by the Arista EOS+ team with support subscriptions
available upon request. Please file any bugs, questions or enhancement requests
using [Github Issues](http://github.com/aristanetworks/puppet-cloudvision/issues)

## Module Description

Arista CloudVision is a dedicated toolset for managing and monitoring Arista
EOS network systems.  While very friendly to Network Engineers, it can be
beneficial to enable self-service functions for other teams who use Puppet.
This module provides the resource types for interacting with CloudVision
components and wrapper classes to enable certain self-service functions.

## Setup

```sudo puppet module install aristanetworks-cloudvision```

You may iuse the included host-port configuration templates or create your own
in a data or profile module. These templates will be used by the included
`cloudvision_configlet` defined type to configure a top-of-rack (TOR) switch.
Name these templates such that they are easily recognizeable by the host
deployment team as this is how they will select the port-profile to apply.

Example [ERB template](https://docs.puppet.com/puppet/4.9/lang_template_erb.html):

``` erb
<%# cloudvision/templates/single_attached_vlan.erb -%>
interface Ethernet<%= @portnum %>
   description Host <%= @host %> managed by puppet template <%= @template %>
   switchport mode access
   switchport access vlan <%= @vlan %>
   no shutdown
!
end
```

Validation rules can be configured within Hiera to setup rules around which
ports on a TOR switch are available for hosts to ensure Puppet will not
accidentally affect network-facing ports such as MLAG peer-link or spine ports.

Example `hieradata/dc01/common.yaml`:
``` yaml
---
# Reserve the last-4 ports of a 64-port TOR for Spine links
cloudvision::switchport::auto_run: true
cloudvision::switchport::host_port_range:
  min: ‘1’
  max: ‘60’
cloudvision::switchport::rack_switch_map:
  A1: dc01-A1-tor.example.com
  A2: dc01-a2-tor.example.com
```

Finally, define the authentication credentials for Puppet to use when logging
into CloudVision Portal in one of the following files:
`$PUPPET_HOME/.cloudvision.yaml`, or a path defined in `$CLOUDVISION_CONF` in
the Puppet user’s environment.

Example `.cloudvision.yaml`:
``` yaml
# Configuration file for the aristanetworks-cloudvision Puppet module.
# Please ensure that you make this readable ONLY but the user starting
#   the Puppet-server. Ex: chmod 0600
---
nodes:
  - 192.0.2.11
  - 192.0.2.12
  - 192.0.2.13
username: 'cvppuppetuser'
password: 'puppetuserpassword'
```

## Usage

The host team can apply the `cloudvision::switchport` defined type to specify
the rack, port number, and host port profile:

``` puppet
cloudvision::switchport { 'esx3-20':
  rack     => 'A2',
  port     => '15',
  template => 'cloudvision/single_attached_vlan.erb',
  vlan     => 123,
}
```

NOTE: `template 'profile/esx_host.erb'` loads file:
`$environment/modules/profile/templates/esx_host.erb`

### Advanced usage: directly use the configlet resource

``` puppet
cloudvision_configlet { 'dc1-rackb3-tor-port-2':
  containers => ['dc1-rackb3-tor.example.com'],
  content    => “interface Ethernet2\n   no shutdown\nend”,
}
```

## Reference

The outward facing portion of this module are the defined types which sanitize
and validate input parameters, combined with environment data, pulled from
Hiera. It, then calls the `cloudvision_configlet` resource type to ensure the
configlet exists with the desired content and is applied to the correct node.
The `cloudvision_configlet` resource type uses [cvprac][cvprac], a RESTful API
Client for CloudVision Portal, to communicate with a single or cluster of CVP
servers.  If `auto_run` is set to true, then the associated CVP task will be
immediately executed, if necessary.

## Limitations
* Puppet 4 or later
* Ruby 2 or later (Included with Puppet all-in-one installer)
* [Arista CloudVision 2016.2 or later](arista)
* [REST API Client for CloudVision (cvprac) 0.1.0 or later](cvprac)

## Development

This module can be configured to run directly from source and configured to do
local development, sending the commands to the node over HTTP.  The following
instructions explain how to configure your local development environment.

This module requires one dependency that must be checked out as a Git working
copy in the context of ongoing development in addition to running Puppet from
source.

 * [cvprac][cvprac]

The dependency is managed via the bundler Gemfile and the environment needs to
be configured to use local Git copies:

    cd /workspace
    git clone https://github.com/aristanetworks/cvprac-rb
    export GEM_RBEAPI_VERSION=file:///workspace/cvprac-rb

Once the dependencies are installed and the environment configured, then
install all of the dependencies:

    git clone https://github.com/aristanetworks/puppet-cloudvision
    cd puppet-cloudvision
    bundle install --path .bundle/gems

Once everything is installed, run the spec tests to make sure everything is
working properly:

    bundle exec rspec spec

To run just a single spec file:

    bundle exec rake spec SPEC=spec/unit/puppet/provider/cloudvision_configlet/default_spec.rb

## Contributing

Contributions to this project are welcomed in the form of issues (bugs,
questions, enhancement proposals) and pull requests.  All pull requests must be
accompanied by unit tests and up-to-date doc-strings, otherwise the pull
request will be rejected.

This project is intended to be a safe, welcoming space for collaboration, and
contributors are expected to adhere to the [Contributor
Covenant](http://contributor-covenant.org) code of conduct.

## License

See the [LICENSE](LICENSE) file.

## Release Notes

See the [CHANGELOG](CHANGELOG.md) file.


[cvprac]: https://github.com/aristanetworks/cvprac-rb
[arista]: http://www.arista.com


