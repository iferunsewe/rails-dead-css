#!/usr/bin/env ruby
require 'rubygems'
require 'ruby-debug'

# http://stackoverflow.com/questions/6224329/how-can-i-iterate-through-a-css-class-subclasses-in-ruby
REGEXES = {
 :id => /[#]\w+ \{/,
 :class => /[.]\w+ \{/
}
STYLESHEET_DIR = ENV['STYLESHEET_DIR'] || 'public/stylesheets'
HTML_DIR = ENV['HTML_DIR'] || 'app/{views,helpers,controllers}'

def include_path(path)
  path.split('/').drop(2).last(2).join('/').sub('.css', '')
end

def short_path(path)
  path.split('/').drop(2).join('/')
end

cssfiles = `find #{STYLESHEET_DIR} -name '*.css'`.split("\n")
cssfiles.each do |cssfile|
  cmd = "grep -r #{include_path(cssfile)} #{HTML_DIR} | grep stylesheet"
  res = `#{cmd}`
  if res.empty?
    puts "* Potentially orphaned stylesheet: #{short_path(cssfile)}"
    images = `grep background-image #{cssfile}`
    unless images.empty?
      images.scan(/url\(.*\)/).each do |image|
        puts "image: #{image.ljust(25)} #{short_path(cssfile)}"
      end
    end
  end

  contents = `grep -v ': ' #{cssfile}`
  tokens = {:id => [], :class => []}
  contents.split("\n").each do |line|
    REGEXES.each do |key, regex|
      token = line.scan(regex).to_s.scan(/\w/).join
      tokens[key] << token unless token.empty?
    end
  end
  REGEXES.each do |key, _|
    tokens[key].uniq!
    tokens[key].each do |val|
      uses = `grep -R #{val} #{HTML_DIR}`
      cols = [30, val.length+1].max
      puts [val.ljust(cols), short_path(cssfile)].join('') if uses.empty?
    end
  end
end
