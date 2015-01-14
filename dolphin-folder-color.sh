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
# Version 1.3
# dolphin-folder-color.sh ICON_NAME PATH1 PATH2 ...
# name: is a color or any other folder-$icon or freedesktop icon

shopt -s extglob
icon=${1:?'Name or color icon is not present'} ; shift
desktopEntry='.directory'
tmp=$TMPDIR/$desktopEntry-$PPID


case $icon in
 default | black  | blue   | brown    |\
 cyan    | green  | grey   | orange   |\
 red     | violet | yellow |\
 bookmark   | remote | tar   | sound  |\
 temp | txt | text   | video | videos |\
 activities | development  | documents    | html   |\
 favorites  | download     | downloads    | locked |\
 image      | images       | image-people | important |\
 network    | templates    | public       | publicshare | print )

	if [ $icon != 'default' ] ; then
		icon="folder-$icon"
	fi
;; custom )
	icon=$(kdialog --caption 'Folder Color' --title 'Select Icon' \
		--geticon Desktop Place 2> /dev/null)
	if [ ${#icon} = 0 ]
		then exit
	fi
;; *)
	if ! [ -f $(kiconfinder $icon) ] ; then
		icon="default"
	fi
esac

for dir in "$@" ; do
	cd "$dir"
	tag=$(grep 'Icon=.*' $desktopEntry)
	header=$(grep '\[Desktop Entry\]' $desktopEntry)

	if [ -d "$dir" ] && [ -w $desktopEntry ] && [ -n "$(< $desktopEntry)" ] ; then
		icon=${icon//+(\/)/\\/}

		if [ $icon = 'default' ] ; then
			sed '/Icon=.*/d' $desktopEntry > $tmp

			pattern='\[Desktop Entry\][[:space:]]*[^[:alpha:]]*(\[|$)'
			headernoTags=$(echo $(< $tmp) | grep -E $pattern )
			if [ ${#headernoTags} != 0 ] ; then
				cat $tmp > $desktopEntry
				sed '/\[Desktop Entry\]/d;/./,$!d' $desktopEntry > $tmp
			fi
		elif [ ${#tag} != 0 ] ; then
			sed "s/Icon=.*/Icon=$icon/" $desktopEntry > $tmp

		elif [ ${#header} != 0 ] ; then
			sed "s/\[Desktop Entry\]/[Desktop Entry]\nIcon=$icon/" $desktopEntry > $tmp

		else
			sed "1i[Desktop Entry]\nIcon=$icon\n" $desktopEntry > $tmp

		fi
		cat $tmp > $desktopEntry
		rm $tmp

	elif [ -d "$dir" ] && [ $icon != 'default' ] ; then
		echo -e "[Desktop Entry]\nIcon=$icon" > $desktopEntry
	fi

done

service="org.kde.dolphin-$PPID"
method='/dolphin/Dolphin_1/actions/reload org.qtproject.Qt.QAction.trigger'
qdbus $service $method &> /dev/null
