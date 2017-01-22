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

class TestFileType < Test::Unit::TestCase

  include Clame

  def test_invalid_filetype
    invalid_schema_filetypes = [
      ['l', false, '/tmp', '/dev/null', 'nobody', 'nobody', 0o0000],
      ['g', false, '/dev/null', '/dev/null', 'nobody', 'nobody', 0o0000],
      ['i', false, '/dev/null', '/dev/null', 'nobody', 'nobody', 0o0000],
    ]

    invalid_schema_filetypes.each do |v|
      assert_raise(InvalidFileType){FileSchemaItem.new(*v)}
    end

  end

  def test_absolute_path
    absolute_paths = [
      ['/opt/absolute', '/dev/null', true, 'nobody', 'nobody', '0644'],
      ['/', '/dev/null', true, 'nobody', 'nobody', '0400'],
      ['/tmp/weird_path/one/two', '/dev/null', true, 'nobody', 'nobody', '0600'],
    ]
    relative_paths = [
      ['relative', '/dev/null', true, 'nobody', 'nobody', '0644'],
      ['relative/path.extesion', '/dev/null', true, 'nobody', 'nobody', '0400'],
      ['tmp/weird_path/one/two', '/dev/null', true, 'nobody', 'nobody', '0600'],
    ]

    absolute_paths.each{|v| assert RegFileSchemaItem.new(*v).absolute?}
    absolute_paths.each do |v|
      assert_equal v[0],
        File.absolute_path(RegFileSchemaItem.new(*v).destination, '/opt')
    end
    relative_paths.each{|v| assert !RegFileSchemaItem.new(*v).absolute?}
    relative_paths.each do |v|
      assert_equal File.join('/opt', v[0]),
        File.absolute_path(RegFileSchemaItem.new(*v).destination, '/opt')
    end

  end

end
