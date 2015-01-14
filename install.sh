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
# Version: 1.2
# INSTALL: Only run this script

shopt -s extglob
cd $(dirname $0)

${exit:=$1}
exit=${exit:-"continue"}

title='Folder Color'
user=$(basename $HOME)
combobox=('⚫ Install on:' 'root' $user)
prefix='/usr'

foldercolorDE='dolphin-folder-color.desktop'
if ( kf5-config ) ; then 
	foldercolorDE='plasma5-folder-color.desktop'
fi
foldercolorSH='dolphin-folder-color.sh'
pathDesktop='ServiceMenus'
pathExec='bin'

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
		pathServices=$(kde4-config --path services)
		for d in $pathServices ; do
			if [ -z ${d/\/usr\/*/} ]
				then pathDesktop=$d$pathDesktop
			fi
		done
		pathExec=$(kde4-config --prefix)/$pathExec

		setPathSH
		kde-cp --overwrite ./$foldercolorSH "$pathExec/$foldercolorSH"
		kde-cp --overwrite ./$tmp "$pathDesktop/$foldercolorDE"
		if [ $? != 0 ] ; then
			succesInstall=false
		fi
		rm $tmp
	fi
else
	pathDesktop=$(kde4-config --localprefix)"share/kde4/services/"$pathDesktop
	pathExec=$(kde4-config --localprefix)$pathExec
	if (! [ -d "$pathExec" ] )
		then mkdir "$pathExec"
	fi
	if (! [ -d "$pathDesktop" ] )
		then mkdir "$pathDesktop"
	fi

	setPathSH
	kde-cp --overwrite ./$foldercolorSH "$pathExec/$foldercolorSH"
	kde-cp --overwrite ./$tmp "$pathDesktop/$foldercolorDE"
	if [ $? != 0 ] ; then
		succesInstall=false
	fi
	rm $tmp
fi

if ! $succesInstall ; then
	kdialog --caption ' ' --title dolphin-folder-color --msgbox "Installation failed!"
	exit 2
fi
kdialog --caption ' ' --title dolphin-folder-color --msgbox "Installed successfully."
