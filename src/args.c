/*
 * *****************************************************************************
 *
 * SPDX-License-Identifier: BSD-2-Clause
 *
 * Copyright (c) 2018-2021 Gavin D. Howard and contributors.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * * Redistributions of source code must retain the above copyright notice, this
 *   list of conditions and the following disclaimer.
 *
 * * Redistributions in binary form must reproduce the above copyright notice,
 *   this list of conditions and the following disclaimer in the documentation
 *   and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 * *****************************************************************************
 *
 * Code for processing command-line arguments.
 *
 */

#include <assert.h>
#include <ctype.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>

#ifndef _WIN32
#include <unistd.h>
#endif // _WIN32

#include <vector.h>
#include <read.h>
#include <args.h>
#include <opt.h>

/**
 * Adds @a str to the list of expressions to execute later.
 * @param str  The string to add to the list of expressions.
 */
static void bc_args_exprs(const char *str) {
	BC_SIG_ASSERT_LOCKED;
	if (vm.exprs.v == NULL) bc_vec_init(&vm.exprs, sizeof(uchar), BC_DTOR_NONE);
	bc_vec_concat(&vm.exprs, str);
	bc_vec_concat(&vm.exprs, "\n");
}

/**
 * Adds the contents of @a file to the list of expressions to execute later.
 * @param file  The name of the file whose contents should be added to the list
 *              of expressions to execute.
 */
static void bc_args_file(const char *file) {

	char *buf;

	BC_SIG_ASSERT_LOCKED;

	vm.file = file;

	buf = bc_read_file(file);

	assert(buf != NULL);

	bc_args_exprs(buf);
	free(buf);
}

/**
 * Processes command-line arguments.
 * @param argc        The number of arguments.
 * @param argv        The arguments.
 * @param exit_exprs  Whether to exit if expressions are encountered.
 */
void bc_args(int argc, char *argv[], bool exit_exprs) {

	int c;
	size_t i;
	bool do_exit = false, version = false;
	BcOpt opts;

	BC_SIG_ASSERT_LOCKED;

	bc_opt_init(&opts, argv);

	// This loop should look familiar to anyone who has used getopt() or
	// getopt_long() in C.
	while ((c = bc_opt_parse(&opts, bc_args_lopt)) != -1) {

		switch (c) {

			case 'e':
			{
				if (vm.no_exit_exprs)
					bc_verr(BC_ERR_FATAL_OPTION, "-e (--expression)");
				bc_args_exprs(opts.optarg);
				vm.exit_exprs = (exit_exprs || vm.exit_exprs);
				break;
			}

			case 'f':
			{
				if (!strcmp(opts.optarg, "-")) vm.no_exit_exprs = true;
				else {
					if (vm.no_exit_exprs)
						bc_verr(BC_ERR_FATAL_OPTION, "-f (--file)");
					bc_args_file(opts.optarg);
					vm.exit_exprs = (exit_exprs || vm.exit_exprs);
				}
				break;
			}

			case 'h':
			{
				bc_vm_info(vm.help);
				do_exit = true;
				break;
			}

			case 'i':
			{
				vm.flags |= BC_FLAG_I;
				break;
			}

			case 'P':
			{
				vm.flags &= ~(BC_FLAG_P);
				break;
			}

			case 'R':
			{
				vm.flags &= ~(BC_FLAG_R);
				break;
			}

#if BC_ENABLED
			case 'g':
			{
				assert(BC_IS_BC);
				vm.flags |= BC_FLAG_G;
				break;
			}

			case 'l':
			{
				assert(BC_IS_BC);
				vm.flags |= BC_FLAG_L;
				break;
			}

			case 'q':
			{
				assert(BC_IS_BC);
				// Do nothing.
				break;
			}

			case 's':
			{
				assert(BC_IS_BC);
				vm.flags |= BC_FLAG_S;
				break;
			}

			case 'w':
			{
				assert(BC_IS_BC);
				vm.flags |= BC_FLAG_W;
				break;
			}
#endif // BC_ENABLED

			case 'V':
			case 'v':
			{
				do_exit = version = true;
				break;
			}

#if DC_ENABLED
			case 'x':
			{
				assert(BC_IS_DC);
				vm.flags |= DC_FLAG_X;
				break;
			}
#endif // DC_ENABLED

#ifndef NDEBUG
			// We shouldn't get here because bc_opt_error()/bc_error() should
			// longjmp() out.
			case '?':
			case ':':
			default:
			{
				BC_UNREACHABLE
				abort();
			}
#endif // NDEBUG
		}
	}

	if (version) bc_vm_info(NULL);
	if (do_exit) exit((int) vm.status);
	if (!BC_IS_BC || vm.exprs.len > 1) vm.flags &= ~(BC_FLAG_Q);

	// We need to make sure the files list is initialized. We don't want to
	// initialize it if there are no files because it's just a waste of memory.
	if (opts.optind < (size_t) argc && vm.files.v == NULL)
		bc_vec_init(&vm.files, sizeof(char*), BC_DTOR_NONE);

	for (i = opts.optind; i < (size_t) argc; ++i)
		bc_vec_push(&vm.files, argv + i);
}
