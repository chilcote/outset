Outset
======

Outset is a script which automatically processes packages, profiles, and scripts during the boot sequence, user logins, or on demand.

Requirements
------------
+ python 2.7+
+ It's only been tested on 10.9.x and above

Usage
-----

	usage: outset [-h]
				(--boot | --login | --on-demand | --login-every | --login-once | --cleanup | --version | --add-ignored-user username | --remove-ignored-user username | --add-override scripts | --remove-override scripts)

	This script automatically processes packages, profiles, and/or scripts at
	boot, on demand, and/or login.

	optional arguments:
	-h, --help            show this help message and exit
	--boot                Used by launchd for scheduled runs at boot
	--login               Used by launchd for scheduled runs at login
	--on-demand           Process scripts on demand
	--login-every         Manually process scripts in login-every
	--login-once          Manually process scripts in login-once
	--cleanup             Used by launchd to clean up on-demand dir
	--version             Show version number
	--add-ignored-user username
							Add user to ignored list
	--remove-ignored-user username
							Remove user from ignored list
	--add-override scripts
							Add scripts to override list
	--remove-override scripts
							Remove scripts from override list

See the [wiki](https://github.com/chilcote/outset/wiki) for info on how to use Outset.

Credits
-------
This script was an excuse for me to try to learn python. I learn best when I can pull apart existing scripts. As such, this script is heavily based on the great work by [Nate Walck](https://github.com/natewalck/Scripts/blob/master/scriptRunner.py), [Allister Banks](https://gist.github.com/arubdesu/8271ba29ac5aff8f982c), [Rich Trouton](https://github.com/rtrouton/First-Boot-Package-Install), [Graham Gilbert](https://github.com/grahamgilbert/first-boot-pkg/blob/master/Resources/first-boot), and [Greg Neagle](https://github.com/munki/munki/blob/master/code/client/managedsoftwareupdate#L87).

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
