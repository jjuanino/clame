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
require 'logger'
require 'stringio'
require 'set'

class TestSchema < Test::Unit::TestCase

  include Clame

  CONF_SETTINGS = ConfSettings[
    :log_file => '/var/log/clame/clame.log',
    :log_severity => Logger::DEBUG,
    :baseclame => 'BASEDIR',
  ]

  def test_valid_items
    valid_schema_items = [
      [FileType::DIRECTORY, false, '/tmp', '/dev/null', 'nobody', 'nobody', '0000'],
      [FileType::REGFILE, false, '/dev/null', '/dev/null', 'nobody', 'nobody', '0000'],
      [FileType::PIPE, false, '/dev/null', '/dev/null', 'nobody', 'nobody', '0001'],
      [FileType::SYMLINK, false, '/dev/null', '/dev/null', 'nobody', 'nobody', '0001'],
      ['s', false, '/dev/null', '/dev/null', 'nobody', 'nobody', '0001'],
      ['f', false, '/dev/null', '/dev/null', 'nobody', 'nobody', '0001'],
      ['h', false, '/dev/null', '/dev/null', nil, nil, nil],
    ]

    valid_schema_items.each do |v|
      assert_nothing_raised{FileSchemaItem.new(*v)}
    end

  end

  def test_invalid_mask
    invalid_schema_masks = [
      [FileType::DIRECTORY, false, '/tmp', '/dev/null', 'nobody', 'nobody', '10000'],
      [FileType::REGFILE, false, '/dev/null', '/dev/null', 'nobody', 'nobody', '50007'],
      [FileType::PIPE, false, '/dev/null', '/dev/null', 'nobody', 'nobody', '20000'],
      [FileType::SYMLINK, false, '/dev/null', '/dev/null', 'nobody', 'nobody', '10000'],
    ]

    invalid_schema_masks.each do |v|
      assert_raise(InvalidMaskPerm){FileSchemaItem.new(*v)}
    end

  end

  def test_directory_item
    assert_nothing_raised{
      DirSchemaItem.new('/a/dir/name', 'nobody', 'nobody', '0755')
    }
  end

  def test_file_item
    assert_nothing_raised{
      RegFileSchemaItem.new('/a/file/name.txt', '/a/file/name.orig',
                            true, 'nobody', 'nobody', '0644')
    }
  end


  def test_pipe_item
    assert_nothing_raised{
      PipeSchemaItem.new('/a/pipe', true, 'nobody', 'nobody', '0644')
    }
  end

  def test_symlink_item
    assert_nothing_raised{
      SymLinkSchemaItem.new('/a/symlink', '/a/destination', false)
    }

  end

  def test_hardlink_item
    assert_nothing_raised{
      HardLinkSchemaItem.new('/a/hardlink', '/a/destination', false)
    }

  end


  def test_schema_1
    schema_contents =<<EOF
# coment
    # also a comment
    
VAR1 = "Varvalue1" 
VAR2  = "Varvalue2"
 VAR3  = "Varvalue3"


EOF

    schema_io = StringIO.new(schema_contents, 'r')
    assert_raise(SyntaxError::InvalidLineFormat){Schema.new(schema_io)}

  ensure
    schema_io.close unless schema_io.nil?
  end

  def test_schema_2
    schema_contents =<<EOF
# coment
    # also a comment
    
VAR1 = "Varvalue1" 
VAR2  = "Varvalue2"	
VAR3= "Varvalue3"


EOF

    schema_io = StringIO.new(schema_contents, 'r')
    schema = Schema.new(schema_io)

    expected = {
      'VAR1' => 'Varvalue1',
      'VAR2' => 'Varvalue2',
      'VAR3' => 'Varvalue3',
    }

    assert_equal expected.to_set, schema.variables.to_set


  ensure
    schema_io.close unless schema_io.nil?
  end

  def test_schema_3
    schema_contents =<<EOF
