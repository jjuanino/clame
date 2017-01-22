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

  # Clase que representa una versión específica de un parche. Es algo
  # puramente formal, del tipo "Foo 1.9.9"
  class PatchVersion

    include Comparable

    attr_reader :patchname, :version
    def initialize(patchname, version)
      @patchname = patchname
      @version = version

      check_patchname
      check_version
    end


    def <=>(other)

      # no se pueden comparar dos parches de distinto nombre
      # En este caso, se propaga automáticamente la exception ArgumentError
      return nil if self.patchname != other.patchname

      # Rompemos la versión por cada punto: 1.5.4 -> [1,5,4] y comparamos
      # cada elemento del array, pasando a integer antes si es posible
      versions_self = self.version.split('.')
      versions_other = other.version.split('.')
      length_max = [versions_self.length, versions_other.length].max


      # los dos arrays necesitan tener el mismo número de elementos. Rellenamos
      # con cadenas vacías
      versions_self += [EMPTY_STRING]*(length_max - versions_self.length)
      versions_other += [EMPTY_STRING]*(length_max - versions_other.length)


      combined_versions =
        versions_self.zip(versions_other).collect do |vs, vo|

          # intentamos convertirlos a integer
          vs = Integer(vs) rescue vs
          vo = Integer(vo) rescue vo

          # si hay diferencia de tipos, convertimos ambos a cadena, pero lo que
          # era una cadena real, lo interpretamos como una cadena vacía, y así
          # un integer siempre será mayor que una cadena. Por ejemplo, si
          # estamos procesando 1,'b', la 'b' se transforma  ''
          vs, vo =
            case [vs.class, vo.class]
            when [String, Fixnum]
              [EMPTY_STRING, vo.to_s]
            when [Fixnum, String]
              [vs.to_s, EMPTY_STRING]
            else
              [vs, vo]
            end

        end

      # comparamos los arrays resultantes, ya formalizados
      combined_versions.collect{|c| c[0]} <=> combined_versions.collect{|c| c[1]}
    end

    # Comparación de objetos.
    def eql?(other)
      self == other
    end

    def hash
      self.instance_variables.collect{|i| self.instance_variable_get(i)}.hash
    end


    private
    def check_patchname
      unless @patchname =~ /\A#{RE_NAME}\Z/
        raise InvalidPatchName.new(@patchname)
      end
    end

    def check_version
      unless @version =~ /\A#{RE_VERSION}\Z/
        raise InvalidPatchVersion.new(@version)
      end
    end


  end

end
