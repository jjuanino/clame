# -*- coding: ISO-8859-15 -*-
#--
# vim: set sts=2 sw=2 ai et:
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


require 'digest'
require 'etc'

module Clame

  # Condiciones generales de salida
  SUCESS = 0
  FAILURE = 1

  # Expresión regular para encontrar asignaciones de variables. Por ejemplo:
  #
  # <tt>FOO_BAR = "foo_bar value"</tt>
  RE_VAR_LINE = /\A([[:upper:]_\d]+)\s*=\s*"([^"]+)"\s*\Z/
  # Expresión regular para determinar las líneas que se ignoran al analizar
  # sintácticamente un fuente.
  IGNORED_LINES = /(^\s*#|^\s+$)/
  # Expresión regular para indicar un nombre en general: no espacios, y solo
  # letras o números.
  RE_NAME = '\w+'
  # Expresión regular para indicar una versión de un parche. Ejemplos:
  # * 1.0
  # * 1.2.BETA-1
  # * 2.24.7
  # * 34
  #
  RE_VERSION = '\d+(\.\w+)*'
  # Versión cero de un parche. Es la versión mínima con la que se puede generar
  # un parche, y en caso de que no se indique versión, por defecto se establece
  # a 0.
  ZERO_VERSION = '0'
  # Cadena vacía.
  EMPTY_STRING = ''
  # expresión regular para detectar un sha256 digest
  REGEX_SHA256 = "[0-9a-f]{#{Digest::SHA256.new.digest_length * 2}}"
  # Tamaño del bloque natural en sistemas unix. Solo se utiliza para
  # determinar el tamaño real de un archivo, ya que el atributo File.stat.blocks
  # indica el número de bloques de tamaño 512b. Ojo que no tiene nada que ver
  # con el blksize, ver man 2 stat
  BLOCK_SIZE = 512

  # shell por defecto
  DEFAULT_SHELL = '/bin/sh'

  # Estados de un parche. Mantener en sincronización con la
  # tabla patch_status
  ST_RUN_PREINSTALL = 'RUN_PREINSTALL'
  ST_ERROR_PREINSTALL = 'ERROR_PREINSTALL'
  ST_RUN_BACKUP = 'RUN_BACKUP'
  ST_ERROR_BACKUP = 'ERROR_BACKUP'
  ST_RUN_SCHEMA = 'RUN_SCHEMA'
  ST_ERROR_SCHEMA = 'ERROR_SCHEMA'
  ST_RUN_POSTINSTALL = 'RUN_POSTINSTALL'
  ST_ERROR_POSTINSTALL = 'ERROR_POSTINSTALL'
  ST_REGISTER_INSTALLED_FILES = 'REGISTER_INSTALLED_FILES'
  ST_ERROR_REGISTER_INSTALLED_FILES = 'ERROR_REGISTER_INSTALLED_FILES'
  ST_REGISTER_INSTALL_SCRIPTS = 'REGISTER_INSTALL_SCRIPTS'
  ST_ERROR_REGISTER_INSTALL_SCRIPTS = 'ERROR_REGISTER_INSTALL_SCRIPTS'
  ST_REGISTER_REQUISITES = 'REGISTER_REQUISITES'
  ST_ERROR_REGISTER_REQUISITES = 'ERROR_REGISTER_REQUISITES'
  ST_REGISTER_CONFLICTS = 'REGISTER_CONFLICTS'
  ST_ERROR_REGISTER_CONFLICTS = 'ERROR_REGISTER_CONFLICTS'
  ST_REGISTER_INPUT_VARS = 'REGISTER_INPUT_VARS'
  ST_ERROR_REGISTER_INPUT_VARS = 'ERROR_REGISTER_INPUT_VARS'
  ST_INSTALLED = 'INSTALLED'
  ST_RUN_PREREMOVE = 'RUN_PREREMOVE'
  ST_ERROR_PREREMOVE = 'ERROR_PREREMOVE'
  ST_RUN_POSTREMOVE = 'RUN_POSTREMOVE'
  ST_ERROR_POSTREMOVE = 'ERROR_POSTREMOVE'
  ST_RUN_RESTORE = 'RUN_RESTORE'
  ST_ERROR_RESTORE = 'ERROR_RESTORE'
  ST_REGISTER_INFO_VARS = 'REGISTER_INFO_VARS'
  ST_ERROR_REGISTER_INFO_VARS = 'ERROR_REGISTER_INFO_VARS'

  # las opciones de configuración por defecto
  CONF_SETTINGS = ConfSettings[
    :log_file           => File.join(Etc.getpwuid(Process.euid).dir,
                                     '.clame', 'clame.log'),
    :log_severity       => Logger::INFO,
    :database_path      => File.join(Etc.getpwuid(Process.euid).dir,
                                     '.clame', 'clame.db'),
    :max_retries_db     => 10,
    :sleep_time_db_lock => 1,
    :deploy_schema_dir  =>
      Gem.path.collect do |path|
          File.join(
            path, 'gems', "clame-#{Clame::VERSION}", 'datamodel', 'schema'
          )
      end.detect{|p| Dir.exist?(p)},
    :backup_dir_install => File.join(Etc.getpwuid(Process.euid).dir,
                                     '.clame', 'save'),
    :baseclame => '../../..',
  ]

end # module Clame
