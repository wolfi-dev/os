#!/usr/bin/env ruby

begin
  require 'logstash/core'
  require 'logstash/util'
  require 'logstash/version'
  
  # Verify version is available and matches expected format
  version = LogStash::VERSION
  puts "Loaded LogStash version: #{version}"
  raise "Invalid version format" unless version.match?(/\d+\.\d+\.\d+.*/) 
  
  # Verify key modules and classes
  raise "LogStash::Event missing" unless defined?(LogStash::Event)
  raise "LogStash::Util missing" unless defined?(LogStash::Util)
  
  # Create a basic LogStash event to test core functionality
  event = LogStash::Event.new("message" => "test")
  raise "Event creation failed" unless event.get("message") == "test"
  
  puts "LogStash::Event properties are functional"
  puts "Successfully tested logstash-core functionality"
rescue => e
  puts "Test failed: #{e.message}"
  puts e.backtrace.join("\n") if e.backtrace
  exit 1
end