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
on a best effort basis by the Arista EOS+ community with support subscriptions
available upon request. Please file any bugs, questions or enhancement requests
using [Github Issues](http://github.com/aristanetworks/puppet-cloudvision/issues)

## Module Description

Arista CloudVision is a dedicated toolset for managing and monitoring Arista
EOS network systems.  While very friendly to Network Engineers, it can be
convenient to enable self-service functions for other teams who use Puppet.
This module provides the resource types for interacting with CloudVision
components and wrapper classes to enable certain self-service functions.

## Setup

ToDo

## Usage

ToDo

## Reference

ToDo

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

## Contributing

Contributions to this project are welcomed in the form of issues (bugs,
questions, enhancement proposals) and pull requests.  All pull requests must be
accompanied by unit tests and up-to-date doc-strings, otherwise the pull
request will be rejected.

## License

See the [LICENSE](LICENSE) file.

## Release Notes

See the [CHANGELOG](CHANGELOG.md) file.


[cvprac]: https://github.com/aristanetworks/cvprac-rb
[arista]: http://www.arista.com


