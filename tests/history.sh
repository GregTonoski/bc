#! /bin/sh
#
# SPDX-License-Identifier: BSD-2-Clause
#
# Copyright (c) 2018-2021 Gavin D. Howard and contributors.
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

script="$0"

testdir=$(dirname "$script")

. "$testdir/../scripts/functions.sh"

# usage: history.sh dir -a|idx [exe args...]

# If Python does not exist, then just skip.
py=$(command -v python3)
err=$?

if [ "$err" -ne 0 ]; then

	py=$(command -v python)
	err=$?

	if [ "$err" -ne 0 ]; then
		printf 'Could not find Python 3.\n'
		printf 'Skipping %s history tests...\n' "$d"
		exit 0
	fi
fi

to=$(command -v timeout)
err=$?

if [ "$err" -ne 0 ]; then
	printf 'Could not find timeout.\n'
	printf 'Skipping %s history tests...\n' "$d"
	exit 0
fi

# d is "bc" or "dc"
d="$1"
shift

# idx is either an index of the test to run or "-a". If it is "-a", then all
# tests are run.
idx="$1"
shift

if [ "$#" -gt 0 ]; then

	# exe is the executable to run.
	exe="$1"
	shift

else
	exe="$testdir/../bin/$d"
fi

# Set the test range correctly for all tests or one test. st is the start index.
if [ "$idx" = "-a" ]; then
	idx=$("$py" "$testdir/history.py" "$d" -a)
	idx=$(printf '%s - 1\n' "$idx" | bc)
	st=0
else
	st="$idx"
fi

# Run all of the tests.
for i in $(seq "$st" "$idx"); do

	if [ "$i" -eq 8 ] && [ "$d" = "bc" ]; then
		limit=45
	else
		limit=30
	fi

	for j in $(seq 1 3); do

		printf 'Running %s history test %d...' "$d" "$i"

		"$to" "$limit" "$py" "$testdir/history.py" "$d" "$i" "$exe" "$@"
		err=$?

		if [ "$err" -eq 0 ]; then
			break
		fi

	done

	checktest_retcode "$d" "$err" "$d history tests $i"

	printf 'pass\n'

done
