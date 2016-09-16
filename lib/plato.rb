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
require 'tempfile'
require 'pp'
require 'zip'

require 'net/http'

require 'plato/version'
require 'plato/scaffolder'
require 'plato/applicationalreadyexistserror'

module Plato
  class << self
    def start(args)
      case args.shift
      when 'app'
        start_app(args)
      when 'get'
        start_get(args)
      when '-v'
        puts "Plato #{Plato::VERSION}"
        exit
      else
        puts "Usage: plato <command> <args>"
        puts ""
        puts "Available commands are:"
        puts "   app\tScaffolder to create new ETA/OS applications"
      end
    end

    def start_get(args)
      options = OpenStruct.new
      options.output = Dir.pwd
      options.target = 'stable'

      parser = OptionParser.new do |opts|
        opts.banner = "Usage: plato get [options]"
        opts.separator ""
        opts.separator "Specific options:"

        opts.on('-o', '--output PATH',
                'Place to dump the ETA/OS download') do |path|
          options.output = path
        end

        opts.on('-t', '--target TARGET',
                'Download target. Available targets are: stable, old-stable and bleeding.') do |target|
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

      parser.parse!
      Plato.download(options.output, options.target)
    end

    def start_app(args)
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
      options.app = true

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

    def parse_target(target)
      ref = target
      odd_versions = ['stable', 'latest', 'old-stable', 'bleeding']

      if odd_versions.include? target
        uri = URI("http://plato.bietje.net/#{target}.txt")
        ref = Net::HTTP.get(uri)
      end

      ref
    end

    def download(out, target)
      # The correct git refs for the target can be found using the Plato
      # web service (plato.bietje.net).
      first = true
      silly_name = nil
      ref = Plato.parse_target(target)
      uri = URI("https://git.bietje.net/etaos/etaos/repository/archive.zip?ref=#{ref}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)
      zip = Tempfile.new("etaos-#{ref}.zip", Dir.tmpdir, 'wb+')
      zip.binmode
      zip.write(response.body)
      path = zip.path
      zip.close

      Zip::File.open(path) do |zip_file|
        zip_file.each do |f|
          if first
            silly_name = f.name
            first = false
          end

          f_path = File.join(out, f.name)
          FileUtils.mkdir_p(File.dirname(f_path))
          zip_file.extract(f, f_path) unless File.exist?(f_path)
        end
      end

      # fix the silly top dir name
      f_path = File.join(out, silly_name)
      f_path_new = File.join(out, "etaos-#{target}")
      FileUtils.mv f_path, f_path_new
    end
  end
end

