#!/usr/bin/env ruby

require "net/http"
require "uri"
require "json"

gistKey = ARGV[0]
gistId = ARGV[1]
gistName = ARGV[2]
gistContent = ARGV[3]

header = {
    "Content-Type": "application/json; charset=utf-8",
    "Authorization": "token #{gistKey}"
}

payload = {
    "files": {
        "#{gistName}": {
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
