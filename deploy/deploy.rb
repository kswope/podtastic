#!/usr/bin/env ruby


cwd = File.expand_path(File.dirname(__FILE__))

exec "ansible-playbook -vv #{cwd}/deploy.yml -u ubuntu -i lucerne,"

