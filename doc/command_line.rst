.. highlight:: none

Command line
******************

General clame usage
===================

.. code-block:: console

    Usage: clame [-d] action [options] ...
        clame [-hv]

    action: build, install, remove. Type 'clame action' to inspect actions sipnosis
        -d, --[no-]debug                 Enable debug messages in log file
        -h, --help                       Show this message.
        -v, --version                    Show version.
    


``-d``
    Enable full debug. It has the same effect as setting ``:log_severity =>
    Logger::DEBUG``. See :ref:`log-severity`.

``-v``
    Shows the current clame version.




clame build
===========

.. code-block:: console

    Usage: clame build [-v VARNAME="value" ...] [-qfh] <dir ...> <zip_output>
    dir: Directory where the patches build files are located. Mandatory.
    zip_output: Output file. Mandatory.

    Allowed flags:
        -v, --variable VARNAME="value"   Set this info variable VARNAME to value. VARNAME must be upper case.
        -f, --[no-]force                 Reuse output zip file if exists.
        -i, --[no-]ignore-miss-prefix    Ignore errors about relative paths but missing PREFIX.
        -q, --[no-]quiet                 Quiet.
        -h, --help                       Show this message.




Build one or several clame patches placed in ``<dir>``. Output zip is
``<zip_output>``. You can specify one or more ``<dir>`` by using shell
patterns. Examples:

.. code-block:: console

    $ clame build clame/foo/* /tmp/foo.zip
    $ clame build clame/foo/1.0 /tmp/foo-1.0.zip
    $ clame build clame/foo/1.0 clame/bar/2.3  /tmp/foo_bar-1.0.zip

It is possible to set info variables with ``--variable|-v`` flag, and thus it
would be possible to avoid to write an ``info`` file:

.. code-block:: console

    $ clame build -v PATCH_NAME="foo" -v VERSION="1.0" INTERPRETER="/bin/bash"  clame/foo/1.0 /tmp/foo-1.0.zip

Output zip can be overwritten when setting the ``--force`` flag.

When you build a patch with some relative path in the schema, clame needs the
``PREFIX`` info variable. Really, it is needed at install stage, but clame
warns you at build stage and will fails if you do not set it. You avoid such
error by setting ``--ignore-miss-prefix|-i`` flag.



clame install
=============

.. code-block:: console

    Usage: clame install [-p PREFIX] [-s paths] [-hrcvgq] <zip_path> [patch_name [version]]
    zip_path: Zip package file. Mandatory.
    patch_name: Patch name. If empty, install the whole of contained patches in zip_path.
    version: Patch version. If empty, install the whole of contained versions of patch_name.

    Allowed flags:
        -p, --prefix PREFIX                   Installation prefix (overwrites info PREFIX variable).
        -r, --[no-]ignore-reqs                Ignore requisites set in depend file.
        -c, --[no-]ignore-conflicts           Ignore conflicts set in depend file.
        -v, --[no-]ignore-higher-versions     Ignore already installed higher versions.
        -g, --[no-]ignore-inst-conflics       Ignore already installed conflicts.
        -s, --ignore-paths <P1>[,P2,...,PN]   Do not backup the specified files.
        -f, --[no-]force                      Do not make any validation (not recommended)
        -q, --[no-]quiet                      Quiet.
            --[no-]prompt                     Do not ask for confirmation.
        -h, --help                            Show this message.


Install one or several patches contained in the clame zip file ``<zip_path>``.
If you leave out ``patch_name`` and ``version``, the whole of patches contained
will install. If you leave out only ``version``, the whole of patches of
``patch_name`` name will install. Examples:


.. code-block:: console

    $ clame install /tmp/foo_bar.zip
    $ clame install /tmp/foo_bar.zip foo # restricted to foo patches
    $ clame install /tmp/foo_bar.zip bar 1.0 # only install bar 1.0 patch

The ``--prefix|p`` flag allow to overwrite the ``PREFIX`` info variable:


.. code-block:: console

    $ clame --prefix /opt/foo install /tmp/foo_bar.zip foo 1.0

With ``--ignore-reqs|-r`` flag, clame does not check the requisites pointed out
in depend file.

With ``--ignore-conflicts|-c`` flag, clame does not check the conflicts pointed
out in depend file.

With ``--ignore-higher-version|-v`` flag, clame does not check if the version
to be installed is the highest of the already installed patch.

With ``--ignore-inst-conflics|g`` flag, clame does not check if this patch
installation may conflict with other already installed.

Usually, clame backups any file that the patch installation overwrites. But is
possible to indicate some specific paths that clame will overwrite without
backup the file (``--ignore-paths|s``). The paths are required to be comma
separated, and therefore shell pattern will not work. Examples:

.. code-block:: console

    $ clame install -s /opt/foo/bin/huge_file,/opt/foo/share/big_file /tmp/foo_bar.zip foo 1.0


The ``--force|-f`` flag instructs to clame to do not check the following (see
:ref:`initial-checks`):

* ``PREFIX`` base directory exists
* Integrity of zip file
* Room enough to install the patch
* Room enough to save the overwritten files
* Current version is the highest



The ``--no-prompt`` flag instructs to clame do not request confirmation in
several stages. It will assume *yes* always.

The ``--quiet|q`` flag instructs to clame to do not show any output, and
implies ``--no-prompt``. Clame will show only errors.


clame remove
============

.. code-block:: console

    Usage: clame remove [-rvau] <patch_name> <version>
    patch_name: Patch name. Mandatory.
    version: Patch version. Mandatory.

    Allowed flags:
        -r, --[no-]ignore-reqs                Do not check if the uninstallation would break some dependency
        -v, --[no-]ignore-higher-version      Do not check if there are higher versions installed
        -a, --[no-]abort-on-restore           Do not abort if ocurrs some restoration error
        -u, --[no-]ignore-unmatching-uids     Ignore if the installation user is not the same as the uninstallation one
        -h, --help                            Show this message.


Uninstall the patch specified by ``patch_name`` and ``version``. It is not
possible to uninstall several patches with an unique call. Examples:

.. code-block:: console

    $ clame remove foo 1.0
    $ clame remove bar 3.3

The ``--ignore-reqs|-r`` flag instructs to clame to do not check if the
uninstallation break some dependency. For example, if *foo 1.0* depends on *bar
3.1*, and both are installed, ``clame remove foo 1.0`` will fails, but
``clame remove -r foo 1.0`` will go ahead. 


The ``--ignore-higher-version|-v`` flag instructs to clame to do not check if
there are higher version of ``patch, version`` installed. For example, if *foo
1.0* and *foo 1.2* are both installed, ``clame remove foo 1.0`` will fails, but
``clame remove -v foo 1.0`` will go ahead.

The ``--abort-on-restore|-a`` flags instructs to clame to ignore any error
happened in the restoration stage.

The ``--ignore--unmatching-uids|-u`` flag instructs to clame to do not check if
the user currently uninstalling the patch is the same user as installed it. See 
:ref:`initial-checks-uninstall`.





