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


module Clame

  # Clase genérica que representa un intervalo.
  class Interval

    # operador puede ser: <, <=, >=, >, ==, !=
    # extreme es el extremo del intervalo. Tiene que ser un objeto
    # que soporte Comparable
    #
    # Por ejemplo,
    # Interval.new('<', 4) representa todos los numeros menores que 4
    # Interval.new('>=', 100) representa todos los numeros mayores o iguales que
    #   100
    # Interval.new('==', 200) representa exactamente el número 200

    VALID_OPERATORS = %w(< <= >= > == !=)


    attr_reader :operator, :extreme
    def initialize(operator, extreme)
      @operator = operator.strip
      @extreme = extreme
      check_operator
    end


    # comprueba si un cierto valor cae dentro del intervalo
    def include?(value)
      value.send(@operator.to_sym, @extreme)
    end

    # igualdad de intervalos
    def ==(other)
      self.instance_variables.all? do |i|
        self.instance_variable_get(i) == other.instance_variable_get(i)
      end
    end

    def eql?(other)
      self == other
    end

    def hash
      self.instance_variables.collect{|i| self.instance_variable_get(i)}.hash
    end

    def marshal_dump
      [@operator, @extreme]
    end

    def marshal_load(array)
      @operator, @extreme = array
    end

    def to_s
      [@extreme.patchname, @operator, @extreme.version].join(' ')
    end


    private
    # El operador tiene que ser <, <=, >=, >, == !=
    def check_operator
      unless VALID_OPERATORS.include?(@operator)
        raise InvalidOperator.new(@operator)
      end
    end


  end
end
