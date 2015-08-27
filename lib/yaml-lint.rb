#!/usr/bin/env ruby

require 'yaml'

module Logging
  ESCAPES = { :green  => "\033[32m",
              :yellow => "\033[33m",
              :red    => "\033[31m",
              :reset  => "\033[0m" }

  def info(message)
    emit(:message => message, :color => :green) unless @config[:quiet]
  end

  def warn(message)
    emit(:message => message, :color => :yellow) unless @config[:veryquiet]
  end

  def error(message)
    emit(:message => message, :color => :red) unless @config[:veryquiet]
  end

  def emit(opts={})
    color   = opts[:color]
    message = opts[:message]
    print ESCAPES[color]
    print message
    print ESCAPES[:reset]
    print "\n"
  end
end

class YamlLint
  include Logging

  def initialize(file, config={})
    # binding.pry
    @file = file
    @config = config
    @config[:quiet] = true if @config[:veryquiet]
    @config[:nocheckfileext] ||= false
  end

  def do_lint
    unless File.exists? @file
      error "File #{@file} does not exist"
      return 0
    else
      if File.directory? @file
        return self.parse_directory @file
      else
        return self.parse_file @file
      end
    end
  end

  def parse_directory(directory)

    unless Dir.entries(directory).include?(".learn")
      error "missing .learn file"
      return 0
    else
      @file = "#{directory}/.learn"
      self.parse_file @file 
    end
  end

  def parse_file(file)
    begin
      YAML.load_file(file)
    rescue Exception => err
      error "File : #{file}, error: #{err}"
      return 1
    else
      # binding.pry
      if validate_whitespace_for_learn(file)
        # binding.pry
        info "File : #{file}, Syntax OK"
        return 0
      else 
        error "Invalid whitespace. Every line with a '-' needs to start with two whitespaces"
        return 1
      end
    end
  end

  def validate_whitespace_for_learn(file)
    f = File.read(file)
    lines = f.split("\n")
    attributes = lines.select { |line| line.include?("-") }
    valid = true
    attributes.each do |attribute| 
      valid = false unless attribute[0..3] == "  - "
    end
    valid 
  end 

end
