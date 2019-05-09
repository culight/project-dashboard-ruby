require 'uri'
require 'http'
require 'json'
require 'time'


def main
	init 
	buildProjectHash
	
	SCHEDULER.every '5m', :first_in => '3m' do		
		buildProjectHash
	end
end

def buildProjectHash
	$projects = getProjects
	projectTasks = getProjectTasks
	
	# retrieve active projects in production queue along with their associated tasks
	$projects.each_with_index do |project, index|
		project['tasks'] = []
		project['ci'] = []
		
		# get a unique color for this project
		project['color'] = "%06x" % (rand * 0xffffff)
			
		# get Github project tasks associated with this project
		taskList = []
		projectTasks.each_with_index do |task, index|
			if task
				if project[:repo_name] == task[:repo_name]
					taskList << task
				end
			end
			
		end
		project['tasks'] = taskList

		# retrieve Jenkins data
		job_name = 'PRM_Prod_ePHI_' + project[:client_name][0..6]
		jenkinsData = getJenkinsData(job_name)
		project['ci'] = [jenkinsData]
		
		# send details for active run to view
		send_event(
			"title_#{index}", 
			{
				'title': project[:client_name],
				'text': project[:proj_name],
				'moreinfo': project[:status],
				'projectRepo': project[:repo_name]
			}
		)

	end	
end

def buildProjectHashTest
	$projects = [
		{:client_name=>"0273WOH", :proj_name=>"Data_Thru_201903_M7", :status=>"Preparing Documentation", :type=>"issues", :repo_name=>"0273WOH_Medicaid", "tasks"=>[{:title=>"Investigate Providers Who Turn Smokers --> Non-Smokers", :status=>"Priority", :type=>"issues", :repo_name=>"0273WOH_Medicaid"}, {:title=>"[April 10] Investigate unique mems in Dental claims", :status=>"Holding Pattern/Processing", :type=>"issues", :repo_name=>"0273WOH_Medicaid"}, {:title=>"[May 15] Clean Up Raw Foster_Care.dat Data", :status=>"Holding Pattern/Processing", :type=>"issues", :repo_name=>"0273WOH_Medicaid"}, {:title=>"[May 1] Don't allow discharge dates to be prior to admit dates", :status=>"Holding Pattern/Processing", :type=>"issues", :repo_name=>"0273WOH_Medicaid"}]},
		{:client_name=>"0273WSP07", :proj_name=>"Data_Thru_201903_M7_Rerun", :status=>"Peer Review", :type=>"issues", :repo_name=>"0273WSP_Commercial", "tasks"=>[{:title=>"Grouper Update", :status=>"Priority", :type=>"issues", :repo_name=>"0273WSP_Commercial"}]},
		{:client_name=>"0273WOH", :proj_name=>"Data_Thru_201903_M7_dental", :status=>"Peer Review", :type=>"issues", :repo_name=>"0273WOH_Medicaid", "tasks"=>[{:title=>"Investigate Providers Who Turn Smokers --> Non-Smokers", :status=>"Priority", :type=>"issues", :repo_name=>"0273WOH_Medicaid"}, {:title=>"[April 10] Investigate unique mems in Dental claims", :status=>"Holding Pattern/Processing", :type=>"issues", :repo_name=>"0273WOH_Medicaid"}, {:title=>"[May 15] Clean Up Raw Foster_Care.dat Data", :status=>"Holding Pattern/Processing", :type=>"issues", :repo_name=>"0273WOH_Medicaid"}, {:title=>"[May 1] Don't allow discharge dates to be prior to admit dates", :status=>"Holding Pattern/Processing", :type=>"issues", :repo_name=>"0273WOH_Medicaid"}]},
		{:client_name=>"1111MCL", :proj_name=>"Data_Thru_201903_M7", :status=>"Final Delivery", :type=>"issues", :repo_name=>"1111MCL_MSSP", "tasks"=>[]}
	]
	
	projectTasks = [{:title=>"[May 1] Don't allow discharge dates to be prior to admit dates", :status=>"Holding Pattern/Processing", :type=>"issues", :repo_name=>"0273WOH_Medicaid"},
		{:title=>"[April 10] Investigate unique mems in Dental claims", :status=>"Holding Pattern/Processing", :type=>"issues", :repo_name=>"0273WOH_Medicaid"},
		{:title=>"[May 15] Clean Up Raw Foster_Care.dat Data", :status=>"Holding Pattern/Processing", :type=>"issues", :repo_name=>"0273WOH_Medicaid"},
		{:title=>"Grouper Update", :status=>"Priority", :type=>"issues", :repo_name=>"0273WSP_Commercial"},
		{:title=>"Investigate Providers Who Turn Smokers --> Non-Smokers", :status=>"Priority", :type=>"issues", :repo_name=>"0273WOH_Medicaid"}
	]
	
	# retrieve active projects in production queue along with their associated tasks
	$projects.each_with_index do |project, index|
		project['tasks'] = []
		project['ci'] = []
		
		# get a unique color for this project
		project['color'] = "%06x" % (rand * 0xffffff)
			
		# get Github project tasks associated with this project
		taskList = []
		projectTasks.each_with_index do |task, index|
			if task
				if project[:repo_name] == task[:repo_name]
					taskList << task
				end
			end
			
		end
		project['tasks'] = taskList

		# retrieve Jenkins data
		jenkinsData = {
		  'currentResult': 'SUCCESS',
		  'lastResult': 'SUCCESS',
		  'timestamp': '1555689735417',
		  'value': 14
		}
		project['ci'] = [jenkinsData]
			
		# send details for active run projects dash
		send_event(
			"title_#{index}", 
			{
				'title': project[:client_name],
				'text': project[:proj_name],
				'moreinfo': project[:status],
				'projectRepo': project[:repo_name]
			}
		)

	end	