# coment
    # also a comment
    
VAR1 = "Varvalue1" 
VAR2  = "Varvalue2"	
var3= "Varvalue3"

EOF

    schema_io = StringIO.new(schema_contents, 'r')
    assert_raise(SyntaxError::InvalidLineFormat){Schema.new(schema_io)}


  ensure
    schema_io.close unless schema_io.nil?
  end



  def test_schema_4
    schema_contents =<<EOF
# coment
    # also a comment
    
VAR1 = "Varvalue1" 
VAR2  = "Varvalue2"	
VAR3= "Varvalue3"

dirdefaults 0775 root:wheel

d  0855 root:nobody path/to/dir

EOF

    schema_io = StringIO.new(schema_contents, 'r')
    assert_raise(SyntaxError::InvalidMaskPerm){Schema.new(schema_io)}


  ensure
    schema_io.close unless schema_io.nil?
  end

  def test_schema_5
    schema_contents =<<EOF
# coment
    # also a comment
    
VAR1 = "Varvalue1" 
VAR2  = "Varvalue2"	
VAR3= "Varvalue3"

notdirdefaults 0775 root:wheel

d  0755 root:nobody path/to/dir
d 0700 root:wheel path
EOF

    schema_io = StringIO.new(schema_contents, 'r')
    schema = Schema.new(schema_io)

    assert_equal [
      DirSchemaItem.new('path/to/dir', 'root', 'nobody', '0755'),
      DirSchemaItem.new('path', 'root', 'wheel', '0700'),
    ], schema.directories

    assert_equal '0775'.oct, schema.notdirdefaults.defperms

  ensure
    schema_io.close unless schema_io.nil?
  end

  def test_schema_6
    schema_contents =<<EOF
d  0755 root:nobody path/to/dir
d 0700 root:wheel path1
d 0700 path2
d path3

EOF

    schema_io = StringIO.new(schema_contents, 'r')
    schema = Schema.new(schema_io)

    assert_equal [
      DirSchemaItem.new('path/to/dir', 'root', 'nobody', '0755'),
      DirSchemaItem.new('path1', 'root', 'wheel', '0700'),
      DirSchemaItem.new('path2', nil, nil, '0700'),
      DirSchemaItem.new('path3', nil, nil, nil),
    ], schema.directories

  ensure
    schema_io.close unless schema_io.nil?
  end

  def test_schema_8
    ## OJO, que dos \\ realmente significan \
    #
    schema_contents =<<EOF
