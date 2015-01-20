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
# Version: 1.4
# DEINSTALL: Only run this script

shopt -s extglob
IFS=':'

prefixServices=($(kde4-config --path services))
if ( kf5-config ) ; then
#	prefixServices=($(kf5-config --path services))
	foldercolorDE='ServiceMenus/plasma5-folder-color.desktop'
else
	foldercolorDE='ServiceMenus/dolphin-folder-color.desktop'
fi
foldercolorSH='bin/dolphin-folder-color.sh'
succesDeinstall=true

for prefixService in ${prefixServices[@]} ; do
	fileDE=$prefixService/$foldercolorDE
	if [ -O $fileDE ] ; then
		if [ $UID = 0 ] ; then
			fileSH=$(kde4-config --prefix)/$foldercolorSH
		else
			fileSH=$(kde4-config --localprefix)/$foldercolorSH
		fi
		rm $fileDE $fileSH
		if [ $? != 0 ] ; then
			succesDeinstall=false
		fi
	elif [ -a $fileDE ] && ! [ -O $fileDE  ] ; then
		kdesu -i folder-red -n -d -c $0 \
			& disown -h
		exit
	fi
done
if ! $succesDeinstall ; then
	kdialog --caption ' ' --title dolphin-folder-color --msgbox "Uninstallation failed!"
	exit 2
fi
kdialog --caption ' ' --title dolphin-folder-color --msgbox "Uninstalled successfully."
