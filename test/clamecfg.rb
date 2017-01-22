# encoding: ISO-8859-15
# vim: set ft=ruby sts=2 sw=2 ai et:
# $Id$
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


#
# Configuration file for Clame
#

module Clame


  TEST_PATH_BASE = File.dirname File.dirname(__FILE__)

  CUSTOM_CONF_SETTINGS = ConfSettings[
    :log_file => "#{TEST_PATH_BASE}/runtime/clame.log",
    :log_severity => Logger::DEBUG,
    # database options
    :database_path => "#{TEST_PATH_BASE}/runtime/clame.db",
    :max_retries_db => 10,
    :sleep_time_db_lock => 1,
    # directorio donde se encuentra el esquema de la base de datos
    :deploy_schema_dir => "#{TEST_PATH_BASE}/datamodel/schema",
    # directorio donde se realizan los backups de los archivos sobreescritos en
    # la instalación de los parches, de modo que luego sea posible desinstalarlo
    :backup_dir_install => "#{TEST_PATH_BASE}/runtime/save",
  ]

end
