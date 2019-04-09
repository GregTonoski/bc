#! /bin/sh
#
# Copyright (c) 2018-2019 Gavin D. Howard and contributors.
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#

usage() {
	printf "usage: %s NLSPATH main_exec\n" "$0" 1>&2
	exit 1
}

script="$0"
scriptdir=$(dirname "$script")

. "$scriptdir/functions.sh"

INSTALL="$scriptdir/safe-install.sh"

test "$#" -ge 2 || usage

nlspath="$1"
shift

main_exec="$1"
shift

locales_dir="$scriptdir/locales"

locales=$(locale -a)

for file in $locales_dir/*.msg; do

	base=$(basename "$file")
	locale=$(removeext "$base")
	loc=$(gen_nlspath "$nlspath" "$locale" "$main_exec")

	if [ ! -z "${locales##*$locale*}" ]; then
		printf 'The following locale is not supported: %s\nContinuing...\n' "$locale"
		continue
	fi

	mkdir -p $(dirname "$loc")

	if [ -L "$file" ]; then
		link=$(readlink "$file")
		d=$(dirname "$file")
		file="$d/$link"
	fi

	err_msgs=$(gencat "$loc" "$file" 2>&1)
	if [ "$err_msgs" != "" ]; then
		printf '\nWarning: gencat produced the following errors:\n\n%s\n\n' "$err_msgs"
	fi

done