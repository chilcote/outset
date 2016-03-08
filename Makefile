USE_PKGBUILD=1
include /usr/local/share/luggage/luggage.make
PACKAGE_VERSION=2.0.0
TITLE=outset
REVERSE_DOMAIN=com.github.outset
PAYLOAD= \
		pack-Library-LaunchDaemons-com.github.outset.boot.plist \
		pack-Library-LaunchDaemons-com.github.outset.cleanup.plist \
		pack-Library-LaunchAgents-com.github.outset.login.plist \
		pack-Library-LaunchAgents-com.github.outset.logout.plist \
		pack-Library-LaunchAgents-com.github.outset.on-demand.plist \
		pack-usr-local-outset-outset \
		pack-usr-local-outset-FoundationPlist \
		pack-usr-local-outset-share-com.chilcote.outset.plist \
		pack-script-postinstall

l_usr_local_outset: l_usr_local
	@sudo mkdir -p ${WORK_D}/usr/local/outset/{boot-once,boot-every,login-once,login-every,logout-once,logout-every,on-demand,share,FoundationPlist}
	@sudo chown -R root:wheel ${WORK_D}/usr/local/outset
	@sudo chmod -R 755 ${WORK_D}/usr/local/outset

pack-usr-local-outset-%: % l_usr_local_outset
	@sudo ${INSTALL} -m 755 -g wheel -o root "${<}" ${WORK_D}/usr/local/outset

pack-usr-local-outset-share-%: % l_usr_local_outset
	@sudo ${INSTALL} -m 644 -g wheel -o root "${<}" ${WORK_D}/usr/local/outset/share

pack-usr-local-outset-FoundationPlist: l_usr_local_outset
	@sudo ${CP} -r "FoundationPlist" ${WORK_D}/usr/local/outset/
	@sudo chown -R root:wheel ${WORK_D}/usr/local/outset/FoundationPlist
	@sudo chmod -R 755 ${WORK_D}/usr/local/outset/FoundationPlist
