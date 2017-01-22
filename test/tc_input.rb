# encoding: ISO-8859-15
# $Id$
# vim: set sts=2 sw=2 ai et:
#
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

require 'test/unit'
require 'stringio'

class TestInput < Test::Unit::TestCase

  include Clame

  def test_input_1
    input_contents =<<EOF
# coment
# also a comment
P PASSWD_VAR1 Request for a password
P PASSWD_VAR2 Request for a second $(VARNAME)
N NORMAL_VAR1 Request for a normal variable
B BOOL_VAR1 Request for a boolean variable

EOF


    input_io = StringIO.new(input_contents, 'r')
    input_obj = Input.new(input_io, {'VARNAME' => 'VarValue'})

    assert_equal [
      ['PASSWD_VAR1', 'Request for a password'],
      ['PASSWD_VAR2', 'Request for a second VarValue'],
    ], input_obj.passwords

    assert_equal [
      ['NORMAL_VAR1', 'Request for a normal variable'],
    ], input_obj.normals

    assert_equal [
      ['BOOL_VAR1', 'Request for a boolean variable'],
    ], input_obj.booleans

  ensure
    input_io.close unless input_io.nil?
  end

  def test_input_2
    input_contents =<<EOF
# coment
# also a comment
P PASSWD_VAR1 Request for a password
P PASSWD_VAR2 Request for a second $(VARNAME)
N NORMAL_VAR1 Request for a normal variable
B BOOL_VAR1 Request for a boolean variable
invalid line

EOF


    input_io = StringIO.new(input_contents, 'r')

    assert_raise(SyntaxError::InvalidLineFormat) do
      Input.new(input_io, {'VARNAME' => 'VarValue'})
    end

  ensure
    input_io.close unless input_io.nil?
  end


  def test_input_3
    input_contents =<<EOF
# coment
# also a comment
P PASSWD_VAR1 Request for a password
P PASSWD_VAR1 Request for a second $(VARNAME)
N NORMAL_VAR1 Request for a normal variable
B BOOL_VAR1 Request for a boolean variable

EOF


    input_io = StringIO.new(input_contents, 'r')

    assert_raise(DuplicatedInputVariable) do
      Input.new(input_io, {'VARNAME' => 'VarValue'})
    end

  ensure
    input_io.close unless input_io.nil?
  end


  def test_input_4
    input_contents =<<EOF
# coment
# also a comment
P PASSWD_VAR1 Request for a password
P PASSWD_VAR2 Request for a second $(VARNAME)
N NORMAL_VAR1 Request for a normal variable
B PASSWD_VAR2 Request for a boolean variable

EOF


    input_io = StringIO.new(input_contents, 'r')

    assert_raise(DuplicatedInputVariable) do
      Input.new(input_io, {'VARNAME' => 'VarValue'})
    end

  ensure
    input_io.close unless input_io.nil?
  end

  def test_input_5
    input_contents =<<EOF
# coment
# also a comment
P PASSWD_VAR1 Request for a password
P PASSWD_VAR2 Request for a second $(VARNAME)
N NORMAL_VAR1 Request for a normal variable
B PASSWD_VAR3 Request for a boolean variable

EOF


    input_io = StringIO.new(input_contents, 'r')

    assert_raise(InfoVarDupInput) do
      Input.new(input_io, {'PASSWD_VAR3' => 'VarValue'})
    end

  ensure
    input_io.close unless input_io.nil?
  end
end
