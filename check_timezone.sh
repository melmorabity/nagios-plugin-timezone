#!/bin/bash

# Copyright © 2017 Mohamed El Morabity <melmorabity@fedoraproject.com>
#
# This module is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# This software is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program. If not, see <http://www.gnu.org/licenses/>.


PLUGIN_FILENAME=${0##*/}
PLUGIN_DIR=$(dirname "$0")

. $PLUGIN_DIR/utils.sh

ERROR_STATE=$STATE_CRITICAL
ERROR_STATE_LABEL="ERROR"


usage() {
    cat <<EOF
Usage: $PLUGIN_FILENAME [-h] EXPECTED_TIMEZONE

Optional arguments:
  -h, --help             Show this help message and exit
  -w, --warning          Exit warning, instead of critical by default, if
                         current timezone doesn't match expected one

Required arguments:
  EXPECTED_TIMEZONE      Expected timezone (to get a list of valid timezones,
                         call 'timedatectl list-timezones')

EOF
}


parse_arguments() {
    local args=( "$@" )

    local temp
    temp=$(getopt --name "$PLUGIN_FILENAME"  --options "hw" --longoptions "help,warning" -- "${args[@]:-}")
    eval set -- "$temp"

    while true; do
	case "$1" in
	    -w | --warning)
		ERROR_STATE=$STATE_WARNING
		ERROR_STATE_LABEL="WARNING"
		shift
		;;
	    --)
		shift
		break
		;;
	    *)
		usage
		exit $STATE_UNKNOWN
		;;
	esac
    done

    if [[ $# -ne 1 ]]; then
	usage
	exit $STATE_UNKNOWN
    fi

    EXPECTED_TIMEZONE=$1
    if [[ -z "$EXPECTED_TIMEZONE" ]]; then
	usage
	exit $STATE_UNKNOWN
    fi
}


check_timezone() {
    # Get current timezone
    local timedatectl
    timedatectl=$(timedatectl status)
    [[ $? -ne 0 ]] && exit $STATE_UNKNOWN

    [[ "$timedatectl" =~ Time\ zone:\ ([^\ ]*) ]]
    local current_timezone=${BASH_REMATCH[1]}

    if [[ "$current_timezone" != "$EXPECTED_TIMEZONE" ]]; then
	echo "$ERROR_STATE_LABEL: Current timezone is $current_timezone (expected timezone: $EXPECTED_TIMEZONE)"
	exit $ERROR_STATE
    fi

    echo "OK: Current timezone is $EXPECTED_TIMEZONE"
    exit $STATE_OK
}


parse_arguments "$@"
check_timezone
