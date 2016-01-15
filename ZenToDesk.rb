#!/usr/bin/ruby -w

#require
require 'rexml/document'
require 'net/http'
require 'json'

#methods

#create case object and send to Desk
def create_case(subject, created_at, resolved_at, description, count, external_id, s, e)
  uri = URI('https://yoursite.desk.com/api/v2/cases') # POST URI
  req = Net::HTTP::Post.new(uri.path, {'Content-Type' => 'application/json'}) #set Post object (uri and content type header)
  req.basic_auth '<email>', '<password>' #set Post object (auth)

  #set Post object body && convert to json (contents of ticket)
  req.body =
  {
    type: "email",
    external_id: "#{external_id}",
    subject: "#{subject}",
    priority: 4,
    status: "open",
    labels: ["archive"],
    created_at: "#{created_at}",
    resolved_at: "#{resolved_at}",
    message: {
      direction: "in",
      subject: "#{subject}",
      body: "#{description}",
      to: "<email>",
      from: "<email>",
      created_at: "#{created_at}"
    }
  }.to_json

  #send the request
  res = Net::HTTP.start(uri.hostname, uri.port,
    :use_ssl => uri.scheme == 'https') do |http|
      http.request(req)
    end
  if res.is_a?(Net::HTTPSuccess)
    puts "Case Created!"
    #success logging
    s.write("#{res.body}\n")
    return true
  else
    puts "Oops! Case not created."
    #error logging
    e.write("#{res.body}")
    return false
  end
end

#parse xml file and send request to Desk
def parse_xml()
  include REXML

  xmlfile = File.new("Tickets.xml")
  xmldoc = Document.new(xmlfile)
  root = xmldoc.root
  external_id = 0
  subject = ""
  created_at = ""
  resolved_at = ""
  description = ""
  count = 0
  totals_parsed = [0,0]
  current_node = root.children[1]

  s = File.open("successLog.txt","a")
  e = File.open("errorLog.txt","a")

  while root

    #storing data in variables
    external_id = current_node.elements["nice-id"].text
    subject = current_node.elements["subject"].text
    created_at = current_node.elements["created-at"].text
    resolved_at = current_node.elements["solved-at"].text
    description = current_node.elements["description"].text

    #account for 500 API requests per minute
    if count == 500
      #pause 60 seconds then reset count
      sleep(60)
      count = 0
    end

    if create_case(subject, created_at, resolved_at, description, count, external_id, s, e) #HTTP Request
      totals_parsed[0] += 1 #success
      count += 1 #increment request count
    else
      totals_parsed[1] += 1 #failed
      count += 1 #increment request count
    end

    #have to move two siblings over for some reason - count is correct
    if current_node.next_sibling.nil?
      break
    else
      current_node = current_node.next_sibling
    end
    if current_node.next_sibling.nil?
      break
    else
      current_node = current_node.next_sibling
    end

  end
  s.close
  e.close
  return totals_parsed
end

#main

totals = parse_xml()

puts "Tickets created: #{totals[0]}"
puts "Failed imports: #{totals[1]}"
