#!/usr/bin/env ruby
require 'rubygems'
require 'ruby-debug'

# http://stackoverflow.com/questions/6224329/how-can-i-iterate-through-a-css-class-subclasses-in-ruby
REGEXES = {
 :id => /[#]\w+ \{/,
 :class => /[.]\w+ \{/
}
CSS_DIR = ENV['CSS_DIR'] || 'public/stylesheets'
puts "Using CSS_DIR=#{CSS_DIR}"
HTML_DIR = ENV['HTML_DIR'] || 'app/{views,helpers,controllers}'

def include_path(path)
  path.split('/').drop(2).last(2).join('/').sub('.css', '')
end

def short_path(path)
  path.split('/').drop(2).join('/')
end

cssfiles = `find #{CSS_DIR} -name '*.css'`.split("\n")
cssfiles.each do |cssfile|
  cmd = "grep -r #{include_path(cssfile)} #{HTML_DIR} | grep stylesheet"
  res = `#{cmd}`

  # if this is dead, can we make any educated guesses?
  if res.empty?
    linecount = `wc -l #{cssfile}`.split(' ').first.strip
    puts "* Potentially orphaned stylesheet: #{short_path(cssfile)} (#{linecount} LOC)"
    images = `grep background-image #{cssfile}`
    unless images.empty?
      images.scan(/url\(.*\)/).each do |image|
        puts "image: #{image.ljust(25)} #{short_path(cssfile)}"
      end
    end
  end

  # extract all classes and ids
  tokens = File.read(cssfile).split("\n").map do |line|
    # need to split on . BUT not swallow dot
    line.split(/[ :,{}]/).
      select {|t| t =~ /^[\.#]/}.
      delete_if {|t| t =~ /[};\)]/}.
      delete_if {|t| t =~ /^#[A-Fa-f0-9]{6}$/}.
      map {|t| t[1..-1]}
  end.flatten.uniq
  tokens.each do |token|
    uses = `grep -R '#{token}' #{HTML_DIR}`
    cols = [30, token.length+1].max
    puts [token.ljust(cols), short_path(cssfile)].join('') if uses.empty?
  end

  #TODO line separator if file yielded reults
  #TODO tokens should be a single list, not a hash
end
