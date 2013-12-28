require 'thor'

module Kook
	module CLI
		module KookHelper

			def fail_for exception, params=nil
				STDERR.puts "ERROR(#{exception.class}) :  #{exception}"
				STDERR.puts exception.backtrace
				exit 1
			end
		end


		class OldConfig
			include Singleton
			include KookHelper

			DEFAULT_CONFIG = {
				'global' => {}, # (ConfigKey_str => ConfigVal_str ) list
				'projects' => {}, # Project_str list 
				'views' => {}, # (Project_str => View_str) list 
				'commands' => {} # (Project_str => View_str) => Command list
			}

			def initialize
				# load file
				@config = DEFAULT_CONFIG
				load_main
				@config
			end



			def [] key
				@config[key]
			end
		end

		class Project < Thor
			include KookHelper

			desc "detect", "Detect current project"
			def detect
				project_name = current_project.nil? ? "-none-" : current_project
				say "Current project is #{project_name}."
			end

			desc "list", "List projects"
			def list
				config.each_project do |project_name,project|
					pp project_name
					exist = File.exist? project.path
					display_path = (
						path.clone
						.gsub!(/#{ENV['HOME']}/,'~')
						.send(exist ? :green : :red)
					)
					puts "%- 24s %s" % [project_name, display_path]
				end
			end

			# FIXME: option for alternative path
			desc "add PROJECT [PATH]", "Register new project"
			def add project_name, project_path=nil

				if project_path.nil? then
					project_path = Dir.pwd
				end
				project_path = File.expand_path project_path
				config.add_project project_name, project_path

				say "Project #{project_name} registered on #{project_path}."
			rescue Exception => e
				fail_for e, project: project_name, path: project_path
			end

			desc "rm PROJECT", "Unregister existing project"
			def rm project
				config['projects'].delete project
				config.save_main
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
			#
			private

			def config 
				Config.instance
			end
		end

		class View < Thor
			include KookHelper

			desc "list [PROJECT]", "List view for a project"
			def list project=nil
				project ||= current_project
				validate_project_exists project

				if config['views'].has_key? project then
					return if config['views'][project].nil?
					config['views'][project].each do |view,path|
						puts "%- 24s %s" % [view, path]

						next if config['commands'][project].nil? or \
							config['commands'][project][view].nil?

						config['commands'][project][view].each_index do |idx|
							puts "  % 4d.  %s" % [
								idx, 
								config['commands'][project][view][idx]
							]
						end
					end
				end
			end

			desc "add PROJECT VIEW", "Register new view"
			def add project, view, path=nil
				if path.nil? then
					path = Dir.pwd
				end
				project_rootdir = config['projects'][project]
				# simplify if current dir is a subdir of project base
				if path == project_rootdir then
					path = '.'
				else
					path.gsub!(/^#{project_rootdir}\//,'')
				end

				if not config['views'].has_key? project then
					config['views'][project] = {}
				elsif config['views'][project].nil? then
					config['views'][project] = {}
				end
				#binding.pry
				config['views'][project][view] = path
				config.save_main
			end

			desc "rm PROJECT VIEW", "Unregister existing view on project"
			def rm project, view
				# FIXME: validate project existance
				# FIXME: validate view existance
				config['views'][project].delete view
				config.save_main
			end

			private

			def config 
				Config.instance
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

			private

			def config 
				Config.instance
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

			desc "fire PROJECT", "Run project environment"
			def fire project
				validate_project_name project
				validate_project_exists project 
				pp config

				raise "No view defined for #{project}" if not config['views'].has_key? project
				config['views'][project].each do |view,view_path|
					project_path = config['projects'][project]
					target = ENV['KONSOLE_DBUS_SERVICE'] || 'org.kde.konsole'
					session=`qdbus #{target} /Konsole newSession`.strip

					system "qdbus org.kde.konsole /Sessions/#{session} sendText \"cd #{project_path}\n\""
					system "qdbus org.kde.konsole /Sessions/#{session} sendText \"cd #{view_path}\n\""
					system "qdbus org.kde.konsole /Sessions/#{session} sendText \"clear\n\""
					system "qdbus org.kde.konsole /Sessions/#{session} setTitle 1 \"#{view}\""
					next unless config['commands'][project].has_key? view
					config['commands'][project][view].each do |command|
						system "qdbus org.kde.konsole /Sessions/#{session} sendText \"#{command}\""
						system "qdbus org.kde.konsole /Sessions/#{session} sendText \"\n\""
					end
				end
			end


			private

			def config 
				Config.instance
			end
		end	
	end
end
