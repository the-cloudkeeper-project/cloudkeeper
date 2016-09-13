# CloudKeeper
CloudKeeper is a AppDB <-> cloud synchronization utility

[![Build Status](https://secure.travis-ci.org/Misenko/cloud-keeper.png)](http://travis-ci.org/Misenko/cloud-keeper)
[![Dependency Status](https://gemnasium.com/Misenko/cloud-keeper.png)](https://gemnasium.com/Misenko/cloud-keeper)
[![Gem Version](https://fury-badge.herokuapp.com/rb/cloud-keeper.png)](https://badge.fury.io/rb/cloud-keeper)
[![Code Climate](https://codeclimate.com/github/Misenko/cloud-keeper.png)](https://codeclimate.com/github/Misenko/cloud-keeper)

##Requirements
* Ruby >= 2.0.0
* Rubygems

## Installation

###From RubyGems.org
To install the most recent stable version
```bash
gem install cloud-keeper
```

###From source (dev)
**Installation from source should never be your first choice! Especially, if you are not
familiar with RVM, Bundler, Rake and other dev tools for Ruby!**

**However, if you wish to contribute to our project, this is the right way to start.**

To build and install the bleeding edge version from master

```bash
git clone git://github.com/Misenko/cloud-keeper.git
cd cloud-keeper
gem install bundler
bundle install
bundle exec rake spec
```

##Configuration
###Create a configuration file for CloudKeeper
Configuration file can be read by CloudKeeper from these
three locations:

* `~/.cloud-keeper/cloud-keeper.yml`
* `/etc/cloud-keeper/cloud-keeper.yml`
* `PATH_TO_GEM_DIR/config/cloud-keeper.yml`

The default configuration file can be found at the last location
`PATH_TO_GEM_DIR/config/cloud-keeper.yml`.

## Usage

TODO

## Contributing
1. Fork it ( https://github.com/Misenko/cloud-keeper/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
