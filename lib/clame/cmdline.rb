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

require 'optparse'
require 'ostruct'

module Clame

  class CmdLine

    ACTIONS = %w(build install remove)

    def initialize(args)

      # Primer análisis de la línea de comandos
      parse_until_action(args)

      # Si pasamos por este punto, han indicado una acción
      @action = args.detect{|a| ACTIONS.include?(a)}

      # Análisis completo de la línea de comandos, comenzando desde la acción.
      # flags will be gone away after call parse_{action}!
      @args = args.drop_while{|a| a != @action}[1..-1]

      # options wil be set after call parse_{action}!
      @options = {}

      # Realizamos el parsing de las flags de la action
      self.method("parse_#{@action}!").call

    end

    # Ejecución del comando
    def execute
      class_action = Clame.const_get("#{@action.capitalize}CmdLine")
      class_action.new(@options, @args).run
    end


    ##################
    # Métodos privados
    ##################
    private


    def parse_install!

      # Valores por defecto
      @options[:prefix] = nil
      @options[:ignore_reqs] = false
      @options[:ignore_confs] = false
      @options[:ignore_paths] = []
      @options[:ignore_hvers] = false
      @options[:ignore_installed_conflicts] = false
      @options[:force] = false
      @options[:quiet] = false
      @options[:prompt] = true
      @options[:debug] = false

      options_parser = OptionParser.new do |opts|

        opts.summary_width = 37
        opts.banner = <<EOF

Usage: #{opts.program_name} install [-p PREFIX] [-s paths] \
[-hrcvgq] <zip_path> [patch_name [version]]
zip_path: Zip package file. Mandatory.
patch_name: Patch name. If empty, install the whole of contained patches \
in zip_path.
version: Patch version. If empty, install the whole of contained versions \
of patch_name.
EOF

        opts.separator ''
        opts.separator 'Allowed flags:'

        opts.on(
          '-p', '--prefix PREFIX',
            'Installation prefix (overwrites info PREFIX variable).'
        ) do |prefix|
          @options[:prefix] = prefix
        end

        opts.on(
          '-r', '--[no-]ignore-reqs', 'Ignore requisites set in depend file.'
        ) do |ignore_reqs|
          @options[:ignore_reqs] = ignore_reqs
        end

        opts.on(
          '-c', '--[no-]ignore-conflicts', 'Ignore conflicts set in depend file.'
        ) do |ignore_confs|
          @options[:ignore_confs] = ignore_confs
        end

        opts.on(
          '-v', '--[no-]ignore-higher-versions',
          'Ignore already installed higher versions.'
        ) do |ignore_hvers|
          @options[:ignore_hvers] = ignore_hvers
        end

        opts.on(
          '-g', '--[no-]ignore-inst-conflics',
          'Ignore already installed conflicts.'
        ) do |ignore_installed_conflicts|
          @options[:ignore_installed_conflicts] = ignore_installed_conflicts
        end

        opts.on(
          '-s', '--ignore-paths <P1>[,P2,...,PN]', Array,
          'Do not backup the specified files.'
        ) do |ignore_paths|
          @options[:ignore_paths] = ignore_paths
        end

        opts.on(
          '-f', '--[no-]force', 'Do not make any validation (not recommended)'
        ) do |force|
          @options[:force] = force
        end

        opts.on(
          '-q', '--[no-]quiet', 'Quiet.'
        ) do |q|
          @options[:quiet] = q
        end

        # Prompt
        opts.on(
          '--[no-]prompt', 'Do not ask for confirmation.'
        ) do |q|
          @options[:prompt] = q
          # Si se ha indicado la flag :quiet=true, no se puede forzar
          # :prompt=true
          if @options[:quiet] && @options[:prompt]
            raise ArgumentError.new(
              'Parser error: --quiet and --prompt' + ' are incompatible flags'
            )
          end
        end


        opts.on_tail(
          '-h', '--help', 'Show this message.'
        ) do |v|
          puts opts
          exit(SUCESS)
        end

      end # options_parser

      # A partir de este momento, @args ya no contiene flags, solo argumentos.
      options_parser.parse!(@args)

      # si se ha indicado quiet, entonces prompt se fuerza a false
      @options[:prompt] = false if @options[:quiet]

      # Tiene que haber al menos un argumento
      if @args.size < 1
        raise OptionParser::MissingArgument.new("zip_path")
      end

      # Como mucho puede haber 3 argumentos
      if @args.size > 3
        raise OptionParser::InvalidArgument.new(@args[3])
      end

    rescue ArgumentError
      $stderr.puts $!.to_s
      exit(status=FAILURE)
    rescue OptionParser::ParseError
      $stderr.puts $!.to_s
      $stderr.puts options_parser
      exit(status=FAILURE)

    end # def parse_install!


    def parse_build!

      # Valores por defecto
      @options[:variables] = {}
      @options[:force] = false
      @options[:quiet] = false
      @options[:ignore_miss_prefix] = false

      options_parser = OptionParser.new do |opts|

        opts.banner =<<EOF

