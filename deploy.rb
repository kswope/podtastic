#!/usr/bin/env ruby

require 'bundler'
Bundler.require
require 'pp'
require 'json'
require 'open3'



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Typical run command in shell.
# Ansible needs an extra error condition because if a task fails its printed
# to stdout with an error.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
def run_command(command, ansible=true)

  puts "running: #{command}".on_green

  stdin, stdout_io, stderr_io = Open3.popen3(command)

  stdout = stdout_io.read
  stderr = stderr_io.read

  if ansible && ( stdout.match(/failed=[1-9]+/) || 
                  stdout.match(/unreachable=[1-9]+/) ||
                  stdout.match(/ERROR/)) || !stderr.empty?

    unless stdout.empty?
      puts "\nSTDOUT from failed command:".on_yellow.blink
      puts "#{stdout}".on_yellow
    end
    puts "#{stderr}".red
    puts "*** exiting #{$PROGRAM_NAME}".red.blink
    exit 1
  end

  return stdout

end



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# check if we forgot to commit anything (push is checked with checkout in
# ansible script)
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
status = `git status --porcelain`
unless status.empty?
  puts "*** Refusing to run because git status returned ...".on_red
  print status
  exit 1
end



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# run playbook that remotely builds and pushes docker image
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
command = ''
command += "ansible-playbook build_n_push_docker_image.yml"
command += " -u ubuntu -i lucerne,"
run_command(command, ansible:true)









