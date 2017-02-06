# cloudkeeper
cloudkeeper is a AppDB <-> cloud synchronization utility

[![Build Status](https://secure.travis-ci.org/the-cloudkeeper-project/cloudkeeper.png)](http://travis-ci.org/the-cloudkeeper-project/cloudkeeper)
[![Dependency Status](https://gemnasium.com/the-cloudkeeper-project/cloudkeeper.png)](https://gemnasium.com/the-cloudkeeper-project/cloudkeeper)
[![Gem Version](https://fury-badge.herokuapp.com/rb/cloudkeeper.png)](https://badge.fury.io/rb/cloudkeeper)
[![Code Climate](https://codeclimate.com/github/the-cloudkeeper-project/cloudkeeper.png)](https://codeclimate.com/github/the-cloudkeeper-project/cloudkeeper)

##Requirements
* Ruby >= 2.0.0
* Rubygems

## Installation

###From RubyGems.org
To install the most recent stable version
```bash
gem install cloudkeeper
```

###From source (dev)
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

##Configuration
###Create a configuration file for cloudkeeper
Configuration file can be read by cloudkeeper from these
three locations:

* `~/.cloudkeeper/cloudkeeper.yml`
* `/etc/cloudkeeper/cloudkeeper.yml`
* `PATH_TO_GEM_DIR/config/cloudkeeper.yml`

The default configuration file can be found at the last location
`PATH_TO_GEM_DIR/config/cloudkeeper.yml`.

## Usage

TODO

## Contributing
1. Fork it ( https://github.com/the-cloudkeeper-project/cloudkeeper/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
