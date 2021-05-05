#!/bin/bash

# Configuration GUI for Renesas RZ/G2 BSP

# Set environment variable "ADVANCED=1" to get full menu.
# For example:   $ ADVANCED=1 ./config.sh
if [ "$ADVANCED" == "1" ] ; then
  echo "Advanced menu"
fi

# start in base directory of BSP
if [ ! -e "meta-rzg2" ] ; then cd .. ; fi
if [ ! -e "meta-rzg2" ] ; then cd .. ; fi
if [ ! -e "meta-rzg2" ] ; then
  echo -e "\nError: Please run this script from the base of the BSP directory\n"
  exit
fi

LOCAL_CONF=build/conf/local.conf

# Text strings
FLASH_TEXT=("SPI Flash" "eMMC Flash")
FLASHWRITER_IF_TEXT=("SCIF Download Mode" "USB Download Mode")
GPLV3_TEXT=("Block all GPLv3 Packages" "Allow GLPv3 Packages")
DOCKER_TEXT=("disable" "enable")
APP_FRAMEWORK_TEXT=("None" "Qt" "HTML5")
INTERNET_TEXT=("Not Available (packages must be supplied)" "Available (packages will be downloaded)")
RT_TEXT=("No (Standard kernel)" "Yes (Realtime Linux kernel)")
HDMI_TEXT=("Disabled" "Enabled")

##################################
function check_for_file
# Inputs
#   $1 : File to check
# Outputs
#   $MISSING_FILE : 1=file not found  (if file is found, not set)
{
  if [ ! -e $1 ] ; then
    echo "File $1 not found"
    MISSING_FILE=1
  fi
}

##################################
function detect_bsp
# Inputs
#   none
# Outputs
#   $BSP_VERSION
#   $BSP_VERSION_STR
#   $IS_RT
{
  # Detect BSP version based off commit id of CIP kernel
  BSP_VERSION=""

  # v1.0.8
  grep -q 0882431bf2fe meta-rzg2/recipes-kernel/linux/linux-renesas_4.19.bb
  if [ "$?" == "0" ] ; then
    BSP_VERSION=108
    BSP_VERSION_STR="VLP64 v1.0.8"
    IS_RT=0
  fi

}


##################################
function check_host_os
# Inputs
#   none
# Outputs
#   Exit if a package not found
{
  grep "Ubuntu 16.04" /etc/issue > /dev/null 2>&1
  if [ "$?" != "0" ] ; then

    echo -en "\n"\
	"WARNING: You must use Ubuntu 16.04 as your host OS (or container) to build this Yocto BSP.\n"\
	"         You may configure your BSP now, but please switch to a Ubuntu 16.04 container before\n"\
	"         attempting to build.\n\n"\
	"Press Enter to continue..."
    read dummy

    BAD_OS=1
  fi
}


##################################
function check_host_packages
# Inputs
#   none
# Outputs
#   Exit if a package not found
{
  #Check for required host packages
  check_for_file /usr/bin/gawk
  check_for_file /usr/bin/wget
  check_for_file /usr/bin/git
  check_for_file /usr/bin/diffstat
  check_for_file /usr/bin/unzip
  #texinfo
  #gcc-multilib
  check_for_file /usr/bin/make ] #build-essential
  check_for_file /usr/bin/chrpath
  check_for_file /usr/bin/socat
  check_for_file /bin/cpio
  check_for_file /usr/bin/python
  check_for_file /usr/bin/python3
  #python3-pip
  #python3-pexpect
  check_for_file /usr/bin/xz
  #debianutils
  #iputils-ping
  #libsdl1.2-dev
  check_for_file /usr/bin/xterm
  check_for_file /usr/bin/7z

  if [ "$MISSING_FILE" == "1" ] ; then
    echo ""
    echo "You are missing one or more packages. Please run this command to make sure they are all installed"
    echo ""
    echo "sudo apt-get install gawk wget git-core diffstat unzip texinfo gcc-multilib \\"
    echo " build-essential chrpath socat cpio python python3 python3-pip python3-pexpect \\"
    echo " xz-utils debianutils iputils-ping libsdl1.2-dev xterm p7zip-full"
    exit
  fi

  # Check git is set up
  git config --list | grep user > /dev/null 2>&1
  if [ "$?" != "0" ] ; then
    echo "Git is not configure yet."
    echo "Please configure your git settings as shown below:"
    echo ""
    echo "$ git config --global user.email \"you@example.com\""
    echo "$ git config --global user.name \"Your Name\""
    exit
  fi
}