ORIG1 = "orig1"
MASK="0755"
f $(MASK) root:nobody path/to/dir1=$(ORIG1)
f $(MASK) root:nobody path/to/dir2\\=orig2
f $(MASK) root:nobody path/to/dir3\\=orig2\\=orig3
f $(MASK) root:nobody path/to/dir4\\=orig2\\=orig3=orig4
f $(MASK) root:nobody path/to/dir5\\=orig2\\=orig3=orig4\\
f $(MASK) root:nobody path/to/dir6\\=orig2\\=orig3=orig4\\  
f! 0755 root:nobody path/to/dir7=orig
f root:nobody path/to/dir8=orig
f 0755 path/to/dir9=orig
f path/to/dir10=orig
f! path/to/dir11
notdirdefaults 0005 root:wheel
EOF

    schema_io = StringIO.new(schema_contents, 'r')
    schema = Schema.new(schema_io, {'BASECLAME' => 'BASEDIR'})

    assert_equal '0005'.oct, schema.notdirdefaults.defperms

    assert_equal [
      RegFileSchemaItem.new('path/to/dir1', 'BASEDIR/orig1', false, 'root',
                            'nobody', '0755'),
      RegFileSchemaItem.new('path/to/dir2=orig2', 'BASEDIR/path/to/dir2=orig2',
                            false, 'root',
                            'nobody', '0755'),
      RegFileSchemaItem.new('path/to/dir3=orig2=orig3',
                            'BASEDIR/path/to/dir3=orig2=orig3',
                            false, 'root',
                            'nobody', '0755'),
      RegFileSchemaItem.new('path/to/dir4=orig2=orig3', 'BASEDIR/orig4', false, 'root',
                            'nobody', '0755'),
      RegFileSchemaItem.new('path/to/dir5=orig2=orig3', 'BASEDIR/orig4\\', false, 'root',
                            'nobody', '0755'),
      RegFileSchemaItem.new('path/to/dir6=orig2=orig3', 'BASEDIR/orig4\\  ',
                            false, 'root',
                            'nobody', '0755'),
      RegFileSchemaItem.new('path/to/dir7', 'BASEDIR/orig', true, 'root',
                            'nobody', '0755'),
      RegFileSchemaItem.new('path/to/dir8', 'BASEDIR/orig', false, 'root',
                            'nobody', nil),
      RegFileSchemaItem.new('path/to/dir9', 'BASEDIR/orig', false, nil,
                            nil, '0755'),
      RegFileSchemaItem.new('path/to/dir10', 'BASEDIR/orig', false, nil,
                            nil, nil),
      RegFileSchemaItem.new('path/to/dir11', 'BASEDIR/path/to/dir11', true, nil,
                            nil, nil),
    ], schema.regfiles

  ensure
    schema_io.close unless schema_io.nil?
  end

  def test_schema_12
    schema_contents =<<EOF
p 709 path	

EOF

    schema_io = StringIO.new(schema_contents, 'r')
    assert_raise(SyntaxError::InvalidMaskPerm){Schema.new(schema_io)}

  ensure
    schema_io.close unless schema_io.nil?
  end

  def test_schema_13
    schema_contents =<<EOF
#f root:nobody path/to/dir=orig
#f 0755 path/to/dir1=orig
p 755 root:nobody path/to/pipe
p! 0755 root:nobody path/to/pipe2
p root:nobody path/to/pipe3
p 0755 path/to/pipe4   
p path/to/pipe1
p! path/to/pipe5
EOF

    schema_io = StringIO.new(schema_contents, 'r')
    schema = Schema.new(schema_io)

    assert_equal [
      PipeSchemaItem.new('path/to/pipe', false, 'root', 'nobody', '0755'),
      PipeSchemaItem.new('path/to/pipe2', true, 'root', 'nobody', '755'),
      PipeSchemaItem.new('path/to/pipe3', false, 'root', 'nobody', nil),
      PipeSchemaItem.new('path/to/pipe4   ', false, nil, nil, '0755'),
      PipeSchemaItem.new('path/to/pipe1', false, nil, nil, nil),
      PipeSchemaItem.new('path/to/pipe5', true, nil, nil, nil),
    ], schema.pipes

  ensure
    schema_io.close unless schema_io.nil?
  end

  def test_schema_14
    schema_contents =<<EOF
s! path	=

EOF

    schema_io = StringIO.new(schema_contents, 'r')
    assert_raise(SyntaxError::SymLinkDestNil){Schema.new(schema_io)}

  ensure
    schema_io.close unless schema_io.nil?
  end

  def test_schema_17
    schema_contents =<<EOF
s path/to/symlink1=destination
s! path/to/symlink2=destination
s! path/to/symlink3= destination
s 700 path=destination
h path/to/hardlink1=destination
h! path/to/hardlink2=destination
h! path/to/hardlink3= destination
h 700 pathhard=destination
EOF

    schema_io = StringIO.new(schema_contents, 'r')
    schema = Schema.new(schema_io)

    assert_equal [
      SymLinkSchemaItem.new('path/to/symlink1', 'destination', false),
      SymLinkSchemaItem.new('path/to/symlink2', 'destination', true),
      SymLinkSchemaItem.new('path/to/symlink3', ' destination', true),
      SymLinkSchemaItem.new('700 path', 'destination', false),
      HardLinkSchemaItem.new('path/to/hardlink1', 'destination', false),
      HardLinkSchemaItem.new('path/to/hardlink2', 'destination', true),
      HardLinkSchemaItem.new('path/to/hardlink3', ' destination', true),
      HardLinkSchemaItem.new('700 pathhard', 'destination', false),
    ].to_set, (schema.symlinks + schema.hardlinks).to_set

  ensure
    schema_io.close unless schema_io.nil?
  end


  def test_schema_18
    schema_contents =<<EOF
