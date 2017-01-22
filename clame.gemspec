# encoding: ISO-8859-15
# vim: set ft=ruby sts=2 sw=2 ai et:
#
#
# Copyright (c) 2016 José García Juanino <jjuanino@gmail.com>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
# 3. The name of the author may not be used to endorse or promote products
#    derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO
# EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'rake'
require 'clame/version'

Gem::Specification.new do |s|
  s.name        = 'clame'
  s.version     = Clame::VERSION
  s.summary     = "Patch manager"
  s.description = <<-EOF
    Clame is a patch manager. It is a tool designed and oriented to manage patches,
    not packages. A patch has a name and a version, and you can
    install/uninstall versions of the same patch. It is intended to provide the
    complete live cycle of a software development for a third party (customer).
EOF
  s.authors     = ["Jose Garcia Juanino"]
  s.email       = 'jjuanino@gmail.com'
  s.files       = FileList[
      'lib/clame/*.rb',
      'lib/clame.rb',
      'datamodel/schema/**/*',
    ].to_a
  s.executables << 'clame'
  s.required_ruby_version = '>= 2.0'
  s.homepage    = 'http://rubygems.org/gems/clame'
  s.license     = 'BSD'
  s.add_runtime_dependency 'mkfifo', '>= 0.1'
  s.add_runtime_dependency 'sqlite3', '>= 1.3'
  s.add_runtime_dependency 'sys-filesystem', '>= 1.1'
  s.add_runtime_dependency 'ruby-termios', '>= 0.9'
  s.add_runtime_dependency 'rubyzip', '>= 1.1'
end