Usage: #{opts.program_name} build [-v VARNAME=\"value\" ...] [-qfh] <dir ...> \
<zip_output>
dir: Directory where the patches build files are located. Mandatory.
zip_output: Output file. Mandatory.
EOF

        opts.separator ''
        opts.separator 'Allowed flags:'

        # Asignación de variables
        opts.on(
          '-v', '--variable VARNAME="value"',
          'Set this info variable VARNAME to value. VARNAME must be upper case.'
        ) do |infovar|
          unless infovar =~ /\A([[:upper:]_\d]+)=([^"]+)\Z/
            raise OptionParser::InvalidOption.new(infovar)
          end
          @options[:variables][$1] = $2
        end

        # Machacar el zip de salida si existe
        opts.on(
          '-f', '--[no-]force', 'Reuse output zip file if exists.'
        ) do |v|
          @options[:force] = v
        end

        # Flag para ignorar el siguiente error: no se ha indicado PREFIX y hay
        # rutas relativas en el schema
        # Atención: en este caso, aunque la forma corta no hubiera sido
        # especificada, se hubiera considerado, ya que OptionParser, para
        # construir la forma corta, tiene en cuenta la primera letra después
        # del corchete (]) de la forma larga. Por lo tanto, si más adelante
        # necesitamos otra flag del tipo --[no-]ignore-otra cosa, habría que
        # escribir el bloque después de éste y poner la format corta con otra
        # letra, por ejemplo '-t', '--[-no-]ignore-tonteria
        opts.on(
          '-i', '--[no-]ignore-miss-prefix', 'Ignore errors about relative ' +
          'paths but missing PREFIX.'
        ) do |q|
          @options[:ignore_miss_prefix] = q
        end

        # Silencioso
        opts.on(
          '-q', '--[no-]quiet', 'Quiet.'
        ) do |q|
          @options[:quiet] = q
        end

        opts.on_tail(
          '-h', '--help', 'Show this message.'
        ) do |v|
          puts opts
          exit(SUCESS)
        end

      end # options_parser

      # A partir de este momento, @args ya no contiene flags, solo argumentos.
      options_parser.parse!(@args)

      # Tiene que haber dos o más argumentos
      if @args.size < 2
        raise OptionParser::MissingArgument.new("<dir ...> <zip_output>")
      end

    rescue OptionParser::ParseError
      $stderr.puts $!.to_s
      $stderr.puts options_parser
      exit(FAILURE)

    end # parse_build!


    def parse_remove!

      # Valores por defecto
      @options[:ignore_reqs] = false
      @options[:ignore_hvers] = false
      @options[:abort_on_restore_error] = false
      @options[:ignore_unmatching_uid] = false

      options_parser = OptionParser.new do |opts|

        opts.summary_width = 37
        opts.banner =<<EOF

Usage: #{opts.program_name} remove [-rvau] <patch_name> <version>
patch_name: Patch name. Mandatory.
version: Patch version. Mandatory.
EOF

        opts.separator ''
        opts.separator 'Allowed flags:'

        opts.on(
          '-r', '--[no-]ignore-reqs',
          'Do not check if the uninstallation would break some dependency'
        ) do |ignore_reqs|
          @options[:ignore_reqs] = ignore_reqs
        end

        opts.on(
          '-v', '--[no-]ignore-higher-version',
          'Do not check if there are higher versions installed'
        ) do |ignore_higher_versions|
          @options[:ignore_hvers] = ignore_higher_versions
        end

        opts.on(
          '-a', '--[no-]abort-on-restore',
          'Do not abort if ocurrs some restoration error'
        ) do |abort_on_restore_error|
          @options[:abort_on_restore_error] = abort_on_restore_error
        end

        opts.on(
          '-u', '--[no-]ignore-unmatching-uids',
          'Ignore if the installation user is not the same as the ' +
          'uninstallation one'
        ) do |ignore_unmatching_uid|
          @options[:ignore_unmatching_uid] = ignore_unmatching_uid
        end

        opts.on_tail(
          '-h', '--help', 'Show this message.'
        ) do |v|
          puts opts
          exit(SUCESS)
        end

      end

      # A partir de este momento, @args ya no contiene flags, solo argumentos.
      options_parser.parse!(@args)

      # Tiene que haber exactamente dos argumentos
      if @args.size != 2
        raise OptionParser::MissingArgument.new("<patch_name> <patch_version>")
      end

    rescue OptionParser::ParseError
      $stderr.puts $!.to_s
      $stderr.puts options_parser
      exit(FAILURE)

    end # parse_remove!


    def parse_until_action(args)


      options_parser = OptionParser.new do |opts|

        opts.banner=<<EOF

Usage: #{opts.program_name} [-d] action [options] ...
       #{opts.program_name} [-hv]

action: #{ACTIONS.join(', ')}. \
Type '#{opts.program_name} action' to inspect actions sipnosis
EOF

        # Debug
        opts.on(
          '-d', '--[no-]debug', 'Enable debug messages in log file'
        ) do |q|
          # si indicamos --no-debug, se activa la severidad por defecto
          q ? Clame.logger.sev_threshold = Logger::DEBUG :
            Clame.logger.sev_threshold = Logger::INFO
        end


        # No argument, shows at tail
        opts.on_tail('-h', '--help', 'Show this message.') do
          puts opts
          exit(true)
        end

        opts.on_tail('-v', '--version', 'Show version.') do
          puts VERSION
          exit(true)
        end


      end

      # no envían ningún argumento. Salimos inmediatamente
      if args.empty?
        raise OptionParser::MissingArgument.new("action")
      end

      # Comprobamos si se indica acción
      action = args.detect{|a| ACTIONS.include?(a)}

      # Si indican acción: analizamos hasta ese punto.
      # Si no indican acción: analizamos el total de la línea de comandos
      options_parser.parse(
         action ? args.take_while{|a| a != action} : args
      )

      # si llegados a este punto, no se ha indicado acción, salimos
      # con error
      raise OptionParser::MissingArgument.new("action") unless action

    rescue OptionParser::ParseError
      $stderr.puts $!.to_s
      $stderr.puts options_parser
      exit(FAILURE)
    end # def parse_until_action


  end # class CmdLine

end
