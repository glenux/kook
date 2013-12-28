
module Kook
	class View
		attr_reader :name, :path
		attr_accessor :description
		VIEW_NAME_MIN_SIZE = 4
		VIEW_NAME_MAX_SIZE = 12

		def initialize name
			self.class.validate_name name
			@name = name
			@path = nil
			@commands = {}
		end

		def self.validate_name name
			raise "TooShortViewIdentifier" if name.size < View::VIEW_NAME_MIN_SIZE
			raise "TooLongViewIdentifier" if name.size > View::VIEW_NAME_MAX_SIZE
			if not name =~ /^[\w-]+$/ then
				raise "BadViewIdentifier #{name}" 
			end
			return true
		end

		def to_hash
			return { 
				view: @name,
				path: @path,
				commands: @commands.values
			}
		end

		def from_hash view_hash
			@name = view_hash[:view]
			@path = view_hash[:path]
			@commands = view_hash[:commands]
		end
	end
end
