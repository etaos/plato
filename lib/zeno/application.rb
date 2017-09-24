#
#   Zeno module
#   Copyright (C) 2017  Michel Megens <dev@bietje.net>
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

require 'zeno/makefile'

module Zeno
  class Application
    attr_reader :dirname, :etaos_path, :arch, :libdir, :uploader

    def initialize(name, path, libdir, arch, upload = nil)
      @dirname = name
      @etaos_path = "../#{path}"
      @libdir = "#{libdir}/etaos"
      @arch = arch
      @uploader = upload
    end

    def create
      raise Zeno::ApplicationAlreadyExistsError if File.directory? @dirname
      FileUtils.mkdir_p @dirname
    end

    def generate
      generate_mkfile
      generate_kbuildfile
    end

    private

    def generate_mkfile
      target_rule = "@$(MAKE) -C $(ETAOS) A=`pwd` ARCH=#{@arch} CROSS_COMPILE=#{@arch}-"
      file = "#{@dirname}/Makefile"
      mkfile = Zeno::Makefile.new file
      mkfile.add_var('ETAOS', @etaos_path)
      mkfile.add_var('MAKEFLAGS', '-rR --no-print-directory', '+=')
      mkfile.add_var('OBJCOPY', "#{@arch}-objcopy")
      mkfile.add_var('MCU', "# TODO: add MCU")
      mkfile.add_var('BAUD', "115200")
      mkfile.add_var('PROGRAMMER', "# TODO: set programmer")
      mkfile.add_var('PORT', "# TODO: set port")
      mkfile.add_var('AVRDUDE', "avrdude")
      mkfile.add_var('AVRUPLOAD', "avrupload")
      mkfile.add_target('all', target_rule + " app")
      mkfile.add_target('clean', target_rule + " clean")

      hex_rule = "@$(OBJCOPY) -R .eeprom -O ihex #{@dirname}.img #{@dirname}.hex"
      avrdude_rule = "@$(AVRDUDE) -D -q -V -p $(MCU) -c $(PROGRAMMER) -b $(BAUD) -P $(PORT) "
      avrdude_rule << "-C /etc/avrdude.conf -U flash:w:#{@dirname}.hex:i"

      avrupload_rule = "@$(AVRUPLOAD) -fH test-app.hex -m $(MCU) -p $(PROGRAMMER) -P $(PORT) "
      avrupload_rule << "-b $(BAUD) -c /etc/avrdude.conf"

      case @uploader
      when :avrdude
        mkfile.add_target('hex', hex_rule)
        mkfile.add_target('upload', avrdude_rule)
      when :avrupload
        mkfile.add_target('hex', hex_rule)
        mkfile.add_target('upload', avrupload_rule)
      end

      mkfile.generate
    end

    def generate_kbuildfile
      file = "#{@dirname}/Kbuild"
      gen = Zeno::FileGenerator.new file
      gen.add_var('obj-y', '# TODO: add source files', '+=')
      gen.add_var('pyusrlib-y', '# TODO: add python libs or delete this line', '+=')
      gen.add_var('crurom-y', '# TODO: add crurom directory or delete this line', ':=')
      gen.add_var('crurom-obj', '# TODO: add crurom object file or delete this line', ':=')
      gen.add_var('ETAOS_LIBS', '-lc', '+=')
      gen.add_var('ETAOS_LIB_DIR', @libdir, ':=')
      gen.add_var('APP_TARGET', "#{@dirname}.img", ':=')
      gen.add_var('clean-files', "#{@dirname}.img", '+=')
      gen.generate
    end
  end
end
