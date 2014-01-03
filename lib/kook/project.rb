
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

			yield self if block_given?
			self
		end

		def path= path
			# FIXME: validate current path exists
			#
			if not (File.exist? path and File.directory? path) then
				raise "PathDoesNotExist #{path}"
			end
			@path = path
		end

		def fire
			target = ENV['KONSOLE_DBUS_SERVICE'] || 'org.kde.konsole'

			@views.each do |view,view_data|
				session=`qdbus #{target} /Konsole newSession`.strip
				system "qdbus org.kde.konsole /Sessions/#{session} sendText \"cd #{@path}\n\""
				system "qdbus org.kde.konsole /Sessions/#{session} sendText \"cd #{view_data.path}\n\""
				system "qdbus org.kde.konsole /Sessions/#{session} sendText \"clear\n\""
				system "qdbus org.kde.konsole /Sessions/#{session} setTitle 1 \"#{view}\""

				view_data.commands.each do |command|
					system "qdbus org.kde.konsole /Sessions/#{session} sendText \"#{command}\""
					system "qdbus org.kde.konsole /Sessions/#{session} sendText \"\n\""
				end
			end
		end

		def create_view view_name, view_path
			raise ExistingView, view_name if @views.has_key? view_name
			View.validate_name view_name

			@views[view_name] = View.new view_name, view_path
		end

		def add_view view_data
			raise ExistingView, view_data.name if @views.has_key? view_data.name

			@views[view_data.name] = view_data
		end

		def remove_view view_name
			raise MissingView, view_name if not @views.has_key? view_name
			return @view.delete(view_name)
		end

		def add_command view_name, command
			raise MissingView, view_name if not @views.has_key? view_name
			@views[view_name].commands << command
		end

		def remove_command view_name, command_idx
			raise MissingView, view_name if not @views.has_key? view_name
			@views[view_name].commands.delete_at(command_idx)
		end

		def each_view 
			#pp @views
			@views.each do |view_name, view_data|
				yield view_name, view_data
			end
		end

		def to_hash
			return { 
				'project' => @name,
				'description' => @description,
				#'path' => @path,
				'views' => @views.values.map{ |v| v.to_hash }
			}
		end

		def self.from_hash project_hash, project_path
			project = Project.new project_hash['project'] do |p|
				p.description = project_hash['description']
				p.path = project_path

				project_hash['views'].each do |view_hash|
					view_data = View.from_hash view_hash
					p.add_view view_data
				end
			end
		end

		def self.validate_name name
			raise "TooShortProjectIdentifier" if name.size < Project::PROJECT_NAME_MIN_SIZE
			raise "TooLongProjectIdentifier" if name.size > Project::PROJECT_NAME_MAX_SIZE
			if not name =~ /^\w(\S+)$/ then
				raise "BadProjectIdentifier #{name}" 
			end
			return true
		end
	end
end
