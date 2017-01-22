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


class TestInfo < Test::Unit::TestCase

  include Clame

  def test_info_1

    info_contents =<<EOF
# coment
# also a comment
    
VAR1 = "Varvalue1" 
VAR2  = "Varvalue2"
VAR3  = "$(VAR1) $(VAR2) $(PATCH_NAME)"


EOF

    info_io = StringIO.new(info_contents, 'r')
    info_test = Info.new(info_io, {'PATCH_NAME' => 'patchname',
                       'VENDOR' => 'juanino',
                       'DESCRIPTION' => 'description juanino',
                       'VERSION' => '0'})

    expected = {
      'PATCH_NAME' => 'patchname',
      'VENDOR' => 'juanino',
      'DESCRIPTION' => 'description juanino',
      'VERSION' => '0',
      'VAR1' => 'Varvalue1',
      'VAR2' => 'Varvalue2',
      'VAR3' => 'Varvalue1 Varvalue2 patchname',
      # BASECLAME se establece por defecto, según el fichero
      # de configuración
      'BASECLAME' => 'BASEDIR',
    }

    assert_equal expected.to_set, info_test.each.to_set

  ensure
    info_io.close unless info_io.nil?
  end



  def test_info_2

    info_contents =<<EOF
# coment
# also a comment
    
VAR1 = "Varvalue1" 
VAR2  = "Varvalue2"
VAR3  = "Varvalue3"


EOF

    info_io = StringIO.new(info_contents, 'r')
    assert_raise(MandatoryVarsNotFound){Info.new(info_io)}
  ensure
    info_io.close unless info_io.nil?
  end


  def test_info_3

    info_contents =<<EOF
# coment
# also a comment
invalid line
    
VAR1 = "Varvalue1" 
VAR2  = "Varvalue2"
VAR3  = "Varvalue3"


EOF

    info_io = StringIO.new(info_contents, 'r')
    assert_raise(SyntaxError::InvalidLineFormat){Info.new(info_io)}
  ensure
    info_io.close unless info_io.nil?
  end


  def test_info_4

    info_contents =<<EOF
# coment
# also a comment
    
PATCH_NAME = "patch_name"
DESCRIPTION = "Description"
VAR1 = "Varvalue1" 
VAR1  = "Varvalue2"
VAR3  = "Varvalue3"


EOF

    info_io = StringIO.new(info_contents, 'r')
    assert_raise(DuplicateVarName){Info.new(info_io)}
  ensure
    info_io.close unless info_io.nil?
  end


  def test_info_5

    info_contents =<<EOF
# coment
# also a comment
    
PATCH_NAME = "patch name"
DESCRIPTION = "Description"
VAR1 = "Varvalue1" 
VAR3  = "Varvalue3"


EOF

    info_io = StringIO.new(info_contents, 'r')
    assert_raise(BadFormatVariable){Info.new(info_io)}
  ensure
    info_io.close unless info_io.nil?
  end

  def test_info_6

    info_contents =<<EOF
# coment
# also a comment
    
PATCH_NAME = "patchname"
DESCRIPTION = "Description"
VERSION = "a.0.4" 
VAR3  = "Varvalue3"


EOF

    info_io = StringIO.new(info_contents, 'r')
    assert_raise(BadFormatVariable){Info.new(info_io)}
  ensure
    info_io.close unless info_io.nil?
  end
  

  def test_info_7

    info_contents =<<EOF
# coment
# also a comment
    
PATCH_NAME = "patchname"
DESCRIPTION = "Description"
VERSION = "601.A.B" 
INTERPRETER = "/bin/sh"
VAR3  = "Varvalue3"


EOF

    info_io = StringIO.new(info_contents, 'r')
    assert_nothing_raised{Info.new(info_io)}
  ensure
    info_io.close unless info_io.nil?
  end


  def test_patch_name
    info_contents =<<EOF
# coment
# also a comment
    
PATCH_NAME = "patchname"
DESCRIPTION = "Description"
VERSION = "601.A.B" 
INTERPRETER = "/bin/sh"
VAR3  = "Varvalue3"


EOF

    info_io = StringIO.new(info_contents, 'r')
    assert_equal 'patchname', Info.new(info_io).patch_name
  ensure
    info_io.close unless info_io.nil?
  end

  def test_patch_version_1
    info_contents =<<EOF
# coment
# also a comment
    
PATCH_NAME = "patchname"
DESCRIPTION = "Description"
VERSION = "601.A.B" 
INTERPRETER = "/bin/sh"
VAR3  = "Varvalue3"


EOF

    info_io = StringIO.new(info_contents, 'r')
    assert_equal '601.A.B', Info.new(info_io).patch_version
  ensure
    info_io.close unless info_io.nil?
  end

  def test_patch_version_2
    info_contents =<<EOF
# coment
# also a comment
    
PATCH_NAME = "patchname"
DESCRIPTION = "Description"
INTERPRETER = "/bin/sh"
VAR3  = "Varvalue3"


EOF

    info_io = StringIO.new(info_contents, 'r')
    assert_equal '0', Info.new(info_io).patch_version
  ensure
    info_io.close unless info_io.nil?
  end
  
end