##################################
function get_current_value
# Inputs
#   $1 = Yocto variable to check
# Outputs
#   $VALUE = The value that was read from local.conf
{
	VALUE=""

	if [ ! -e "$LOCAL_CONF" ] ; then
		return
	fi

	# Read local.conf and skip any line that start with  #
	str_len=${#1}
	#echo "Searching for $1..."
	while IFS="" read -r line || [ -n "$line" ]
	do
		## trim leading white spaces
		#line_trimmed=$(echo "$line" | xargs)

		# Remove all spaces
		line_compact=${line// /}

		# skip blank lines
		if [ "$line_compact" == "" ] ; then continue;fi

		# skip commented lines
		if [ "${line_compact:0:1}" == "#" ] ; then continue; fi
	
		# Check if it is what we are looking for.
		# we nee to check "=" and "??="
		str_len_add_1=$((str_len+1))
		str_len_add_2=$((str_len+2))
		str_len_add_3=$((str_len+3))
		str_len_add_4=$((str_len+4))
		if [ "${line_compact:0:$str_len_add_1}" == "${1}=" ] ; then
			#printf '%s\n' "$line"
			#printf '%s\n' "$line_compact"

			#VALUE="${line_compact:$str_len_add_1}"

			# Remove quotes when returning
			VALUE=$(echo ${line_compact:$str_len_add_1} | tr -d '"')
		fi
		if [ "${line_compact:0:$str_len_add_3}" == "${1}??=" ] ; then
			#printf '%s\n' "$line"
			#printf '%s\n' "$line_compact"
			#VALUE="${line_compact:$str_len_add_3}"

			# Remove quotes when returning
			VALUE=$(echo ${line_compact:$str_len_add_3} | tr -d '"')
		fi

	done < $LOCAL_CONF
}


BOARD_NAME=(\
	"RZ/G2E EK874 by Silicon Linux (Rev A,B,C)" \
	"RZ/G2E EK874 by Silicon Linux (Rev D,E)" \
	"RZ/G2N HiHope by Hoperun Technology" \
	"RZ/G2M HiHope by Hoperun Technology" \
	"RZ/G2H HiHope by Hoperun Technology" \
	)
BOARD_MACHINE=(\
	"ek874" \
	"ek874" \
	"hihope-rzg2n" \
	"hihope-rzg2m" \
	"hihope-rzg2h" \
	)

##################################
function do_menu_board()
{
  SELECT=$(whiptail --title "Board Selection" --menu "You may use ESC+ESC to cancel." 0 0 0 \
	"1.   ${BOARD_NAME[0]}" "" \
	"2.   ${BOARD_NAME[1]}" "" \
	"3.   ${BOARD_NAME[2]}" "" \
	"4.   ${BOARD_NAME[3]}" "" \
	"5.   ${BOARD_NAME[4]}" "" \
	3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 0 ] ; then
    case "$SELECT" in
      1.\ *) BOARD=0 ;;
      2.\ *) BOARD=1 ;;
      3.\ *) BOARD=2 ;;
      4.\ *) BOARD=3 ;;
      5.\ *) BOARD=4 ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $SELECT" 20 60 1
  fi
}

