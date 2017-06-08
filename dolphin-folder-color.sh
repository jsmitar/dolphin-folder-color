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
# Version 1.9

shopt -s extglob
shopt -s expand_aliases

declare colors=(black blue brown cyan green grey magenta orange red violet yellow\
                activities bookmark    development documents download            \
                downloads  favorites   html        image     image-people        \
                images     important   locked      network   print               \
                public     publicshare remote      sound     tar                 \
                temp       templates   text txt    video     videos       default)

declare option=${1:?"Use `basename $0` -h to get a help"}
declare desktopEntry='.directory'
declare tmp=${TMPDIR:="/tmp"}/$desktopEntry-$PPID
declare icon
declare random=false
declare rand_colors=(${colors[@]:0:11})

# avoid warnings
unset GREP_OPTIONS

if which kiconfinder5 &>/dev/null ; then
    alias kiconfinder="kiconfinder5"
fi

if [[ "$1" == @(--help|-h) ]] ; then
    cat <<-EOF
    Usage:
    `basename $0` <color>  [FOLDER1 FOLDER2 ...]
    `basename $0` <option> [FOLDER1 FOLDER2 ...]

    Colors:                 black blue brown cyan green grey magenta orange red violet yellow
                            activities bookmark    development documents download
                            downloads  favorites   html        image     image-people
                            images     important   locked      network   print
                            public     publicshare remote      sound     tar
                            temp       templates   text txt    video     videos        default

    --path, -p <icon|path>  Absolute path of the icon or a name of icon, e.g. /usr/share/pixmaps/vlc.png or vlc

    --custom, -c            Opens a selection window icons

    --random, -r            Colour the set of folders with any icon between:
                            black blue brown cyan green grey magenta orange red violet yellow

    --help, -h              Show this help
EOF
    exit
fi


if [[ "$1" == @(--path|-p) ]] ; then
    icon="$2"
    if ! [ -r "$(kiconfinder "$icon")" ] ; then
        echo "icon '${icon:=null}' not found"
        exit
    fi
    shift
elif [[ "$1" == @(--custom|-c) ]] ; then
    icon=$(kdialog --title 'Select Icon' \
           --geticon Desktop Place 2> /dev/null)

    if [[ ${#icon} = 0 ]] ; then
        exit
    fi
elif [[ "$1" == @(--random|-r) ]] ; then
    random=true

elif [[ "^(${colors[@]})" =~ "$1" ]] ; then
    if [[ $1 != 'default' ]] ; then
        icon="folder-$1"
    fi
else
    echo "Error: Use `basename $0` -h to get a help"
    exit

fi


rand_color() {
    rand=$(od -An -N2 -i /dev/random)
    pos=$((rand % ${#rand_colors[@]}))
    icon="folder-${rand_colors[pos]}"

    unset rand_colors[pos]
    rand_colors=(${rand_colors[@]})

    if [[ ${#rand_colors[@]} == 0 ]] ; then
        rand_colors=(${colors[@]:0:11})
    fi
}

shift
for dir in "$@" ; do

    if [ -d "$dir" ] ; then
        cd "$dir"
    else
        echo "Directory not found: $dir" ; continue
    fi

    if [ -w $desktopEntry ] && [ -n "$(< $desktopEntry)" ] ; then

        tag=$(grep 'Icon=.*' $desktopEntry)
        header=$(grep '\[Desktop Entry\]' $desktopEntry)

        if $random ; then
            rand_color
        fi

        icon=${icon//+(\/)/\\/} ##syntax ${parameter//pattern/string}

        if [[ $icon = 'default' ]] ; then
            sed '/Icon=.*/d' $desktopEntry > $tmp

            pattern='\[Desktop Entry\][[:space:]]*[^[:alpha:]]*(\[|$)'
            headernoTags=$(echo $(< $tmp) | grep -E $pattern)
            if [[ ${#headernoTags} != 0 ]] ; then
                cat $tmp > $desktopEntry
                sed '/\[Desktop Entry\]/d;/./,$!d' $desktopEntry > $tmp
            fi

        elif [[ ${#tag} != 0 ]] ; then
            sed "s/Icon=.*/Icon=$icon/" $desktopEntry > $tmp

        elif [[ ${#header} != 0 ]] ; then
            sed "s/\[Desktop Entry\]/[Desktop Entry]\nIcon=$icon/" $desktopEntry > $tmp

        else
            sed "1i[Desktop Entry]\nIcon=$icon\n" $desktopEntry > $tmp

        fi

        cat $tmp > $desktopEntry
        rm $tmp

    elif [[ $icon != 'default' ]] ; then
        echo -e "[Desktop Entry]\nIcon=$icon" > $desktopEntry
    fi

    ## Return to parent directory
    cd ..
done

# Reload the Dolphin windows with qdbus
method='/dolphin/Dolphin_1/actions/reload org.qtproject.Qt.QAction.trigger'
service='org.kde.dolphin-'
reloaded=false

for pid in $(pidof "dolphin") ; do
    if [[ $pid = $PPID ]] ; then
        qdbus $service$PPID $method &> /dev/null & disown -h
        reloaded=true
    fi
done

if ! $reloaded ; then
    for pid in $(pidof "dolphin") ; do
        qdbus $service$pid $method &> /dev/null & disown -h
    done
fi
