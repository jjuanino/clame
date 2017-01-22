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

require 'pathname'

module Clame

  #
  # Class to hold configuration settings. It has the same behaviour that
  # ordinary Hash class, but raises _InvalidConfSetting_ exception if we ask
  # for a inexistent key. This, it is not possible to use configuration
  # variables not previously defined
  #
  class ConfSettings < Object::Hash

    def [](key)
      raise InvalidConfSetting.new(key) unless self.has_key?(key)
      super
    end

  end

end


=begin
expand string acording variables
for example, if

ONE=one value 

then

one line with $(ONE)

is expanded to

one line with one value

\ before $ does not expand anything, e,g

one line with \$(ONE)

expand to the same string

=end

class String

  # see http://www.regular-expressions.info/lookaround.html
  def expand!(variables)
    self.replace(self.expand(variables))
    #variables.each{|v| self.gsub!(/(?<!\\)\$\(#{v.varname}\)/, v.varvalue)}
  end


  def expand(variables)
    variables.inject(self){|a,e| a.gsub(/(?<!\\)\$\(#{e[0]}\)/, e[1])}
  end

end


class Pathname

  # las rutas padre de una dada, incluida ella misma
  # Por ejemplo:
  # File.parents('/usr/local/bin/gmake').each{|p| puts p}
  # /usr/local/bin/gmake
  # /usr/local/bin
  # /usr/local
  # /usr
  # /

  def parents
    # No funciona para rutas relativas
    raise Clame::InvalidPathname.new(self) if self.relative?

    return to_enum(:parents) unless block_given?

    actual = self
    loop do
      yield actual
      actual == actual.parent ? break : actual = actual.parent
    end
  end


  def subdir?(parent)
    self.parents.include?(parent)
  end

end


class Integer

  # Transformar bytes a kib.  Redondeamos al alza.
  def to_kib
    (self / 1024.to_f).ceil
  end

end

# Ampliar esta clase para poder convertir un objeto File::Stat a Clame::Stat.
# Ver comentario de la clase Clame::Stat (no es posible hacer un marshall de un
# objeto File::Stat)
class File::Stat

  # pstat significa Clame::Stat
  def to_pstat
    Clame::Stat.new(self.mode, self.uid, self.gid, self.atime,
                       self.mtime, self.ctime, self.ftype)
  end

end