##################################
function do_menu_ecc
{
  ECC_TEXT="
Configuration for ECC
Adds ecc to MACHINE_FEATURES to configure DRAM for ECC usage.
ECC_MODE Options: Full, Full Dual, Full Single, Partial
 - Full : DRAM is configured for FULL ECC support, half of memory is reduced for storing ECC code
          Default is Full Single for RZ/G2E, RZ/G2N, Full Dual for RZ/G2M(v1.3 & v3.0), RZ/G2H
 - Full Dual : DRAM is configured for FULL ECC Dual channel support, half of memory is reduced for storing ECC code
               Use only for RZ/G2M(v1.3 & v3.0) and RZ/G2H
 - Full Single: DRAM is configured for FULL ECC Single channel support, half of memory is reduced for storing ECC code
                Use only for RZ/G2E, RZ/G2N, RZ/G2M(v3.0) and RZ/G2H
 - Partial: Manual add/remove ECC area by u-boot command (Default mode)"

  SELECT=$(whiptail --title "ECC Selection" --menu "$ECC_TEXT You may use ESC+ESC to cancel." 0 0 0 \
	"1 None" "  (not set)" \
	"2 Full" "  " \
	"3 Full Dual" "  " \
	"4 Full Single" "  " \
	"5 Partial" "  " \
	3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 0 ] ; then
    case "$SELECT" in
      1\ *) ECC_MODE="None" ;;
      2\ *) ECC_MODE="Full" ;;
      3\ *) ECC_MODE="Full Dual" ;;
      4\ *) ECC_MODE="Full Single" ;;
      5\ *) ECC_MODE="Partial" ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $SELECT" 20 60 1
  fi
}

##################################
function do_menu_target_flash
{
  SELECT=$(whiptail --title "Boot Flash Selection" --menu "You may use ESC+ESC to cancel." 0 0 0 \
	"1. ${FLASH_TEXT[0]}"  " " \
	"2. ${FLASH_TEXT[1]}"  " " \
	3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 0 ] ; then
    case "$SELECT" in
      1.\ *) FLASH=0
        ;;
      2.\ *) FLASH=1
        ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $SELECT" 20 60 1
  fi
}

##################################
function do_menu_flashwriter_if()
{
  SELECT=$(whiptail --title "Boot Flash Selection" --menu "You may use ESC+ESC to cancel." 0 0 0 \
	"1. ${FLASHWRITER_IF_TEXT[0]}"  " " \
	"2. ${FLASHWRITER_IF_TEXT[1]}" " " \
	3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 0 ] ; then
    case "$SELECT" in
      1.\ *) FLASHWRITER_IF=0 ;
        ;;
      2.\ *) FLASHWRITER_IF=1
        ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $SELECT" 20 60 1
  fi
}


##################################
function show_advanced_msg
{
  whiptail --msgbox "This option is only available in advanced mode." 0 0 0
}

