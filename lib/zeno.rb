#
#   Zeno module
#   Copyright (C) 2016, 2017  Michel Megens <dev@bietje.net>
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

require 'zeno/version'
require 'zeno/application'
require 'zeno/solution'
require 'zeno/applicationalreadyexistserror'
require 'zeno/missingargumentexception'

# Zeno base module
module Zeno
  class << self
    # Start the Zeno application
    # @param args [Array] The ARGV argument array.
    def start(args)
      case args.shift
      when 'app'
        start_app(args)
      when 'get'
        start_get(args)
      when 'solution'
        start_solution(args)
      when '-v'
        puts "Zeno #{Zeno::VERSION}"
        exit
      when '--version'
        puts "Zeno #{Zeno::VERSION}"
        exit
      else
        puts "Usage: zeno <command> <args>"
        puts ""
        puts "Available commands are:"
        puts "   app\t\tApplication to create new ETA/OS applications"
        puts "   get\t\tETA/OS download service"
        puts "   solution\tCreate an ETA/OS solution"
      end
    end

    # Start the get subcommand.
    # @param args [Array] The ARGV argument array.
    def start_get(args)
      options = OpenStruct.new
      options.output = Dir.pwd
      options.target = 'stable'

      parser = OptionParser.new do |opts|
        opts.banner = "Usage: zeno get [options]"
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

        opts.on('-V', '--versions',
                'List all available ETA/OS versions.') do
          puts "Available ETA/OS versions:"
          puts ""
          puts Zeno.get_versions
          exit
        end

        opts.separator ""
        opts.separator "Common options:"

        opts.on_tail("-h", "--help", "Show this message") do
          puts opts
          exit
        end

        opts.on_tail("-v", "--version", "Print the Zeno version") do
          puts "Zeno #{Zeno::VERSION}"
          exit
        end
      end

      parser.parse!
      Zeno.download(options.output, options.target)
    end

    # Start the solution subcommand.
    # @param args [Array] The ARGV argument array.
    def start_solution(args)
      options = OpenStruct.new
      options.name = nil
      options.path = Dir.pwd
      options.libdir = nil
      options.target = nil
      options.version = 'stable'
      options.apps = nil
      options.uploader = nil

      parser = OptionParser.new do |opts|
        opts.banner = "Usage: zeno solution [options]"
        opts.separator ""
        opts.separator "Specific options:"

        opts.on("-b", "--base PATH",
                "Solution base path") do |path|
          options.path = path || Dir.pwd
        end

        # Mandatory
        opts.on("-n", "--name NAME",
                "Solution name") do |name|
          options.name = name
        end

        # Mandatory
        opts.on("-l", "--libs PATH",
                "Relative path to the ETA/OS libraries") do |path|
          options.libdir = path
        end

      	opts.on("-a", "--apps APP1[,APP2,APPn]",
      		"List of applications to generate (comma separated") do |apps|
      	  options.apps = apps.split(',')
      	end

        # Mandatory
        opts.on("-t", "--target TARGET",
                "ETA/OS target architecture") do |arch|
          options.target = arch
        end

        opts.on("-V", "-ref VERSION",
                "ETA/OS version (git ref) to download") do |ref|
          options.version = ref
        end

        opts.on("-A", "--avrupload",
                "Configure the application Makefiles to use avrupload") do |u|
          options.uploader = :avrupload
        end

        opts.on("-d", "--avrdude",
                "Configure the application Makefiles to use avrdude") do |a|
          options.uploader = :avrdude
        end

        opts.separator ""
        opts.separator "Common options:"

        opts.on_tail("-h", "--help", "Show this message") do
          puts opts
          exit
        end

        opts.on_tail("-v", "--version", "Print the Zeno version") do
          puts "Zeno #{Zeno::VERSION}"
          exit
        end
      end

      parser.parse!

      mandatory = {
        :name => '-n',
        :libdir => '-l',
        :target => '-t'
      }

      begin
        Zeno.check_missing_args!(options, mandatory)
      rescue MissingArgumentException => e
        puts "#{e.msg}: #{e.missing_arguments.values.join(', ')}"
        puts parser
        exit
      end

      opts = Hash.new
      opts['apps'] = options.apps
      opts['name'] = options.name
      opts['ref']  = options.version
      opts['libs'] = options.libdir
      opts['path'] = options.path
      opts['target'] = options.target
      opts['uploader'] = options.uploader

      solution = Zeno::Solution.new(opts)
      solution.create
    end

    # Start the app subcommand.
    # @param args [Array] The ARGV argument array.
    def start_app(args)
      options = OpenStruct.new
      options.name = nil
      options.epath = nil
      options.app = false
      options.libdir = nil
      options.target = nil
      options.uploader = nil

      parser = OptionParser.new do |opts|
        opts.banner = "Usage: zeno app [options]"
        opts.separator ""
        opts.separator "Specific options:"

        # Mandatory
        opts.on("-r", "--root PATH",
                "Path to ETA/OS") do |path|
          options.epath = path
        end

        # Mandatory
        opts.on("-n", "--name NAME",
                "Name of the application") do |name|
          options.name = name
        end

        # Mandatory
        opts.on("-l", "--libs PATH",
                "Relative path to the ETA/OS libraries") do |path|
          options.libdir = path
        end

        # Mandatory
        opts.on("-t", "--target TARGET",
                "Target architecture") do |target|
          options.target = target
        end

        opts.on("-A", "--avrupload",
                "Configure the application Makefiles to use avrupload") do |u|
          options.uploader = :avrupload
        end

        opts.on("-d", "--avrdude",
                "Configure the application Makefiles to use avrdude") do |a|
          options.uploader = :avrdude
        end

        opts.separator ""
        opts.separator "Common options:"

        opts.on_tail("-h", "--help", "Show this message") do
          puts opts
          exit
        end

        opts.on_tail("-v", "--version", "Print the Zeno version") do
          puts "Zeno #{Zeno::VERSION}"
          exit
        end
      end

      parser.parse!(args)
      options.app = true

      mandatory = [:app, :epath, :name, :target, :libdir]
      mandatory = {
        :app => 'Critical failure',
        :epath => '-r',
        :name => '-n',
        :target => '-t',
        :libdir => '-l'
      }

      begin
        Zeno.check_missing_args!(options, mandatory)
      rescue MissingArgumentException => e
        puts "#{e.msg}: #{e.missing_arguments.values.join(', ')}"
        puts parser
        exit
      end

      begin
        scaffolder = Zeno::Application.new(options.name, options.epath,
                                           options.libdir, options.target,
                                           options.uploader)
        scaffolder.create
        scaffolder.generate
      rescue ApplicationAlreadyExistsError => e
        puts "Error: #{e.message}"
        exit
      end
    end

    # Parse a target string (git reference).
    # @param target [String] Git reference to parse.
    # @return [String] A valid git ref.
    #
    # Targets such as 'stable', 'old-stable' and 'bleeding' are turned into
    # actual git refs using this method.
    def parse_target(target)
      ref = target
      odd_versions = ['stable', 'latest', 'old-stable', 'bleeding']

      if odd_versions.include? target
        uri = URI("http://zeno.bietje.net/#{target}.txt")
        ref = Net::HTTP.get(uri)
      end

      ref
    end

    # Get all available ETA/OS versions.
    # @return [String] A list of all published ETA/OS versions.
    def get_versions
      uri = URI("http://zeno.bietje.net/versions.txt")
      Net::HTTP.get(uri)
    end

    # Download a specific version of ETA/OS.
    # @param out [String] Output directory.
    # @param target [String] Version to download.
    def download(out, target)
      # The correct git refs for the target can be found using the Zeno
      # web service (zeno.bietje.net).
      first = true
      silly_name = nil
      ref = Zeno.parse_target(target)
      ref.strip!
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
      f_path_new = File.join(out, "etaos-#{ref}")
      FileUtils.mv f_path, f_path_new
    end

    # Check if any arguments are missing.
    # @param options [OpenStruct] Structure of the complete argument set.
    # @param mandatory Hash of mandatory arguments
    # @return nil
    def check_missing_args!(options, mandatory = {})
      return nil if mandatory.empty?

      missing = mandatory.select do |param, value|
        options[param].nil? or options[param] == false
      end

      raise Zeno::MissingArgumentException.new(missing) unless missing.empty?
      nil
    end
  end # class
end # module Zeno
