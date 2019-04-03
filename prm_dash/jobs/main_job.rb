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
	
	# github connection try/catch block
	begin
    	response = http.request(request)
	rescue
		puts "Failed to connect to Github"
		writeGithubErrorLog("Failed to connect to Github")
		return {}
	end
	
	# github authentiation fail/success block
	if(response.code.to_i < 400)
		writeGithubDataLog(response.body)
		return JSON.parse(response.body)
	else
		puts "Github request failed with error #{response.code} : #{response.msg}"
		writeGithubErrorLog(
		  "Github request failed with error #{response.code} : #{response.msg}"
		)
		return {}
	end
end

# write to github Log file
def writeGithubDataLog(message)
	time = Time.now.inspect
	File.open('githubDataLog.txt', 'w') do |f2|
		f2.puts "LogDate #{time} : #{message}"
	end
end

# write to github Log file
def writeGithubErrorLog(message)
	time = Time.now.inspect
	File.open('githubErrorLog.txt', 'w') do |f2|
		f2.puts "LogDate #{time} : #{message}"
	end
end

main
