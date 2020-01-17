#!/bin/bash

# gentoo-sources compilation helper
#
# Copyright (C) 2019 Marcus Hoffren <marcus@harikazen.com>.
# License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>.
# This is free software: you are free to change and redistribute it.
# There is NO WARRANTY, to the extent permitted by law.
#

### <script_colors>

bold=$(tput bold)
redfg=$(tput setaf 9)
greenfg=$(tput setaf 10)
yellowfg=$(tput setaf 11)
off=$(tput sgr 0)

### </script_colors>

### <source_functions>

. func/error.sh 2>/dev/null || { echo -e "\n${redfg}*${off} error.sh not found" 1>&2; exit 1; } # error handler
. func/gtoe.sh 2>/dev/null || error "gtoe.sh not found" # lexicographical greater than or equal
. func/usage.sh 2>/dev/null || error "usage.sh not found"
. func/except.sh 2>/dev/null || error "except.sh not found" # exception handler
. func/addzero.sh 2>/dev/null || error "addzero.sh not found" # adds a 0 to version string under a condition
. func/missing.sh 2>/dev/null || error "missing.sh not found" # missing dependency handler
. func/version.sh 2>/dev/null || error "version.sh not found"
. func/largest.sh 2>/dev/null || error "largest.sh not found" # return largest element from array
. func/yestoall.sh 2>/dev/null || error "yestoall.sh not found" # yestoall handler

### </source_functions>

### <sanity_check>

[[ $(whoami) != "root" ]] && error "You must be root to run this script"

if [[ ${BASH_VERSINFO[0]} -lt "4" ]] || { [[ ${BASH_VERSINFO[0]} -eq "4" && ${BASH_VERSINFO[1]} -lt "4" ]]; }; then
    error "${0##*/} requires ${bold}bash v4.4${off} or newer"
fi

if [[ -e gch.conf ]]; then
    . gch.conf
else
    error "gkh.conf not found"
fi

missing "perl" "dev-lang/perl" # "look for" "required package"
missing "zcat" "app-arch/gzip"
missing "find" "sys-apps/findutils"
missing "uname" "sys-apps/coreutils"
missing "grub-mkconfig" "sys-boot/grub"

[[ $(getopt -V) =~ util-linux ]] || error "getopt is missing or is the wrong version. Install \033[1msys-apps/util-linux\033[m"

### </sanity_check>

scriptdir="$(cd $(dirname "${BASH_SOURCE[0]}"); pwd)" ||  error "Could not cd to script directory" # save script directory

### <populate_array_with_kernel_versions>

kerndirs=(${kernelroot}/linux-*); kerndirs=("${kerndirs[@]##*/}") # basename
kernhigh=$(largest "${kerndirs[@]}") # return largest element from array

### </populate_array_with_kernel_versions>

### <script_arguments>

{ OPTS=$(getopt -ngch.sh -a -o "vk:iyh" -l "version,kernel:,initramfs,yestoall,help" -- "${@}"); except "${bold}getopt${off}: Error in argument"; }

eval set -- "${OPTS}" # evaluating to avoid white space separated expansion

while true; do
    case ${1} in
	--version|-v)
	    version
	    exit 0;;
	--kernel|-k)
	    trigger="1"
	    kernhigh="${2}" # make input argument highest version
	    shift 2;;
	--initramfs|-i)
	    missing "dracut" "sys-kernel/dracut"
	    dracut="1"
	    shift;;
	--yestoall|-y)
	    yestoall="1"
	    shift;;
	--help|-h)
	    usage
	    exit 0;;
	--)
	    shift
	    break;;
	*)
	    usage
	    exit 1;;
    esac
done; unset OPTS

### </script_arguments>

### <kernel_version_sanity_check>

re="^(linux-)[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2}(-gentoo)(-r[0-9]([0-9])?)?$"

