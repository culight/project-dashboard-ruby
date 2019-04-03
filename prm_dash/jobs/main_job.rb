require 'json'
require 'uri'
require 'net/https'

# main dashboard that pulls data from github and jenkins every 5 mins
def main
	init
	# send new dashboard data every 5 minutes, start in 10s (some cushion room to read in config file)
	puts "printing string"
end

def init
	initGithub
end

# init github connection
def initGithub
	uri = URI.parse('https://indy-github.milliman.com/api/v3')
	http = Net::HTTP.new(uri.host, uri.port)
	http.use_ssl = true
	
	config_file = File.read('../.config.json')
	config = JSON.parse(config_file)

	request = Net::HTTP::Get.new(uri.request_uri)
	request.basic_auth(config['github_uname'], config['github_passwd'])
	
	response = http.request(request)
end

main
