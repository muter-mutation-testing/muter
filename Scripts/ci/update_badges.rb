#!/usr/bin/env ruby

require "net/http"
require "uri"
require "json"

gistKey = ARGV[1]
gistId = ARGV[2]
gistName = ARGV[3]
gistContent = ARGV[4]

header = {
	"Content-Type": "application/json; charset=utf-8",
	"Authorization": "token #{gistKey}"
}

payload = {
    files: {
        "muter-coverage-badge.json": {
            "content": "#{gistContent}"
        }
    }
}

uri = URI.parse("https://api.github.com/gists/#{gistId}")

http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true

request = Net::HTTP::Post.new(uri.request_uri, header)
request.body = payload.to_json
response = http.request(request)

if (response.code == '200') then
	exit(true)
else
	abort("Got #{response.code}")
end
