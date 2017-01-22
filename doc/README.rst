.. highlight:: none

What is clame?
==============

Clame is a package manager, in some way as Debian *dpkg* or *pkg* FreeBSD. But
clame is oriented to provide fixes or patches to previous installed versions,
and therefore it could be more precisely defined as a *patch manager.* A patch
has a name and a version, and you can install/uninstall versions of the same
patch. It is intended to provide the complete life cycle of a software
development for a third party or customer. See `Clame in action
<#clame-in-action>`__ to get a better idea of clame capabilities. Full clame
documentation is hosted in `read the docs
<http://clame.readthedocs.io/en/latest/>`__ website. 

Clame inspiration comes from `Sun Packaging Tool
<https://docs.oracle.com/cd/E19683-01/806-7008/6jftmsc0k/index.html>`__ and lot
of ideas have been borrowed from there.

Currently clame is alpha software. Use at your own risk.


Clame in action
===============

The aim of clame will become clearer exposing the following scenario.  Suppose
you are developing a product to a sales departament. At a first stage, you only
need a table and a function in a PostgreSQL database: a ``SALES`` table and a
``ADD_SALE`` function. Build the patch with the following directory structure::


    clame/
        sales/
            1.0/
                info
                schema
                postinstall
                postremove
    functions/
        add_sale.sql
    tables/
        sales.sql

In the ``info`` file, assign some mandatory variables to build the patch, as
patch name, description, etc:

.. code-block:: make

    # clame/sales/1.0/info
    PATCH_NAME="sales"
    DESCRIPTION="Sales database deployment"
    PREFIX="/opt/sales"
    VERSION="1.0"

The ``schema`` file describes the files and directories making up your patch::

    # clame/sales/1.0/schema
    d 0755 postgres:postgres tables
    d 0755 postgres:postgres procedures

    f 0644 postgres:postgres tables/sales.sql
    f 0644 postgres:postgres functions/add_sale.sql

The ``sales.sql`` and ``add_sale.sql`` files contain, respectively, the code to
create the ``SALES`` table, and the function to add a specific sale to the
``SALES`` table:

.. code-block:: plpgsql

    -- tables/sales.sql
    create table sales
    (
        saleid          SERIAL PRIMARY KEY,
        customer_name   TEXT   NOT NULL,
        product         TEXT   NOT NULL,
        amount          INT    NOT NULL
    );

    -- functions/add_sale.sql
    create or replace function add_sale(
        v_customer_name TEXT,
        v_product TEXT,
        v_amount INT
    ) RETURNS integer as $$
    DECLARE v_saleid INTEGER;
    BEGIN
        INSERT INTO sales(
            customer_name, product, amount
        )
        VALUES(
            v_customer_name, v_product, v_amount
        )
        RETURNING saleid INTO v_saleid;

        RETURN v_saleid;
    END;
    $$ LANGUAGE plpgsql;

The ``postinstall`` file contains the PostgreSQL sentences to create the table
and function:

.. code-block:: sh

    # clame/sales/1.0/postinstall
    su postgres -c "/usr/local/bin/psql -d sales" << EOF
    \i $PREFIX/tables/sales.sql
    \i $PREFIX/functions/add_sale.sql
    EOF

Finally, the ``postremove`` file contains the sentences to revert the
postinstall actions if the patch is removed later:

.. code-block:: sh

    # clame/sales/1.0/postremove
    su postgres -c "/usr/local/bin/psql -d sales" << EOF
    DROP FUNCTION add_sale(TEXT, TEXT, INT);
    DROP TABLE sales;
    EOF

To build the patch, place at the top level directory, and run the following::

    $ clame build clame/sales/1.0 sales-1.0.zip
    * Check: syntax in (clame/sales/1.0) directory ... Success
    => Building patch (sales), version (1.0)
    * Check: relative paths ... Success
    * Check: (/opt/sales) is an absolute path ... Success
    - Task: Add (/usr/home/juanino/clame/clame_examples/tables/sales.sql) ... Done: 1 KiB
    - Task: Add (/usr/home/juanino/clame/clame_examples/functions/add_sale.sql) ... Done: 1 KiB
    - Task: Add (postinstall) ... Done: 1 KiB
    - Task: Add (postremove) ... Done: 1 KiB
    - Task: Add (corefile) ... Done: 2 KiB
    - Task: Add (contents) ... Done: 1 KiB
    => Patch (sales), version (1.0) successfully added to (sales-1.0.zip)

    => Created (sales-1.0.zip, 1 KiB)

