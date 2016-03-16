Outset
======

This script automatically processes packages, profiles, and/or scripts at boot, on demand, and/or login.

Requirements
------------
+ python 2.7+
+ I've only tested on 10.9+. YMMV

Usage
-----

The script is meant to be triggered by launchd so there is no interactive mode as such. The `--boot` argument is triggered by a LaunchDaemon and therefore will be run by root. The `--login` argument is triggered by a LaunchAgent, so it is running in the user context.  

For testing purposes, one could manually run the command:

	sudo /usr/local/bin/outset/outset --boot
	/usr/local/bin/outset/outset --login

`outset` is controlled by four launchd plists:

	/Library/LaunchDaemons/com.github.outset.boot.plist
	/Library/LaunchDaemons/com.github.outset.cleanup.plist
	/Library/LaunchAgents/com.github.outset.login.plist
	/Library/LaunchAgents/com.github.outset.on-demand.plist

The `com.github.outset.boot.plist` launch daemon runs any scripts and packages you'd like to have processed once or at every boot. You pass scripts and packages to the launchd job by placing them in the corresponding directories listed below. Scripts in the `boot-every` directory will run at each boot. Scripts/packages in `boot-once` directory will self-destruct after completion (this is useful for "firstboot" style packages and configuration scripts that you only want to run once):

	/usr/local/outset/boot-once
	/usr/local/outset/boot-every

The `com.github.outset.login.plist` launch agent runs any scripts you wish to be processed at user login. You pass scripts and packages to the launchd job by placing them in the corresponding directories listed below. `Login-every` scripts will continue to be run at every login, while `login-once` scripts will only be run once per user:

	/usr/local/outset/login-once
	/usr/local/outset/login-every

The `com.github.outset.on-demand.plist` launch agent runs any scripts you wish to be processed immediately, in the user context. You pass scripts and packages to the launchd job by placing them in the corresponding directory listed below, and then trigger the `on-demand` run by touching the file at `/private/tmp/.com.github.outset.ondemand.launchd`, i.e. with a postinstall script. `On-demand` scripts will be immediately removed by the `com.github.outset.cleanup.plist` launch daemon, so they will **not** run for subsequent logins:

	/usr/local/outset/on-demand

Logging
-------
`outset` logs to two different files, depending on the context in which the script is being run (root or user):

	/var/log/outset.log
	~/Library/Logs/outset.log

Note: Make sure all scripts you use in the controlled directories listed above have 'root' ownership, the group set to 'wheel', and permissions set to '755'. Packages should also have the ownership of 'root', and should have '644' permissions:

	sudo chown root:wheel /usr/local/outset && chmod -R 755 /usr/local/outset/boot-every/*
	sudo chmod -R 644 /usr/local/outset/boot-every/*.pkg

Configuration
-------------
Download the [latest release](https://github.com/chilcote/outset/releases) or alternatively use the included Makefile to create a pkg. You can use the resulting pkg installer in your [AutoDMG](https://github.com/MagerValp/AutoDMG) workflow.

	make pkg

You can also use the included `custom-outset` files to package up some scripts to be run by `outset`. Replace the example scripts in the corresponding directories with your scripts, profiles, or packages, and the included Makefile will package up your files:

	cd ./custom-outset
	make pkg

Credits
-------
This script was an excuse for me to learn more about python. I learn best when I can pull apart existing scripts. As such, this script is heavily based on the great work by [Nate Walck](https://github.com/natewalck/Scripts/blob/master/scriptRunner.py), [Allister Banks](https://gist.github.com/arubdesu/8271ba29ac5aff8f982c), [Rich Trouton](https://github.com/rtrouton/First-Boot-Package-Install), [Graham Gilbert](https://github.com/grahamgilbert/first-boot-pkg/blob/master/Resources/first-boot), and [Greg Neagle](https://github.com/munki/munki/blob/master/code/client/managedsoftwareupdate#L87).

Outset uses [FoundationPlist](https://github.com/munki/munki/blob/master/code/client/munkilib/FoundationPlist.py), a library to work with binary plists written by Greg Neagle as part of his [Munki](https://github.com/munki) project.

License
-------

	Copyright 2016 Joseph Chilcote
	
	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at
	
		http://www.apache.org/licenses/LICENSE-2.0
	
	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.
