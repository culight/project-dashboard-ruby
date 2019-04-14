require 'uri'
require 'net/https'
require File.expand_path("models/http_client.rb", Dir.pwd)


	

# main dashboard that pulls data from github and jenkins every 5 mins
def main
	$projects = [
		{
			'client_name': 'test_client_1',
			'proj_name': 'test project',
			'status': 'processing',
			'type': 'issue'
		},
		{
			'client_name': 'test_client_2',
			'proj_name': 'test project',
			'status': 'In Review',
			'type': 'issue'
		}
	]
	#init
	# send new dashboard data every 5 minutes, start in 10s (some cushion room to read in config file)
	SCHEDULER.every '1m', :first_in => '5s' do
		#getProjects	
		#getProjectTasks
		$projects.each_with_index do |project, index|
			send_event(
				"project_#{index}", 
				{
					'title': project[:client_name],
					'text': project[:proj_name],
					'moreinfo': project[:status]
				}
			)
		end
	end
end

def init
	config_file = File.read('../.config.json')
	config = JSON.parse(config_file)
	
	initGithub(config)
	initJenkins(config)
end

def initGithub(config)
	client_uri = 'https://indy-github.milliman.com/api/v3'
	username = config['github_uname']
	token = config['github_pat']
	
	$github_client = HTTP_CLIENT.new(client_uri, username, token)
	$github_client.connect('Github')
end

def initJenkins(config)
	client_uri = 'indy-jenkins.milliman.com'
	username = config['jenkins_uname']
	token = config['jenkins_pat']
	$jenkins_client = "https://#{username}:#{token}@#{client_uri}"
end

def getProjects
	proj_board_url = "https://indy-github.com/milliman.com/api/v3/projects/33/columns"
	$projects = parseProjectData(proj_board_url)
end

def getProjectTasks
	task_board_url = "https://indy-github.com/milliman.com/api/v3/projects/31/columns"
	$tasks = parseProjectData(task_board_url)
end

def parseProjectData(board_url)
	data = []
	
	uri = URI.parse(board_url)
	request = Net::HTTP::Get.new(uri.request_uri)
	request['Accept'] = "application/vnd.github.inertia-preview+json"
	response = $github_client.send_request(request,"Github")

	for i in 0..(response.size - 1)
		column = response[i]
		status = column['name']
		data.concat(getBoardItems(column, status))
	end
	
	return data
end

def getBoardItems(column, status)
	items = []
	cards = getCards(column)

	for i in 0..(cards.size - 1)
		uri = URI.parse(cards[i]['content_url'])
		request = Net::HTTP::Get.new(uri.request_uri)
		request['Accept'] = "application/vnd.github.inertia-preview+json"
		response = $github_client.send_request(request,"Github")
		
		if response['title'].size > 0
			title_segments = response['title'].split('-')[0]
		else
			title_segments = ['xxxxx', 'Unknown Client']
		end
		
		type = response['url'].split('/')[-2]
		if type == 'pulls'
			items[i] = {
				'client_name': 'TBD',
				'proj_name': 'TBD',
				'status': status,
				'type': type
			}
		elsif type == 'issues'
			items[i] = {
				'client_name': title_segments[0].strip,
				'proj_name': title_segments[1].strip,
				'status': status,
				'type': type
			}
		else
			puts 'something'
		end
			
		
	end
		
	return issues
end

def getCards(column)
	uri = URI.parse(column['cards_url'])
	request = Net::HTTP::Get.new(uri.request_uri)
	request['Accept'] = "application/vnd.github.inertia-preview+json"
	response = $github_client.send_request(request,"Github")
	
	return response
end


main
