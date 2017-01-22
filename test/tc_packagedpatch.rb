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
require 'tmpdir'


class TestPackagedPatch < Test::Unit::TestCase

  include Clame

  PATH_CURRENT_DIR = Pathname.new(CURRENT_DIR)

  def setup
    @tmpdir = Dir.mktmpdir
    Factory.bootstrap_conf
    CONF_SETTINGS[:log_file] = File.join(@tmpdir, 'clame.log')
    CONF_SETTINGS[:database_path] = File.join(@tmpdir, 'clame.db')
    CONF_SETTINGS[:backup_dir_install] = File.join(@tmpdir, 'save')
    Dir.mkdir CONF_SETTINGS[:backup_dir_install]

    Factory.bootstrap_logger
    Factory.bootstrap_database
    Fs.compute_free_space_per_fs
    Fs.get_mounted_fs

    @initial_vars = {'MYVAR' => 'MYVALUE'}

  end

  def teardown
    # esto es una ñapa para que se eliminen los archivos temporales que
    # permanecen después de construir el zip. A veces fallan los test por
    # esto
    GC.start
    FileUtils.remove_entry_secure(@tmpdir)
  end

  # comprobar que al instalar un parche, se instalan los ficheros esperados, y
  # con el contenido esperado
  def test_install_bison
    Dir.chdir(File.join(PATH_CURRENT_DIR, 'tc_patchbuilder')) do
      PatchBuilder.build(%w(bison_no_output),
                         File.join(@tmpdir, 'bison_no_output.zip'),
                         {variables: @initial_vars, quiet: true}
                        )
    end

    basedir = File.join(@tmpdir, 'basedir')
    bison_patch = PackagedPatch.new(
      File.join(@tmpdir, 'bison_no_output.zip'), 'bison', '2.4.3',
      {prefix: basedir, ignore_reqs: true}
    )

    bison_patch.install

    sha256s={
      'share/aclocal/bison-i18n.m4' =>
      '8cc79bba0fc564269723e718bba3b4bf37e689cd89d86daff387f248d9c1d011',
        'share/bison/java-skel.m4' =>
      '759b1bf132880bc0e9b1e35487adbb561653c6f861b3e0e1b28d7697077795b5',
        'share/bison/glr.cc' =>
      'b2886c5f26a7cb514e27ee0b4d8bd67acdab10917d79960b071d2e9b055f3a2a',
        'share/bison/xslt/bison.xsl' =>
      'ec73857039952cc1d78966edd207c5c4b59398bb3fea58b0a2b5a165206a0831',
        'share/bison/xslt/xml2dot.xsl' =>
      '3d592b5c6ff4379a4675a1f88928d228e123a3bce5b220ecd25322df9bc36073',
        'share/bison/xslt/xml2text.xsl' =>
      '8da8cc56ee5514826da193dfc61f5775006b98ca13fb9ec4864c3ed55826c815',
        'share/bison/xslt/xml2xhtml.xsl' =>
      'c11b9f0e670631879589f67f4ea5e90c30afe4c01a1ed0b5b7ec3b76aa9c9b5a',
        'share/bison/glr.c' =>
      '288ddfee5b5ece99ef10a5ae0c71900611e38a76c75c5cd05541344aaf623ad2',
        'share/bison/c++.m4' =>
      '6495cea340183c36fd1dee05397c1386796a2225c5af2dbba2f0f72fc558f685',
        'share/bison/bison.m4' =>
      'c559617ec5ed2fd34094a02bef4c2a54e71350b1171d436545c8ebd366add145',
        'share/bison/java.m4' =>
      '1263d9c1e7b4be101d9b7c45c4a53a73a809532ce517ea0bc026d155080f2abc',
        'share/bison/lalr1.java' =>
      'c9688202e060629149be0371ac277a2aea885ff28199d364ab293cc7ac166fb8',
        'share/bison/lalr1.cc' =>
      '8ae12461861057d52375a5d4cb6a99fd21248c0f4bafcc9ff43d51195e08dc3a',
        'share/bison/c++-skel.m4' =>
      'f316931efb83790377efd79312af745ecd165b901dda75a2880ac090dddc0e50',
        'share/bison/c.m4' =>
      'd1e49cc6ae15584fad52dcbe772039fb6ff43b16dca62747052c40ff22a0d204',
        'share/bison/c-skel.m4' =>
      '8130254b6358f6324af90e4428989e7d19afa40e98fd2dc00f985e74822577f1',
        'share/bison/README' =>
      'c6437918b8b0bb1801636fe3bf0635473e666bc2e214e5af857d482bb3d372f8',
        'share/bison/location.cc' =>
      'ff38e996eee566666fd359c2146221fd605c8cbd7e95086b6d0db44297d5283a',
        'share/bison/yacc.c' =>
      '9ca24d69837bc67fca41f1b2e59349571b086a02d6952ab210e3f5e869b896d3',
        'share/bison/m4sugar/m4sugar.m4' =>
      'c18807c50e51ab8521d1da4015a872c352b08918b70be56cea0920f6528262de',
        'share/bison/m4sugar/foreach.m4' =>
      '2613914dbf7dc93a6afc34f0cf2cda6e84343e6d77119420f0df12459255fa0d',
        'share/locale/tr/LC_MESSAGES/bison.mo' =>
      '31fca9fe95050cbe756572e40efcea9595d0fab301eddb7b99284f10ef877a7a',
        'share/locale/tr/LC_MESSAGES/bison-runtime.mo' =>
      'b88cb74635b3c3bb7b2eafc28f3bc4cf1caa68d2a3b58560b652a973b05be948',
        'share/locale/pt_BR/LC_MESSAGES/bison.mo' =>
      'ce60035a54ae0e107c8d73dc31fa5d4ad1623380accb41e018865e7ce4f26a72',
        'share/locale/pt_BR/LC_MESSAGES/bison-runtime.mo' =>
      '461d818b6340cbc0608feee035a4661dc13801d770f929c62ce76cd46882b542',
        'share/locale/da/LC_MESSAGES/bison.mo' =>
      '368a96126e3f2ec423329ba8da4f6b5d852a54c9ec75e24b93fbe80905bb62d8',
        'share/locale/da/LC_MESSAGES/bison-runtime.mo' =>
      '50f11882de62ffe60d072650e8286b7956c1f80a00a1b9d00c74d4bfdda2f6af',
        'share/locale/ro/LC_MESSAGES/bison.mo' =>
      'a307242e573d5f1e61fdaccfdd5b95106f69b3d2d976509ab7a76f26b1825120',
        'share/locale/ro/LC_MESSAGES/bison-runtime.mo' =>
      'd3e6d8b4db20e3e7a5f92ad215b80f0ddb8dafb1ff09a8d48da236fdfd2e9682',
        'share/locale/it/LC_MESSAGES/bison-runtime.mo' =>
      '6612bef5266c0268925425bd076e8da45978a519d14653cd607089c5686d8c5c',
        'share/locale/it/LC_MESSAGES/bison.mo' =>
      '67e20a7752944bad33fe0d7098e56fb89b1c3a6e19847aaf0e957fa7496b2703',
        'share/locale/sl/LC_MESSAGES/bison-runtime.mo' =>
      '13a9f5459d6ad70720cb8938b069a50ada68b0ce0f29320d76be075390069f03',
        'share/locale/sv/LC_MESSAGES/bison.mo' =>
      '426cd89d16ac357dbbe6920dcca3c2a0435a8397e1d6247cfa1298fce98f0968',
        'share/locale/sv/LC_MESSAGES/bison-runtime.mo' =>
      '664d3be06d2eb4fe589ab585a822dbb2c2d7b38a3ebd439876b18c30b4d04436',
        'share/locale/fi/LC_MESSAGES/bison-runtime.mo' =>
      '88edb2c52242719ad33c1efc3b2297cdd9ae629e9bd677eae537ddb2f2869cd4',
        'share/locale/fi/LC_MESSAGES/bison.mo' =>
      '1ad799f01f51ec4ac5724c1114a2018110670fba1b473a3880e4204a0f1f814f',
        'share/locale/lv/LC_MESSAGES/bison-runtime.mo' =>
      'b0d99afb2d28594a870dcf355afec06f4b2b1f2e4f60924966139b03fc64e4dc',
        'share/locale/pt/LC_MESSAGES/bison-runtime.mo' =>
      'b25e2a99a4cde13a2dca4c36e7a7fd54ef1c448a3d116345f91578977ae64967',
        'share/locale/pt/LC_MESSAGES/bison.mo' =>
      '43d97b286d5c2900e17204b7e1ca1231fd689ee5cb5da8a2fb3085ca9c36b2dd',
        'share/locale/id/LC_MESSAGES/bison.mo' =>
      'f3e2a46234563df69d0e51ca02540ca60a7af74d12cdfb894e78d7933ee44e28',
        'share/locale/id/LC_MESSAGES/bison-runtime.mo' =>
      'cc80c24e16c60d5a455c1a5120f391c6828dc8ee81dd2770751a9b2b931d6e63',
        'share/locale/ru/LC_MESSAGES/bison.mo' =>
      'ab360eedda1498338506d91963553805060c841e364f567c28822728432501d1',
        'share/locale/ru/LC_MESSAGES/bison-runtime.mo' =>
      '5639fec400a92786c93869e2aa6c7c3d69be630d17cb966bd6a688d14418bcc3',
        'share/locale/ja/LC_MESSAGES/bison-runtime.mo' =>
      '7e09df62c71dc1f807dd9679c69ff8634f2d16e89110c478f4140cbfe7ff93f7',
        'share/locale/ja/LC_MESSAGES/bison.mo' =>
      '4171365f7a1140c9115d849ac0848b5d5ac0b3abffd71c214801686446809c69',
        'share/locale/de/LC_MESSAGES/bison.mo' =>
      'f07753633b9d1bfde0dd1f810904c76f126d5f1d7ee7f0ee9ad14d48011e1717',
      'share/locale/de/LC_MESSAGES/bison-runtime.mo' =>
        '0a491a4d9527f9b15149bf6304269d515503f913fd80edef2cc2a490792fdc84',
      'share/locale/vi/LC_MESSAGES/bison-runtime.mo' =>
        '841ddc2ddb02f466da1c68005e4825c54c8809745bc3be0fca989c5a48418b91',
      'share/locale/vi/LC_MESSAGES/bison.mo' =>
        '8a6434bb40ef8294d01dac3d5a82690f1fb92bbfba835cb16b871d9bc23d5a97',
      'share/locale/uk/LC_MESSAGES/bison.mo' =>
        '6dfe8c21a08c56f83776650abf6f0faefbafc249a796bee589c93c9317060781',
      'share/locale/uk/LC_MESSAGES/bison-runtime.mo' =>
        '64c6453e99b4d3e0c31b159fb9cfccc5656d0ed3cda13728649f03a5b39fe2a6',
      'share/locale/el/LC_MESSAGES/bison.mo' =>
        '960e9c00bbafc3e5c3dbd63045562f3a9f4870c004ae4bfac03eff1ab7d24ffc',
      'share/locale/el/LC_MESSAGES/bison-runtime.mo' =>
        '44304b212c6cdaf119e608a66b1c843bdc50cc24771c824b0106e5e6dde863b0',
      'share/locale/th/LC_MESSAGES/bison-runtime.mo' =>
        '84db1abb8e2e84b75fdfe586e82f5cdd95e917a5c76fee39dc63b140256e3e6f',
      'share/locale/zh_CN/LC_MESSAGES/bison-runtime.mo' =>
        'ecf60ee6838bd0321f72b433001a1a87b204a992acd3d0f1be7dcbecbcf252af',
      'share/locale/fr/LC_MESSAGES/bison.mo' =>
        '827db14eeff1938bf3992483861c4a4072ec372959d7c18b56836213824e3f27',
      'share/locale/fr/LC_MESSAGES/bison-runtime.mo' =>
        'e1411cb48c1edf2caa3676023f86fcf25b0697a21aa90bb3f64d98d49d231185',
      'share/locale/nl/LC_MESSAGES/bison-runtime.mo' =>
        'c75de15d5e1633ac8fed6aaaf6772ed0fcce328276eb84c318f36aebc7ee221e',
      'share/locale/nl/LC_MESSAGES/bison.mo' =>
        'c963934a616ea21f783be3eebc8fed29773897bfd9884af68a37a0a4e0f099ad',
      'share/locale/zh_TW/LC_MESSAGES/bison.mo' =>
        '7e2cc3dc0be83e5b11a326fe34af0a2d8dc25b8d1d355e17c3cd4e30a7610a09',
      'share/locale/zh_TW/LC_MESSAGES/bison-runtime.mo' =>
        'ad77162e7af5d6e2dcea61be45cce78bc168ed73a55ea94b02257102e6e2f6f3',
      'share/locale/lt/LC_MESSAGES/bison-runtime.mo' =>
        '889e5a62ca79b4b827eee358ebed36c744fc3b11a94febdd37eb782ef13173a1',
      'share/locale/ky/LC_MESSAGES/bison-runtime.mo' =>
        '0f2d83357aefc8913a2094c12f36191604be10bcda9002e64c7011c7c7b5c7b9',
      'share/locale/es/LC_MESSAGES/bison-runtime.mo' =>
        'fe946280e7b857c99428f3ee755711951775f18a052a3b0011b9dbab9ddef00b',
      'share/locale/es/LC_MESSAGES/bison.mo' =>
        '82e2ab64b731e89f78df3dc6c521f83448c60bfe786f500c201397331f3c787f',
      'share/locale/pl/LC_MESSAGES/bison-runtime.mo' =>
        '5b6f7f739acdeb6545175de6e415de06a95e795bb1d09e717bc0b32c07b154c4',
      'share/locale/pl/LC_MESSAGES/bison.mo' =>
        '1a97fceaf3dc88c322574e7aeda9081eef791d3baa7817fa6672b9399a86547f',
      'share/locale/ms/LC_MESSAGES/bison-runtime.mo' =>
        '91d4346da6113a5354eee8898d83ff3541825f9df0e4b6d1ec900ee7bc83dd2b',
      'share/locale/ms/LC_MESSAGES/bison.mo' =>
        'ddc1e23096c4570d2eaa5d96799bf9bad738d8f74025a4cdaec39b561a739420',
      'share/locale/ga/LC_MESSAGES/bison-runtime.mo' =>
        '482491c2140b18d58811439758f1339f8cfba78b9ae612be254e838ae95cff63',
      'share/locale/ga/LC_MESSAGES/bison.mo' =>
        'b946cef5fc419861a8c323d5ef679f467c718decd565c8b7344c115396316210',
      'share/locale/nb/LC_MESSAGES/bison.mo' =>
        '0c039008191e09741f1eb82aa027d6aec6f619e7e70a161b797f2104e4046ea7',
      'share/locale/nb/LC_MESSAGES/bison-runtime.mo' =>
        '326eeab5d17f73bf5d8667a9412fe438bd4fa2e29bce1e28f8323bcb6fdf4621',
      'share/locale/hr/LC_MESSAGES/bison-runtime.mo' =>
        '009a160814c1555a12b6c009005b6b3476debc7e9893557e21e52e68bf6664df',
      'share/locale/hr/LC_MESSAGES/bison.mo' =>
        '0d033692866daf0d350a1cc8eace7c7856e5e3dd90ab228cda48e6589bec0090',
      'share/locale/et/LC_MESSAGES/bison.mo' =>
        '52adc6c41e526577b5340d2aa7c8f875094f9f8d38e76e8dd000142ba5aed986',
      'share/locale/et/LC_MESSAGES/bison-runtime.mo' =>
        '2a5c122d78ff82f1e51eb967a1aa64f50771b30056b793c6ece861a67ccb87bd',
      'share/locale/ast/LC_MESSAGES/bison-runtime.mo' =>
        '532ccb1e2fdae4e8c286ef5ba3b2ba72c0edb19bedad3a5b2ab66c17d6c5ab16',
      'share/examples/bison/calc++/calc++-scanner.ll' =>
        '4782fb4235d0d906f79ab45e2a1df96e6336118baa7c4b5ba7295a3ed9c45486',
      'share/examples/bison/calc++/stack.hh' =>
        '50ca443459bef3d87c9f089004d4812bee02e09195d382f7b6908abff4864228',
      'share/examples/bison/calc++/calc++-parser.yy' =>
        '09145f3e8288774198cf8c58e9fb6135d5a32b6865ae91e7477c9d59acf51822',
      'share/examples/bison/calc++/position.hh' =>
        'b2d10af6292bc51d116afdcc486c216694e86086e512197ddd147a0e29418dc5',
      'share/examples/bison/calc++/calc++-parser.cc' =>
        '58d468d29dea5b91859b865c76f33023bc1297ed40bb7a2d81e26fdc69d11f10',
      'share/examples/bison/calc++/calc++-driver.hh' =>
        '5e7cbf439e5c4399ac017456ba20fe7d4b83ea8b3ca9c2bf4fc1f9307361a226',
      'share/examples/bison/calc++/calc++-driver.cc' =>
        '8d5bba3071d11112bc5fd1b6c5bd3254953a09902e7bc43b317e62f920ad905d',
      'share/examples/bison/calc++/calc++-parser.hh' =>
        '398a4731429100fc8744668153fff51736bb1f20bc26215b5a60568bf87b2eb7',
      'share/examples/bison/calc++/calc++-scanner.cc' =>
        'e78a2ecda21fb2f2a1f5ae4af63a73a7bba86a6b1646f80c70bb1b2e78013cc1',
      'share/examples/bison/calc++/location.hh' =>
        '44644e5a99fa5a2a7239540db82f2b162e838036bda03f0225d1a41482efed42',
      'share/examples/bison/calc++/calc++.cc' =>
        'd60dd212a976523beb8fbeece56d6065b9f353c6ce04489a783525fb752d3143',
      'info/bison.info' =>
        '3d2647edc8068a8c8c897f2e5200c39ca7bb0c4bceb2b92d613a72ce577a72e3',
      'man/man1/bison.1.gz' =>
        'c0a7682db655a4e838fa9d348af88747c55837b326cea9a5fbac7253217a73c3',
      'bin/bison' =>
        '75570662dc13ba088b7d3a4927aa2331647694f061a15cf19704e1f3fb9fc208'
      }

    Dir.chdir(basedir) do
      sha256s.each do |file, sha256|
        assert_equal sha256, Digest::SHA256.file(file).hexdigest
      end
    end


  end


  def test_info_bison

    expected = {
      'PATCH_NAME' => 'bison',
      'DESCRIPTION' => 'An example for test',
      'PREFIX' => '/usr/local',
      'VERSION' => '2.4.3',
      'MYVAR' => 'MYVALUE',
    }

    Dir.chdir(File.join(PATH_CURRENT_DIR, 'tc_patchbuilder')) do
      PatchBuilder.build(%w(autoconf bison_no_output),
                         File.join(@tmpdir, 'bison_autoconf.zip'),
                         {variables: @initial_vars, quiet: true}
                        )
    end

    bison_243_patch = PackagedPatch.new(
      File.join(@tmpdir, 'bison_autoconf.zip'), 'bison', '2.4.3'
    )


    assert_equal expected, bison_243_patch.info

  end

  def test_info_autoconf

    Dir.chdir(File.join(PATH_CURRENT_DIR, 'tc_patchbuilder')) do
      PatchBuilder.build(%w(autoconf bison_no_output),
                         File.join(@tmpdir, 'bison_autoconf.zip'),
                         {variables: @initial_vars, quiet: true}
                        )
    end

    expected = {
      'PATCH_NAME' => 'autoconf',
      'DESCRIPTION' => 'An example for test',
      'VERSION' => '2.a.0',
      'NEED_SUPERUSER' => 'YES',
      'INTERPRETER' => '/bin/sh',
      'INTERPRETER_FLAGS' => '-x',
      'PREFIX' => '/usr',
      'MYVAR' => 'MYVALUE',
    }


    autoconf_2a0_patch = PackagedPatch.new(
      File.join(@tmpdir, 'bison_autoconf.zip'), 'autoconf', '2.a.0'
    )

    assert_equal expected, autoconf_2a0_patch.info

  end


  def test_check_integrity

    Dir.chdir(File.join(PATH_CURRENT_DIR, 'tc_patchbuilder')) do
      PatchBuilder.build(%w(autoconf bison_no_output),
                         File.join(@tmpdir, 'bison_autoconf.zip'),
                         {variables: @initial_vars, quiet: true}
                        )
    end

    bison_243_patch = PackagedPatch.new(
      File.join(@tmpdir, 'bison_autoconf.zip'), 'bison', '2.4.3'
    )
    autoconf_2a0_patch = PackagedPatch.new(
      File.join(@tmpdir, 'bison_autoconf.zip'), 'autoconf', '2.a.0'
    )

    assert_nothing_raised{bison_243_patch.check_integrity}
    assert_nothing_raised{autoconf_2a0_patch.check_integrity}
  end


  def test_extract_file

    Dir.chdir(File.join(PATH_CURRENT_DIR, 'tc_patchbuilder')) do
      PatchBuilder.build(%w(autoconf bison_no_output),
                         File.join(@tmpdir, 'bison_autoconf.zip'),
                         {variables: @initial_vars, quiet: true}
                        )
    end

    bison_243_patch = PackagedPatch.new(
      File.join(@tmpdir, 'bison_autoconf.zip'), 'bison', '2.4.3'
    )

    Tempfile.open('stack.hh') do |tmp|
      bison_243_patch.extract_file('share/examples/bison/calc++/stack.hh', tmp)
      tmp.close

      assert_equal \
        '50ca443459bef3d87c9f089004d4812bee02e09195d382f7b6908abff4864228',
        Digest::SHA256.file(tmp).hexdigest
    end


    assert_raise(FileNotExist) do
      bison_243_patch.extract_file('weird_file_not_in_schema')
    end

    assert_nothing_raised do
      Tempfile.open('bison-runtime.mo') do |tmp|

        bison_243_patch.extract_file(
          'share/locale/ast/LC_MESSAGES/bison-runtime.mo',
          tmp
        )

        tmp.close

        assert_equal(
          '532ccb1e2fdae4e8c286ef5ba3b2ba72c0edb19bedad3a5b2ab66c17d6c5ab16',
          Digest::SHA256.file(tmp).hexdigest
        )
      end
    end

  end


  def test_entry_not_exist

    Dir.chdir(File.join(PATH_CURRENT_DIR, 'tc_patchbuilder')) do
      PatchBuilder.build(%w(autoconf bison_no_output),
                         File.join(@tmpdir, 'bison_autoconf.zip'),
                         {variables: @initial_vars, quiet: true}
                        )
    end

    bison_243_patch = PackagedPatch.new(
      File.join(@tmpdir, 'bison_autoconf.zip'), 'bison', '2.4.3'
    )

    # eliminamos una entrada del zip
    bison_243_patch.container.remove(
      File.join(
        Clame::PatchBuilder::INSTALL_DIR,
        '6495cea340183c36fd1dee05397c1386796a2225c5af2dbba2f0f72fc558f685')
    )

    assert_raise(ContainerEntryNotExist) do
      bison_243_patch.check_integrity
    end

  end

  def test_invalid_entry


    Dir.chdir(File.join(PATH_CURRENT_DIR, 'tc_patchbuilder')) do
      PatchBuilder.build(%w(autoconf bison_no_output),
                         File.join(@tmpdir, 'bison_autoconf.zip'),
                         {variables: @initial_vars, quiet: true}
                        )
    end

    autoconf_2a0_patch = PackagedPatch.new(
      File.join(@tmpdir, 'bison_autoconf.zip'), 'autoconf', '2.a.0'
    )
    # añadimos una fila rara al contents
    new_contents =
      autoconf_2a0_patch.container.get_input_stream(
        File.join(
          PatchBuilder::BASE_PATCHES,
          'autoconf', '2.a.0', PatchBuilder::CONTENTS_FILE
        )
      ){|f| f.read << File.join(PatchBuilder::INSTALL_DIR, 'invalid_entry')}

    autoconf_2a0_patch.container.get_output_stream(
      File.join(
        PatchBuilder::BASE_PATCHES, 'autoconf', '2.a.0',
        PatchBuilder::CONTENTS_FILE
      )
    ){|f| f.puts new_contents}

    assert_raise(InvalidContainerEntry) do
      autoconf_2a0_patch.check_integrity
    end

  end


  def test_integrity_check_fail

    Dir.chdir(File.join(PATH_CURRENT_DIR, 'tc_patchbuilder')) do
      PatchBuilder.build(%w(autoconf bison_no_output),
                         File.join(@tmpdir, 'bison_autoconf.zip'),
                         {variables: @initial_vars, quiet: true}
                        )
    end

    bison_243_patch = PackagedPatch.new(
      File.join(@tmpdir, 'bison_autoconf.zip'), 'bison', '2.4.3'
    )

    # modificamos una de las entradas a instalar, para que el hash no coincida
    bison_243_patch.container.get_output_stream(
      File.join(
        PatchBuilder::INSTALL_DIR,
        '3d2647edc8068a8c8c897f2e5200c39ca7bb0c4bceb2b92d613a72ce577a72e3')
    ){|f| f.puts 'new content'}

    bison_243_patch.container.commit if bison_243_patch.container.commit_required?

    assert_raise(IntegrityCheckFail) do
      bison_243_patch.check_integrity
    end

  end


  def test_check_size_by_fs

    Dir.chdir(File.join(PATH_CURRENT_DIR, 'tc_patchbuilder')) do
      PatchBuilder.build(%w(autoconf bison_no_output),
                         File.join(@tmpdir, 'bison_autoconf.zip'),
                         {variables: @initial_vars, quiet: true}
                        )
    end

    bison_243_patch = PackagedPatch.new(
      File.join(@tmpdir, 'bison_autoconf.zip'), 'bison', '2.4.3'
    )

    # mounted_fs tiene que ordenarse en modo inverso por profundidad
    Fs.mounted_fs = %w(/usr/local /usr /)

    Fs.free_space = {'/' => 1709, '/usr' => 1706, '/usr/local' => 1706}
    assert_nothing_raised{bison_243_patch.check_size_by_fs}
    assert_nothing_raised{bison_243_patch.check_size_by_fs('/usr/local')}
    assert_nothing_raised{bison_243_patch.check_size_by_fs('/usr')}
    assert_nothing_raised{bison_243_patch.check_size_by_fs('/')}

    Fs.free_space = ({'/' => 1708, '/usr' => 1705, '/usr/local' => 1705})
    assert_raise(NotEnoughFsFreeSpace) do
      bison_243_patch.check_size_by_fs
    end
    assert_raise(NotEnoughFsFreeSpace) do
      bison_243_patch.check_size_by_fs('/usr')
    end
    assert_raise(NotEnoughFsFreeSpace) do
      bison_243_patch.check_size_by_fs('/')
    end

  end


  def test_check_user_and_groups

    Dir.chdir(File.join(PATH_CURRENT_DIR, 'tc_patchbuilder')) do
      PatchBuilder.build(%w(autoconf bison_no_output),
                         File.join(@tmpdir, 'bison_autoconf.zip'),
                         {variables: @initial_vars, quiet: true}
                        )
    end

    bison_243_patch = PackagedPatch.new(
      File.join(@tmpdir, 'bison_autoconf.zip'), 'bison', '2.4.3'
    )
    assert_nothing_raised{bison_243_patch.check_user_and_groups}

    # invalid default owner
    Dir.chdir(File.join(PATH_CURRENT_DIR, 'tc_patchbuilder')) do
      PatchBuilder.build(%w(bison_invalid_def_owner),
                         File.join(@tmpdir, 'bison_invalid_def_owner.zip'),
                        )
    end
    bison_invalid_def_owner = PackagedPatch.new(
      File.join(@tmpdir, 'bison_invalid_def_owner.zip'), 'bison', '2.4.3'
    )
    assert_raise(DefaultUserNotExists) do
      bison_invalid_def_owner.check_user_and_groups
    end

    # invalid default group
    Dir.chdir(File.join(PATH_CURRENT_DIR, 'tc_patchbuilder')) do
      PatchBuilder.build(%w(bison_invalid_def_group),
                         File.join(@tmpdir, 'bison_invalid_def_group.zip'),
                        )
    end
    bison_invalid_def_group = PackagedPatch.new(
      File.join(@tmpdir, 'bison_invalid_def_group.zip'), 'bison', '2.4.3'
    )
    assert_raise(DefaultGroupNotExists) do
      bison_invalid_def_group.check_user_and_groups
    end

    # invalid user
    Dir.chdir(File.join(PATH_CURRENT_DIR, 'tc_patchbuilder')) do
      PatchBuilder.build(%w(bison_invalid_user),
                         File.join(@tmpdir, 'bison_invalid_user.zip'),
                        )
    end
    bison_invalid_user = PackagedPatch.new(
      File.join(@tmpdir, 'bison_invalid_user.zip'), 'bison', '2.4.3'
    )
    assert_raise(UserNotExists) do
      bison_invalid_user.check_user_and_groups
    end

    # invalid group
    Dir.chdir(File.join(PATH_CURRENT_DIR, 'tc_patchbuilder')) do
      PatchBuilder.build(%w(bison_invalid_group),
                         File.join(@tmpdir, 'bison_invalid_group.zip'),
                        )
    end
    bison_invalid_group = PackagedPatch.new(
      File.join(@tmpdir, 'bison_invalid_group.zip'), 'bison', '2.4.3'
    )
    assert_raise(GroupNotExists) do
      bison_invalid_group.check_user_and_groups
    end
  end


  def test_check_patch_already_installed

    Dir.chdir(File.join(PATH_CURRENT_DIR, 'tc_patchbuilder')) do
      PatchBuilder.build(%w(autoconf bison_no_output),
                         File.join(@tmpdir, 'bison_autoconf.zip'),
                         {variables: @initial_vars, quiet: true}
                        )
    end

    basedir = File.join(@tmpdir, 'basedir')
    Dir.mkdir basedir

    bison_243_patch = PackagedPatch.new(
      File.join(@tmpdir, 'bison_autoconf.zip'), 'bison', '2.4.3',
      {prefix: basedir, ignore_reqs: true}
    )

    # La primera vez que se instala el parche, no puede estar registrado
    assert_nothing_raised{bison_243_patch.install}

    # Instalamos una segunda vez. El parche ya está registrado
    bison_243_patch = PackagedPatch.new(
      File.join(@tmpdir, 'bison_autoconf.zip'), 'bison', '2.4.3',
      {prefix: basedir}
    )
    assert_raise(PatchAlreadyInstalled) do
      bison_243_patch.install
    end

  end


  def test_check_max_version_installed

    Dir.chdir(File.join(PATH_CURRENT_DIR, 'tc_patchbuilder')) do
      PatchBuilder.build(%w(autoconf bison_no_output),
                         File.join(@tmpdir, 'bison_autoconf.zip'),
                         {variables: @initial_vars, quiet: true}
                        )
    end

    basedir = File.join(@tmpdir, 'basedir')
    Dir.mkdir basedir
    bison_243_patch = PackagedPatch.new(
      File.join(@tmpdir, 'bison_autoconf.zip'), 'bison', '2.4.3',
      {prefix: basedir, ignore_reqs: true}
    )


    # Instalamos el parche, ignorando requisitos
    bison_243_patch.install

    # Intentamos instalar una versión inferior
    Dir.chdir(File.join(PATH_CURRENT_DIR, 'tc_patchbuilder')) do
      PatchBuilder.build(%w(bison_242), File.join(@tmpdir, 'bison_242.zip'))
    end

    bison_242_patch = PackagedPatch.new(
      File.join(@tmpdir, 'bison_242.zip'), 'bison', '2.4.2', {prefix: basedir}
    )

    assert_raise(HigherPatchVersionInstalled) do
      bison_242_patch.install
    end

    # Intentamos instalar una versión inferior, pero esta vez ignorando los
    # requisitos.
    bison_242_patch = PackagedPatch.new(
      File.join(@tmpdir, 'bison_242.zip'), 'bison', '2.4.2',
      {prefix: basedir, ignore_hvers: true, ignore_reqs: true}
    )
    assert_nothing_raised{bison_242_patch.install}

    # Intentamos instalar una versión superior, y en este caso no se puede
    # producir un error
    Dir.chdir(File.join(PATH_CURRENT_DIR, 'tc_patchbuilder')) do
      PatchBuilder.build(%w(bison_244), File.join(@tmpdir, 'bison_244.zip'))
    end

    bison_244_patch = PackagedPatch.new(
      File.join(@tmpdir, 'bison_244.zip'), 'bison', '2.4.4', {prefix: basedir}
    )
    assert_nothing_raised{bison_244_patch.install}

  end


  def test_check_requirements

    basedir = File.join(@tmpdir, 'basedir')
    Dir.mkdir basedir

    # Instalamos foo, versión 2.3.4. Las dependencias no se satisfacen
    Dir.chdir(File.join(PATH_CURRENT_DIR, 'tc_patchbuilder')) do
      PatchBuilder.build(%w(foo_234), File.join(@tmpdir, 'foo_234.zip'))
    end

    foo_234_patch = PackagedPatch.new(
      File.join(@tmpdir, 'foo_234.zip'), 'foo', '2.3.4', {prefix: basedir}
    )
    assert_raise(RequirementsNotSatisfied) do
      foo_234_patch.install
    end

    # Instalamos bar, versión 7.6. Las dependencias no se satisfacen
    Dir.chdir(File.join(PATH_CURRENT_DIR, 'tc_patchbuilder')) do
      PatchBuilder.build(%w(bar_76), File.join(@tmpdir, 'bar_76.zip'))
    end

    bar_76_patch = PackagedPatch.new(
      File.join(@tmpdir, 'bar_76.zip'), 'bar', '7.6', {prefix: basedir}
    )
    assert_nothing_raised{bar_76_patch.install}
    assert_raise(RequirementsNotSatisfied) do
      foo_234_patch.install
    end

    # Instalamos tee, versión 8.9.a. Las dependencias SI se satisfacen
    Dir.chdir(File.join(PATH_CURRENT_DIR, 'tc_patchbuilder')) do
      PatchBuilder.build(%w(tee_89a), File.join(@tmpdir, 'tee_89a.zip'))
    end

    tee_89a_patch = PackagedPatch.new(
      File.join(@tmpdir, 'tee_89a.zip'), 'tee', '8.9.a', {prefix: basedir}
    )
    assert_nothing_raised{tee_89a_patch.install}
    assert_nothing_raised{foo_234_patch.install}
  end


  def test_register_requeriments

    basedir = File.join(@tmpdir, 'basedir')
    Dir.mkdir basedir

    # foo 2.3.4
    Dir.chdir(File.join(PATH_CURRENT_DIR, 'tc_patchbuilder')) do
      PatchBuilder.build(%w(foo_234), File.join(@tmpdir, 'foo_234.zip'))
    end

    # bar 7.6
    Dir.chdir(File.join(PATH_CURRENT_DIR, 'tc_patchbuilder')) do
      PatchBuilder.build(%w(bar_76), File.join(@tmpdir, 'bar_76.zip'))
    end

    # tee 8.9.a
    Dir.chdir(File.join(PATH_CURRENT_DIR, 'tc_patchbuilder')) do
      PatchBuilder.build(%w(tee_89a), File.join(@tmpdir, 'tee_89a.zip'))
    end

    foo_234_patch = PackagedPatch.new(
      File.join(@tmpdir, 'foo_234.zip'), 'foo', '2.3.4', {prefix: basedir}
    )

    bar_76_patch = PackagedPatch.new(
      File.join(@tmpdir, 'bar_76.zip'), 'bar', '7.6', {prefix: basedir}
    )

    tee_89a_patch = PackagedPatch.new(
      File.join(@tmpdir, 'tee_89a.zip'), 'tee', '8.9.a', {prefix: basedir}
    )

    bar_76_patch.install
    tee_89a_patch.install
    foo_234_patch.install

    # Comprobamos los que los requisitos de foo_234 son:
    # R bar >= 7.6
    # R bar < 7.8
    # R bar != 7.7
    # R tee == 8.9.a
    req_bar_1 = Interval.new('>=', PatchVersion.new('bar', '7.6'))
    req_bar_2 = Interval.new('<', PatchVersion.new('bar', '7.8'))
    req_bar_3 = Interval.new('!=', PatchVersion.new('bar', '7.7'))
    req_tee_1 = Interval.new('==', PatchVersion.new('tee', '8.9.a'))


    expected = [req_bar_1, req_bar_2, req_bar_3, req_tee_1].to_set

    assert_equal(
      expected,
      Clame.database.get_requisites('foo', '2.3.4').to_set
    )

  end


  def test_check_conflicts_1

    basedir = File.join(@tmpdir, 'basedir')
    Dir.mkdir basedir

    # Instalamos foo, versión 4.0.1.
    Dir.chdir(File.join(PATH_CURRENT_DIR, 'tc_patchbuilder')) do
      PatchBuilder.build(%w(foo_401), File.join(@tmpdir, 'foo_401.zip'))
    end

    foo_401_patch = PackagedPatch.new(
      File.join(@tmpdir, 'foo_401.zip'), 'foo', '4.0.1'
    )

    # Instalamos bar, versión 9.5. No hay conflictos
    Dir.chdir(File.join(PATH_CURRENT_DIR, 'tc_patchbuilder')) do
      PatchBuilder.build(%w(bar_95), File.join(@tmpdir, 'bar_95.zip'))
    end

    bar_95_patch = PackagedPatch.new(
      File.join(@tmpdir, 'bar_95.zip'), 'bar', '9.5', {prefix: basedir}
    )
    assert_nothing_raised{bar_95_patch.install}
    assert_nothing_raised{foo_401_patch.install}
  end


  def test_check_conflicts_2

    basedir = File.join(@tmpdir, 'basedir')
    Dir.mkdir basedir

    # Instalamos foo, versión 4.0.1.
    Dir.chdir(File.join(PATH_CURRENT_DIR, 'tc_patchbuilder')) do
      PatchBuilder.build(%w(foo_401), File.join(@tmpdir, 'foo_401.zip'))
    end

    foo_401_patch = PackagedPatch.new(
      File.join(@tmpdir, 'foo_401.zip'), 'foo', '4.0.1', {prefix: basedir}
    )

    # Instalamos bar, versión 9.4
    Dir.chdir(File.join(PATH_CURRENT_DIR, 'tc_patchbuilder')) do
      PatchBuilder.build(%w(bar_94), File.join(@tmpdir, 'bar_94.zip'))
    end

    bar_94_patch = PackagedPatch.new(
      File.join(@tmpdir, 'bar_94.zip'), 'bar', '9.4', {prefix: basedir}
    )
    assert_nothing_raised{bar_94_patch.install}
    # Instalamos bar, versión 9.6
    Dir.chdir(File.join(PATH_CURRENT_DIR, 'tc_patchbuilder')) do
      PatchBuilder.build(%w(bar_96), File.join(@tmpdir, 'bar_96.zip'))
    end

    bar_96_patch = PackagedPatch.new(
      File.join(@tmpdir, 'bar_96.zip'), 'bar', '9.6', {prefix: basedir}
    )
    assert_nothing_raised{bar_96_patch.install}

    # Instalamos tee, versión 7.1
    Dir.chdir(File.join(PATH_CURRENT_DIR, 'tc_patchbuilder')) do
      PatchBuilder.build(%w(tee_71), File.join(@tmpdir, 'tee_71.zip'))
    end

    tee_71_patch = PackagedPatch.new(
      File.join(@tmpdir, 'tee_71.zip'), 'tee', '7.1', {prefix: basedir}
    )
    assert_nothing_raised{tee_71_patch.install}

    # Instalamos foo 4.0.1. Aparecen conflictos
    assert_raise(InstalledConflicts){foo_401_patch.install}

  end


  def test_check_installed_conflicts

    basedir = File.join(@tmpdir, 'basedir')
    Dir.mkdir basedir

    # bar 7.5
    Dir.chdir(File.join(PATH_CURRENT_DIR, 'tc_patchbuilder')) do
      PatchBuilder.build(%w(bar_75), File.join(@tmpdir, 'bar_75.zip'))
    end

    # tee 9.0
    Dir.chdir(File.join(PATH_CURRENT_DIR, 'tc_patchbuilder')) do
      PatchBuilder.build(%w(tee_90), File.join(@tmpdir, 'tee_90.zip'))
    end

    # foo 2.3.5
    Dir.chdir(File.join(PATH_CURRENT_DIR, 'tc_patchbuilder')) do
      PatchBuilder.build(%w(foo_235), File.join(@tmpdir, 'foo_235.zip'))
    end

    bar_75_patch = PackagedPatch.new(
      File.join(@tmpdir, 'bar_75.zip'), 'bar', '7.5', {prefix: basedir}
    )
    tee_90_patch = PackagedPatch.new(
      File.join(@tmpdir, 'tee_90.zip'), 'tee', '9.0', {prefix: basedir}
    )
    foo_235_patch = PackagedPatch.new(
      File.join(@tmpdir, 'foo_235.zip'), 'foo', '2.3.5', {prefix: basedir}
    )

    assert_nothing_raised{foo_235_patch.install}
    assert_raise(InstallWouldConflict){bar_75_patch.install}
    assert_raise(InstallWouldConflict){tee_90_patch.install}

    tee_90_patch = PackagedPatch.new(
      File.join(@tmpdir, 'tee_90.zip'), 'tee', '9.0',
      {prefix: basedir, ignore_installed_conflicts: true}
    )
    assert_nothing_raised{tee_90_patch.install}

  end


  def test_register_conflicts

    basedir = File.join(@tmpdir, 'basedir')
    Dir.mkdir basedir

    # foo 2.3.5
    Dir.chdir(File.join(PATH_CURRENT_DIR, 'tc_patchbuilder')) do
      PatchBuilder.build(%w(foo_235), File.join(@tmpdir, 'foo_235.zip'))
    end

    foo_235_patch = PackagedPatch.new(
      File.join(@tmpdir, 'foo_235.zip'), 'foo', '2.3.5', {prefix: basedir}
    )

    assert_nothing_raised{foo_235_patch.install}

    conf_bar = Interval.new('<', PatchVersion.new('bar', '7.6'))
    conf_tee = Interval.new('==', PatchVersion.new('tee', '9.0'))

    expected = [conf_bar, conf_tee].to_set

    assert_equal(
      expected,
      Clame.database.get_conflicts('foo', '2.3.5').to_set
    )
  end


  def test_register_install_scripts

    basedir = File.join(@tmpdir, 'basedir')
    Dir.mkdir basedir

    # bison
    Dir.chdir(File.join(PATH_CURRENT_DIR, 'tc_patchbuilder')) do
      PatchBuilder.build(%w(bison_register_script),
                         File.join(@tmpdir, 'bison_register_script.zip'))
    end

    bison = PackagedPatch.new(
      File.join(@tmpdir, 'bison_register_script.zip'), 'bison', '2.4.3',
      {prefix: basedir, ignore_reqs: true}
    )
    bison.install

    expected_postinstall = "echo \"Instalando\" > /dev/null\n"
    expected_postremove = "echo \"Desinstalando\"\n"

    assert_equal(
      expected_postinstall,
      Clame.database.get_install_script('bison', '2.4.3', 'postinstall')
    )
    assert_equal(
      expected_postremove,
      Clame.database.get_install_script('bison', '2.4.3', 'postremove')
    )

  end



  def test_enviroment_postinstall

    basedir = File.join(@tmpdir, 'basedir')
    Dir.mkdir basedir

    Dir.chdir(File.join(PATH_CURRENT_DIR, 'tc_patchbuilder')) do
      PatchBuilder.build(%w(foo_402),
                         File.join(@tmpdir, 'foo_402.zip'),
                         {variables: @initial_vars, quiet: true}
                        )
    end

    foo_402 = PackagedPatch.new(
      File.join(@tmpdir, 'foo_402.zip'), 'foo', '4.0.2',
      {prefix: basedir, ignore_reqs: true}
    )

    IO.popen('-', 'w') do |pipe|
      if pipe
        pipe.puts "NORMAL_VAR1"
        pipe.puts "n"
        pipe.puts "y"
      else
        $stdout.reopen File::NULL
        foo_402.install
        # para que elimine ficheros temporales.
        GC.start
      end
    end

    assert $?.exitstatus.zero?, "Error #{$?.exitstatus}"

  end

  def test_input_vars

    basedir = File.join(@tmpdir, 'basedir')
    Dir.mkdir basedir

    Dir.chdir(File.join(PATH_CURRENT_DIR, 'tc_patchbuilder')) do
      PatchBuilder.build(%w(foo_404),
                         File.join(@tmpdir, 'foo_404.zip'),
                         {variables: @initial_vars, quiet: true}
                        )
    end

    foo_404 = PackagedPatch.new(
      File.join(@tmpdir, 'foo_404.zip'), 'foo', '4.0.4',
      {prefix: basedir, ignore_reqs: true}
    )

    IO.popen('-', 'w') do |pipe|
      if pipe
        pipe.puts "NORMAL_VAR1"
        pipe.puts "n"
        pipe.puts "y"
      else
        $stdout.reopen File::NULL
        foo_404.install

        expected = {
          'NORMAL_VAR1' => 'NORMAL_VAR1',
          'BOOL_VAR1' => nil,
          'BOOL_VAR2' => 'true',
        }

        Clame.database.get_input_vars(
          'foo', '4.0.4'
        ).each do |res|
          assert_equal expected[res['var_name']], res['var_value']
        end
      end
    end

    assert $?.exitstatus.zero?, "Error #{$?.exitstatus}"

  end


  def test_checkinstall_vars

    basedir = File.join(@tmpdir, 'basedir')
    Dir.mkdir basedir

    Dir.chdir(File.join(PATH_CURRENT_DIR, 'tc_patchbuilder')) do
      PatchBuilder.build(%w(foo_403),
                         File.join(@tmpdir, 'foo_403.zip'),
                         {variables: @initial_vars, quiet: true}
                        )
    end

    foo_403 = PackagedPatch.new(
      File.join(@tmpdir, 'foo_403.zip'), 'foo', '4.0.3',
      {prefix: basedir, ignore_reqs: true}
    )

    fork do
      $stdout.reopen File::NULL
      foo_403.install
    end

    Process.wait

    assert $?.exitstatus.zero?, "Error #{$?.exitstatus}"

  end

  def test_info_vars

    basedir = File.join(@tmpdir, 'basedir')
    Dir.mkdir basedir

    Dir.chdir(File.join(PATH_CURRENT_DIR, 'tc_patchbuilder')) do
      PatchBuilder.build(%w(foo_403),
                         File.join(@tmpdir, 'foo_403.zip'),
                         {variables: @initial_vars, quiet: true}
                        )
    end

    foo_403 = PackagedPatch.new(
      File.join(@tmpdir, 'foo_403.zip'), 'foo', '4.0.3',
      {prefix: basedir, ignore_reqs: true}
    )

    fork do
      $stdout.reopen File::NULL
      foo_403.install
    end

    Process.wait

    expected = {
      'PATCH_NAME' => 'foo',
      'DESCRIPTION' => 'An example for test',
      'VERSION' => '4.0.3',
      'NEED_SUPERUSER' => 'YES',
      'INTERPRETER' => '/usr/bin/env',
      'INTERPRETER_FLAGS' => 'ruby',
      'PREFIX' => '/usr',
      'PATH' => '/bin:/usr/bin:/usr/local/bin',
      'MYVAR' => 'MYVALUE',
    }

    Clame.database.get_info_vars(
      'foo', '4.0.3'
    ).each do |res|
      assert_equal expected[res['var_name']], res['var_value']
    end

  end


  def test_invalid_patch_name_cmd_line
    Dir.chdir(File.join(PATH_CURRENT_DIR, 'tc_patchbuilder')) do
      PatchBuilder.build(%w(bison_no_output),
                         File.join(@tmpdir, 'bison_no_output.zip'),
                         {variables: @initial_vars, quiet: true}
                        )
    end

    clame_bin = PATH_CURRENT_DIR.parent.join('bin', 'clame')

    env = {'RUBYLIB' => LIB_CLAME_DIR}

    fork do
      exec(env, clame_bin.to_s, 'install',
           File.join(@tmpdir, 'bison_no_output.zip'),
           'patch_nonexist', :out => File::NULL, :err => File::NULL)
    end

    Process.wait
    # asegurarse de que tira el error 156 (PatchNameNotExistInZip)
    assert ($?.exited? && $?.exitstatus == 156),
      "Código de salida incorrecto: #{$?}"

  end


end

