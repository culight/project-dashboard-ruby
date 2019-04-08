require 'uri'
require 'net/https'
require '../models/http_client.rb'

# main dashboard that pulls data from github and jenkins every 5 mins
def main
	init
	# send new dashboard data every 5 minutes, start in 10s (some cushion room to read in config file)
	puts "printing string"
end

def init
	config_file = File.read('../.config.json')
	config = JSON.parse(config_file)
	
	initGithub(config)
	#initJenkins(config)
	
	getProjects
end

# init github connection
def initGithub(config)
	$client_uri = 'https://indy-github.milliman.com/api/v3'
	username = config['github_uname']
	password = config['github_passwd']
	
	$github_client = HTTP_CLIENT.new($client_uri, username, password)
	$github_client.connect('Github')
end

def getProjects
	uri = URI.parse("https://indy-github.milliman.com/api/v3/orgs/PRM/projects")
	request = Net::HTTP::Get.new(uri.request_uri)
	request['Accept'] = "application/vnd.github.inertia-preview+json"
	response = $github_client.send_request(request,"Github")
	puts response
end

main
