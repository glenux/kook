module Kook
	class App
		CONFIG_DIR = File.join ENV['HOME'], '.config', 'kook'
		CONFIG_FILE = File.join CONFIG_DIR, 'config.yml'

		attr_accessor :verbose

		class ExistingProject < RuntimeError ; end
		class MissingProject < RuntimeError ; end

		def initialize
			super
			@projects = {}
			@config_file = CONFIG_FILE
			@verbose = false
			@current_project = nil
		end

		def list_projects
			projects_exist = false

			@projects.each do |project_name,project_data|
				projects_exist = true
				exist = File.exist? project_data.path
				display_path = (
					project_data.path.clone
					.gsub!(/#{ENV['HOME']}/,'~')
						.send(exist ? :green : :red)
				)
				puts "%- 24s %s" % [project_name, display_path]
			end
			STDERR.puts "No project found." if not projects_exist
		end

		def add_project project_name, project_path=nil
			raise ExistingProject if @projects.has_key? project_name

			project_data = Project.new project_name
			project_data.path = project_path
			@projects[project_name] = project_data
			save
		end

		def remove_project project_name
			raise MissingProject if not @projects.has_key? project_name
			@projects.delete project_name
			save
		end

		def fire_project project_name
			raise MissingProject if not @projects.has_key? project_name

			project_path = @projects[project_name].path
			@projects[project_name].each_view do |view,view_data|
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

		def add_view project_name, view_name, view_path=nil
			Project.validate_name project_name
			View.validate_name view_name

			raise MissingProject if not @projects.has_key? project_name

			project_path = @projects[project_name].path

			# simplify if current dir is a subdir of project base
			if view_path == project_path then
				view_path = '.'
			else
				view_path.gsub!(/^#{project_path}\//,'')
			end

			@projects[project_name].create_view view_name, view_path
			save
		end

		def list_views project_name
			raise MissingProject if not @projects.has_key? project_name
			
			# FIXME: return if config['views'][project].nil?
			
			@projects[project_name].each_view do |view_name,view_data|
				puts "%- 24s %s" % [view_name, view_data.path]

				#next if config['commands'][project].nil? or \
				#	config['commands'][project][view].nil?

				#config['commands'][project][view].each_index do |idx|
				#	puts "  % 4d.  %s" % [
				#		idx, 
				#		config['commands'][project][view][idx]
				#	]
				#end
			end
		end

		def load config_file=nil
			config_file ||= @config_file
			@config_file = config_file

			if not File.exist? config_file then
				STDERR.puts "Missing config file #{config_file}" if @verbose
				return false
			end


			STDERR.puts "Loading main configuration #{config_file}..." if @verbose
			yaml = YAML::load_file config_file

			yaml['projects'].each do |project_name,project_path|
				# pp project_path
				#project_path = @config['projects'][project]
				project_file = kook_file_for project_path

				STDERR.puts "Loading sub configuration #{project_file}..." if @verbose
				if File.exist? project_file then
					subconfig = YAML::load_file project_file
					next if not subconfig
					
					@projects[project_name] = Project.from_hash subconfig, project_path
				end
			end

			return true
		end

		def save config_file=nil
			config_file ||= @config_file
			config_dir = File.dirname config_file
			if not File.exist? config_dir then
				FileUtils.mkdir_p config_dir
			end
				
			STDERR.puts "Saving to #{config_file}" if @verbose

			@projects.each do |project_name,project_data|
				# FIXME: test if project configuration is dirty
				project_file = File.join project_data.path, "Kookfile"
					
				File.open(project_file, "w") do |file|
					file.write project_data.to_hash.to_yaml
				end
			end

			File.open(config_file, "w") do |file|
				file.write to_yaml
			end
			self
		end

		def current_project= project_name
			# FIXME: validate project name
			@current_project = project_name
		end

		def current_project
			return @current_project if not @current_project.nil?

			current_dir = Dir.pwd
			@projects.each do |project_name,project|
				if current_dir =~ /^#{project.path}/ then
					return project_name
				end
			end
			return nil
		end

		private

		def kook_file_for project_path
			kook_files = Dir.glob(File.join(project_path, 'Kookfile'))
			raise MissingProjectFile if kook_files.empty?
			kook_files.first
		end

		def to_yaml
			return {
				'global' => {},
				'projects' => Hash[@projects.map{ |p,v| [v.name, v.path] }]
			}.to_yaml
		end

	end
end
