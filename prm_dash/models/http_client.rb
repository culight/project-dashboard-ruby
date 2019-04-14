require 'net/https'
require 'uri'
require 'json'

class HTTP_CLIENT
	def initialize(client_uri, username, password)
		uri = URI.parse(client_uri)
		http = Net::HTTP.new(uri.host, uri.port)
		http.use_ssl = true	

		@uri = uri
		@username = username
		@password = password
		@http = http
	end
	
	# general request with error handling
	def send_request(request, clientName)
		# connection try/catch block
		begin
			puts request
			request.set_form_data({"format" => "json"})
			response = @http.request(request)
		rescue
			message = "Failed to connect to #{clientName}"
			puts message
			writeErrorLog(message, clientName)
			return {}
		end
		
		# authentication fail/success block
		if(response.code.to_i < 400)
			writeDataLog(response.body, clientName)
			return JSON.parse(response.body)
		else
			puts "#{clientName} request failed with error #{response.code} : #{response.msg}"
			writeErrorLog(
			  "#{clientName} request failed with error #{response.code} : #{response.msg}",
			  clientName
			)
			return {}
		end
	end
	
	# initial connection to client server
	def connect(clientName)
		request = Net::HTTP::Get.new(@uri.request_uri)
		request.basic_auth(
			@username, @password
		)
		
		response = send_request(request, clientName)
		
		return response
	end
	
	private
	
	# write to general log file
	def writeDataLog(message, clientName)
		time = Time.now.inspect
		File.open("logs/#{clientName}DataLog.txt", 'w') do |f2|
			f2.puts "LogDate #{time} : #{message}"
		end
	end

	# write to error log file
	def writeErrorLog(message, clientName)
		time = Time.now.inspect
		File.open("logs/#{clientName}ErrorLog.txt", 'w') do |f2|
			f2.puts "LogDate #{time} : #{message}"
		end
	end

end
	
	
