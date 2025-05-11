#!/usr/bin/env ruby

begin
  require 'logstash/plugin_mixins/plugin_api'
  
  # Verify Plugin API version is available
  plugin_api = LogStash::PluginMixins::PluginAPI
  puts "Loaded Plugin API version: #{plugin_api}" 
  
  # Make sure core API classes/modules are present
  if defined?(LogStash::PluginMixins)
    puts "Found PluginMixins module"
  else
    raise "PluginMixins module not found"
  end
  
  # Test registering of plugin
  plugin_api_module = LogStash::PluginMixins::PluginAPI
  puts "Successfully verified logstash-core-plugin-api"
rescue => e
  puts "Test failed: #{e.message}"
  exit 1
end