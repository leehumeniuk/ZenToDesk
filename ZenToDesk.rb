#!/usr/bin/ruby -w

require 'rexml/document'
require 'net/http'
require 'json'

#variables
xmlfile = File.new(".xml")

MigratesCases = Struct.new(:file) do
  def parse_xml(doc)
    doc.elements.to_a('tickets/ticket').each_slice(500) do |batch|
      batch.each do |node|
        parse_node(node)
      end
      sleep(60) # 500 API req/s
    end
  end

  def parse_node(node)
    external_id = node.elements['nice-id'].text
    subject = node.elements['subject'].text
    created_at = node.elements['created-at'].text
    resolved_at = node.elements['solved-at'].text
    description = node.elements['description'].text

    #currentNode.elements.each("comments/comment/value") { |element| comments.push(element.text)}
    #comments.each {|e| finalComments << e}

    create_case(subject, created_at, resolved_at, description, external_id)
  end

  def create_case(subject, created_at, resolved_at, description, external_id)
    uri = URI('https://yoursite.desk.com/api/v2/cases') # POST URI
    req = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json') #set Post object (uri and content type header)
    req.basic_auth '', '' #set Post object (auth)

    # set Post object body && convert to json (contents of ticket)
    req.body = {
      type: 'email',
      external_id: external_id.to_s,
      subject: subject.to_s,
      priority: 4,
      status: 'open',
      labels: ['archive'],
      created_at: created_at.to_s,
      resolved_at: resolved_at.to_s,
      message: {
        direction: 'in',
        subject: subject.to_s,
        body: description.to_s,
        to: '',
        from: '',
        created_at: created_at.to_s
      }
    }.to_json

    #send the request
    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.request(req)
    end

    case res
    when Net::HTTPSuccess
      # sounds good...
    else
      puts "Failed migrating #{external_id}"
      puts res.body
    end
  end

  def xml_doc
    @xml_doc ||= REXML::Document.new(file)
  end
end

#main
migrator = MigratesCases.new(xmlfile)
migrator.migrate
