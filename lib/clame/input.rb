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

# entrada de parámetros necesarios para instalar el parche, como passwords,
# variables de configuración, etc.


=begin
TipoEntrada Variable Frase_de_solicitud_de_parametro

TipoEntrada puede ser: N (normal) P (password) B (boolean)
Variable es la variable donde se almacenará la respuesta
Frase_de_solicitud_de_parametro debe estar entre comillas
=end

module Clame

  class Input

    include Enumerable

    # Regular expressions used in parse lines
    RE_COMMON = '\s+([[:upper:]_\d]+)\s+(.+)'
    RE_PASSWORDS = /\AP#{RE_COMMON}\Z/
    RE_NORMAL = /\AN#{RE_COMMON}\Z/
    RE_BOOLEAN = /\AB#{RE_COMMON}\Z/


    attr_reader :passwords, :normals, :booleans

    # infovars son las variables heredadas de info
    def initialize(io_stream, infovars={})

      @passwords = []
      @normals = []
      @booleans = []
      @infovars = infovars.dup

      io_stream.each_line do |line|
        parse(line, io_stream.lineno) unless line =~ IGNORED_LINES
      end

      # no se pueden indicar variables duplicadas
      Clame.check_dup_iterator(each_input_var, DuplicatedInputVariable)

      # las variables definidas en el info no pueden duplicarse aquí
      Clame.check_dup_iterator(each_input_and_info, InfoVarDupInput)
    end

    def each(&block)
      (@passwords + @normals + @booleans).each(&block)
    end

    def each_input_var
      return to_enum(:each_input_var) unless block_given?
      (@passwords + @normals + @booleans).each{|i| yield i[0]}
    end

    # Itera sobre todas las variables input y las definidas en el info.
    # Realmente solo se utiliza para comprobar que entre esos dos conjuntos no
    # hay duplicados, ya que una variable de info no puede indicarse en el
    # input
    def each_input_and_info
      return to_enum(:each_input_and_info) unless block_given?
      @infovars.each_key{|k| yield k}
      each_input_var.each{|v| yield v}
    end


    private
    def parse(line, lineno)

      line.chomp!

      case line
      when RE_PASSWORDS
        @passwords
      when RE_NORMAL
        @normals
      when RE_BOOLEAN
        @booleans
      else
        # syntax error
        raise SyntaxError::InvalidLineFormat.new(
          self.class.to_s.downcase.sub(/\A.+::/, EMPTY_STRING), line, lineno
        )

      end << [$1, $2.expand(@infovars)]

    end


  end

end
