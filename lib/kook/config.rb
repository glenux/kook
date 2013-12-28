module Kook
	class Config
		include Singleton

		CONFIG_DIR = File.join ENV['HOME'], '.config', 'kook'
		CONFIG_FILE = File.join CONFIG_DIR, 'config.yml'

		class ExistingProject < RuntimeError ; end
		class MissingProject < RuntimeError ; end

		def add_project project_name, project_path=nil
			raise ExistingProject if @projects.has_key? project_name

			project_data = Project.new project_name
			project_data.path = project_path
			@projects[project_name] = project_data
			save
		end

		def each_project
			@projects.each do |p,data|
				yield p,data
			end
		end

		def add_view project_name, view_name
			Project.validate_name project_name
			View.validate_name view_name
			raise MissingProject if not @projects.has_key? project_name

			view = View.new view_name
			@projects[project_name].add_view view
			save
		end

		def load
			yaml = YAML::load_file CONFIG_FILE

			yaml['projects'].each do |project_name,project_path|
				pp project_path
				#project_path = @config['projects'][project]
				project_file = kook_file_for project_path

				if File.exist? project_file then
					subconfig = YAML::load_file project_file
					next if not subconfig
					@config['views'][project] = subconfig['views']
					@config['commands'][project] = subconfig['commands']
				end
			end
		end

		def save
			if not File.exist? CONFIG_DIR then
				FileUtils.mkdir_p CONFIG_DIR
			end
				
			@projects.each do |project_name,project_data|
				# FIXME: test if project configuration is dirty
				#pp project_data
				project_file = File.join project_data.path, "Kookfile"
					
				File.open(project_file, "w") do |file|
					file.write project_data.to_hash.to_yaml
				end
			end

			File.open(CONFIG_FILE, "w") do |file|
				file.write to_yaml
			end
			self
		end

		def current_project
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
				'projects' => @projects.values.map{ |p| { p.name => p.path } }
			}.to_yaml
		end

		def initialize
			super
			@projects = {}
			self.load
		end
	end
end
