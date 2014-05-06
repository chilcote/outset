USE_PKGBUILD=1
include /usr/local/share/luggage/luggage.make
TITLE=script_outset
REVERSE_DOMAIN=com.github.outset
PAYLOAD=pack-Library-LaunchDaemons-com.github.outset.once.plist \
		pack-Library-LaunchAgents-com.github.outset.every.plist \
		pack-usr-local-outset-outset \

l_usr_local_outset: l_usr_local
	@sudo mkdir -p ${WORK_D}/usr/local/outset/{once,every,packages}
	@sudo chown -R root:wheel ${WORK_D}/usr/local/outset
	@sudo chmod -R 755 ${WORK_D}/usr/local/outset

pack-usr-local-outset-%: % l_usr_local_outset
	@sudo ${INSTALL} -m 755 -g wheel -o root "${<}" ${WORK_D}/usr/local/outset

