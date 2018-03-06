#! /bin/sh

# Tests the timeconst.bc script from the Linux kernel build.
# You can find the script at kernel/time/timeconst.bc in any Linux repo.
# One such repo is: https://github.com/torvalds/linux

script="$0"

testdir=$(dirname "$script")

if [ "$#" -gt 4 ]; then
	echo "usage: $0 [timeconst.bc bc test_output1 test_output2]"
	exit 1
fi

set -e

if [ "$#" -gt 0 ]; then
	timeconst="$1"
	shift
else
	timeconst="$testdir/../../timeconst.bc"
fi

if [ "$#" -gt 0 ]; then
	bc="$1"
	shift
else
	bc="$testdir/../bc"
fi

if [ "$#" -gt 0 ]; then
	out1="$1"
	shift
else
	out1="$testdir/../log_bc.txt"
fi

if [ "$#" -gt 0 ]; then
	out2="$1"
	shift
else
	out2="$testdir/../log_test.txt"
fi

rm -rf "$out1"
rm -rf "$out2"

for i in $(seq 1 10000); do

	echo "$i"

	(echo $i | bc -q "$timeconst" ) > "$out1"
	(echo $i | "$bc" -q "$timeconst" ) > "$out2"

	diff "$out1" "$out2"

done
