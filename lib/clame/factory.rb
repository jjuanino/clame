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


require 'fileutils'

module Clame

  # Devuelve el _logger_ configurado
  #
  # :call-seq:
  #   Factory.logger  -> Logger
  #
  def Clame.logger
    Factory.logger
  end


  # Devuelve la base de datos configurada
  #
  # :call-seq:
  #   Factory.database  -> Clame::Database
  #
  def Clame.database
    Factory.database
  end

  # Verbosity en la línea de comandos
  def Clame.quiet
    Factory.quiet
  end

  def Clame.quiet=(new)
    Factory.quiet = new
  end

  # Clase usada para configurar algunas clases que se usan a lo largo de todo
  # el código, como _logger_ o _database_
  class Factory

    # Por defecto, la salida por el terminal es mínima
    @@quiet = true

    private_class_method :new

    # Opciones de configuración
    def Factory.bootstrap_conf
      clamecfg = [
        ENV['CLAMECFG'],
        File.join(Etc.getpwuid(Process.euid).dir,'.clame', 'clamecfg.rb'),
        '/usr/local/etc/clamecfg.rb',
        '/etc/clamecfg.rb',
      ].detect{|c| c && File.readable?(c)}

      if clamecfg && (require clamecfg) && defined?(CUSTOM_CONF_SETTINGS)
        CUSTOM_CONF_SETTINGS.each_key do |key|
          CONF_SETTINGS[key] = CUSTOM_CONF_SETTINGS[key]
        end
      end

    end


    # Configuración y arranque del _logger_
    def Factory.bootstrap_logger
      @@logger = Logger.new(CONF_SETTINGS[:log_file])
      @@logger.progname = File.basename $0
      @@logger.sev_threshold = CONF_SETTINGS[:log_severity]
      @@logger.datetime_format = "%b %d %H:%M:%S"
    end


    # Configuración y arranque de la base de datos
    #
    # :call-seq:
    #   Factory.bootstrap_database  -> Clame::Database
    #
    def Factory.bootstrap_database
      @@database = Database.new(CONF_SETTINGS[:database_path])
    end


    # Devuelve el _logger_ configurado
    #
    # :call-seq:
    #   Factory.logger  -> Logger
    #
    def Factory.logger
      @@logger
    end

    # Devuelve la base de datos configurada
    #
    # :call-seq:
    #   Factory.database  -> Clame::Database
    #
    def Factory.database
      @@database
    end

    def Factory.quiet
      @@quiet
    end

    def Factory.quiet=(flag)
      @@quiet = flag
    end

  end # class Factory

end # module Clame
