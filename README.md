NAME

	gch - gentoo-sources compilation helper

VERSION

	0.5

SYNOPSIS:

	gch.sh [--help|-h] [--version|-v] [--kernel|-k <version>] [arg]

DESCRIPTION

	If you're tired of manually (re)compiling your gentoo-sources for the
	N:th time, or you're just lazy, this is the script for you.

	If a new gentoo-sources update has been synced, or you want to recompile
	your kernel for what ever reason, all you need to do is to run this
	script without arguments, or explicitly choose kernel version to install
	by using the --kernel option. No need to run eselect or symlinking kernel
	manually.

	What this script does:

	- Leads you through kernel configuration and compilation by boolean (y/n)
	  questions
	- Checks if your /boot directory is empty, and if it is, asks to mount it
	- Automatically re-links your current (or explicit) kernel version to
	  /usr/src/linux
	- Checks if a .config file exists, if not, you will either get an option
	  to deflate it from /proc/config.gz, or manually setup new kernel .config
	- Compiles kernel and (optionally) modules, and inintramfs depending on
	  your makearg settings
	- Adds kernel to grub by running grub-mkconfig
	- Automatically unmounts /boot, if mounted, after installation
	- Makes a copy of /usr/src/linux/.config to /boot/config-<version>
	- Renames *-gentoo-x64 to *-x64-gentoo because i don't know

ARGUMENTS

	-h, --help			Display this help
	-v, --version			Display version and exit

	OPTIONS

	-k, --kernel			kernel version in format:
					linux-<version>-gentoo

	No arguments, or --kernel option accepted

DEPENDENCIES

	You need to be root to run this script

	- Bash v4.4 or newer		app-shells/bash
	- gentoo-sources		sys-kernel/gentoo-sources
	- perl				dev-lang/perl
	- grub				sys-boot/grub
	- find				sys-apps/findutils
	- uname				sys-apps/coreutils
	- zcat				app-arch/gzip

	The following kernel flags are used for /proc/config.gz support,
	and need to be set:

	- CONFIG_PROC_FS
	- CONFIG_IKCONFIG
	- CONFIG_IKCONFIG_PROC

	gch.sh has built in sanity checks and will exit if any of these
	conditions are not met.

CONFIGURATION

	gch.conf is to be kept in the same directory as gch.sh


	bootmount

	    Default location of kernel binaries

	Default: "/boot"



	grubcfg

	    Grub configuration file in relation to the bootmount setting

	Default: "${bootmount}/grub/grub.cfg"



	fstab

	    fstab location

	 Default: "/etc/fstab"



	kernelroot

	    Kernel source root location

	Default: "/usr/src"



	makeopt

	    make kernel configutation option This could be "oldconfig",
	    "xconfig", "menuconfig" and so on.
	    See https://wiki.gentoo.org/wiki/Kernel/Configuration
	    for more information.

	Default: "oldconfig"



	makearg

	    make kernel build options. See
	    https://wiki.gentoo.org/wiki/Kernel/Configuration for
	    more information. initramfs support implemented but untested.

	Default: "bzImage modules modules_install install"

AUTHOR

	Written by Marcus Hoffren

REPORTING BUGS

	Report gch.sh bugs to marcus@harikazen.com
	Updates of gch.sh and other projects of mine can be found at
	https://github.com/rewtnull?tab=repositories

COPYRIGHT

	Copyright © 2017 Marcus Hoffren. License GPLv3+:
	GNU GPL version 3 or later - http://gnu.org/licenses/gpl.html

	This is free software: you are free to change and redistribute it.
	There is NO WARRANTY, to the extent permitted by law.

HISTORY

	LEGEND: [+] Add, [-] Remove, [*] Change, [!] Bugfix

	v0.5 (20170715) [+] Initial release
	v0.6 (20170715) [!] Missed unset variable
			[!] Accidentally unset a variable too early
			[*] Removed unnecessary duplicate code
			[*] Minor code cleanup

TODO
	Send a message with ideas to marcus@harikazen.com
