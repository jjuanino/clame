Building patches
****************

Basic concepts
==============
A clame patch is formed by *patch name* and a *version*. It is mandatory to
indicate the patch name, but not the version. In such case, clame automatically
assigns the version zero (0).

Patch names can be anything formed by single letter and digits, but not spaces
(more precisely, it must match with ``/[a-zA-Z0-9_]/`` regular expression). 

Patch versions follows the usual conventions: digits or letters separated by
dots: ``1.2``, ``4.1.3``, ``1.2.a1`` are valid versions. However, the first
character must be a digit, not a letter, thus ``a.1`` is not a valid version.

Clame handle versions as ruby comparable objects, but does not allow to compare
versions of differents patch names. Therefore, clame cannot compare ``foo 1.1``
with ``bar 1.2``.  Integers are always greather than letters, and thus valid
comparations are::

    foo  1.1 < foo 1.2
    bar 0 < bar 2.3
    foo 0.a < foo 0.1
    bar 0.b < bar 0.ba
    foo 3.a < 1.ab


Core clame files
================
In order to build a clame patch, you need some files to lead the build process.
This section describes each file in detail.


Info file
---------
The ``info`` file is made up just of a list of ``VARNAME="VarValue"`` pairs.
Left side is the variable name, and must be upper case with optional underscore
or digits. Must to followed by equal character (``=``). Right side contains the
variable value, inside double quotes. Here you can put anything except a doble
quote.

Examples:

.. code-block:: make

    NAME="Foo patch"
    VERSION="1.2.a"
    VAR1="Value1"
    VAR_2="Value2"


.. warning::
    Do not span a pair ``VARNAME="VarValue"`` by several lines, neither with a
    final escape (``\``).  It will raise a syntax error. If you need to put a
    line end in a variable content, use ``\n`` character.

Some variables are mandatory and others optional. They are described in the
following sections.

Mandatory variables
^^^^^^^^^^^^^^^^^^^
``PATCH_NAME``
    The patch name. Cannot contain spaces.
``DESCRIPTION``
    Brief description of the goal of your patch. If line breaks are needed,
    write them as ``\n``.

Examples:

.. code-block:: sh

    PATCH_NAME="foo"
    DESCRIPTION = "Foo patch install the bar software.\nIs a stable version"
    

.. _optional-variables:

Optional variables
^^^^^^^^^^^^^^^^^^
Optional variables are classified in two categories: free variables and special
variables.  Free variables are custom variables, with no special meaning.
Special variables are also optionals, but if they happen, it must to follow
some rules and has a special meaning to the build process. The list of special
variables is the following, along with the default value if not set.

``VERSION``: ``0``
    See `basic concepts <#basic-concepts>`__. Defaults to ``0`` (zero).
``INTERPRETER``: ``/bin/sh``
    Is the absolute path to an executable that clame will uses to run the
    following scripts: ``checkinstall``, ``preinstall``, ``postinstall``,
    ``preremove`` and ``postremove``.  By default is ``/bin/sh``, as usually
    the above scripts will be coded as bourne shell scripts, but if the patch
    needs to run perl code, ``INTERPRETER`` can be set to ``/usr/bin/perl``.
``INTERPRETER_FLAGS``: none
    Flags to the ``INTERPRETER`` executable. For example, if you have to run
    your above perl scripts with warnings enabled, ``INTERPRETER_FLAGS`` will
    be set to ``-w``. There is no default to this variable.
``NEED_SUPERUSER``: no
    Specify if the patch needs to be installed as root user. Possible values:
    yes or no. **(Not yet implemented).**
``PREFIX``: none
    Absolute path used to install relative paths. For example, if
    ``PREFIX="/opt/foo"`` and clame has to install ``a/relative/path``, it will
    be finally installed in ``/opt/foo/a/relative/path``.
``REQUIRE_ACCEPT_LEGAL``: none
    If set, it need to be set as ``YES``. Clame will request the user who
    install the patch to accept the disclaimer. When not set, clame just show
    the disclaimer by the terminal.
