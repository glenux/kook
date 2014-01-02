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

			option :path
			desc "add PROJECT", "Register new project"
			def add project_name, project_path=nil
				before_filter options
				project_path = options[:path]

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

			desc "edit PROJECT", "Open editor on project file"
			def edit project
				if config['projects'].has_key? project then
					project_config_path = File.join CONFIG_DIR, "Kookfile"
					system "%s %s" % [ENV['EDITOR'], project_config_path]
				else
					raise "Project #{project} not found"
				end
			end
			# TODO: editcopy project to another name + base path
			# TODO: copy project to another name + base path
		end

		class View < Thor
			include KookHelper

			desc "list", "List view for a project"
			def list project_name=nil
				before_filter options
				project_name ||= @app.current_project

				@app.list_views project_name
			end

			desc "add VIEW", "Register new view"
			option :path
			def add view_name
				before_filter options
				project_name ||= @app.current_project

				view_path = options[:path]
				if view_path.nil? then
					view_path = Dir.pwd
				end

				@app.add_view project_name, view_name, view_path

			end

			desc "rm PROJECT VIEW", "Unregister existing view on project"
			def rm project, view
				# FIXME: validate project existance
				# FIXME: validate view existance
				config['views'][project].delete view
				config.save_main
			end
		end

		# FIXME: add helper validating project name
		# FIXME: add helper validating vie name for project
		class Command < Thor
			desc "add PROJECT VIEW COMMAND", "Add command for view "
			def add project, view, command
				unless config['commands'].has_key? project then
					config['commands'][project] = {}
				end
				if config['commands'][project].nil? then
					config['commands'][project] = {}
				end
				unless config['commands'][project].has_key? view then
					config['commands'][project][view] = []
				end
				config['commands'][project][view] << command
				config.save_main
			end

			desc "rm PROJECT VIEW", "Remove command for view"
			def rm project, view, index
				raise NotImplementedError
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

			desc "fire [PROJECT]", "Run project environment"
			def fire project_name=nil
				before_filter options
				@app.fire_project project_name
			end

		end	
	end
end
