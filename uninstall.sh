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

${exit:=$1}
exit=${exit:-"continue"}

declare succesUninstall=true
declare rect='330x130'
declare title='Folder Color'

declare foldercolorDE='plasma5-folder-color.desktop'
declare foldercolorSH='dolphin-folder-color'
declare kde_config_data=`kf5-config --path data`
declare kde_config_services=`kf5-config --path services`

authorize() {
    if [ `which kdesu` ] ; then
        kdesu   -i folder-red -n -d -c $0 finish & disown -h
    elif [ `which kdesudo` ] ; then
        kdesudo -i folder-red -n -d -c $0 finish & disown -h
    else
        kdialog --title dolphin-folder-color --error 'kdesu not found'
        exit 1
    fi
}

fileSH='/usr/bin/dolphin-folder-color'
IFS=':'

if [ -a $fileSH ] ; then
    if [[ $UID = 0 ]] ; then
        rm $fileSH
    else
        authorize
        exit 0
    fi
else
    for pathData in $kde_config_services ; do
        fileSH="$pathData/$foldercolorSH"
        if [ -O "$fileSH" ] ; then
            rm "$fileSH"
            
            if [[ $? != 0 ]] ; then
                succesUninstall=false
            fi
        fi
    done
fi

for pathService in $kde_config_services ; do
    fileDE="$pathService/$foldercolorDE"
    if [ -O "$fileDE" ] ; then
        rm "$fileDE"
        if [[ $? != 0 ]] ; then
            succesUninstall=false
        fi
    elif [ -a "$fileDE" ] && ! [ -O "$fileDE"  ] ; then
        authorize
    fi
done

if $succesUninstall ; then
    msg="Uninstalled successfully"
else
    msg="Uninstallation failed!"
fi
kdialog --title "$title" --msgbox "$msg" --geometry $rect
