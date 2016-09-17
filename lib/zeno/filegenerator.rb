#
#   Zeno module
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

module Zeno
  class FileGenerator
    attr_reader :path, :vars

    @path = nil
    @vars = nil

    def initialize(path)
      @path = path
      @vars = Hash.new
    end

    def add_var(name, value, assign = '=')
      @vars[name] = value
    end

    def del_var(name)
      @vars.delete name
    end

    def generate
      File.open(path, 'w') do |file|
        file.puts self.to_s
      end

      nil
    end

    def to_s
      output = ""
      @vars.each do |key, value|
        output += "#{key}=#{value}\n"
      end

      output
    end
  end
end

