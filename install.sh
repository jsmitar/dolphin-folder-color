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
# INSTALL: Only run this script

shopt -s extglob
shopt -s expand_aliases
shopt -s extdebug

cd $(dirname $0)

${exit:=$1}
exit=${exit:-"continue"}

declare title='Folder Color'
declare user=$(basename $HOME)
declare combobox1=('⚫ Install in:' 'root' $user)
declare rect='330x130'
declare prefix='/usr'

declare foldercolorDE='plasma5-folder-color.desktop'
declare foldercolorSH='dolphin-folder-color'
declare kde_config_services=`kf5-config --path services`
declare pathService=''
declare pathExec='/usr/bin'

setPathSH() {
    export tmp='.tmp'
    pattern='dolphin-folder-color'
    str="$pathExec/$foldercolorSH"
    str=${str//+(\/)/\\/}
    sed "s/$pattern/$str/" $foldercolorDE > $tmp
}

mk_directory() {
    if ! [ -e $1 ] ; then
        mkdir "$1"
    fi
}

authorize() {
    if [ `which kdesu` ] ; then
        kdesu   -i red -n -d -c $0 finish & disown -h
    elif [ `which kdesudo` ] ; then
        kdesudo -i red -n -d -c $0 finish & disown -h
    else
        kdialog --title dolphin-folder-color --error 'kdesu not found'
        exit 1
    fi
}


if [ $exit != "finish" ] && [ $UID != 0 ] ; then
    kdg=$(kdialog \
        --title "$title" \
        --combobox "${combobox1[@]}" \
        --default $user \
        --geometry $rect)

    if [ -z "$kdg" ]
        then exit 0
    elif [[ "$kdg" = "$user" ]]
        then prefix=$HOME
    fi
fi


if [[ $prefix = '/usr' ]] ; then
    declare -r RootInstall=true
else
    declare -r RootInstall=false
fi

chmod +x ./$foldercolorSH
chmod +x ./$foldercolorDE

succesInstall=true
if $RootInstall ; then
    if [[ $UID != 0 ]] ; then
        authorize
        exit
    else
        IFS=":"

        for p in $kde_config_services ; do
            if [ -z ${p/\/usr\/*/} ] ; then
                pathService="$p"
            fi
        done

        setPathSH
        mk_directory $pathService
        mk_directory $pathExec

        rm "$pathService/$foldercolorSH" "$pathService/$foldercolorDE"
        kdecp5 --overwrite ./$foldercolorSH "$pathExec/$foldercolorSH"
        kdecp5 --overwrite ./$tmp           "$pathService/$foldercolorDE"

        if [ $? != 0 ] ; then
            succesInstall=false
        fi

        rm -r $tmp
    fi
else
    IFS=":"

    for p in $kde_config_services ; do
        if ! [ -d "$p" ]
            then mkdir "$p"
        fi
        if [ -w "$p" ] ; then
            pathService="$p"
            pathExec="$pathService"
            break
        fi
    done

    setPathSH
    mk_directory $pathService
    
    rm "$pathService/$foldercolorSH" "$pathService/$foldercolorDE"
    kdecp5 --overwrite ./$foldercolorSH "$pathService/$foldercolorSH"
    kdecp5 --overwrite ./$tmp           "$pathService/$foldercolorDE"
    if [[ $? != 0 ]] ; then
        succesInstall=false
    fi
    rm $tmp
fi

if $succesInstall ; then
    msg="Installed successfully
    \nPlease restart Dolphin to update the Service Menus"
else
    msg="Installation failed!"
fi
kdialog --title "$title" --msgbox "$msg" --geometry $rect