Now, the ``sales-1.0.zip`` file contains all the necessary to install the patch
in any other computer. Send the file to your customer; they will be able to
install it as ``root`` user::

    # id
    root
    # clame install sales-1.0.zip
    => The following patches & versions will be installed:
            Patch name: (sales), Version: (1.0)
    Do you want to continue?(y/n) y
    => Installing (sales), version (1.0) contained in (sales-1.0.zip)
    * Check: (/opt/sales) directory prefix exists ... Success
    * Check: integrity of the zip container patch ... Success
    * Check: there is room enough to install the patch ... Success: 4 Kib required
    * Check: there is room enough to save the previous state ... Success: 0 KiB required, 10641648 KiB free in (/)
    Do you want to continue?(y/n) y
    * Check: patch is not already installed ... Success
    * Check: version (1.0) is greather than the whole of installed of (sales) ... Success: no version installed of sales
    * Check: requirements ... Success
    * Check: conflicts ... Success
    * Check: this patch will not cause conflict with other patch ... Success
    => Setting installation prefix to (/opt/sales)
    * Check: exist schema defined user and groups ... Success
    => Register info backup in clame database
    => Installing schema components
    - Task: Create directory: 755 postgres:postgres (/opt/sales/tables) ... Done
    - Task: Create directory: 755 postgres:postgres (/opt/sales/procedures) ... Done
    - Task: Create regular file: 644 postgres:postgres (/opt/sales/tables/sales.sql) ... Done
    - Task: Create regular file: 644 postgres:postgres (/opt/sales/functions/add_sale.sql) ... Done
    => Run postinstall
    CREATE TABLE
    CREATE FUNCTION
    - Task: Register installed files ... Done
    - Task: Register patch scripts ... Done
    - Task: Register patch requisites ... Done
    - Task: Register patch conflicts ... Done
    - Task: Register input variables ... Done
    - Task: Register info variables ... Done
    => (sales) patch, (1.0) version has been successfully installed

So far, so good: your customer is now featuring of your deployment.


But one month later, you receive a call from him to require a new
functionality: they need to register the sale timestamp also in ``SALES``
table. Your table has not such column, but you cannot simply use the same patch
as before with a ``sale_date`` column and send it to your customer with a
diferent version (1.1), as the ``CREATE TABLE`` sentence would fail (``SALES``
table already exists). And you cannot run ``DROP TABLE`` before, as the
``SALES`` rows previously registered will gone out.

The right approach is add a ``sales_date`` column to the ``SALES`` table and
write a new function to take into account the new column. Therefore, you create
a new version (1.1) of ``sales`` patch as follows (notice the new ``depend``
file, as the new version depends on 1.0 version)::

    clame/
        sales/
            1.1/
                info
                depend
                schema
                postinstall
                postremove
    functions/
        add_sale.sql


.. code-block:: make

    # clame/sales/1.1/info
    PATCH_NAME="sales"
    DESCRIPTION="Sales database deployment"
    PREFIX="/opt/sales"
    VERSION="1.1"

::

    # clame/sales/1.1/schema
    f 0644 postgres:postgres functions/add_sale.sql

::

    # clame/sales/1.1/depend
    R sales == 1.0


.. code-block:: plpgsql

    -- functions/add_sale.sql
    create or replace function add_sale(
        v_customer_name TEXT,
        v_product TEXT,
        v_amount INT
    ) RETURNS integer as $$
    DECLARE v_saleid INTEGER;
    BEGIN
        -- new column sale_date
        INSERT INTO sales(
            customer_name, product, amount, sale_date
        )
        VALUES(
            v_customer_name, v_product, v_amount, current_date
        )
        RETURNING saleid INTO v_saleid;

        RETURN v_saleid;
    END;
    $$ LANGUAGE plpgsql;

The ``postinstall`` file now contains the sentences to add the ``sale_date``
column and to compile the new database function:

