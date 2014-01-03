require 'thor'

module Kook
	module CLI
		module KookHelper
			def before_filter options
				@app = App.new
				@app.load options[:config]
				@app.verbose = options[:verbose]
				@app.current_project = options[:project]
			end

			# Inject our extensions in thor instances
			def self.included(base)
				base.class_eval do
					#if ancestors.include? Thor::Group
					#	namespace self.name.split('::').last.downcase.to_sym
					#end

					class_option :verbose, 
						type: :boolean, 
						default: false,
						aliases: '-v', 
						desc: 'Whether to output informative debug'

					class_option :config, 
						type: :string, 
						default: nil,
						aliases: '-c', 
						desc: 'Configuration file'

					class_option :project, 
						type: :string, 
						default: nil,
						aliases: '-p', 
						desc: 'Target project'

					class_option :directory, 
						type: :string, 
						default: nil,
						aliases: '-d', 
						desc: 'Target directory'
				end
			end
		end

		class Project < Thor
			include KookHelper

			desc "detect", "Detect current project"
			def detect
				before_filter options
				current_project = @app.current_project
				project_name = current_project.nil? ? "-none-" : current_project
				say "Current project is #{project_name}."
			end

			desc "list", "List projects"
			def list
				before_filter options
				@app.list_projects
			end

			desc "add PROJECT [-d DIRECTORY]", "Register new project"
			def add project_name
				before_filter options
				project_path = options[:directory]

				if project_path.nil? then
					project_path = Dir.pwd
				end
				project_path = File.expand_path project_path
				@app.add_project project_name, project_path

				say "Project #{project_name} registered on #{project_path}."
			end

			desc "rm PROJECT", "Unregister existing project"
			def rm project
				before_filter options
				@app.remove_project project
				say "Project #{project} unregistered."
			end

			desc "edit [-p PROJECT]", "Open editor on project file"
			def edit
				before_filter options
				project_name ||= @app.current_project

				@app.edit_project project_name
			end
			# TODO: editcopy project to another name + base path
			# TODO: copy project to another name + base path
		end

		class View < Thor
			include KookHelper

			desc "list [-p PROJECT]", "List view for a project"
			def list
				before_filter options
				project_name = @app.current_project

				@app.list_views project_name
			end

			desc "add VIEW [-p PROJECT] [-d DIRECTORY]", "Register new view"
			def add view_name
				before_filter options
				project_name = @app.current_project

				view_path = options[:directory]
				if view_path.nil? then
					view_path = Dir.pwd
				end

				@app.add_view project_name, view_name, view_path

			end

			desc "rm VIEW [-p PROJECT]", "Unregister existing view on project"
			def rm view_name
				before_filter options
				project_name = @app.current_project

				@app.remove_view project_name, view_name, view_path
			end
		end

		# FIXME: add helper validating project name
		# FIXME: add helper validating vie name for project
		class Command < Thor
			include KookHelper

			desc "add VIEW COMMAND [-p PROJECT]", "Add command for view"
			def add view_name, command
				before_filter options
				project_name = @app.current_project

				@app.add_command project_name, view_name, command
			end

			desc "rm VIEW INDEX [-p PROJECT]", "Remove command for view"
			def rm view_name, command_index
				before_filter options
				project_name = @app.current_project

				@app.remove_command project_name, view_name, command_index.to_i
			end
		end

		class Main < Thor
			include KookHelper

			desc "project SUBCOMMAND [options]", "Commands for managing projects"
			subcommand "project", CLI::Project

			desc "view SUBCOMMAND [options]", "Commands for managing view"
			subcommand "view", CLI::View

			desc "command SUBCOMMAND [options]", "Commands for managing commands"
			subcommand "command", CLI::Command

			desc "start [-p PROJECT]", "Run project environment"
			def start
				before_filter options
				project_name = @app.current_project

				@app.fire_project project_name
			end

		end	
	end
end
