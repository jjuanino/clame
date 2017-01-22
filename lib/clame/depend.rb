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

  class Depend

    # Regular expressions used in parse lines
    RE_OPERATOR = Interval::VALID_OPERATORS.join('|') # '<|<=|>=|>|==|!='
    RE_REQUISITES = /\AR\s+(#{RE_NAME})(\s+(#{RE_OPERATOR})\s+(#{RE_VERSION}))?\s*\Z/
    RE_CONFLICS = /\AC\s+(#{RE_NAME})(\s+(#{RE_OPERATOR})\s+(#{RE_VERSION}))?\s*\Z/

    attr_reader :requisites, :conflicts

    def initialize(io_stream)

      @requisites = []
      @conflicts = []

      io_stream.each_line do |line|
        parse(line, io_stream.lineno) unless line =~ IGNORED_LINES
      end

    end



    private
    def parse(line, lineno)

      line.chomp!

      # mod_dep: dependencia a modificar
      case line
      when RE_REQUISITES then mod_dep = @requisites
      when RE_CONFLICS then mod_dep = @conflicts
      else
        # syntax error
        raise SyntaxError::InvalidLineFormat.new(
          self.class.to_s.downcase.sub(/\A.+::/, EMPTY_STRING), line, lineno
        )
      end

      # $1 : patchname
      # $3 : operator
      # $4 : version
      mod_dep <<
        if $4
          Interval.new($3, PatchVersion.new($1, $4))
        else
          # No se indica versión. Entendemos que cualquier versión
          # es válida.
          # Notar que PatchVersion.new($1, '0') es la versión más pequeña
          # que puede tener un parche
          Interval.new('>=', PatchVersion.new($1, ZERO_VERSION))
        end

    end

  end

end
