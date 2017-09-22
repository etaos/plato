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

module Zeno
  class Solution
    attr_reader :name, :path

    @name = nil
    @basepath = nil
    @path = nil
    @ref = nil
    @libs = nil
    @apps = nil
    @target = nil

    def initialize(opts)
      @name = opts['name']
      @basepath = opts['path']
      @ref = opts['ref']
      @libs = opts['libs']
      @path = "#{@basepath}/#{@name}"
      @apps = opts['apps']
      @target = opts['target']

      raise Zeno::ApplicationAlreadyExistsError if File.directory? @path
    end

    def create
      FileUtils.mkdir_p @path unless File.directory? @path
      Dir.chdir @path

      version = Zeno.parse_target(@ref)
      etaos_path = "etaos-#{version}"
      Zeno.download(Dir.pwd, @ref)

      # Create applications
      @apps.each do |app|
      	application = Zeno::Application.new(app, etaos_path, @libs, @target)
      	application.create
      	application.generate
      end
    end
  end
end
