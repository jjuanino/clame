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


class TestPatchVersion < Test::Unit::TestCase

  include Clame

  def test_patchversion_1

    assert_nothing_raised{PatchVersion.new('foo', '1.a.5')}
    assert_raise(InvalidPatchName){PatchVersion.new('foo bar', '1.a.5')}
    assert_raise(InvalidPatchVersion){PatchVersion.new('foo', 'A.1.5')}

  end

  def test_patchversion_2
    assert PatchVersion.new('foo', '1.0') <= PatchVersion.new('foo', '1.0')
    assert PatchVersion.new('foo', '1.0') >= PatchVersion.new('foo', '1.0')
    assert PatchVersion.new('foo', '1.0') == PatchVersion.new('foo', '1.0')
    assert PatchVersion.new('foo', '1.0') != PatchVersion.new('foo', '1.8')
    assert PatchVersion.new('foo', '1.1') < PatchVersion.new('foo', '1.2')
    assert PatchVersion.new('foo', '1.9') > PatchVersion.new('foo', '1.2')
    assert PatchVersion.new('foo', '1.9') >= PatchVersion.new('foo', '1.2')
    assert PatchVersion.new('foo', '1.9') <= PatchVersion.new('foo', '1.10')
    assert PatchVersion.new('foo', '1.a') < PatchVersion.new('foo', '2.10')
    assert PatchVersion.new('foo', '1.a') < PatchVersion.new('foo', '1.b')
    assert PatchVersion.new('foo', '1.a') < PatchVersion.new('foo', '2.b')
    assert PatchVersion.new('foo', '1.ab') == PatchVersion.new('foo', '1.ab')
    assert PatchVersion.new('foo', '1.ab') > PatchVersion.new('foo', '1.a')
    assert PatchVersion.new('foo', '3.a.b') > PatchVersion.new('foo', '3.a')
    assert PatchVersion.new('foo', '3.1') < PatchVersion.new('foo', '3.1.a')
    assert PatchVersion.new('foo', '3.1.a') > PatchVersion.new('foo', '3.1')
    assert PatchVersion.new('foo', '3.10.a') > PatchVersion.new('foo', '3.9.a')
    assert PatchVersion.new('foo', '0') < PatchVersion.new('foo', '0.9.a')
    assert PatchVersion.new('foo', '0.a') > PatchVersion.new('foo', '0')
    assert PatchVersion.new('foo', '0.a').eql? PatchVersion.new('foo', '0.a')
    assert !(PatchVersion.new('foo', '0.a').eql? PatchVersion.new('foo', '0.b'))
    assert !(PatchVersion.new('bar', '0.a').eql? PatchVersion.new('foo', '0.a'))
    assert !(PatchVersion.new('bar', '0.a') == PatchVersion.new('foo', '0.a'))
    assert PatchVersion.new('bar', '0.a') != PatchVersion.new('foo', '0.a')
  end


  def test_patchversion_3
    assert_raise(ArgumentError) do
      PatchVersion.new('foo', '1.0') < PatchVersion.new('foobar', '1.8')
    end

    assert_raise(ArgumentError) do
      PatchVersion.new('foo', '1.0') <= PatchVersion.new('foobar', '1.8')
    end

    assert_raise(ArgumentError) do
      PatchVersion.new('foo', '1.0') >= PatchVersion.new('foobar', '1.8')
    end

    assert_raise(ArgumentError) do
      PatchVersion.new('foo', '1.0') > PatchVersion.new('foobar', '1.8')
    end

    assert_nothing_raised do
      PatchVersion.new('foo', '1.0') == PatchVersion.new('foobar', '1.8')
    end

    assert_nothing_raised do
      PatchVersion.new('foo', '1.0') != PatchVersion.new('foobar', '1.8')
    end
  end
end
