# This file is used by Rack-based servers to start the application.

require 'yaml'
require 'bundler'
Bundler.require(:default)

require_relative 'lib/metis-util'
require_relative 'lib/server'

use Etna::CrossOrigin
use Etna::ParseBody
use Etna::SymbolizeParams

run Ihg::Server.new(YAML.load(File.read('config.yml')))