end

def init
	config_file = File.read('.config.json')
	config = JSON.parse(config_file)

	$github_auth = {
		'client_uri': 'https://indy-github.milliman.com/api/v3',
		'username': config['github_uname'],
		'token': config['github_password'],
		'preview_param': 'application/vnd.github.inertia-preview+json'
	}
	
	$jenkins_auth = {
		'http': 'http://indy-jenkins.milliman.com',
		'username': config['jenkins_uname'],
		'password': config['jenkins_pat']
	}
end

def getProjects
	proj_board_url = "https://indy-github.milliman.com/api/v3/projects/33/columns"
	$projects = parseProjectData(proj_board_url, 'production')
end

def getJenkinsData(job_name)
	current_status = nil
	last_status = current_status
	build_info = get_json_for_job(job_name)
	current_status = build_info["result"]
	
	if build_info["building"]
		current_status = "BUILDING"
		percent = get_completion_percentage(job_name)
	end

	return {
	  currentResult: current_status,
	  lastResult: last_status,
	  timestamp: build_info["timestamp"],
	  value: percent
	}
end

def getProjectTasks
	task_board_url = "https://indy-github.milliman.com/api/v3/projects/31/columns"
	$tasks = parseProjectData(task_board_url, 'onboarding')
end

def parseProjectData(url, boardType)
	data = []

	response = HTTP.basic_auth(
		:user => $github_auth[:username] , :pass => $github_auth[:token]
	).headers(
		:accept=> $github_auth[:preview_param]
	).get(url)
	
	for column in JSON.parse(response)
		status = column['name']
		data.concat(getBoardItems(column, status, boardType))
	end
	
	return data
end

def getBoardItems(column, status, boardType)
	items = []
	
	cards = getCards(column)
	
	cards.each_with_index do |card, index|
		if !card['content_url']
			next
		end

		response = HTTP.basic_auth(
			:user => $github_auth[:username] , :pass => $github_auth[:token]
		).headers(
			:accept=> $github_auth[:preview_param]
		).get(card['content_url'])
		
		item = JSON.parse(response)

		if boardType == 'production'
			if item['title']
				title_segments = item['title'].split('-')
			else
				title_segments = ['xxxxx', 'Unknown Client']
			end
	
			type = item['url'].split('/')[-2]
			
			index_marker = '[Client-Specific GitHub Repository]'
			index_start = item['body'].rindex(index_marker) + index_marker.length
			github_repo_url = ''
			item['body'][index_start..item['body'].length].each_char { |c|
				if c == '('			
				elsif c == ')'
					break
				else
					github_repo_url.concat(c)
				end
			}

			github_repo_name = github_repo_url[-3..-1] == '...' ? nil : github_repo_url.split('/')[-1]
			
			if type == 'pull'
				items[index] = {
					'client_name': 'TBD',
					'proj_name': 'TBD',
					'status': status,
					'type': type,
					'repo_name': github_repo_name,
					'url': item['url']
				}
			elsif type == 'issues'
				items[index] = {
					'client_name': title_segments[0].strip,
					'proj_name': title_segments[1].strip,
					'status': status,
					'type': type,
					'repo_name': github_repo_name,
					'url': item['url']
				}
			else
				items[index] = {
					'client_name': nil,
					'proj_name': nil,
					'status': nil,
					'type': nil,
					'repo_name': github_repo_name,
					'url': item['url']
				}
				puts item
			end
		elsif boardType == 'onboarding'
			type = item['html_url'].split('/')[-2]
			repo_name = item['repository_url'].split('/')[-1]
			items[index] = {
				'title': item['title'],
				'status': status,
				'type': type,
				'repo_name': repo_name
			}
		end
	end
	
	return items
end

def getCards(column)
	response = HTTP.basic_auth(
		:user => $github_auth[:username] , :pass => $github_auth[:token]
	).headers(
		:accept=> $github_auth[:preview_param]
	).get(column['cards_url'])
	
	return JSON.parse(response)
end

def get_number_of_failing_tests(job_name)
  info = get_json_for_job(job_name, 'lastCompletedBuild')
  info['actions'][4]['failCount']
end

def get_completion_percentage(job_name)
  build_info = get_json_for_job(job_name)
  prev_build_info = get_json_for_job(job_name, 'lastCompletedBuild')

  return 0 if not build_info["building"]
  last_duration = (prev_build_info["duration"] / 1000).round(2)
  current_duration = (Time.now.to_f - build_info["timestamp"] / 1000).round(2)
  return 99 if current_duration >= last_duration
  ((current_duration * 100) / last_duration).round(0)
end

def get_json_for_job(job_name, build = 'lastBuild')
  response = HTTP.basic_auth(
	:user => $jenkins_auth[:username], :pass => $jenkins_auth[:password]
  ).get($jenkins_auth[:http] + "/job/#{job_name}/#{build}/api/json")
  
  jobDetails = JSON.parse(response)
  return jobDetails
end

main
