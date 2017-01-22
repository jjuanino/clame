#!/usr/bin/env ruby
# encoding: ISO-8859-15
# vim: set sts=2 sw=2 ai et:
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

# clean the environment
ENV.delete_if{|k,v| k != 'PATH'}

CURRENT_DIR = File.realpath(File.dirname(__FILE__))
LIB_CLAME_DIR = File.join(CURRENT_DIR,'..','lib')

$LOAD_PATH << LIB_CLAME_DIR << CURRENT_DIR

ENV['CLAMECFG'] = File.join(CURRENT_DIR, 'clamecfg.rb')

require 'clame'

$VERBOSE=2

#
# keep in alphabetic order
#

require 'tc_backuppatch'
require 'tc_buildcmdline'
require 'tc_conf_settings'
require 'tc_cmdline'
require 'tc_database'
require 'tc_extensions'
require 'tc_filetype'
require 'tc_info'
require 'tc_input'
require 'tc_installcmdline'
require 'tc_installedpatch'
require 'tc_interval'
require 'tc_links'
require 'tc_packagedpatch'
require 'tc_patchbuilder'
require 'tc_patchescontainer'
require 'tc_patchversion'
require 'tc_removecmdline'
require 'tc_schema'
