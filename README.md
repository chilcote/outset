outset
======

This script automatically processes packages and scripts at first boot and/or each (subsequent) user login. This script is meant to meet my particular requirements, and is based on the great work by [Nate Walck](https://github.com/natewalck/Scripts/blob/master/scriptRunner.py), [Rich Trouton](https://github.com/rtrouton/First-Boot-Package-Install), and [Graham Gilbert](https://github.com/grahamgilbert/first-boot-pkg/blob/master/Resources/first-boot).

Requirements
------------
+ [The Luggage](https://github.com/unixorn/luggage)  
+ python 2.7  

Usage
-----

The script is meant to be triggered by launchd so there is no interactive mode as such. For testing purposes, one could manually run the command. The `--once` argument is triggered by a LaunchDaemon and therefore will be run by root. The `--every` argument is triggerd by a LaunchAgent, so it is running in the user context.

	sudo ./outset --once
	./outset --every

`outset` is controlled by two launchd plists:

	/Library/LaunchDaemons/com.github.outset.once.plist
	/Library/LaunchAgents/com.github.outset.every.plist

The first plist runs any scripts and packages you define to be processed at firstboot by placing them in the following directories, and will self-destruct after completion (this is for firstboot packages and configuration scripts that you only want to run once):

	/usr/local/outset/once/
	/usr/local/outset/packages/

The second plist runs any scripts you define to be processed at login by placing them in the following directory, and will continue to run at every login (this is for scripts you wish to run every time a user logs in):

	/usr/local/outset/every/

Logging
-------
`outset` logs to two different files, depending on the context in which the script is being run (root or user):

	/var/log/outset.log
	~/Library/Logs/outset.log

Configuration
-------------
Use [The Luggage](https://github.com/unixorn/luggage) to create a package of the script and accompanying launchd plists. You can use the resulting pkg installer in your [AutoDMG](https://github.com/MagerValp/AutoDMG) workflow.

You can also use The Luggage to package up some scripts to be run by `outset`. Here is an example Makefile that would package up some hypothetical scripts and packages to be installed at firstboot and each login:

	USE_PKGBUILD=1
	include /usr/local/share/luggage/luggage.make
	TITLE=sample_resources_outset
	REVERSE_DOMAIN=com.github.outset
	PAYLOAD= \
			pack-usr-local-outset-every-sample_script_every.py \
			pack-usr-local-outset-once-sample_script_once.py \
			pack-usr-local-outset-packages-sample_pkg.dmg \
			pack-usr-local-outset-packages-sample_pkg.pkg

	l_usr_local_outset: l_usr_local
		@sudo mkdir -p ${WORK_D}/usr/local/outset/{once,every,packages}
		@sudo chown -R root:wheel ${WORK_D}/usr/local/outset
		@sudo chmod -R 755 ${WORK_D}/usr/local/outset

	pack-usr-local-outset-every-%: % l_usr_local_outset
		@sudo ${INSTALL} -m 755 -g wheel -o root "${<}" ${WORK_D}/usr/local/outset/every

	pack-usr-local-outset-once-%: % l_usr_local_outset
		@sudo ${INSTALL} -m 755 -g wheel -o root "${<}" ${WORK_D}/usr/local/outset/once

	pack-usr-local-outset-packages-%: % l_usr_local_outset
		@sudo ${INSTALL} -m 755 -g wheel -o root "${<}" ${WORK_D}/usr/local/outset/packages


License
-------

	Copyright 2014 Joseph Chilcote
	
	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at
	
		http://www.apache.org/licenses/LICENSE-2.0
	
	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.
