#!/bin/bash

# Copyright (C) 2014  Smith AR <audoban@openmailbox.org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#
# UNINSTALL: Only run this script

shopt -s extglob
shopt -s expand_aliases
shopt -s extdebug

declare foldercolorSH
declare foldercolorDE
declare succesUninstall=true

authorize() {
	if [ -x `which kdesudo` ] ; then
		kdesudo -i folder-red -n -d -c $0 finish & disown -h
	elif [ -x `which kdesu` ] ; then
		kdesu   -i folder-red -n -d -c $0 finish & disown -h
	else
		kdialog --caption ' ' --title dolphin-folder-color --error 'kdesu not found'
		exit 1
	fi
}

if dolphin --version | grep "Qt: 5.*" ; then
	foldercolorDE='plasma5-folder-color.desktop'
	foldercolorSH='dolphin-folder-color.sh'

	alias kde-config-data='kf5-config --path data'
	alias kde-config-services='kf5-config --path services'
elif dolphin --version | grep "Qt: 4.*" ; then
	foldercolorDE='ServiceMenus/dolphin-folder-color.desktop'
	foldercolorSH='ServiceMenus/dolphin-folder-color.sh'

	alias kde-config-data='kde4-config --localprefix'
	alias kde-config-services='kde4-config --path services'
fi

fileSH='/usr/bin/dolphin-folder-color.sh'
IFS=':'

if [ -a $fileSH ] ; then
	if [ $UID = 0 ] ; then
		rm $fileSH
	else
		authorize
		exit
	fi
else
	for pathService in $(kde-config-services) ; do
		fileSH=$pathService/$foldercolorSH
		if [ -O $fileSH ] ; then
			rm $fileSH
			if [ $? != 0 ] ; then
				succesUninstall=false
			fi
		fi
	done
fi

for pathService in $(kde-config-services) ; do
	fileDE=$pathService/$foldercolorDE
	if [ -O $fileDE ] ; then
		rm "$fileDE"
		if [ $? != 0 ] ; then
			succesUninstall=false
		fi
	elif [ -a $fileDE ] && ! [ -O $fileDE  ] ; then
		authorize
		exit
	fi
done


if $succesUninstall ; then
	msg="Uninstalled successfully."
else
	msg="Uninstallation failed!"
fi
kdialog --caption ' ' --title dolphin-folder-color --msgbox "$msg"
