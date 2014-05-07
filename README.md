outset
======

This script automatically processes packages and scripts at first boot and/or each (subsequent) user login. 

Requirements
------------
+ [The Luggage](https://github.com/unixorn/luggage)  
+ python 2.7  
+ I've only tested on 10.9.x. YMMV

Usage
-----

The script is meant to be triggered by launchd so there is no interactive mode as such. The `--boot` argument is triggered by a LaunchDaemon and therefore will be run by root. The `--login` argument is triggered by a LaunchAgent, so it is running in the user context.  

For testing purposes, one could manually run the command:  

	sudo ./outset --boot
	./outset --login

`outset` is controlled by two launchd plists:

	/Library/LaunchDaemons/com.github.outset.boot.plist
	/Library/LaunchAgents/com.github.outset.login.plist

The first plist runs any scripts and packages you define to be processed at first boot or every boot by placing them in the following directories. Every boot scripts will run at each boot. First boot scripts/packages will self-destruct after completion (this is for firstboot packages and configuration scripts that you only want to run once):

	/usr/local/outset/firstboot-packages
	/usr/local/outset/firstboot-scripts
	/usr/local/outset/everyboot-scripts
  

The second plist runs any scripts you define to be processed at login by placing them in the following directory, and will continue to run at every login (scripts in the `login-once` directory will only be run once per user):

	/usr/local/outset/login-every
	/usr/local/outset/login-once

Logging
-------
`outset` logs to two different files, depending on the context in which the script is being run (root or user):

	/var/log/outset.log
	~/Library/Logs/outset.log

Configuration
-------------
Use [The Luggage](https://github.com/unixorn/luggage) to create a package of the script and accompanying launchd plists. You can use the resulting pkg installer in your [AutoDMG](https://github.com/MagerValp/AutoDMG) workflow.

	sudo make pkg

You can also use The Luggage to package up some scripts to be run by `outset`. Here is an example Makefile that would package up some hypothetical scripts and packages to be installed at first boot, every boot, each login, and first login:

	USE_PKGBUILD=1
	include /usr/local/share/luggage/luggage.make
	TITLE=outset_resources_sample
	REVERSE_DOMAIN=com.github.outset
	PAYLOAD= \
			pack-usr-local-outset-firstboot-packages-sample_pkg.dmg \
			pack-usr-local-outset-firstboot-packages-sample_pkg.pkg \
			pack-usr-local-outset-firstboot-scripts-sample_script_firstboot.py \
			pack-usr-local-outset-everyboot-scripts-sample_script_every.py \
			pack-usr-local-outset-login-every-sample_script_every.py \
			pack-usr-local-outset-login-once-sample_script_once.py

	l_usr_local_outset: l_usr_local
		@sudo mkdir -p ${WORK_D}/usr/local/outset/{firstboot-packages,firstboot-scripts,everyboot-scripts,login-every,login-once}
		@sudo chown -R root:wheel ${WORK_D}/usr/local/outset
		@sudo chmod -R 755 ${WORK_D}/usr/local/outset

	pack-usr-local-outset-firstboot-packages-%: % l_usr_local_outset
		@sudo ${INSTALL} -m 755 -g wheel -o root "${<}" ${WORK_D}/usr/local/outset/firstboot-packages

	pack-usr-local-outset-firstboot-scripts-%: % l_usr_local_outset
		@sudo ${INSTALL} -m 755 -g wheel -o root "${<}" ${WORK_D}/usr/local/outset/firstboot-scripts

	pack-usr-local-outset-everyboot-scripts-%: % l_usr_local_outset
		@sudo ${INSTALL} -m 755 -g wheel -o root "${<}" ${WORK_D}/usr/local/outset/everyboot-scripts

	pack-usr-local-outset-login-every-%: % l_usr_local_outset
		@sudo ${INSTALL} -m 755 -g wheel -o root "${<}" ${WORK_D}/usr/local/outset/login-every

	pack-usr-local-outset-login-once-%: % l_usr_local_outset
		@sudo ${INSTALL} -m 755 -g wheel -o root "${<}" ${WORK_D}/usr/local/outset/login-once

Credits
-------
This script was an excuse for me to learn more about python. I learn best when I can pull apart existing scripts. As such, this script is heavily based on the great work by [Nate Walck](https://github.com/natewalck/Scripts/blob/master/scriptRunner.py), [Allister Banks](https://gist.github.com/arubdesu/8271ba29ac5aff8f982c), [Rich Trouton](https://github.com/rtrouton/First-Boot-Package-Install), [Graham Gilbert](https://github.com/grahamgilbert/first-boot-pkg/blob/master/Resources/first-boot), and [Greg Neagle](https://code.google.com/p/munki/source/browse/code/client/managedsoftwareupdate#87).

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
