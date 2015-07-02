USE_PKGBUILD=1
include /usr/local/share/luggage/luggage.make
PACKAGE_VERSION=1.0.1
TITLE=outset_script
REVERSE_DOMAIN=com.github.outset
PAYLOAD= \
		pack-Library-LaunchDaemons-com.github.outset.boot.plist \
		pack-Library-LaunchAgents-com.github.outset.login.plist \
		pack-usr-local-outset-outset \
		pack-usr-local-outset-FoundationPlist

l_usr_local_outset: l_usr_local
	@sudo mkdir -p ${WORK_D}/usr/local/outset/{firstboot-packages,firstboot-scripts,everyboot-scripts,login-every,login-once,FoundationPlist}
	@sudo chown -R root:wheel ${WORK_D}/usr/local/outset
	@sudo chmod -R 755 ${WORK_D}/usr/local/outset

pack-usr-local-outset-%: % l_usr_local_outset
	@sudo ${INSTALL} -m 755 -g wheel -o root "${<}" ${WORK_D}/usr/local/outset

pack-usr-local-outset-FoundationPlist: l_usr_local_outset
	@sudo ${CP} -r "FoundationPlist" ${WORK_D}/usr/local/outset/
	@sudo chown -R root:wheel ${WORK_D}/usr/local/outset/FoundationPlist
	@sudo chmod -R 755 ${WORK_D}/usr/local/outset/FoundationPlist