##################################
function do_main_menu
{
export NEWT_COLORS='
root=,blue
'

  SELECT=$(whiptail --title "RZ/G2 BSP Configuration" --menu \
	"Select your build options for $BSP_VERSION_STR.\nYou may use [ESC]+[ESC] to Cancel/Exit (no save). Use [Tab] key to select buttons.\n\nUse the <Change_Item> button (or enter) to make changes.\n\nUse the <Save> button To start the configuration." \
	0 0 0 --cancel-button Save --ok-button Change_Item \
	--default-item "$LAST_SELECT" \
	"1.                       Board:" "  ${BOARD_NAME[$BOARD]}"  \
	"2.             Realtime kernel:" "  ${RT_TEXT[$RT]}"  \
	"3.                 Enable HDMI:" "  ${HDMI_TEXT[$HDMI]}"  \
	"4.                  Boot Flash:" "  ${FLASH_TEXT[$FLASH]}" \
	"5.  Boot Programming Interface:" "  ${FLASHWRITER_IF_TEXT[$FLASHWRITER_IF]}"  \
	"6.                    ECC Mode:" "  $ECC_MODE"  \
	"7.                    CIP Mode:" "  $CIP_MODE"  \
	"8.                      Docker:" "  ${DOCKER_TEXT[$DOCKER]}"  \
	"9.       Application Framework:" "  ${APP_FRAMEWORK_TEXT[$APP_FRAMEWORK]}"  \
	"10.        Internet Connection:" "  ${INTERNET_TEXT[$INTERNET]}"  \
	"11.               GPLv3 GPLv3+:" "  ${GPLV3_TEXT[$GPLV3]}"  \
	3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ] ; then
    # We used the 'cancel' button as Exit/Save button.
    echo "Preparing to configure..."
  elif [ $RET -eq 0 ] ; then
    LAST_SELECT="$SELECT"
    case "$SELECT" in
      1.\ *) do_menu_board ;;
      2.\ *) show_advanced_msg ;;
      3.\ *) show_advanced_msg ;;
      4.\ *) if [ "$ADVANCED" == "1" ] ; then do_menu_target_flash ; else show_advanced_msg ; fi ;;
      5.\ *) if [ "$ADVANCED" == "1" ] ; then do_menu_flashwriter_if ; else show_advanced_msg ; fi ;;
      6.\ *) if [ "$ADVANCED" == "1" ] ; then do_menu_ecc ; else show_advanced_msg ; fi ;;
      7.\ *) show_advanced_msg ;;
      8.\ *) show_advanced_msg ;;
      9.\ *) show_advanced_msg ;;
      10.\ *) show_advanced_msg ;;
      11.\ *) show_advanced_msg ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $SELECT" 20 60 1
  else
    exit 1
  fi

}

##################################
# Start of script
##################################

# Check for correct version of Ubuntu
check_host_os

# Check Host machine for minimum packages and that git is set up
# Skip if not running the correct Ubuntu version
if [ "$BAD_OS" != "1" ] ; then
  check_host_packages
fi

# Defaults
BOARD=0
FLASH=0 # SPI Flash
FLASHWRITER_IF=0 # SCIF Download Mode
CIP_MODE="Buster-full"
DOCKER=0 # Not included
GLPV3=0 # No GPLv3 packages
APP_FRAMEWORK=1 # Qt
INTERNET=1 # Download packages from Internet
ECC_MODE="None" # No ECC
RT=0
HDMI=1

# Determine what BSP we are using
detect_bsp

# If there is already a local.conf, we can read it
#if [ -e "$LOCAL_CONF" ] ; then
#  get_current_value "MACHINE"
#  BOARD=$VALUE
#  get_current_value "ECC_MODE"
#  if [ "$VALUE" == "" ] ; then
#    ECC_MODE="None"
#  fi
#fi

# Main loop
while true ; do
  do_main_menu
done

# If we are this far, then the user pressed "Save"

# First build?
if [ ! -e "build" ] ; then
  echo "Setting up build environment..."
  source poky/oe-init-build-env
  # This command will leave you in the 'build' directory
  cd ..

  echo "Copying the default configuration files for the target board..."
  cp -v meta-rzg2/docs/sample/conf/${BOARD_MACHINE[$BOARD]}/linaro-gcc/*.conf build/conf/

  if [ "HDMI" == "1" [ ; then
    echo "Applying HDMI patches..."
    patch -i extra/*HDMI*.patch
  fi
fi


# Executing the copy script for proprietary software if not already done
if [ ! -e  proprietary/RCE3G001L4101ZDO_2_0_9.zip ] &&
   [ -e meta-rzg2/recipes-multimedia/omx-module/omx-user-module/RTM0AC0000XV264D30SL41C.tar.bz2 ] ; then
  echo "Executing the copy script for proprietary software"
  cd meta-rzg2
  sh docs/sample/copyscript/copy_proprietary_softwares.sh ../proprietary
  cd ..
fi
