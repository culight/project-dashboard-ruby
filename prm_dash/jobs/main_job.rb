require 'uri'
require 'net/https'
require File.expand_path("models/http_client.rb", Dir.pwd)

def main
	$client_colormap = {}
	$projects = [
		{
			'client_name': '0273UNH',
			'proj_name': 'Data_Thru_201903_M7',
			'status': "Processing",
			'type': 'issue'
		},
		{
			'client_name': '0273WSP',
			'proj_name': 'Data_Thru_201903_M7_Datamart',
			'status': 'In Review',
			'type': 'issue'
		}
	]

	SCHEDULER.every '20s', :first_in => '2s' do
		$color = "%06x" % (rand * 0xffffff)
		puts $color
	
		$projects.each_with_index do |project, index|
			# get a unique color for each client
			if !$client_colormap.key?(project[:client_name])
				color = "%06x" % (rand * 0xffffff)
				$client_colormap[project[:client_name]] =  color
			end
			send_event(
				"project_#{index}", 
				{
					'title': project[:client_name],
					'text': project[:proj_name],
					'moreinfo': project[:status],
					'type': project[:type]
				}
			)
		end
	end
end

def init
	config_file = File.read('.config.json')
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
	proj_board_url = "https://indy-github.milliman.com/api/v3/projects/33/columns"
	proj_board_url = "https://indy-github.milliman.com/api/v3/projects/114/columns"
	$projects = parseProjectData(proj_board_url)
end

def getProcoljectTasks
	task_board_url = "https://indy-github.milliman.com/api/v3/projects/31/columns"
	$tasks = parseProjectData(task_board_url)
end

def parseProjectData(url)
	data = []
	
	uri = URI.parse(url)
	request = Net::HTTP::Get.new(uri.request_uri)
	request['Accept'] = "application/vnd.github.inertia-preview+json"
	response = $github_client.send_request(request,"Github")
	puts response
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
