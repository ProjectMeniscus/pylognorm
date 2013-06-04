/**
 * @file samples.h
 * @brief Object to process log samples.
 * @author Rainer Gerhards
 *
 * This object handles log samples, and in actual log sample files.
 * It co-operates with the ptree object to build the actual parser tree.
 *//*
 *
 * liblognorm - a fast samples-based log normalization library
 * Copyright 2010 by Rainer Gerhards and Adiscon GmbH.
 *
 * This file is part of liblognorm.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 * A copy of the LGPL v2.1 can be found in the file "COPYING" in this distribution.
 */
#ifndef LIBLOGNORM_SAMPLES_H_INCLUDED
#define	LIBLOGNORM_SAMPLES_H_INCLUDED
#include <stdio.h>	/* we need es_size_t */
#include <libestr.h>


/**
 * Object that represents a sample repository (file).
 *
 * Doing this via an objects helps with abstraction and future
 * changes inside the module (which are anticipated).
 */
struct ln_sampRepos {
	FILE *fp;
};

/**
 * A single log sample.
 */
struct ln_samp {
	es_str_t *msg;
};

/**
 * Open a Sample Repository.
 *
 * @param[in] ctx current library context
 * @param[in] name file name
 * @return repository object or NULL if failure
 */
struct ln_sampRepos *
ln_sampOpen(ln_ctx ctx, char *name);


/**
 * Close sample file.
 *
 * @param[in] ctx current library context
 * @param[in] fd file descriptor of open sample file
 */
void
ln_sampClose(ln_ctx ctx, struct ln_sampRepos *repo);


/**
 * Read a sample from repository (sequentially).
 *
 * Reads a sample starting with the current file position and
 * creates a new ln_samp object out of it. 
 *
 * @note
 * It is the caller's responsibility to delete the newly
 * created ln_samp object if it is no longer needed.
 *
 * @param[in] ctx current library context
 * @param[in] repo repository descriptor
 * @param[out] isEof must be set to 0 on entry and is switched to 1 if EOF occured.
 * @return Newly create object or NULL if an error or EOF occured.
 */
struct ln_samp *
ln_sampRead(ln_ctx ctx, struct ln_sampRepos *repo, int *isEof);


/**
 * Free ln_samp object.
 */
void
ln_sampFree(ln_ctx ctx, struct ln_samp *samp);

#endif /* #ifndef LIBLOGNORM_SAMPLES_H_INCLUDED */
