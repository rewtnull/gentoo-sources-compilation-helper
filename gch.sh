#!/bin/bash

# gentoo-sources compilation helper
#
# Copyright (C) 2017 Marcus Hoffren <marcus@harikazen.com>.
# License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>.
# This is free software: you are free to change and redistribute it.
# There is NO WARRANTY, to the extent permitted by law.
#

if [[ -e func/error.sh ]]; then
    . func/error.sh
else
    { echo -e "\n\e[91m*\e[0m error.sh not found\n"; exit 1; }
fi

if [[ -e gch.conf ]]; then
    . gch.conf
else
    error "\n\e[91m*\e[0m gkh.conf not found"
fi

if [[ $(type -p zcat) == "" ]]; then
    error "\n\e[91m*\e[0m zcat is missing. Install \033[1mapp-arch/gzip\033[m"
else
    comp="zcat"
fi

[[ $(whoami) != "root" ]] && error \
    "\n\e[91m*\e[0m you must be root to run this script"
[[ "${BASH_VERSION}" < 4.4 ]] && error \
    "\n\e[91m*\e[0m ${0##*/} requires \033[1mbash v4.4 or newer\033[m"
[[ $(type -p perl) == "" ]] && error \
    "\n\e[91m*\e[0m perl is missing. Install \033[1mdev-lang/perl\033[m"
[[ $(type -p uname) == "" ]] && error \
    "\n\e[91m*\e[0m uname is missing. Install \033[1msys-apps/coreutils\033[m"
[[ $(type -p grub-mkconfig) == "" ]] && error \
    "\n\e[91m*\e[0m grub-mkconfig is missing. Install \033[1msys-boot/grub\033[m"
[[ $(type -p find) == "" ]] && error \
    "\n\e[91m*\e[0m find is missing. Install \033[1msys-apps/findutils\033[m"

. func/version.sh 2>/dev/null || error "\n\e[91m*\e[0m version.sh not found"
. func/except.sh 2>/dev/null || error "\n\e[91m*\e[0m except.sh not found"
. func/usage.sh 2>/dev/null || error "\n\e[91m*\e[0m usage.sh not found"
. func/gtoe.sh 2>/dev/null || error "\n\e[91m*\e[0m gtoe.sh not found"
. func/max.sh 2>/dev/null || error "\n\e[91m*\e[0m max.sh not found"

scriptdir="$( cd $(dirname "${BASH_SOURCE[0]}") && pwd )"
confcomp="gz"
#dirs=($(ls -t1 ${kernelroot} | grep linux-))
dirs1=(${kernelroot}/*); dirs1=("${dirs1[@]##*/}") # basename
dirs2=($(max "${dirs1[@]}")) # return largest element from array

case ${1} in
    --version|-v)
	version
	exit 0;;
    --kernel|-k)
	trigger="1";;
    --help|-h)
	usage
	exit 0;;
    "")
	;;
    *)
	usage
	exit 1;;
esac

[[ "${trigger}" == "1" ]] && dirs2[0]="${2}"

if [[ ${dirs2[0]} =~ ^linux-$(uname -r)$ ]]; then
    echo ""
    read -rp \
	"Kernel version already installed. do you want to reinstall it? [y/N] "
	[[ "${REPLY}" != "y" ]] && { echo -e "\nSee ya!\n"; exit 0; }
fi

re="^(linux-)[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2}(-r[0-9]([0-9])?)?(-gentoo)(-r[0-9]([0-9])?)?$"

