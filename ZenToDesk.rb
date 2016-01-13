#!/usr/bin/ruby -w

require 'rexml/document'
require 'net/http'
require 'json'

#variables
xmlfile = File.new(".xml")
xmldoc = REXML::Document.new(xmlfile)
root = xmldoc.root
count = 1
totals = []

#methods
#create case object and send to Desk
def CreateCase(subject, createdAt, resolvedAt, description, count, externalId)
  uri = URI('https://yoursite.desk.com/api/v2/cases') # POST URI
  req = Net::HTTP::Post.new(uri.path, {'Content-Type' => 'application/json'}) #set Post object (uri and content type header)
  req.basic_auth '', '' #set Post object (auth)

  #set Post object body && convert to json (contents of ticket)
  req.body = {type: "email", external_id: "#{externalId}", subject: "#{subject}", priority: 4, status: "open", labels: ["archive"], created_at: "#{createdAt}", resolved_at: "#{resolvedAt}",message: {
    direction: "in", subject: "#{subject}",body: "#{description}", to: "", from: "", created_at: "#{createdAt}"}}.to_json

  #send the request
  res = Net::HTTP.start(uri.hostname, uri.port,
    :use_ssl => uri.scheme == 'https') do |http|
      http.request(req)
    end
  if res.is_a?(Net::HTTPSuccess)
    puts "Case Created!"
    f = File.open("successLog.txt","a")
    f.write("#{res.body}\n")
    f.close
    return true
  else
    puts "Oops! Case not created."
    #error logging
    f = File.open("errorLog.txt","a")
    f.write("#{res.body}")
    f.close
    return false
  end
end

#parse xml file and send request to Desk
def ParseXML(root)

totalsParsed = [0,0]
currentNode = root.children[1]

  while root

    #storing data in variables
    externalId = currentNode.elements["nice-id"].text
    subject = currentNode.elements["subject"].text
    createdAt = currentNode.elements["created-at"].text
    resolvedAt = currentNode.elements["solved-at"].text
    description = currentNode.elements["description"].text
    #currentNode.elements.each("comments/comment/value") { |element| comments.push(element.text)}
    #comments.each {|e| finalComments << e}

    #account for 500 API requests per minute
    if count == 500
      #pause 60 seconds then create case
      sleep(60)
      if CreateCase(subject, createdAt, resolvedAt, description, count, externalId) #HTTP Request
        totalsParsed[0] = totalsParsed[0] + 1 #success
      else
        totalsParsed[1] = totalsParsed[1] + 1 #failed
      end
      count = 1 #reset request count
    else
      if CreateCase(subject, createdAt, resolvedAt, description, count, externalId) #HTTP Request
        totalsParsed[0] = totalsParsed[0] + 1 #success
      else
        totalsParsed[1] = totalsParsed[1] + 1 #failed
      end
      count=count+1 #increment request count
    end

    #have to move two siblings over for some reason - count is correct
    if currentNode.next_sibling.nil?
      break
    else
      currentNode = currentNode.next_sibling
    end
    if currentNode.next_sibling.nil?
      break
    else
      currentNode = currentNode.next_sibling
    end

  end
  return totalsParsed
end

#main
totals = ParseXML(root)
puts "Tickets created: #{totals[0]}"
puts "Failed imports: #{totals[1]}"
