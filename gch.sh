#!/bin/bash

# gentoo-sources compilation helper
#
# Copyright (C) 2017 Marcus Hoffren <marcus@harikazen.com>.
# License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>.
# This is free software: you are free to change and redistribute it.
# There is NO WARRANTY, to the extent permitted by law.
#

### <sanity_check>

if [[ -e func/error.sh ]]; then
    . func/error.sh
else
    { echo -e "\n\e[91m*\e[0m error.sh not found\n"; exit 1; }
fi

if [[ -e gch.conf ]]; then
    . gch.conf
else
    error "\n\e[91m*\e[0m gkh.conf not found\n"
fi

[[ $(whoami) != "root" ]] && error \
    "\n\e[91m*\e[0m you must be root to run this script\n"
[[ "${BASH_VERSION}" < 4.4 ]] && error \
    "\n\e[91m*\e[0m ${0##*/} requires \033[1mbash v4.4\033[m or newer\n"
[[ $(type -p perl) == "" ]] && error \
    "\n\e[91m*\e[0m perl is missing. Install \033[1mdev-lang/perl\033[m\n"
[[ $(type -p zcat) == "" ]] && error \
    "\n\e[91m*\e[0m zcat is missing. Install \033[1mapp-arch/gzip\033[m\n"
[[ $(type -p uname) == "" ]] && error \
    "\n\e[91m*\e[0m uname is missing. Install \033[1msys-apps/coreutils\033[m\n"
[[ $(type -p grub-mkconfig) == "" ]] && error \
    "\n\e[91m*\e[0m grub-mkconfig is missing. Install \033[1msys-boot/grub\033[m\n"
[[ $(type -p find) == "" ]] && error \
    "\n\e[91m*\e[0m find is missing. Install \033[1msys-apps/findutils\033[m\n"

### </sanity_check>

### <source_functions>

. func/version.sh 2>/dev/null || error "\n\e[91m*\e[0m version.sh not found\n"
. func/largest.sh 2>/dev/null || error "\n\e[91m*\e[0m largest.sh not found\n" # return largest element from array
. func/except.sh 2>/dev/null || error "\n\e[91m*\e[0m except.sh not found\n" # exception handler
. func/usage.sh 2>/dev/null || error "\n\e[91m*\e[0m usage.sh not found\n"
. func/gtoe.sh 2>/dev/null || error "\n\e[91m*\e[0m gtoe.sh not found\n" # lexicographic greater than or equal

### </source_functions>

scriptdir="$( cd $(dirname "${BASH_SOURCE[0]}") && pwd )" # save script directory

### <populate_array_with_kernel_versions>

kerndirs=(${kernelroot}/*); kerndirs=("${kerndirs[@]##*/}") # basename
kernhigh="$(largest "${kerndirs[@]}")" # return largest element from array

### </populate_array_with_kernel_versions>

### <script_arguments>

case ${1} in
    --version|-v)
	version
	exit 0;;
    --kernel|-k)
	trigger="1"
	kernhigh="${2}";;
    --help|-h)
	usage
	exit 0;;
    "")
	;;
    *)
	usage
	exit 1;;
esac

### </script_arguments>

### <kernel_version_sanity_check>

if [[ ${kernhigh} =~ ^linux-$(uname -r)$ ]]; then
    echo ""
    read -rp "Kernel version already installed. Do you want to reinstall it? [y/N] "
	[[ "${REPLY}" != "y" ]] && { echo -e "\nSee ya!\n"; exit 0; }
fi

re="^(linux-)[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2}(-r[0-9]([0-9])?)?(-gentoo)(-r[0-9]([0-9])?)?$"

