#
#   Plato module
#   Copyright (C) 2016  Michel Megens <dev@bietje.net>
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

require 'optparse'
require 'optparse/time'
require 'ostruct'
require 'pp'

require 'plato/version'
require 'plato/scaffolder'
require 'plato/applicationalreadyexistserror'

module Plato
  class << self
    @cmd_args = nil

    def start(args)
      options = OpenStruct.new
      options.name = nil
      options.epath = nil
      options.app = false
      options.name = nil
      options.libdir = nil
      options.target = nil

      parser = OptionParser.new do |opts|
        opts.banner = "Usage: plato app [options]"
        opts.separator ""
        opts.separator "Specific options:"

        # Mandatory
        opts.on("-r", "--root PATH",
                "Absolute path to ETA/OS") do |path|
          options.epath = path
        end

        # Mandatory
        opts.on("-n", "--name NAME",
                "Name of the application") do |name|
          options.name = name
        end

        # Mandatory
        opts.on("-l", "--libs PATH",
                "Path to the ETA/OS libraries") do |path|
          options.libdir = path
        end

        # Mandatory
        opts.on("-t", "--target TARGET",
                "Target architecture") do |target|
          options.target = target
        end

        opts.separator ""
        opts.separator "Common options:"

        opts.on_tail("-h", "--help", "Show this message") do
          puts opts
          exit
        end

        opts.on_tail("-v", "--version", "Print the Plato version") do
          puts "Plato #{Plato::VERSION}"
          exit
        end
      end

      parser.parse!(args)
      options.app = true if ARGV.pop.eql? "app"

      mandatory = [:app, :epath, :name, :target, :libdir]
      missing = mandatory.select do |param|
        if options[param].nil? or options[param] == false
          param
        end
      end

      unless missing.empty?
        puts "Missing mandatory arguments"
        puts ""
        puts parser
        exit
      end

      begin
        scaffolder = Plato::Scaffolder.new options
        scaffolder.create
        scaffolder.generate
      rescue ApplicationAlreadyExistsError => e
        puts "Error: #{e.message}"
        exit
      end
    end
  end
end

