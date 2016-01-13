#!/usr/bin/ruby -w

require 'rexml/document'
require 'net/http'
require 'json'
include REXML

#variables
xmlfile = File.new("Tickets/Tickets0.xml")
xmldoc = Document.new(xmlfile)
root = xmldoc.root
externalId = 0
subject = ""
createdAt = ""
resolvedAt = ""
description = ""
comments = []
finalComments = ""
count = 1
success = 0
failed = 0

#methods
#create case object and send to Desk
def CreateCase(success, failed, subject, createdAt, resolvedAt, description, count, externalId, finalComments)
  uri = URI('https://yoursite.desk.com/api/v2/cases') # POST URI
  req = Net::HTTP::Post.new(uri.path, {'Content-Type' => 'application/json'}) #set Post object (uri and content type header)
  req.basic_auth 'email', 'password' #set Post object (auth)

  #set Post object body && convert to json (contents of ticket)
  req.body = {type: "email", external_id: "#{externalId}", subject: "#{subject}", priority: 4, status: "open", labels: ["archive"], created_at: "#{createdAt}", resolved_at: "#{resolvedAt}",message: {
    direction: "in", subject: "#{subject}",body: "#{description}", to: "", from: "", created_at: "#{createdAt}"},replies: {direction: "in", body:"#{finalComments}"}}.to_json

  #send the request
  res = Net::HTTP.start(uri.hostname, uri.port,
    :use_ssl => uri.scheme == 'https') do |http|
      http.request(req)
    end
  if res.is_a?(Net::HTTPSuccess)
    puts "Case Created!"
    success = success+1
  else
    "Oops! Case not created."
    failed = failed+1
  end
  return
end

#parse xml file and send request to Desk
def ParseXML(root, subject, createdAt, resolvedAt, description, comments, count, externalId, success, failed, finalComments)

currentNode = root.children[1]

  while root

    #storing data in variables
    externalId = currentNode.elements["nice-id"].text
    subject = currentNode.elements["subject"].text
    createdAt = currentNode.elements["created-at"].text
    resolvedAt = currentNode.elements["solved-at"].text
    description = currentNode.elements["description"].text
    currentNode.elements.each("comments/comment/value") { |element| comments.push(element.text)}
    comments.each {|e| finalComments << e}

    #account for 500 API requests per minute
    if count == 500
      #pause 60 seconds then create case
      sleep(60)
      CreateCase(success, failed, subject, createdAt, resolvedAt, description, count, externalId, finalComments) #HTTP Request
      count = 1
    else
    CreateCase(success, failed, subject, createdAt, resolvedAt, description, count, externalId, finalComments) #HTTP Request
    count=count+1
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
  return
end

ParseXML(root, subject, createdAt, resolvedAt, description, comments, count, externalId, success, failed, finalComments)
puts "Tickets created: #{success}"
puts "Failed imports: #{failed}"
