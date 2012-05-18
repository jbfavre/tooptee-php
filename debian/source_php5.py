#!/usr/bin/python

'''PHP5 Apport interface

Copyright (C) 2010 Canonical Ltd.
Author: Chuck Short <chuck.short@canonical.com>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.  See http://www.gnu.org/copyleft/gpl.html for
the full text of the license.
'''

import os
import subprocess
from apport.hookutils import *

def _add_my_conf_files(report, filename):
	if not os.path.exists(filename):
		return

	key = 'PHPConf' + path_to_key(filename)
	report[key] = ""
	for line in read_file(filename).split('\n'):
		try:
			if 'mysql.default_password ' in line.split('=')[0]:
				line = "%s = @@APPORTREPLACED@@" % (line.split('=')[0])
			if 'mysqli.default_pw ' in line.split('=')[0]:
				line = "%s = @@APPORTREPLACED@@" % (line.split('=')[0])
			if 'ifx.default_password ' in line.split('=')[0]:
				line = "%s = @@APPORTREPLACED@@" % (line.split('=')[0])
			report[key] += line + '\n'
		except IndexError:
			continue

def add_info(report):
	_add_my_conf_files(report, '/etc/php5/apache2/php.ini')
	_add_my_conf_files(report, '/etc/php5/cli/php5.ini')

	# packages in main
	packages=['php5', 'php-common', 'libapache2-mod-php5', 'libapache2-mod-php5filter'
		'php5-cgi', 'php5-cli', 'php5-dev', 'php5-dbg', 'php-pear', 'php5-curl', 'php5-gd'
		'php5-gmp', 'php5-ldap', 'php5-mhash', 'php5-mysql', 'php5-odbc', 'php5-pgsql',
		'php5-pspell', 'php5-recode', 'php5-snmp', 'php5-sqlite', 'php5-sybase', 'php5-tidy',
			'php5-xmlrpc', 'php5-xsl']

	versions = ''
	for package in packages:
		try:
			version = packaging.get_version(package)
		except ValueError:
			version = 'N/A'
		if version is None:
			version = 'N/A'
		versions += '%s %s\n' %(package, version)
	report['PHPInstalledModules'] = versions
