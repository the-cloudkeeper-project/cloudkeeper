<h1 align="center">
  <img src="https://i.imgur.com/dObI6KR.png" alt="Logo Cloudkeeper" title="Logo Cloudkeeper" style="width: 256px;"/>
  <p>Cloudkeeper</p>
</h1>

<p align="center">
  <a href="http://travis-ci.org/the-cloudkeeper-project/cloudkeeper"><img src="https://img.shields.io/travis/the-cloudkeeper-project/cloudkeeper.svg?style=flat-square" alt="Travis"></a>
  <a href="https://depfu.com/repos/the-cloudkeeper-project/cloudkeeper"><img src="https://img.shields.io/depfu/the-cloudkeeper-project/cloudkeeper.svg?style=flat-square" alt="Depfu"></a>
  <a href="https://rubygems.org/gems/cloudkeeper"><img src="https://img.shields.io/gem/v/cloudkeeper.svg?style=flat-square" alt="Gem"></a>
  <a href="https://codeclimate.com/github/the-cloudkeeper-project/cloudkeeper"><img src="https://img.shields.io/codeclimate/maintainability/the-cloudkeeper-project/cloudkeeper.svg?style=flat-square" alt="Code Climate"></a>
  <a href="https://hub.docker.com/r/cloudkeeper/cloudkeeper/"><img src="https://img.shields.io/badge/docker-ready-blue.svg?style=flat-square" alt="DockerHub"></a>
  <a href="https://zenodo.org/record/891885"><img src="https://img.shields.io/badge/dynamic/json.svg?label=DOI&colorB=0D7EBE&prefix=&suffix=&query=$.doi&uri=https%3A%2F%2Fzenodo.org%2Fapi%2Frecords%2F891885&style=flat-square" alt="DOI"></a>
</p>

<h4 align="center">EGI AppDB <-> CMF synchronization utility</h4>

## What does Cloudkeeper do?
Cloudkeeper is able to read image lists provided by EGI AppDB, parse their content and decide what cloud appliances should be added, updated or removed from managed cloud. During the addition and update Cloudkeeper is able to download an appliance's image and convert it to the format supported by the managed cloud.

Currently supported image formats are:
* QCOW2
* RAW
* VMDK
* OVA

