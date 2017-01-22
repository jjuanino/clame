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
require 'set'

class TestDepend < Test::Unit::TestCase

  include Clame

  def test_depend_1
    depend_contents =<<EOF
# coment
# also a comment
R depend1
R depend3
C conflict1
C conflict3  	

EOF


    depend_io = StringIO.new(depend_contents, 'r')
    depend_obj = Depend.new(depend_io)

    assert_equal [
      Interval.new('>=', PatchVersion.new('depend1','0')),
      Interval.new('>=', PatchVersion.new('depend3','0')),
    ], depend_obj.requisites

    assert_equal [
      Interval.new('>=', PatchVersion.new('conflict1','0')),
      Interval.new('>=', PatchVersion.new('conflict3','0')),
    ], depend_obj.conflicts

  ensure
    depend_io.close unless depend_io.nil?
  end

  def test_depend_2
    depend_contents =<<EOF
# coment
# also a comment
invalid line
R depend1
R depend3
C conflict1
C conflict3

EOF


    depend_io = StringIO.new(depend_contents, 'r')
    assert_raise(SyntaxError::InvalidLineFormat){Depend.new(depend_io)}

  ensure
    depend_io.close unless depend_io.nil?
  end


  def test_depend_3
    depend_contents =<<EOF
# coment
# also a comment

EOF

    depend_io = StringIO.new(depend_contents, 'r')
    assert_nothing_raised{Depend.new(depend_io)}

  ensure
    depend_io.close unless depend_io.nil?
  end



  def test_depend_4
    depend_contents =<<EOF
# coment
# also a comment
R depend1 < 1.4
R depend2 >= 0.4
R depend3 == 9.a
R depend4 != 3.4
#
C conflict1 == 9.1.1
C conflict2 != 0.7
C conflict3 < 9.1.1
C conflict4 <= 0.7

EOF


    depend_io = StringIO.new(depend_contents, 'r')
    depend_obj = Depend.new(depend_io)

    assert_equal [
      Interval.new('<', PatchVersion.new('depend1','1.4')),
      Interval.new('>=', PatchVersion.new('depend2','0.4')),
      Interval.new('==', PatchVersion.new('depend3','9.a')),
      Interval.new('!=', PatchVersion.new('depend4','3.4')),
    ].to_set, depend_obj.requisites.to_set

    assert_equal [
      Interval.new('==', PatchVersion.new('conflict1','9.1.1')),
      Interval.new('!=', PatchVersion.new('conflict2','0.7')),
      Interval.new('<', PatchVersion.new('conflict3','9.1.1')),
      Interval.new('<=', PatchVersion.new('conflict4','0.7')),
    ], depend_obj.conflicts

  ensure
    depend_io.close unless depend_io.nil?
  end

  def test_depend_5
    depend_contents =<<EOF
# coment
# also a comment
R depend3
C conflict1
C conflict3
R depend1 == a

EOF


    depend_io = StringIO.new(depend_contents, 'r')
    assert_raise(SyntaxError::InvalidLineFormat){Depend.new(depend_io)}

  ensure
    depend_io.close unless depend_io.nil?
  end
end
