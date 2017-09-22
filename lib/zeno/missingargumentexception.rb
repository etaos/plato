#
#   MissingArgumentException class
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
	class MissingArgumentException < StandardError
		attr_reader :msg, :missing_arguments

		@msg = nil
		@missing_arguments = nil

		def initialize(missing, msg = nil)
			@msg = msg || "Mandatory arguments are missing!"
			@missing_arguments = missing
		end

		def message
			@msg
		end
	end # class MissingArgumentException
end # module Zeno
