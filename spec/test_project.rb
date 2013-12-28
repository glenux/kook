#!/usr/bin/env ruby

require 'singleton'
require 'yaml'
require 'pp'

module Kook
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
