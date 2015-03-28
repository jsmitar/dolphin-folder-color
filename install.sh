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
# Version: 1.5.1
# INSTALL: Only run this script

shopt -s extglob
shopt -s expand_aliases
shopt -s extdebug

cd $(dirname $0)

${exit:=$1}
exit=${exit:-"continue"}

title='Folder Color'
user=$(basename $HOME)
combobox=('⚫ Install on:' 'root' $user)
prefix='/usr'

foldercolorDE='dolphin-folder-color.desktop'
foldercolorSH='dolphin-folder-color.sh'
pathService='ServiceMenus'
pathExec='/usr/bin'


if which kf5-config &>/dev/null && dolphin --version | grep "Qt: 5" ; then
	foldercolorDE='plasma5-folder-color.desktop'
	pathService=''

	alias kde-config-data='kf5-config --path data'
	alias kde-config-services='kf5-config --path services'
else
    alias kde-config-data='kde4-config --localprefix'
	alias kde-config-services='kde4-config --path services'
fi


if [ $exit != "finish" ] && [ $UID != 0 ] ; then
	kdg=$(kdialog --caption Dolphin --title "$title" --combobox "${combobox[@]}" --default $user)
	if [ -z $kdg ]
		then exit 2
	elif [ $kdg = $user ]
		then prefix=$HOME
	fi
fi


if [ $prefix = '/usr' ] ; then
	declare -r RootInstall=true
else
	declare -r RootInstall=false
fi

chmod +x ./$foldercolorSH
chmod +x ./$foldercolorDE

setPathSH(){
	export tmp='.tmp'
	pattern='dolphin-folder-color\.sh'
	str="$pathExec/$foldercolorSH"
	str=${str//+(\/)/\\/}
	sed "s/$pattern/$str/" $foldercolorDE > $tmp
}

succesInstall=true
if ( $RootInstall ) ; then
	if [ $UID != 0 ] ; then
		kdesu -i folder-red -n -d -c $0 finish \
			& disown -h
		exit
	else
		IFS=":"

		for p in $(kde-config-services) ; do
			if [ -z ${p/\/usr\/*/} ] ; then
				pathService=$p/$pathService
			fi
		done

		setPathSH

		kde-cp --overwrite ./$foldercolorSH "$pathExec/$foldercolorSH"
		kde-cp --overwrite ./$tmp "$pathService/$foldercolorDE"

		if [ $? != 0 ] ; then
			succesInstall=false
		fi

		rm $tmp
	fi
else
	IFS=":"

	for p in $(kde-config-services) ; do
	    if (! [ -d "$p" ] )
			then mkdir "$p"
	    fi
		if [ -w "$p" ] ; then
			pathService=$p/$pathService
			pathExec=$pathService
			break
		fi
	done

	setPathSH

	kde-cp --overwrite ./$foldercolorSH "$pathService/$foldercolorSH"
	kde-cp --overwrite ./$tmp "$pathService/$foldercolorDE"
	if [ $? != 0 ] ; then
		succesInstall=false
	fi
	rm $tmp
fi

if $succesInstall ; then
	msg="Installed successfully."
else
	msg="Installation failed!"
fi
kdialog --caption ' ' --title dolphin-folder-color --msgbox "$msg"
