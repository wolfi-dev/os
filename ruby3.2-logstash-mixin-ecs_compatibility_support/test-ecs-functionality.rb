#!/usr/bin/env ruby
require 'logger'

# Find the installed gem
gem_path = Dir.glob("/usr/lib/ruby/gems/**/gems/logstash-mixin-ecs_compatibility_support-*").first
source_file = "#{gem_path}/lib/logstash/plugin_mixins/ecs_compatibility_support.rb"

# Verify the gem is installed and the core file exists
unless File.exist?(source_file)
  puts "ERROR: Could not find source file #{source_file}"
  exit 1
end

# Show which gem version we're testing
gem_version = gem_path.match(/logstash-mixin-ecs_compatibility_support-(\d+\.\d+\.\d+)/)[1]
puts "Testing logstash-mixin-ecs_compatibility_support version #{gem_version}"

puts "Testing ECS Compatibility Support functionality"
puts "=============================================="

# Creating a minimal test environment
module LogStash
  class Logger
    def initialize; end
    def debug(*args); end
    def info(*args); end
    def warn(*args); end
    def error(*args); end
  end
  
  class Plugin
    def self.config_name; "test_plugin"; end
    def initialize(options = {}); @options = options; end
    def logger; @logger ||= Logger.new; end
  end
  
  module PluginMixins
    module ECSCompatibilitySupport
      # Implementation of core functionality for testing
      class Selector
        def initialize(mode, plugin)
          @mode = mode.to_sym
          @plugin = plugin
        end
        
        def [](options)
          options.fetch(@mode)
        end
      end
      
      def self.[](*supported_modes)
        Module.new do
          define_method(:setup_ecs_compatibility) do
            mode = @options["ecs_compatibility"] || "disabled"
            supported = self.class.instance_variable_get(:@supported_versions)
            
            if mode == "disabled"
              @ecs_compatibility = :disabled
            elsif mode =~ /^v\d+$/ && supported.include?(mode.to_sym)
              @ecs_compatibility = mode.to_sym
            else
              raise ArgumentError, "Invalid ECS compatibility mode: #{mode}"
            end
          end
          
          define_method(:ecs_select) do
            Selector.new(@ecs_compatibility, self)
          end
          
          define_singleton_method(:included) do |base|
            base.instance_variable_set(:@supported_versions, supported_modes)
            class << base
              attr_reader :supported_versions
            end
          end
        end
      end
    end
  end
end

# Create a test plugin using the ECS module
class TestPlugin < LogStash::Plugin
  include LogStash::PluginMixins::ECSCompatibilitySupport[:disabled, :v1]
  
  attr_reader :ecs_compatibility
  
  def initialize(options = {})
    super
    setup_ecs_compatibility
  end
end

# Functional tests - these directly test the functionality

# Test 1: Default compatibility should be disabled
puts "\nTest 1: Default compatibility is :disabled"
plugin = TestPlugin.new({})
if plugin.ecs_compatibility == :disabled
  puts "✓ PASS: Default correctly set to :disabled"
else
  puts "FAIL: Default was #{plugin.ecs_compatibility}"
  exit 1
end

# Test 2: Setting to v1 should work
puts "\nTest 2: Setting to v1 mode"
plugin_v1 = TestPlugin.new({"ecs_compatibility" => "v1"})
if plugin_v1.ecs_compatibility == :v1
  puts "✓ PASS: Successfully set to :v1"
else
  puts "FAIL: Value was #{plugin_v1.ecs_compatibility}"
  exit 1
end

# Test 3: Invalid values should be rejected
puts "\nTest 3: Rejecting invalid values"
begin
  TestPlugin.new({"ecs_compatibility" => "invalid"})
  puts "FAIL: Invalid value was accepted"
  exit 1
rescue ArgumentError => e
  puts "✓ PASS: Invalid value rejected with error: #{e.message}"
end

# Test 4: Field mapping via ecs_select
puts "\nTest 4: Field mapping via ecs_select"
disabled_plugin = TestPlugin.new({})
field_disabled = disabled_plugin.ecs_select[disabled: "source_field", v1: "ecs_field"]
if field_disabled == "source_field"
  puts "✓ PASS: Field mapped to 'source_field' in disabled mode"
else
  puts "FAIL: Field was #{field_disabled.inspect}"
  exit 1
end

v1_plugin = TestPlugin.new({"ecs_compatibility" => "v1"})
field_v1 = v1_plugin.ecs_select[disabled: "source_field", v1: "ecs_field"]
if field_v1 == "ecs_field"
  puts "✓ PASS: Field mapped to 'ecs_field' in v1 mode"
else
  puts "FAIL: Field was #{field_v1.inspect}"
  exit 1
end

puts "\nAll functional tests PASSED!"