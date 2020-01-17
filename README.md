NAME

	gch - gentoo-sources compilation helper

VERSION

	0.20

SYNOPSIS:

	gch.sh	[--help|-h] [--version|-v] [--kernel|-k <version>]
		[--initramfs|-i] [--yestoall|-y]

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
	  questions (or optionally answers these for you because your time is too
	  valuable to answer questions)
	- Checks if your /boot directory is empty, and if it is, asks to mount it
	- Automatically re-links your current (or explicit) kernel version to
	  /usr/src/linux
	- Checks if a .config file exists, if not, you will either get an option
	  to deflate it from /proc/config.gz, or manually setup new kernel .config
	- Compiles kernel and (optionally) modules, depending on your makearg
	  settings
	- Optionally generates initramfs to /boot with the --initramfs option
	- Adds kernel to grub by running grub-mkconfig
	- Automatically unmounts /boot, if mounted, after installation
	- Makes a copy of /usr/src/linux/.config to /boot/config-<version>
	- Adds *-x64* to naming because i don't know

ARGUMENTS

	-h, --help			Display this help
	-v, --version			Display version and exit

	OPTIONS

	-k, --kernel <kernel>		Kernel version in format:
					linux-<version>-gentoo[<-r<1-9>>]
	-i, --initramfs			Generate initramfs
	-y, --yestoall			Automatically answer yes to all questions

	No arguments, --kernel option, optionally --yestoall and/or --initramfs
	option accepted

DEPENDENCIES

	You need to be root to run this script

	- Bash v4.4 or newer		app-shells/bash
	- gentoo-sources		sys-kernel/gentoo-sources
	- getopt			sys-apps/util-linux
	- perl				dev-lang/perl
	- grub				sys-boot/grub
	- find				sys-apps/findutils
	- uname				sys-apps/coreutils
	- zcat				app-arch/gzip

	Only needed for initramfs support:

	- dracut			sys-kernel/dracut

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

	    Default location to install kernel binaries

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



	makeconf

	    make kernel configuration option This could be "oldconfig",
	    "xconfig", "menuconfig" and so on.
	    See https://wiki.gentoo.org/wiki/Kernel/Configuration
	    for more information.

	Default: "oldconfig"



	makearg

	    make kernel build options. See
	    https://wiki.gentoo.org/wiki/Kernel/Configuration for
	    more information.

	Default: "bzImage modules modules_install install"



	makeopt

	    Override /etc/portage/make.conf MAKEOPTS options. See MAKE(1)
	    and MAKE.CONF(5) for more information

	Default: ""



	architecture

	    Adds architecture to name. i.e. vmlinuz-<version>-x64-gentoo ...
	    Valid options are "x32" and "x64"

	Default: "x64"



	dracutopt

	    dracut options. If you don't use initramfs, you can safely ignore
	    this. Do NOT add --force and/or --kver options, since these are
	    already hardcoded. See DRACUT(8) for more information on which
	    options you can use. Renaming with the architecture setting is not
	    supported, as dracut searches /lib/modules/<kernel version> for
	    modules to be included in the initramfs

	Default: ""



	dracut

	    Optional. Set this to "1" if you want to generate initramfs when
	    running the script without arguments

	Default: ""

AUTHOR

	Written by Marcus Hoffren

REPORTING BUGS

	Report gch.sh bugs to marcus@harikazen.com
	Updates of gch.sh and other projects of mine can be found at
	https://github.com/rewtnull?tab=repositories

COPYRIGHT

	Copyright � 2019 Marcus Hoffren. License GPLv3+:
	GNU GPL version 3 or later - http://gnu.org/licenses/gpl.html

	This is free software: you are free to change and redistribute it.
	There is NO WARRANTY, to the extent permitted by law.

CHANGELOG

	LEGEND: [+] Add, [-] Remove, [*] Change, [!] Bugfix

	v0.5 (20170715)		[+] Initial release
	v0.6 (20170715)		[!] Missed unset variable
				[!] Accidentally unset a variable too early
				[*] Removed unnecessary duplicate code
				[*] Minor code cleanup
	v0.7 (20170715)		[*] Moved variable to a more logical place
				[-] Removed variable pointer and left over
				    eval from an earlier idea
				[+] Added more comments
	v0.8 (20170716)		[+] Added option for make.conf make optimization
				    override
				[*] Renamed some variables and a function for
				    clarity
				[*] Changed an unnecessary array to a variable
	v0.9 (20170717)		[+] Added arch setting to define architecture
				    type in name
				[!] Wrong var used in an error expression
				[*] Minor code cleanup
	v0.10 (20170720)	[+] Added --yestoall option to automatically
				    answer yes to all questions
				[!] Fixed bug in kernel version sanity handler
				[*] Changed output format of error handler
	v0.11 (20170720)	[*] Forgot to remove some debug code
				[!] Sometimes you break stuff more when trying
				    to fix them. This was one of those cases.
				    Kernel version sanity handler should now
				    be fixed for realsies
	v0.12 (20170721)	[+] Added kerninstall setting to allow for
				    either moving or copying kernel to
				    boot directory
				[*] Made kernel install process verbose
				[*] Tightened argument checks
				[*] Minor code cleanup
				[-] Removed superflous check for non-existing
				    symbolic link
	v0.13 (20170725)	[+] Added --initramfs option to generate
				    initramfs using dracut
				[-] Removed old initramfs related code
				[!] Missed unset variable
				[*] Code cleanup
	v0.14 (20170726)	[!] Moved dracut check outside of getopt
				[!] yestoall variable unset too early
				[*] Refractored yestoall code by lifting it
				    out to a general yestoall function
				[*] Refractored parts of sanity check to
				    missing function
				[*] Renamed arch to architecture to avoid
				    possible naming conflict with coreutils
				    arch command
	v0.15 (20170727)	[*] Rewrote symlink handler to create symlink
				    only if it doesn't exist/point to the right
				    kernel version
				[*] Refractored renaming handler to do the
				    same with less code, also removed superflous
				    check
				[*] Decided to hardcode dracut --force and --kver
				    options since they are always needed anyway
				[-] Removed copy/move option. Why did i even put
				    it there to begin with? We will never know
	v0.16 (20170917)	[!] Found out that even variables declared in loop
				    expressions are global in bash /o\
				[!] Fixed bug in lexicographical comparison to
				    return the largest element in cases like
				    f.i. 4.1.9 vs. 4.1.10
				[*] Moved dracut check to where it makes more
				    sense
				[*] Removed reduntant part of regex
	v0.17 (20171107)	[!] Lexicographical comparison bug should now
				    work properly. Sorry for that
				[!] Fixed small bug that added the /usr/src/linux
				    symlink to array when it should not be there
				[*] Added new addzero() function
	v0.18 (20171121)	[!] Fixed some bugs with sanity checks
				[*] Code cleanup
				[*] Squashed some shellsheck warnings
				[*] Now unmounts /boot upon exit if choosing to
				    not compile kernel
	v0.19 (20171122)	[*] Now using tput instead of hardcoded terminal
				    sequences for output
				[!] Fixed silly little bug in bash version check
	v0.20 (20190128)	[!] Came Bash v5 and guess what. Yes, bash version
				    check was apparently still broken :[

TODO

	Send ideas to marcus@harikazen.com
