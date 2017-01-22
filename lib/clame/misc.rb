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
require 'sys/filesystem'


# Constantes y métodos de uso general por las distintas clases del módulo
module Clame

  # A menos que _perms_ sea nil o false, comprueba que la cadena _perms_ sea un
  # entero entre _0000_ y _7777_ (octales).  En caso contrario, se propaga la
  # excepción InvalidMaskPerm.
  def self.check_perms(perms)
    if perms
      unless perms =~ /\A[0-7]+\Z/ && (0o0000..0o7777).include?(perms.oct)
        raise InvalidMaskPerm.new(perms)
      end
    end
  end

  # Interpreta la cadena _perms_ como un número octal
  #
  # :call-seq:
  #   canonic_perms(perms) -> integer
  #
  def self.canonic_perms(perms)
    perms.oct unless perms.nil?
  end


  # Comprueba si un <i>iterator_name</i> devuelve algún elemento duplicado.
  # En caso afirmativo, se propaga la excepción _exception_
  #
  #--
  # Para detectar el duplicado, construiremos un hash donde la clave será cada
  # uno de los elementos del iterador, y detectaremos si alguno se repite
  #
  def self.check_dup_iterator(iterator_name, exception)
    iterator_name.inject({}) do |a,e|
      raise exception.new(e) if a.has_key?(e)
      a[e] = nil
      a
    end
  end

  # Ejecución de un script en un proceso con un entorno limpio, sin variables
  # de entorno a excepción de las indicadas en info e input.
  def self.exec_script(info, script_path, script_name, basedir,
                       input_responses, checkins_out_vars={})

    interpreter = info[Info::INTERPRETER] || DEFAULT_SHELL,
    flags = info[Info::INTERPRETER_FLAGS] || EMPTY_STRING
    patch_name = info['PATCH_NAME']
    version = info['VERSION']

    if script_name == Core::CHECKINSTALL
      env_checkinstall = Tempfile.new('env_checkinstall')
      # Escribir en la ruta temporal un sencillo script que permita
      # añadir a la base de datos N parejas variable-valor.
      # Dentro de un script de checkinstall, se puede invocar así:
      #
      # $1 VAR_NAME VAR_VALUE
      #
      # y automáticamente se añadiría la pareja (nombre, valor) a la base de
      # datos para una posterior recuperación.
      #
      #
      env_checkinstall.puts <<EOF
#!#{File.join(RbConfig::CONFIG['bindir'], RbConfig::CONFIG['ruby_install_name'])}
# Incluir en $: las rutas necesarias para que se encuentren las librerias de clame
$:.unshift(*#{$LOAD_PATH})
require 'clame'


Clame::CONF_SETTINGS[:database_path] = '#{CONF_SETTINGS[:database_path]}'
Clame::Factory.bootstrap_database

Clame.database.register_checkinstall_vars('#{patch_name}', '#{version}', *ARGV)
EOF

      env_checkinstall.close
      File.chmod(0700, env_checkinstall.path)
      Clame.logger.debug("Checkinstall register variables script:\n" +
                          IO.read(env_checkinstall.path))
    end

    fork do
      # Lo primero es construir un hash con las variables de entorno que se van
      # a exportar al script. Observar que no se distingue entre:
      # 1- una variable input booleana establecida a false
      # 2- Una variable no indicada ni en info ni en input
      # Las variables booleanas true aparecerán en el entorno con la cadena
      # "true" (aunque realmente esto es irrelevante, porque se sobreentiende
      # que de una variable booleana solo se chequea su existencia)
      # Las variables exportadas por el checkinstall se ponen al principio
      # porque tienen menor precedencia sobre el resto; con ello se impide
      # que desde un checkinstall se corrompan variables básicas como
      # PATCH_NAME o version
      env = {}
      [checkins_out_vars, info, input_responses].each do |hash|
        hash.each{|k,v| env[k] = v.to_s if v} if hash
      end

      # La variable PREFIX se establece a basedir
      env['PREFIX'] = basedir

      Clame.logger.info "Executing #{script_name} with pid #$$"
      Clame.logger.debug \
        "Environment: #{env.to_a.collect do |vr, vl|
          "#{vr}=#{vl}"
        end.join("\t")}"

      $stdin.reopen File::NULL
      exec(env, interpreter, *flags.split(/\s+/), script_path,
        *(env_checkinstall.path if env_checkinstall),
        {:unsetenv_others => true})
    end

    Process.wait

    if $?.exited?
      unless $?.exitstatus.zero?
        Clame.logger.error "#{script_name} error"
        raise ScriptInstallExecutionError.new(script_name, $?.exitstatus)
      end
    else
      Clame.logger.error("#{script_name} anormal exit: #{$?.inspect}")
      raise ScriptInstallAnormalExit.new(script_name, $?.inspect)
    end

  rescue SignalException
    Clame.logger.error("#{script_name} signal #{$!.signo} received" )
    raise ScriptInstallSignalReceived.new(script_name, $!.signo)
  ensure
    env_checkinstall.close! if env_checkinstall
  end


  def self.print(message)
    $stdout.print "#{message}" unless Clame.quiet
  end

  def self.puts_info(message)
    $stdout.puts "=> #{message}" unless Clame.quiet
  end


  def self.puts_check(msg_ini, msg_end='Success', &block)
    $stdout.print "* Check: #{msg_ini} ... " unless Clame.quiet
    # permitir que msg_end sea modificado dentro del bloque, si fuera
    # necesario. Con ello conseguimos que el mensaje impreso final pueda ser
    # personalizado
    block.call(msg_end)
    puts msg_end unless Clame.quiet
  end

  def self.puts_task(msg_ini, msg_end='Done', &block)
    $stdout.print "- Task: #{msg_ini} ... " unless Clame.quiet
    # permitir que msg_end sea modificado dentro del bloque, si fuera
    # necesario. Con ello conseguimos que el mensaje impreso final pueda ser
    # personalizado
    block.call(msg_end)
    $stdout.puts msg_end unless Clame.quiet
  end


  def self.ask_yes_no(force_exit=true)
    Clame.print 'Do you want to continue?(y/n) '
    resp = %w(y Y).include?($stdin.gets.chomp)
    exit (false) if !resp && force_exit
  end

end
