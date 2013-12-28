
require 'kook/exceptions'

module Kook
	class Project
		attr_reader :name, :path
		attr_accessor :description

		class MissingProjectFile < RuntimeError ; end
		class InvalidProjectName < RuntimeError ; end
		PROJECT_NAME_MIN_SIZE = 4
		PROJECT_NAME_MAX_SIZE = 12

		def initialize project_name
			self.class.validate_name project_name
			@name = project_name
			@description = nil
			@path = nil
			@views = {}
		end

		def path= path
			# FIXME: validate current path exists
			#
			if not (File.exist? path and File.directory? path) then
				raise "PathDoesNotExist #{path}"
			end
			@path = path
		end

		def add_view view
			raise "ExistingView #{view.name}" if @views.has_key? view.name
			@views[view.name] = view
		end

		def remove_view view_name
			View.validate_name view_name
			return @view.delete(view_name)
		end

		def to_hash
			return { 
				project: @name,
				description: @description,
				path: @path,
				views: @views.values.map{ |v| v.to_hash }
			}
		end

		def from_hash project_hash
			@name = project_hash[:project]
			@description = project_hash[:description]
			@path = project_hash[:path]
			project_hash[:views].each do |hash_view|
				view = View.new do |v|
					v.from_hash hash_view
				end
				add_view view
			end
		end

		def self.validate_name name
			raise "TooShortProjectIdentifier" if name.size < Project::PROJECT_NAME_MIN_SIZE
			raise "TooLongProjectIdentifier" if name.size > Project::PROJECT_NAME_MAX_SIZE
			if not name =~ /^\w+$/ then
				raise "BadProjectIdentifier #{name}" 
			end
			return true
		end
	end
end