notdirdefaults 0700 root:wheel
notdirdefaults 1755 nobody:nogroup
EOF

    schema_io = StringIO.new(schema_contents, 'r')
    assert_raise(SyntaxError::DuplicateNotDirDefaults){Schema.new(schema_io)}

  ensure
    schema_io.close unless schema_io.nil?
  end


  def test_schema_18_bis
    schema_contents =<<EOF
dirdefaults 0700 root:wheel
dirdefaults 1755 nobody:nogroup
EOF

    schema_io = StringIO.new(schema_contents, 'r')
    assert_raise(SyntaxError::DuplicateDirDefaults){Schema.new(schema_io)}

  ensure
    schema_io.close unless schema_io.nil?
  end


  def test_schema_19
    schema_contents =<<EOF
dirdefaults	0709	root:wheel	 
notdirdefaults 1758 nobody:nogroup
EOF

    schema_io = StringIO.new(schema_contents, 'r')
    assert_raise(SyntaxError::InvalidMaskPerm){Schema.new(schema_io)}

  ensure
    schema_io.close unless schema_io.nil?
  end


  def test_check_duplicates

    schema_contents =<<EOF
f destination1=origin1
f! destination2=origin1
d 0755 root:nobody destination1
EOF

    schema_io = StringIO.new(schema_contents, 'r')


    assert_raise(DuplicateDestination) do
      Schema.new(schema_io, {'BASECLAME' => CONF_SETTINGS[:baseclame]})
    end


  ensure
    schema_io.close unless schema_io.nil?
  end


  def test_each_destination
    schema_contents =<<EOF
f destination1=origin1
f! destination2=origin1
d destination3
s symlink=destination
p 0755 oracle:dba pipe
EOF

    schema_io = StringIO.new(schema_contents, 'r')
    schema = Schema.new(schema_io, {'BASECLAME' => 'BASEDIR'})

    assert_equal %w{
      destination1
      destination2
      destination3
      symlink
      pipe}.to_set, schema.each_destination.to_set

  ensure
    schema_io.close unless schema_io.nil?
  end

  def test_each
    schema_contents =<<EOF
f destination1=origin1
f! 764 root:nobody destination2=origin1
d destination3
d 644 root:nobody destination4
s symlink=destination
p 0755 oracle:dba pipe1
p! 0755 oracle:dba pipe2
h! hardlink=destination
EOF

    schema_io = StringIO.new(schema_contents, 'r')
    schema = Schema.new(schema_io, {'BASECLAME' => CONF_SETTINGS[:baseclame]})

    assert_equal [
      RegFileSchemaItem.new('destination1', 'BASEDIR/origin1', false, nil, nil, nil),
      RegFileSchemaItem.new('destination2', 'BASEDIR/origin1', true, 'root',
                            'nobody', '764'),
      DirSchemaItem.new('destination3', nil, nil, nil),
      SymLinkSchemaItem.new('symlink', 'destination', false),
      HardLinkSchemaItem.new('hardlink', 'destination', true),
      PipeSchemaItem.new('pipe1', false, 'oracle', 'dba', '755'),
      PipeSchemaItem.new('pipe2', true, 'oracle', 'dba', '755'),
      DirSchemaItem.new('destination4', 'root', 'nobody', '644'),
    ].to_set, schema.each.to_set

  ensure
    schema_io.close unless schema_io.nil?
  end


end
