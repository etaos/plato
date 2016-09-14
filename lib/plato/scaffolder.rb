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

require 'fileutils'

require 'plato/makefile'
require 'plato/filegenerator'
require 'plato/applicationalreadyexistserror'

module Plato
  class Scaffolder
    attr_reader :dirname, :etaos_path, :app

    def initialize(options)
      @dirname = options.name
      @etaos_path = options.epath
      @app = options.app
      @libdir = options.libdir
      @arch = options.target
    end

    def create
      raise Plato::ApplicationAlreadyExistsError if File.directory? @dirname
      FileUtils.mkdir_p @dirname
    end

    def generate
      generate_mkfile
      generate_kbuildfile
    end

    private

    def generate_mkfile
      target_rule = "@$(MAKE) -C $(ETAOS) A=#{Dir.pwd}/#{@dirname} ARCH=#{@arch} CROSS_COMPILE=#{@arch}-"
      file = "#{@dirname}/Makefile"
      mkfile = Plato::Makefile.new file
      mkfile.add_var('ETAOS', @etaos_path)
      mkfile.add_target('all', target_rule + " app")
      mkfile.add_target('clean', target_rule + " clean")
      mkfile.generate
    end

    def generate_kbuildfile
      file = "#{@dirname}/Kbuild"
      gen = Plato::FileGenerator.new file
      gen.add_var('obj-y', '# TODO: add source files', '+=')
      gen.add_var('crurom-y', '# TODO: add crurom directory or delete this line', ':=')
      gen.add_var('crurom-obj', '# TODO: add crurom object file or delete this line', ':=')
      gen.add_var('ETAOS_LIBS', '-lc', '+=')
      gen.add_var('ETAOS_LIB_DIR', '', ':=')
      gen.add_var('APP_TARGET', "#{@dirname}.img", ':=')
      gen.add_var('clean-files', "#{@dirname}.img", '+=')
      gen.generate
    end
  end
end