if [[ ${kernhigh} =~ ${re} ]]; then # check if input format is valid
    if [[ ${trigger} == "1" ]]; then # --kernel option set
	for (( i = 0; i < ${#kerndirs[@]}; i++ )); do
	    [[ ${kerndirs[${i}]} == "${kernhigh}" ]] && { current="${kernhigh}"; break; } # check if version exists
	done
    elif [[ ${1} == "" ]]; then
	current="${kernhigh}" # if run without argument, make highest version current
    else
	error "${1} - Invalid argument"
    fi
    [[ ${current} == "" ]] && error "${kernhigh} - Version does not exist. Is it installed under ${kernelroot}?"
else
    error "${bold}${kernhigh}${off} - Illegal format. Use linux-<version>-gentoo[<-r<1-9>>]"
fi; unset re kerndirs kernhigh trigger

### </kernel_version_sanity_check>

### <kernel_reinstall_check>

if [[ ${current} =~ ^linux-$(uname -r)$ ]]; then
    yestoall "Kernel ${current} currently in use. Do you want to reinstall it? [y/N]"

    [[ ${REPLY} != "y" ]] && { echo -e "\nSee ya!\n"; exit 0; }
fi

### </kernel_reinstall_check>

### <mount_handling>

if [[ $(find ${bootmount} -maxdepth 0 -empty) ]]; then # check if directory is empty
    yestoall "${bootmount} is empty. Do you want to try to mount it? [y/N]"

    if [[ ${REPLY} == "y" ]]; then
	grep -o ${bootmount} ${fstab} >/dev/null || error "${bootmount} missing from ${fstab}"
	echo -e ">>> Mounting ${bootmount}"
	{ mount "${bootmount}" 2>/dev/null; except "Could not mount ${bootmount}"; }
    else
	error "${bootmount} is empty"
    fi

fi; unset fstab

### </mount_handling>

echo -e "\n${greenfg}*${off} Processing kernel: ${bold}${current}${off}\n"

### <symbolic_link_handling>

if [[ -L ${kernelroot}/linux ]]; then
    if [[ ! ${kernelroot}/linux -ef "${kernelroot}/${current}" ]]; then # remove symlink if it doesn't point to the right kernel
	{ rm ${kernelroot}/linux 2>/dev/null; except "Could not remove symbolic link ${kernelroot}/linux"; }
    fi
fi

if [[ ! -L ${kernelroot}/linux ]]; then # if symlink doesn't exist, create it
    echo -e ">>> Creating symbolic link ${bold}${kernelroot}/${current}${off} as ${bold}${kernelroot}/linux${off}\n"
    { ln -s "${kernelroot}/${current}" "${kernelroot}/linux" 2>/dev/null;  except "Could not create symbolic link"; }
fi

### </symbolic_link_handling>

### <config_handling>

if [[ ! -f ${kernelroot}/linux/.config ]]; then
	yestoall "${kernelroot}/linux/.config not present. Reuse current .config from /proc/config.gz? [y/N]"

	if [[ ${REPLY} == "y" ]]; then
	    if [[ -e /proc/config.gz ]]; then
		echo -e "\n>>> Deflating ${bold}/proc/config.gz${off} to ${bold}${kernelroot}/linux/.config${off}\n"
		{ zcat /proc/config.gz > "${kernelroot}/linux/.config" 2>/dev/null; \
		    except "Could not deflate /proc/config.gz to ${kernelroot}/linux/.config"; }
	    else
		echo -e "\n${redfg}*${off} The following kernel flags need to be set:"
		echo -e "${redfg}*${off} ${bold}CONFIG_PROC_FS${off}"
		echo -e "${redfg}*${off} ${bold}CONFIG_IKCONFIG${off}"
		echo -e "${redfg}*${off} ${bold}CONFIG_IKCONFIG_PROC${off}\n"
		exit 1
	    fi
	else
	    echo -e "\n>>> Running manual kernel configuration\n"
	fi
elif [[ ! -s ${kernelroot}/linux/.config ]]; then
    error "${bold}.config${off} is empty"
fi

cd "${kernelroot}/linux" 2>/dev/null || error "Could not cd ${kernelroot}/linux"; unset kernelroot

{ make "${makeconf}"; except "make ${makeconf} failed"; }; unset makeconf

### </config_handling>

### <compilation_handling>

yestoall "Init complete. Do you want to compile kernel now? [y/N]"

if [[ ${REPLY} == "y" ]]; then
    echo ""
    { make ${makeopt} ${makearg}; except "make ${makeopt} ${makearg} failed"; } # unqouted because we want word splitting here
else
    echo -e "\nSee Ya!\n"; umount ${bootmount}; exit 0
fi; unset makeopt makearg

### </compilation_handling>

### <rename_with_architecture>

case ${architecture} in
    x64)
	re="$(echo "${current:6}" | perl -pe 's/(\d{1,2}\.\d{1,2}\.\d{1,2})/\1-x64/')";;
    x32)
	re="$(echo "${current:6}" | perl -pe 's/(\d{1,2}\.\d{1,2}\.\d{1,2})/\1-x32/')";;
    *)
	error "\${architecture}: ${architecture} - Valid architectures are \033[1mx32\033[m and \033[1mx64\033[m";;
esac; unset architecture

filename=("System.map" "config" "vmlinuz")
echo ""
for (( s = 0; s < ${#filename[@]}; s++ )); do
    echo -e ">>> Moving ${bold}${bootmount}/${filename[${s}]}-${current:6}${off} to ${bold}${bootmount}/${filename[${s}]}-${re}${off}"
    { mv "${bootmount}/${filename[${s}]}-${current:6}" "${bootmount}/${filename[${s}]}-${re}" 2>/dev/null; \
	except "Moving ${filename[${s}]} failed"; }
done; unset re filename s

### </rename_with_architecture>

### <initramfs_handling>

if [[ ${dracut} == "1" ]]; then
    yestoall "Do you want to generate initramfs? [y/N]"

    if [[ ${REPLY} == "y" ]]; then
	echo -e ">>> Generating ${bold}${bootmount}/initramfs-${current:6}${off}\n"
	{ dracut ${dracutopt} --force --kver "${current:6}"; except "dracut - Generating initramfs-${current:6} failed"; }
    else
	echo -e "\n${yellowfg}*${off} Don't forget to run ${bold}# dracut${off} to generate initramfs"
    fi
fi; unset dracutopt dracut yestoall

### </initramfs_handling>

### <grub_handling>

echo ""
{ grub-mkconfig -o "${grubcfg}"; except "grub-mkconfig -o ${grubcfg} failed"; }; unset grubcfg

### </grub_handling>

### <unmount_handling>

if [[ $(mount | grep -o "${bootmount}") != "" ]]; then
    echo -e "\n>>> Unmounting ${bootmount}"
    { umount "${bootmount}" 2>/dev/null; except "umount ${bootmount} failed"; }
fi; unset bootmount

### </unmount_handling>

echo -e "\n${greenfg}*${off} Kernel version ${bold}${current}${off} is now installed\n"; unset current

cd "${scriptdir}" 2>/dev/null || error "Could not cd to ${scriptdir}"; unset scriptdir # return to script directory

echo -e "${yellowfg}*${off} If you have any installed packages with external modules"
echo -e "${yellowfg}*${off} such as VirtualBox or GFX card drivers, don't forget to"
echo -e "${yellowfg}*${off} run ${bold}# emerge -1 @module-rebuild${off} after upgrading\n"

unset redfg yellowfg greenfg bold off

exit 0