``BASECLAME``: none
    It is a relative or absolute path necessary to find some instalable files
    in schema file. See the section `schema file`_ for details.
    
    
Info variables expansion
^^^^^^^^^^^^^^^^^^^^^^^^
Info variables can reference to other previously defined info variables by
enclosing it in ``$(VARNAME)``. Examples:

.. code-block:: sh

    PATCH_NAME="foo"
    DESCRIPTION = "$(PATCH_NAME) is a cool patch"


Set info variables by command line
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Currently, it is possible to set info variables by two ways: by mean of the
``info`` file, as it is explained in this section, or by mean of command line
arguments, as it is explained in `TODO`. You can mixed the assignments by both
modes, as long as they are not duplicated.

.. TODO: completar 
    Indicar que las variables VARNAME = "VARVALUE" del schema no se exportan a los scripts, tal y como
    se hace con las info variables


How ``info`` variables are used later in install phase
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. TODO




Schema file 
-----------
Schema file (``schema``) is the core of clame build process. It is responsible
to define the files and directories that will become installed later. This
section describes the full syntax of this file.

.. TODO: se pueden referenciar a infovars

Ignored lines
    Blank lines or lines begining with a pound (``#``) are ignored.

Variable: ``VARNAME="VarValue"``
    As in ``info`` file, it is possible to assign variables in ``schema`` file
    to be referenced later. But be aware that the scope of these variables is
    exclusively limited to the ``schema`` file, conversely as info variables,
    which make up the environment of the ``postinstall``, ``postremove`` and so
    on. Example::

        # schema
        SHARE="share/$(PATCH_NAME)/$(PATCH_NAME)-$(VERSION)"
        LANG="$(SHARE)/lang"
        MACROS="$(SHARE)/macros"
        d $(SHARE)
        d $(LANG)
        d $(MACROS)
        f $(MACROS)/mymacro.sh

    Notice that you can reference info variables also, as ``PATCH_NAME`` and
    ``VERSION``.

.. Debería prohibirse la asignación de info variables en el schema. Esto
   provocaría confusiones varias. Ahora mismo esto no se prohibe de modo alguno.

Default permissions for other files than directories: ``notdirdefaults perm user:group``
    Indicates the default permissions and owner for files that are not
    directories and which does not specify such attributes. Example::

        notdirdefaults 0644 root:wheel
    
Default permissions for directories: ``dirdefaults perm user:group``
    Indicates the default permissions and owner for directories which does not
    specify such attributes. Example::

        dirdefaults 0755 root:wheel

Directory: ``d [[perm] [user:group]] dirname``
    Indicates a directory to install. Permissions and owners are optional. Example::

        d 0700 root:wheel share/syntax
        d nobody:nogroup share/syntax
        d 0755 share/syntax
        d share/syntax

    .. note::
        User and group must be set both or none. The following lines are invalid::
            
            d nobody share/syntax
            d nogroup share/syntax
            d 0700 nogroup share/syntax

Regular file: ``f[!] [[perm] [user:group]] destination[=origin]``
    Indicates a regular file to install. The exclamation point set the
    *nobackup* flag on this file, which means that clame will not backup any
    file overwritten, and thus the destination, if existed previously,
    will be lost. Permissions and owner are optional, as before. Left side of
    equal sign is the installation destination, and rigth side is the path
    where clame read the contents of such destination. Example::

        f /opt/bin/foo.sh=bin/mycustomfoo.sh

    Here, ``mycustomfoo.sh`` must exist at build time. Later, at install
    stage, clame will install such file in the path ``/opt/bin/foo.sh``. 

    ``BASECLAME`` is an important variable at schema scope. It can be defined
    globally in configuration settings, at command line level, or at ``info``
    file (it cannot be set as schema variable, however). It can be absolute or
    relative. If *origin* file is an absolute path, it will be taken as is, but
    if relative, clame will prefix it with ``CLAMEBASE``. For example, in the
    previous example::

        f /opt/bin/foo.sh=bin/mycustomfoo.sh

    clame will assume that ``mycustomfoo.sh`` exits and is placed in
    ``$BASECLAME/bin/mycustomfoo.sh``. If ``CLAMEBASE`` is a relative path,
    clame will assume that the begining is the directory where ``schema`` file
    resides. To be clearer, assume your directory structure is the following::

        clame/
            foo/
                1.0/
                    info
                    schema
        bin/
            mycustomfoo.sh

    Under this scenario, setting ``CLAMEBASE="../.."`` (two level higher) will
    instruct clame to find the ``bin/mycustomfoo.sh`` in the
    ``../../bin/mycustomfoo.sh``, assuming this path relative to
    ``clame/foo/1.0`` directory.

    .. note::
        By default, ``CLAMEBASE`` is set to ``../..`` if not set at any level
        (globally, command line or info file). It is hardcoded as a sane
        default when your directory structure looks like as above.
 
    *Origin* is optional, but if not set, clame will assume that
    ``origin=$BASECLAME/destination``. For example, the following line::

        f /opt/bin/foo.sh

    will instruct to clame to find ``foo.sh`` under
    ``$BASECLAME/opt/bin/foo.sh``. If you like this approach, and
    ``BASECLAME="../.."``, your directory structure may look like to this
    one::

        clame/
            foo/
                1.0/
                    info
                    schema
            opt/
                bin/
                    foo.sh


    Pipe: ``p[!] [[perms] [owner:group]] pipefile``
        Indicates a pipe to install. 

    Symbolic link: ``s[!] destination=origin``
        Indicates a symbolic link to install. Here the meaning or *origin* is not
        the same as in regular files above: at install stage, clame will create
        an symbolic link in the path *destination* pointing out to *origin*.
        For example, with the following line::

            s /opt/bin/foolink.sh=/opt/bin/foo.sh

        clame will install ``/opt/bin/foolink.sh -> /opt/bin/foo.sh``.

        If ``/opt/bin/foo.sh`` does not exist, ``foolink.sh`` will become a
        broken symbolic link, but clame will not raise any error.

    Hard link: ``h[!] destination=origin``
        Pretty similar to symbolic link, but this time with a *hard* link. If
        *origin* does not exist, clame will raise an error at install stage, as
        the hard link could not be created.

        

Depend file
-----------
Depend file (``depend``) contains all about requisites and conflicts at install stage.

To indicate a requisite or conflict, the syntax is, respectively::
    
    R patch_name [operator version]
    C patch_name [operator version]

Operator may be one of the following: ``<, <=, >=, >, ==, !=``


For example, if you are building ``foo`` patch, the meaning of the requisites
and conflicts is as follows::

    # foo will refuse to install if there is not any bar version installed
    R bar

    # foo is allowed to install only if there is some bar >= 5.1 version previosly installed
    R bar >= 5.1

    # foo is allowed to install only if exactly bar == 4 version is previosly installed
    R bar == 4

    # foo is allowed to install if there is any other than bar 3.a version installed
    R bar != 3.a

    # foo will refuse to install if there is any bar version installed
    C bar

    # foo will refuse to install if there is some bar >= 5.1 version previously installed
    C bar >= 5.1

    # foo will refuse to install if exactly bar == 4 version is previosly installed
    C bar == 4

    # foo will refuse to install if there is any other than 3.a bar version previosly installed
    C bar != 3.a





Input file
----------
Input file (``input``) is designed to request, at install stage, some relevant
information to deploy the patch that is unknown at build stage. Clame will
generate environment variables, treated equaly as info variables, that will
make up the environment of the ``postinstall``, ``postremove`` and so on
scripts.

There are several types of input variables, described below.

Normal input variables: ``N VAR_NAME Description``
    Same rules as info variables: ``VAR_NAME`` must be upper case with optional
    digits or underscore. *Description* is free text; clame will show it at
    install stage.

Password input variables: ``P VAR_NAME Description`` 
    They are equal as normal input variables, but clame will not echo the
    output as you write in the terminal.

Boolean input variables: ``B VAR_NAME Description``
    Boolean variables can take only two values: ``y`` or ``n``. When ``y``,
    clame will set the variable to some non empty value in the environment at
    the install stage (``1`` to be precise, but it is irrelevant and may change
    in future releases).  When is set to ``n``, clame will *not* set the
    variable, and it will be taken out of the environment. Is like if the
    variable never exists.

.. warning::
    You cannot define a info variable in input file. It will raise an error at
    build time.
    

Example::

    # depend file
    N PGSQL_PATH Path base of PostgreSQL installation
    P FOO_PWD Passwd of foo user
    B BAR_CONSIRED Wether bar functionaly must be considered


*Description* may contain references to info variables::

    P FOO_PWD Please type the password of $(SCHEMA)



Legal file
----------
Legal file (``legal``) is a disclaimer about the software to be installed. Example::

    © This sotfware is tailored by foo corporation. All rigths reserved.

Sometimes the disclaimer is so important that operator must be accept it
*before* install the patch. See ``REQUIRE_ACCEPT_LEGAL`` in
:ref:`optional-variables`.


Scripts for install/uninstall
-----------------------------
Clame allows to set up several scripts to control more precisely how your patch
is installed/uninstalled, executing specific actions before and after the
schema files are installed or uninstalled. None of these scripts are mandatory.

.. note::
    You are not limited to set up scripts with interpreted code. It is
    possible, though inusual, to consider a binary file as ``postinstall``
    script.

In all cases, clame will set up the enviroment according to info and input
variables. Thus, inside each script, you may reference to ``PATCH_NAME``,
``VERSION`` and so on environment variables. A notable exception is the
variable ``CLAMEBASE``, as it is only used to drive the patch building, and
is not taken into account in the install or uninstall stage. 


.. important::

   The scripts checkinstall, preinstall and so on are **never** considered as
   executable files. They are just the last argument of the ``INTERPRETER``
   configuration setting (usually ``/bin/sh``). Really, clame will run
   the ``/bin/sh`` executable (or whatever), with somes flags and arguments.
   Therefore, if you write a postinstall file as follows:

   .. code-block:: sh

       #!/bin/bash
       ... some bash specific code ...


   the first line is like a commented line, and if you ``INTERPRETER``
   configuration setting is not ``/bin/bash``, your script will not run as bash
   script. This misunderstanding can lead to problems very hard to diagnose. 


Checkinstall
^^^^^^^^^^^^
The checkinstall code is run by clame at early stage, if provided. Usually,
it checks if patch is allowed to be installed by inspecting the returning
exit code. If is not zero, the install stage aborts enterely.

The interesting part of checkinstall is that it allows to set environment
variables that can be consumed by the remaining scripts (at uninstall stage
also). To achieve this, clame set the first argument of the
``checkinstall`` to a custom path with a script specifically designed to
this task. The following example will clarify it:


.. code-block:: shell

    # checkinstall

    # aborts if some sentence ends with error
    set -e

    # script to register vars is placed in first argument ($1)
    register_vars="$1"

    # get the PostgreSQL server version and platform
    # Will return something like: 9.6.1 amd64-portbld-freebsd11.0
    pgsql_version(){
    su postgres -c "psql -q"<< EOF | awk '{print $2,$4}'
    \pset tuples_only
    select version();
    EOF
    }

    # populate the $1 and $2 positional variables with the version and platform
    set `pgsql_version`

    PG_VERSION="$1"
    PG_PLATFORM="$2"

    # check if major version is 9. Otherwise, exit and abort
    if ! echo "$PG_VERSION" | egrep '^9' > /dev/null
    then
        echo "Invalid PostgreSQL version: $PG_VERSION"
        exit 1
    fi

    # register the version and platform to be available later in the pre*
    # or post* scripts
    $register_vars \
        PG_VERSION $PG_VERSION \
        PG_PLATFORM $PG_PLATFORM



Notice the last code section that registers the pairs *varname* and
*varvalue*. You invoque the internal ``$register_vars`` executable with a
pairwise list, though you could perform the same task by doing several
calls:

.. code-block:: shell

    $register_vars PG_VERSION $PG_VERSION
    $register_vars PG_PLATFORM $PG_PLATFORM

Behing the scenes, ``$register_vars`` saves in the clame internal database
the variable names and values, and so they can be got later.

Preinstall
^^^^^^^^^^
After successful checkinstall execution, clame will run ``preinstall`` code, if
provided. Its goal is perform the actions needed to install sucessfully the
overall of schema files and directories. For example, assume your ``schema``
file installs a directory with an inexistent user owner, let say::
    
    d 0755 foouser:foogroup /opt/foodir

Before to deploy such directory, it is needed to create the foouser and
foogroup in ``preinstall``:

.. code-block:: shell

    # preinstall

    # aborts if some sentence ends with error
    set -e

    useradd foouser
    groupadd foogroup

If this scripts returns a non zero code, clame will abort the install stage.
Otherwise, it will desploy the schema files and directories.


Postinstall
^^^^^^^^^^^
After clame deploys the schema files and directories sucessfully, it will run
``postinstall`` code, where you perform specific actions relative to the
installed code.

For example, if you need to compile a PosgreSQL database function installed by
schema::

    # schema
    f 0644 postgres:postgres functions/add_sale.sql

you will write the proper code to compile the function in ``postinstall``::

    # postinstall
    su postgres -c "psql" << EOF
    \i $PREFIX/functions/add_sale.sql
    EOF


.. TODO: ¿¿exit code efecto del postinstall??


Preremove
^^^^^^^^^
If provided, clame run ``preremove`` code in the early stage of uninstall
action. Is intended to perform checks to decide if is allowed to remove the
software.

After ``preremove`` sucessful execution, clame will try revert the actions
deployed by the schema, restoring previous files and directories.
    

Postremove
^^^^^^^^^^ 
If provided, clame run ``postremove`` code after revert the actions deployed by
the schema. It is intended to run code that consumes the restored files or
directories. For example, following the previuos ``postinstall`` example, assume
you are uninstalling the patch later; you need again compile the previous
version, to leave the database as close as it was before. Therefore, you need
again the same code in ``postremove`` file::

    # postremove
    su postgres -c "psql" << EOF
    \i $PREFIX/functions/add_sale.sql
    EOF

The key is that the ``add_sale.sql`` content at this moment (in postremove
phase) is not the same as in postinstall phase, as it has been properly
restored.


Build the patch
===============
You build an alone patch or a bunch of them by running ``clame build``:

.. code-block:: console

    $ clame build <dir1> <dir2> .... <dirN> <zip_output>

.. TODO: flag -i no aparece en la sinopsis. Y la descripción no es muy clara:
   -i, --[no-]ignore-miss-prefix    Ignore errors about relative paths but missing PREFIX. 

You can even specify a pattern shell, as ``clame build clame/foo/* /tmp/foo.zip``.

Directories ``dir_N`` contains the core files of each patch, and the output
will go to a zip file. For example, if your structure directory is as follows::

    clame/
        foo/
            1.0/
                info
                schema
                postinstall
            1.1/
                info
                depend
                schema
                postinstall
                postremove
        bar/
            1.a/
                info
                schema
            1.b/
                info
                schema
                depend

you could build all of your patches with an unique command:

.. code-block:: console

    $ clame build clame/*/*/ /tmp/foo_bar.zip

If you are interested only in a specific, patch, run:

.. code-block:: console

    $ clame build clame/foo/1.1/ /tmp/foo_1.1.zip

To build all the ``foo`` patches:

.. code-block:: console

    $ clame build clame/foo/*/ /tmp/foo.zip

Run ``clame build -h`` to get the full options list.