.. code-block:: sh

    # clame/sales/1.1/postinstall
    su postgres -c "/usr/local/bin/psql -d sales" << EOF
    ALTER TABLE sales ADD COLUMN sale_date DATE;
    \i $PREFIX/functions/add_sale.sql
    EOF

Finally, the ``postremove`` file contains the sentences to leave the patch in
the same state as it was in 1.0 version: it has to compile the previous version
of ``add_sale`` function and remove the ``sale_date`` column:

.. code-block:: sh

    # clame/sales/1.1/postremove
    su postgres -c "/usr/local/bin/psql -d sales" << EOF
    \i $PREFIX/functions/add_sale.sql
    ALTER TABLE sales DROP COLUMN sale_date;
    EOF

Exactly as previous, build the 1.1 version::

    $ clame build clame/sales/1.1 sales-1.1.zip

and your customer will get the new functionality by installing the new
version::

    # clame install sales-1.1.zip
    => The following patches & versions will be installed:
            Patch name: (sales), Version: (1.1)
    Do you want to continue?(y/n) y
    => Installing (sales), version (1.1) contained in (sales-1.1.zip)
    * Check: (/opt/sales) directory prefix exists ... Success
    * Check: integrity of the zip container patch ... Success
    * Check: there is room enough to install the patch ... Success: 1 Kib required
    * Check: there is room enough to save the previous state ... Success: 5 KiB required, 10623428 KiB free in (/)
    Do you want to continue?(y/n) y
    * Check: patch is not already installed ... Success
    * Check: version (1.1) is greather than the whole of installed of (sales) ... Success: (1.0) max version installed
    * Check: requirements ... Success
    * Check: conflicts ... Success
    * Check: this patch will not cause conflict with other patch ... Success
    => Setting installation prefix to (/opt/sales)
    * Check: exist schema defined user and groups ... Success
    - Task: Back up (/opt/sales/functions/add_sale.sql) ... Done. 5 KiB
    => Register info backup in clame database
    => Installing schema components
    - Task: Create regular file: 644 postgres:postgres (/opt/sales/functions/add_sale.sql) ... Done
    => Run postinstall
    ALTER TABLE
    CREATE FUNCTION
    - Task: Register installed files ... Done
    - Task: Register patch scripts ... Done
    - Task: Register patch requisites ... Done
    - Task: Register patch conflicts ... Done
    - Task: Register input variables ... Done
    - Task: Register info variables ... Done
    => (sales) patch, (1.1) version has been successfully installed

If something goes wrong, your customer will uninstall your 1.1 version, and run
their bussiness with the 1.0 version. Notice that clame will revert the
``add_sale.sql`` source as it looked like in 1.0 version::

    # clame remove sales 1.1
    => Unstalling (sales), version (1.1)
    * Check: Version (1.1) is the highest of the patch (sales) ... Success
    * Check: The unistallation will not break any dependency ... Success
    * Check: Effective installation uid is the same as current one ... Success
    - Task: Get input variables ... Done
    - Task: Get checkinstall variables ... Done
    - Task: Get info variables ... Done
    => Restore backup
    - Task: Restore regular file (/opt/sales/functions/add_sale.sql) ... Done
    => Run postremove
    CREATE FUNCTION
    ALTER TABLE
    - Task: Unregister patch (sales), version (1.1) from database ... Done
    => (sales) patch, (1.1) version has been successfully uninstalled

Now it will be clearer why clame is a patch manager: in 1.1 version you *patch*
the 1.0 version to accomplish your costumer requirements. This is in sharp
contrast with other packaging tools, where each version always install the full
software, with no dependency on previous versions.  In clame, you need to
install the right sequence of versions (patches) to achieve the same.



Installing clame
================

Prerequisites
-------------

Clame is written entirely in ruby (2.0 version or higher). Additionally, you
need the following ruby gems:

#. rake
#. mkfifo
#. sys-filesystem
#. ruby-termios
#. sqlite3

You can install these gems by mean of your operating system package manager
(dpkg in Debian, FreeBSD ports, etc) or directly by running::

    # gem install rake mkfifo sys-filesystem ruby-termios sqlite3


Build and install clame
-----------------------

Download the latest release from Github, place in the top level directory and
run as root::

    # gem uninstall -x clame
    # rake build install

Running the tests
-----------------

Before using clame, run ``rake test``. If everythings works as expected, you
should not get any error or warning.