## How does Cloudkeeper work?
Cloudkeeper communicates with cloud specific components via [gRPC](http://www.grpc.io/) communication framework to manage individual clouds.

Currently supported clouds:
* [OpenNebula](https://opennebula.org/) - component [Cloudkeeper-ONE](https://github.com/the-cloudkeeper-project/cloudkeeper-one)
* [OpenStack](https://www.openstack.org/) - component [Cloudkeeper-OS](https://github.com/the-cloudkeeper-project/cloudkeeper-os)
* [Amazon Web Services](https://aws.amazon.com/) - component [Cloudkeeper-AWS](https://github.com/the-cloudkeeper-project/cloudkeeper-aws)

## Requirements
* Ruby >= 2.2.0
* Rubygems
* qemu-img (image conversion utility)
* NGINX (optional)

## Installation

### From RubyGems.org
To install the most recent stable version
```bash
gem install cloudkeeper
```

### From source (dev)
**Installation from source should never be your first choice! Especially, if you are not
familiar with RVM, Bundler, Rake and other dev tools for Ruby!**

**However, if you wish to contribute to our project, this is the right way to start.**

To build and install the bleeding edge version from master

```bash
git clone git://github.com/the-cloudkeeper-project/cloudkeeper.git
cd cloudkeeper
gem install bundler
bundle install
bundle exec rake spec
```

## Configuration
### Create a configuration file for Cloudkeeper
Configuration file can be read by Cloudkeeper from these
three locations:

* `~/.cloudkeeper/cloudkeeper.yml`
* `/etc/cloudkeeper/cloudkeeper.yml`
* `PATH_TO_GEM_DIR/config/cloudkeeper.yml`

The default configuration file can be found at the last location
`PATH_TO_GEM_DIR/config/cloudkeeper.yml`.

## Usage
Cloudkeeper is run with executable `cloudkeeper`. For further assistance run `cloudkeeper help sync`:
```bash
$ cloudkeeper help sync

Usage:
  cloudkeeper sync --backend-endpoint=BACKEND-ENDPOINT --external-tools-execution-timeout=N --formats=one two three --image-dir=IMAGE-DIR --image-list=IMAGE-LIST --qemu-img-binary=QEMU-IMG-BINARY

Options:
  --image-list=IMAGE-LIST                            # Image list to sync against
  [--verify-image-list], [--no-verify-image-list]    # Verify SMIME signature on image list
                                                     # Default: true
  [--ca-dir=CA-DIR]                                  # CA directory
                                                     # Default: /etc/grid-security/certificates/
  [--authentication], [--no-authentication]          # Client <-> server authentication
  [--certificate=CERTIFICATE]                        # Core's host certificate
                                                     # Default: /etc/grid-security/hostcert.pem
  [--key=KEY]                                        # Core's host key
                                                     # Default: /etc/grid-security/hostkey.pem
  --image-dir=IMAGE-DIR                              # Directory to store images to
                                                     # Default: /var/spool/cloudkeeper/images/
  --qemu-img-binary=QEMU-IMG-BINARY                  # Path to qemu-img binary (image conversion)
                                                     # Default: /usr/bin/qemu-img
  [--nginx-binary=NGINX-BINARY]                      # Path to nginx binary (HTTP server)
                                                     # Default: /usr/bin/nginx
  --external-tools-execution-timeout=N               # Timeout for execution of external tools in seconds
                                                     # Default: 600
  [--remote-mode], [--no-remote-mode]                # Remote mode starts HTTP server (NGINX) and serves images to backend via HTTP
  [--nginx-runtime-dir=NGINX-RUNTIME-DIR]            # Runtime directory for NGINX
                                                     # Default: /var/run/cloudkeeper/
  [--nginx-error-log-file=NGINX-ERROR-LOG-FILE]      # NGINX error log file
                                                     # Default: /var/log/cloudkeeper/nginx-error.log
  [--nginx-access-log-file=NGINX-ACCESS-LOG-FILE]    # NGINX access log file
                                                     # Default: /var/log/cloudkeeper/nginx-access.log
  [--nginx-pid-file=NGINX-PID-FILE]                  # NGINX pid file
                                                     # Default: /var/run/cloudkeeper/nginx.pid
  [--nginx-ip-address=NGINX-IP-ADDRESS]              # IP address NGINX can listen on
                                                     # Default: 127.0.0.1
  [--nginx-port=N]                                   # Port NGINX can listen on
                                                     # Default: 50505
  [--nginx-proxy-ip-address=NGINX-PROXY-IP-ADDRESS]  # Proxy IP address
  [--nginx-proxy-port=N]                             # Proxy port
  [--nginx-proxy-ssl], [--no-nginx-proxy-ssl]        # Whether proxy will use SSL connection
  --backend-endpoint=BACKEND-ENDPOINT                # Backend's gRPC endpoint
                                                     # Default: 127.0.0.1:50051
  [--backend-certificate=BACKEND-CERTIFICATE]        # Backend's certificate
                                                     # Default: /etc/grid-security/backendcert.pem
  --formats=one two three                            # List of acceptable formats images can be converted to
                                                     # Default: ["qcow2"]
  --logging-level=LOGGING-LEVEL
                                                     # Default: ERROR
                                                     # Possible values: DEBUG, INFO, WARN, ERROR, FATAL, UNKNOWN
  [--logging-file=LOGGING-FILE]                      # File to write logs to
                                                     # Default: /var/log/cloudkeeper/cloudkeeper.log
  --lock-file=LOCK-FILE                              # File used to ensure only one running instance of cloudkeeper
                                                     # Default: /var/lock/cloudkeeper/cloudkeeper.lock
  [--debug], [--no-debug]                            # Runs cloudkeeper in debug mode
```

## Contributing
1. Fork it ( https://github.com/the-cloudkeeper-project/cloudkeeper/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
