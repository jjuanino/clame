# encoding: ISO-8859-15
# $Id$
# vim: set sts=2 sw=2 ai et:
#
#
# Copyright (c) 2016 Jos� Garc�a Juanino <jjuanino@gmail.com>
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


class TestConfSettings < Test::Unit::TestCase

  def setup
    @conf_settings = Clame::ConfSettings[
      :setting1 => 'value1',
      :setting2 => 'value2',
    ]
  end

  def test_valid_settings
    valid_settings = [
      :setting1,
      :setting2,
    ]

    valid_settings.each do |setting|
      assert_nothing_raised{@conf_settings[setting]}
    end

  end

  def test_invalid_settings
    invalid_settings = [
      :invalid1,
      :invalid2,
    ]

    invalid_settings.each do |setting|
      assert_raise(Clame::InvalidConfSetting){
        @conf_settings[setting]
      }
    end

  end

end