if [[ "${trigger}" == "1" ]] && [[ "${dirs2[0]}" =~ ${re} ]]; then
    for (( i = 0; i < ${#dirs1[@]}; i++ )); do
	[[ "${dirs1[${i}]}" == "${dirs2[0]}" ]] && { current="${dirs2[0]}"; break; }
    done
    [[ ${current} == "" ]] && error "\n\e[91m*\e[0m ${dirs2[0]} - Version does not exist"
elif [[ ${1} == "" ]]; then
    current="${dirs2[0]}"
elif [[ ${dirs2[0]} == "" ]]; then
    usage; exit 1
else
    error "\n\e[91m*\e[0m ${dirs2[0]} - Illegal format. Use linux-<version>-gentoo"
fi; unset re dirs1 trigger

[[ ${current} == "" ]] && error "\n\e[91m*\e[0m \033[1m\033[1msys-kernel/gentoo-sources\033[m needs to be installed"

if [[ $(find ${bootmount} -maxdepth 0 -empty) ]]; then
    echo ""
    read -rp "${bootmount} is empty. Do you want to try to mount it? [y/N] "
	if [[ "${REPLY}" == "y" ]]; then
	    [[ $(grep -o ${bootmount} ${fstab}) == "" ]] && error "\n\e[91m*\e[0m ${bootmount} missing from ${fstab}"
	    mount "${bootmount}" 2>/dev/null || error "\n\e[91m*\e[0m Could not mount ${bootmount}"
	else
	    error "\n\e[91m*\e[0m ${bootmount} is empty"
	fi
fi; unset fstab

echo -e "\n\e[92m*\e[0m Processing kernel: ${current}"

[[ -L ${kernelroot}/linux ]] && { rm ${kernelroot}/linux 2>/dev/null; \
    except "\n\e[91m*\e[0m Could not remove symbolic link"; }

if [[ ! -L ${kernelroot}/linux ]]; then
    echo -e ">>> Creating symbolic link \033[1m${kernelroot}/${current}\033[m as \033[1m${kernelroot}/linux\033[m\n"
    { ln -s "${kernelroot}/${current}" "${kernelroot}/linux" 2>/dev/null; \
	except "\n\e[91m*\e[0m Could not create symbolic link"; }
fi

if [[ ! -f ${kernelroot}/linux/.config ]]; then
    read -rp \
	"${kernelroot}/linux/.config not present. Reuse old .config? [y/N] "
	if [[ "${REPLY}" == "y" ]]; then
	    if [[ -e /proc/config.${confcomp} ]]; then
		echo -e "\n>>> Deflating \033[1m\033[1m/proc/config.${confcomp}\033[m to \033[1m\033[1m${kernelroot}/linux/.config\033[m\n"
		{ eval ${comp} /proc/config.${confcomp} > "${kernelroot}/linux/.config" 2>/dev/null \
		    except "\n\e[91m*\e[0m Could not copy .config. Is the \033[1mcomp\033[m setting correct?"; }
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
    error "\n\e[91m*\e[0m .config is empty. Is the \033[1mcomp\033[m setting correct?"
fi; unset confcomp

cd "${kernelroot}/linux" 2>/dev/null || error "\n\e[91m*\e[0m Could not cd ${kernelroot}/linux"

if ! make ${makeopt}; then
    error "\n\e[91m*\e[0m make ${makeopt} failed"
fi; unset makeopt kernelroot

echo ""
read -rp "Init complete. Do you want to compile kernel now? [y/N] "
    if [[ "${REPLY}" == "y" ]]; then
	echo ""
	{ make ${makearg}; except "\n\e[91m*\e[0m make ${makearg} failed "; }
    else
	echo -e "\nSee Ya!\n"; exit 0
    fi; unset makearg

re="$(echo "${current:6}" | perl -pe 's/(\d{1,2}\.\d{1,2}\.\d{1,2})/\1-x64/')"

if [[ "${dirs2[0]}" =~ ^${current}$ ]]; then
    { mv "${bootmount}/System.map-${current:6}" ${bootmount}/System.map-"${re}" \
	2>/dev/null; except "\n\e[91m*\e[0m mv System.map failed "; }
    { mv "${bootmount}/config-${current:6}" ${bootmount}/config-"${re}" \
	2>/dev/null; except "\n\e[91m*\e[0m mv config failed "; }
    { mv "${bootmount}/vmlinuz-${current:6}" ${bootmount}/vmlinuz-"${re}" \
	2>/dev/null; except "\n\e[91m*\e[0m mv vmlinuz failed "; }
    if [[ -f "${bootmount}/initramfs-${current}" ]]; then
	{ mv "${bootmount}/initramfs-${current:6}" ${bootmount}/initramfs-"${re}" \
	    2>/dev/null; except "\n\e[91m*\e[0m mv initramfs failed "; }
    fi
    { cp "${kernelroot}/linux/.config" ${bootmount}/config-"${re}" \
	2>/dev/null; except "\n\e[91m*\e[0m cp ${kernelroot}/linux/.config to ${bootmount}/config-${re} failed"; }
else
    error "\n\e[91m*\e[0m Something went wrong.."
fi; unset re dirs2

echo ""
{ grub-mkconfig -o "${grubcfg}"; except "\n\e[91m*\e[0m grub-mkconfig failed"; }

if [[ ! $(mount | grep -o "${bootmount}") == "" ]]; then
    echo -e "\n>>> Unmounting ${bootmount}"
    umount "${bootmount}" 2>/dev/null || error "\n\e[91m*\e[0m umount ${bootmount} failed"; unset bootmount
fi; unset grubcfg

echo -e "\e[92m*\e[0m Kernel version ${current} now installed\n"; unset current

cd "${scriptdir}" 2>/dev/null || error "\n\e[91m*\e[0m Could not cd to ${scriptdir}"; unset scriptdir

echo -e "\e[93m*\e[0m If you have VirtualBox installed, don't forget to run"
echo -e "\e[93m*\e[0m \033[1m# emerge -1 @module-rebuild\033[m after upgrading\n"
exit 0
