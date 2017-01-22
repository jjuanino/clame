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

require 'set'

module Clame


  class Info


    # Variables que deben estar definidas obligatoriamente. En caso contrario,
    # se propaga una excepción.
    # Las variables obligatorias necesariamente tienen que ajustarse a un patrón
    # NOTA: DESCRIPTION no permite retornos de carro. Está pensada para contener
    # una descripción corta del parche
    MANDATORY_VARS = {
      :PATCH_NAME => {:name => 'PATCH_NAME', :regexp => /\A#{RE_NAME}\Z/},
      :DESCRIPTION => {:name => 'DESCRIPTION', :regexp => /\A.*\Z/},
    }

    PATCH_NAME = MANDATORY_VARS[:PATCH_NAME][:name]
    DESCRIPTION = MANDATORY_VARS[:DESCRIPTION][:name]

    # Variables especiales. Se trata de variables no obligatorias pero que
    # en caso de indicarse tienen un significado especial. Son las siguientes:
    #
    # * La versión del parche.
    #   Se trata de una cadena de la forma A.B.C, donde
    #   A es un entero. Por ejemplo, la versión 1.a es válida, pero a.1 no lo
    #   es. También lo son 9.1a, 0.1.c
    # * El intérprete con el que se lanzarán los scripts.
    #   Aquí se admite cualquier cosa.
    # * Flags del intérprete
    #   Se admite cualquier cosa.
    # * Superusuario
    #   Indica que el parche tiene que instalarse con permisos de superusuario
    # * PREFIX
    #   Las rutas del schema que no comiencen con una / se instalarán debajo de
    #   esta ruta. Este componente tiene que ser absoluto, por eso tiene que
    #   comenzar con File::SEPARATOR. Si esta variable no se indica y hay alguna
    #   ruta relativa en el schema, se abortará la construcción del parche
    # * REQUIRE_ACCEPT_LEGAL
    #   El usuario debe aceptar expresamente la cláusula legal (archivo legal)
    #   Solo admite el valor "YES"
    #
    SPECIAL_VARS = {
      :VERSION => {:name => 'VERSION', :regexp => /\A#{RE_VERSION}\Z/},
      :INTERPRETER => {:name => 'INTERPRETER', :regexp => /\A.+\Z/},
      :INTERPRETER_FLAGS => {:name => 'INTERPRETER_FLAGS', :regexp => /\A.+\Z/},
      :NEED_SUPERUSER => {:name => 'NEED_SUPERUSER', :regexp => /yes|no/i},
      :PREFIX => {:name => 'PREFIX', :regexp => /\A#{File::SEPARATOR}.*\Z/},
      :REQUIRE_ACCEPT_LEGAL => {:name => 'REQUIRE_ACCEPT_LEGAL',
        :regexp => /\AYES\Z/},
      :BASECLAME => {:name => 'BASECLAME', :regexp => /\A.+\Z/},
    }

    VERSION = SPECIAL_VARS[:VERSION][:name]
    INTERPRETER = SPECIAL_VARS[:INTERPRETER][:name]
    INTERPRETER_FLAGS = SPECIAL_VARS[:INTERPRETER_FLAGS][:name]
    NEED_SUPERUSER = SPECIAL_VARS[:NEED_SUPERUSER][:name]
    PREFIX = SPECIAL_VARS[:PREFIX][:name]
    REQUIRE_ACCEPT_LEGAL = SPECIAL_VARS[:REQUIRE_ACCEPT_LEGAL][:name]
    BASECLAME = SPECIAL_VARS[:BASECLAME][:name]


    include Enumerable

    def initialize(io_stream, initial_vars={})

      # Inicialmente, establecemos las variables del parche al valor que
      # indican en initial_vars. Lo que pretendemos con ello es que desde fuera
      # del fichero info se puedan indicar variables, y así la construcción del
      # parche sea más flexible, pudiendo indicar en tiempo de construcción del
      # parche por ejemplo el nombre y la versión.
      @variables = initial_vars.dup

      io_stream.each_line do |line|
        parse(line, io_stream.lineno) unless line =~ IGNORED_LINES
      end

      # por defecto la versión es 0. Es decir, si el parche no indica versión,
      # se sobreentiende que es 0.
      @variables[VERSION] = ZERO_VERSION unless patch_version

      # si la variable BASECLAME no está indicada, la establecemos al valor por
      # defecto
      @variables[BASECLAME] ||= CONF_SETTINGS[:baseclame]

      # comprobar variables obligatorias
      check_mandatory_vars

      # comprobar que las variables obligatorias siguen el formato especificado
      # para ellas
      check_mandatory_vars_format

      # comprobar que las variables especiales que se indiquen tienen el formato
      # especificado para ellas
      check_special_vars_format

    end


    # realiza una limpieza de las variables que son auxiliares y solo tienen sentido
    # en la fase de construcción del parche. Ahora mismo, solo tenemos una variable de este tipo:
    # BASECLAME. Es una variable que no se debe usar en ningún otro sitio salvo
    # para construir el parche.
    def cleanout_vars
      @variables.delete(BASECLAME)
    end


    def to_hash
      # Devolvemos un duplicado, para que no sea posible alterar el original.
      @variables.dup
    end

    def [](key)
      @variables[key]
    end

    def patch_name
      @variables[PATCH_NAME]
    end

    def patch_version
      @variables[VERSION]
    end

    def each(&block)
      @variables.each(&block)
    end

    def each_varname(&block)
      @variables.each_key(&block)
    end

    # Itera sobre los nombres de las variables obligatorias. Se trata de un
    # procedimiento de clase, ya que no hace falta tener ninguna instancia para
    # determinar las variables obligatorias.
    def self.each_mand_varname
      return to_enum(:each_mand_varname) unless block_given?
      MANDATORY_VARS.each_value{|v| yield v[:name]}
    end

    # itera sobre las variables especiales. Se trata de un procedimiento de
    # clase, ya que no hace falta tener ninguna instancia para determinar las
    # variables obligatorias.

    def self.each_spec_varname
      return to_enum(:each_spec_varname) unless block_given?
      SPECIAL_VARS.each_value{|v| yield v[:name]}
    end

    private
    def parse(line, lineno)

      line.chomp!

      case line
      # upper case is required
      # VARNAME = "VARVALUE"
      when RE_VAR_LINE
        # expandir solo parte de la asignación (nunca el nombre de la variable)
        varname, varvalue = $1, $2.expand(@variables)
        unless @variables.has_key?(varname)
          @variables[varname] = varvalue
        else
          # No se puede declarar una variable dos veces.
          raise DuplicateVarName.new(varname)
        end
      else
        # syntax error
        raise SyntaxError::InvalidLineFormat.new(
          self.class.to_s.downcase.sub(/\A.+::/, EMPTY_STRING), line, lineno
        )

      end

    end


    # comprueba que todas las variables obligatorias se han especificado
    def check_mandatory_vars

      unless Info.each_mand_varname.to_set.subset?(self.each_varname.to_set)
        # calculamos las variables obligatorias que faltan
        missing_vars = Info.each_mand_varname.to_set.subtract(self.each_varname)
        raise MandatoryVarsNotFound.new(missing_vars.to_a)
      end

    end


    # comprueba que todas las variables obligatorias siguen su patron
    def check_mandatory_vars_format

      # para cada variable obligatoria, detectamos el valor que tiene asignado
      # (tiene que tener uno, porque se supone que este procedimiento se llama
      # después de check_mandatory_vars) y comprobamos que sigue el formato
      # asignado
      MANDATORY_VARS.each_value do |mv|
        unless @variables[mv[:name]] =~ mv[:regexp]
          raise BadFormatVariable.new(mv[:name])
        end
      end

    end

    # comprueba que todas las variables especiales siguen su patron
    def check_special_vars_format

      # para cada variable especial indicada, detectamos el valor que tiene asignado
      # y comprobamos que sigue el formato asignado
      # sv_name -> special var name
      # sv_re -> special var reg exp

      SPECIAL_VARS.each_value do |sv|
        self.each do |varname, varvalue|
          next unless varname == sv[:name]
          raise BadFormatVariable.new(sv[:name]) if varvalue !~ sv[:regexp]
        end
      end

    end


  end

end