if [[ "${trigger}" == "1" ]] && [[ "${kernhigh}" =~ ${re} ]]; then
    for (( i = 0; i < ${#kerndirs[@]}; i++ )); do
	[[ "${kerndirs[${i}]}" == "${kernhigh}" ]] && { current="${kernhigh}"; break; } # check if input version is valid
    done
    [[ ${current} == "" ]] && error "\n\e[91m*\e[0m ${kernhigh} - Version does not exist\n"
elif [[ ${1} == "" ]]; then
    current="${kernhigh}" # if run without argument, make highest version current
elif [[ ${2} == "" ]]; then
    usage; exit 1 # don't leave the second argument blank
else
    error "\n\e[91m*\e[0m ${kernhigh} - Illegal format. Use linux-<version>-gentoo[<-r<1-9>>]\n"
fi; unset re kerndirs trigger

### </kernel_version_sanity_check>

[[ ${current} == "" ]] && error "\n\e[91m*\e[0m \033[1msys-kernel/gentoo-sources\033[m needs to be installed\n"

### <mount_handling>

if [[ $(find ${bootmount} -maxdepth 0 -empty) ]]; then
    echo ""
    read -rp "${bootmount} is empty. Do you want to try to mount it? [y/N] "
	if [[ "${REPLY}" == "y" ]]; then
	    [[ $(grep -o ${bootmount} ${fstab}) == "" ]] && error "\n\e[91m*\e[0m ${bootmount} missing from ${fstab}\n"
	    mount "${bootmount}" 2>/dev/null || error "\n\e[91m*\e[0m Could not mount ${bootmount}\n"
	else
	    error "\n\e[91m*\e[0m ${bootmount} is empty\n"
	fi
fi; unset fstab

### </mount_handling>

echo -e "\n\e[92m*\e[0m Processing kernel: \033[1m${current}\033[m"

### <symbolic_link_handling>

[[ -L ${kernelroot}/linux ]] && { rm ${kernelroot}/linux 2>/dev/null; except "\n\e[91m*\e[0m Could not remove symbolic link\n"; }

if [[ ! -L ${kernelroot}/linux ]]; then
    echo -e ">>> Creating symbolic link \033[1m${kernelroot}/${current}\033[m as \033[1m${kernelroot}/linux\033[m\n"
    { ln -s "${kernelroot}/${current}" "${kernelroot}/linux" 2>/dev/null; except "\n\e[91m*\e[0m Could not create symbolic link\n"; }
fi

### </symbolic_link_handling>

### <config_handling>

if [[ ! -f ${kernelroot}/linux/.config ]]; then
    read -rp "${kernelroot}/linux/.config not present. Reuse old .config? [y/N] "
	if [[ "${REPLY}" == "y" ]]; then
	    if [[ -e /proc/config.gz ]]; then
		echo -e "\n>>> Deflating \033[1m/proc/config.gz\033[m to \033[1m${kernelroot}/linux/.config\033[m\n"
		{ zcat /proc/config.gz > "${kernelroot}/linux/.config" 2>/dev/null \
		    except "\n\e[91m*\e[0m Could not copy .config\n"; }
	    else
		echo -e "\n\e[91m*\e[0m The following kernel flags need to be set:"
		echo -e "\e[91m*\e[0m \033[1m\033[1mCONFIG_PROC_FS\033[m"
		echo -e "\e[91m*\e[0m \033[1m\033[1mCONFIG_IKCONFIG\033[m"
		echo -e "\e[91m*\e[0m \033[1m\033[1mCONFIG_IKCONFIG_PROC\033[m\n"
		exit 1
	    fi
	else
	    echo -e "\n>>> Running manual kernel configuration\n"
	fi
elif [[ ! -s ${kernelroot}/linux/.config ]]; then
    error "\n\e[91m*\e[0m .config is empty\n"
fi

cd "${kernelroot}/linux" 2>/dev/null || error "\n\e[91m*\e[0m Could not cd ${kernelroot}/linux\n"; unset kernelroot

{ make ${makeconf}; except "\n\e[91m*\e[0m make ${makeconf} failed\n"; }; unset makeconf

### </config_handling>

### <compilation_handling>

echo ""
read -rp "Init complete. Do you want to compile kernel now? [y/N] "
    if [[ "${REPLY}" == "y" ]]; then
	echo ""
	{ make ${makeopt} ${makearg}; except "\n\e[91m*\e[0m make ${makeopt} ${makearg} failed\n"; }
    else
	echo -e "\nSee Ya!\n"; exit 0
    fi; unset makeopt makearg

### </compilation_handling>

### <naming_with_architecture>

case ${arch} in
    x64)
	re="$(echo "${current:6}" | perl -pe 's/(\d{1,2}\.\d{1,2}\.\d{1,2})/\1-x64/')";;
    x32)
	re="$(echo "${current:6}" | perl -pe 's/(\d{1,2}\.\d{1,2}\.\d{1,2})/\1-x32/')";;
    *)
	error "\n\e[91m*\e[0m \${arch}: ${arch} - Valid architectures are \033[1mx32\033[m and \033[1mx64\033[m\n";;
esac

### </naming_with_architecture>

### <move_kernel_to_boot_and_rename_x64>

if [[ "${kernhigh}" =~ ^${current}$ ]]; then
    { mv "${bootmount}/System.map-${current:6}" ${bootmount}/System.map-"${re}" \
	2>/dev/null; except "\n\e[91m*\e[0m mv System.map failed\n"; }
    { mv "${bootmount}/config-${current:6}" ${bootmount}/config-"${re}" \
	2>/dev/null; except "\n\e[91m*\e[0m mv config failed\n"; }
    { mv "${bootmount}/vmlinuz-${current:6}" ${bootmount}/vmlinuz-"${re}" \
	2>/dev/null; except "\n\e[91m*\e[0m mv vmlinuz failed\n"; }
    if [[ -f "${bootmount}/initramfs-${current}" ]]; then
	{ mv "${bootmount}/initramfs-${current:6}" ${bootmount}/initramfs-"${re}" \
	    2>/dev/null; except "\n\e[91m*\e[0m mv initramfs failed\n"; }
    fi
else
    error "\n\e[91m*\e[0m Something went wrong..\n"
fi; unset re kernhigh

### </move_kernel_to_boot_and_rename_x64>

### <grub_handling>

echo ""
{ grub-mkconfig -o "${grubcfg}"; except "\n\e[91m*\e[0m grub-mkconfig failed\n"; }

### </grub_handling>

### <unmount_handling>

if [[ ! $(mount | grep -o "${bootmount}") == "" ]]; then
    echo -e "\n>>> Unmounting ${bootmount}"
    umount "${bootmount}" 2>/dev/null || error "\n\e[91m*\e[0m umount ${bootmount} failed"
fi; unset grubcfg bootmount

### </unmount_handling>

echo -e "\e[92m*\e[0m Kernel version \033[1m${current}\033[m now installed\n"; unset current

cd "${scriptdir}" 2>/dev/null || error "\n\e[91m*\e[0m Could not cd to ${scriptdir}"; unset scriptdir # return to script directory

echo -e "\e[93m*\e[0m If you have any installed packages with external modules"
echo -e "\e[93m*\e[0m such as VirtualBox or GFX card drivers, don't forget to"
echo -e "\e[93m*\e[0m run \033[1m# emerge -1 @module-rebuild\033[m after upgrading\n"
exit 0
