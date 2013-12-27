#!/usr/bin/env ruby

require 'singleton'
require 'yaml'
require 'pp'

module Kook
	class Project
		attr_reader :name, :path
		attr_accessor :description
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

	class Command
	end

	class Config
		include Singleton

		def create_project project_name
			raise "ExistingProject" if @projects.has_key? project_name

			@projects[project_name] = Project.new project_name
		end

		def create_view project_name, view_name
			Project.validate_name project_name
			View.validate_name view_name
			raise "MissingProject" if not @projects.has_key? project_name

			view = View.new view_name
			@projects[project_name].add_view view
		end

		def to_yaml
			return {
				global: {},
				projects: @projects.values.map{ |p| p.to_hash }
			}.to_yaml
		end

		private

		def initialize
			@projects = {}
			super
		end
	end

end

class Test
	def self.test_project_create
		config = Kook::Config.instance
		config.create_project 'proj' 
	end

	def self.test_view_create
		config = Kook::Config.instance
		config.create_view 'proj', 'proj-root' 
		config.create_view 'proj', 'proj-base' 
		config.create_view 'proj', 'proj-3' 

		puts config.to_yaml
	end
end

Test.test_project_create
Test.test_view_create
