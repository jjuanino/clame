.. highlight:: none

Installing patches
******************

After you are built a patch, the contents is packaged in a zip file. This file
contains all the instructions needed to install the patch or patches it keeps,
with no other dependency. In short, it contains the regular files specified in
the schema, and a bunch of other marshaled ruby objects.

Then next sections explain in detail the instalation process.

Command line
============
To install one o more patches contained in a clame zip file, run ``clame
install``. To inspect the patches and versions contained, just run:

.. code-block:: console

    # clame install foo_bar.zip

Clame shows the patches and versions to be installed, and request to you to
confirm:

.. code-block:: console

    $ clame install foo_bar.zip
    => The following patches & versions will be installed:
            Patch name: (foo), Version: (1.1)
            Patch name: (bar), Version: (1.a)
            Patch name: (bar), Version: (1.b)
    Do you want to continue?(y/n) n

If you are interested in a specific patch and version, specify it at end of the
command line:
    
.. code-block:: console

    $ clame install foo_bar.zip foo 1.1
    
If you need to install all the *bar* versions, leave out the version:

.. code-block:: console

    $ clame install foo_bar.zip bar
    => The following patches & versions will be installed:
            Patch name: (bar), Version: (1.b)
    Do you want to continue?(y/n) n

.. _initial-checks:

Initial checks
==============
Once clame knows the patch and version to install, performs several basic
checks.

* ``PREFIX`` base directory exists

    When you install a patch with relative paths, clame needs to know the final
    absolute path. In such case, you must to have specified the ``PREFIX`` info
    variable at build time (unless ``-i`` flag was set in ``clame build``), but it
    could be overwritten at install stage by mean of ``-p`` flag. For example, at
    build time your ``PREFIX`` could be ``/opt/patches``, but it can be overwritten
    by mean of:


    .. code-block:: console

        $ clame install -p /opt/clame-patches foo_bar.zip

    If you do not specify ``PREFIX`` either at build or install stages, clame
    assumes a default ``PREFIX=/``. Anyway, clame always checks that ``PREFIX``
    is a absolute path and that exists in the current filesystem. This check
    cannot be ignored.


* Integrity of zip file

    Every clame zip file incorporates a ``contents`` file for each patch and
    version. This file lists the files that the patch needs to install, along with
    a SHA256 hash. Clame computes that hash for each file here listed, and compare
    it with the real contained in zip. If there is any inconsistency, clame aborts.
    The aim of this check is only to ensure that your patch is not corrupted or
    that has been badly manipulated. It is a very basic check, but neccesary.
    This check cannot be ignored.


* Room enough to install the patch

    Clame try to guess how much space will require a specific patch to be
    installed. It is not absolutely precise, but it helps in the vast majority
    of cases. This check can be ignored.

* Room enough to save the overwritten files

    When clame installs a file, and that file existed in the current
    filesystem, that existing file is saved in a special area, pointed out by
    ``backup_dir_install`` configuracion setting.  That provide the capability
    of restoring such file later, if the patch become uninstalled. At the same
    way as before, clame try to guess if it will be able to save the whole of
    overwritten
    files, and will abort if it thinks the opposite. You can ignore such
    recommendation, of course, at your own risk (or because you suspect that
    clame is wrong computing the required space).


* Current version is not installed

    If exactly the same version of patch is already installed, clame fails.
    This check cannot be ignored.

* Current version is the highest
    
    Clame checks that you are going to install a the highest version of the
    patch.  For example, if *foo 4.4* is already installed, you cannot install
    *foo 4.3* version. But unlike before, this check can be ignored.

* Check requirements

    Clame checks if the requirements pointed out in the ``depend`` file are
    already installed. This check can be ignored.

* Check conflicts
    
    Clame checks if there is currently installed some patch which conflicts
    with this one that will become installed (pointed out in ``depend``). Also,
    checks if this patch installation conflicts with other one already
    installed. For example, if you have ``foo 3.4`` patch already installed
    that conflicts with ``bar >= 1.0``, you cannot install the ``bar 1.5``
    patch. This check can be ignored.




The installation stage
======================

The installation stage begins when the previous checks are passed or ignored.
Clame performs the patch installation following these points:

Disclaimer
----------
Clame writes to stdout the ``legal`` contents, verbatim. If info variable
``REQUIRE_ACCEPT_LEGAL`` is set, then clame stops and require you to accept the
disclaimer. Otherwise, it continues with the following step.

Input 
-----
If provide, clame will require you to fill the input variables, and will
register its internal database to be able to use later.

Checkinstall
------------
Clame runs ``checkinstall`` file if provided. The environment is set according
with info and input variables. If the return exit code is non zero, clame
aborts.

Preinstall
----------
Clame runs ``checkinstall`` file if provided. The environment is set according
with info, input and checkinstall variables. If the return exit code is non
zero, clame aborts. Otherwise, clame will continue by checking it that the user
and groups pointed out by schema files and directories do exist. This check is
unavoidable, and when fails will abort the entire installation.

Backup of files that will become overwritten
--------------------------------------------
Before to deploy any file or directory pointed out by schema, clame will save
in ``backup_dir_install`` directory the regular files that will become
overwritten. To accomplish this, clame computes the SHA256 hash file and will
copy a file according on this hash. For example, if clame needs to save the
``foo.sh`` file, with hash
``43b99f8e9ffb632c0c9a39fe47f87d9ed6be77afd451f84fe7435b4f105b22be``, it will
be copied it to::

    <backup_dir_install>/43b/43b99f8e9ffb632c0c9a39fe47f87d9ed6be77afd451f84fe7435b4f105b22be

As you can see, ``backup_dir_install`` is a unorganized pool, with no
relationship with any patch. Only contains regular files named as their
respective hashes. So, it is easy search them later.


Deploy the schema
-----------------
When clames saves the regular files that will become overwritten, it deploys the
files and directories pointed out in schema.

If you are not logging as root, in general clame will not be able to set the
user or group owner of any file. But if you have not set user or group owner
on a specific file or directory, clame will install it as your current user
and group. For example, if you are logging as ``foo`` user, with primary
group ``foogroup``, and clame is installing this schema file::

    f /opt/bin/foo.sh

it will be installed as ``foo`` user and ``foogroup`` group.


Clame deploy the several schema files and directories in the following order:

#. Directories
#. Regular files
#. Pipes
#. Symbolic links
#. Hard links

Clame will try to create any intermediate directory needed, but those
directories will not be included into the list of installed directories of the
patch, and clame will not register them in its internal database. Those
directories are created with default permissions and owners, according with the
effective uid of the user running clame.

Any error on this stage will abort the whole installation.


Postinstall
-----------
When clame finish the deployment of the schema files and directories, it runs
the postinstall script. The environment is set according with info, input and
checkinstall variables. If the returned exit code is non zero, clame aborts.


.. note::
    In checkinstall, preinstall and postinstall stages, clame will set standard
    input to ``/dev/null``. Standard output and error remains unchanged.


Register installed files and directories
----------------------------------------
After sucessfull postinstall execution, clame registers in its internal
database the whole of files and directories referenced by schema, and the
checkinstall, preinstall and postinstall scripts.


Register requisites, conflicts and variables
--------------------------------------------
Clame also needs keep track of the requisites and conflicts set by ``depend``.
They are all registered in the internal database, along as the info and input
variables names and values (the checkinstall variables were registered
previously).


Set the patch status as completely installed
--------------------------------------------
Finally, clame register in the internal database the fact that the patch is
sucessfully installed, and returns the control to the command line.


