/**
 * @file ptree.h
 * @brief The parse tree object.
 * @class ln_ptree ptree.h
 *//*
 * Copyright 2010 by Rainer Gerhards and Adiscon GmbH.
 *
 * This file is meant to be included by applications using liblognorm.
 * For lognorm library files themselves, include "lognorm.h".
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
#ifndef LIBLOGNORM_PTREE_H_INCLUDED
#define	LIBLOGNORM_PTREE_H_INCLUDED
#include <libestr.h>
#include <libee/libee.h>

typedef struct ln_ptree ln_ptree; /**< the parse tree object */
typedef struct ln_fieldList_s ln_fieldList_t;

/**
 * List of supported fields inside parse tree.
 * This list holds all fields and their description. While normalizing,
 * fields are tried in the order of this list. So the enqeue order
 * dictates precedence during parsing.
 *
 * value list. This is a single-linked list. In a later stage, we should
 * optimize it so that frequently used fields are moved "up" towards
 * the root of the list. In any case, we do NOT expect this list to
 * be long, as the parser should already have gotten quite specific when
 * we hit a field.
 */
struct ln_fieldList_s {
	es_str_t *name;		/**< field name */
	es_str_t *data;		/**< extra data to be passed to parser */
	int (*parser)(ee_ctx, es_str_t*, es_size_t*, es_str_t*, struct ee_value**);
				/**< parser to use */
	ln_ptree *subtree;	/**< subtree to follow if parser succeeded */
	ln_fieldList_t *next;	/**< list housekeeping, next node (or NULL) */
	unsigned char isIPTables; /**< special parser: iptables! */
};


/* parse tree object
 */
struct ln_ptree {
	ln_ctx		ctx;	/**< our context */
	ln_ptree	**parentptr; /**< pointer to *us* *inside* the parent 
				BUT this is NOT a pointer to the parent! */
	ln_fieldList_t	*froot; /**< root of field list */
	ln_fieldList_t	*ftail; /**< tail of field list */
	struct {
		unsigned isTerminal:1;	/**< designates this node a terminal sequence? */
	} flags;
	struct ee_tagbucket *tags;	/* tags to assign to events of this type */
	/* the respresentation below requires a lof of memory but is
	 * very fast. As an alternate approach, we can use a hash table
	 * where we ignore control characters. That should work quite well.
	 * But we do not do this in the initial step.
	 */
	ln_ptree	*subtree[256];
	unsigned short	lenPrefix;	/**< length of common prefix, 0->none */
	union {
		unsigned char *ptr;	/**< use if data element is too large */
		unsigned char data[16]; /**< fast lookup for small string */
	} prefix;	/**< a common prefix string for all of this node */
};


/* Methods */

/**
 * Allocates and initializes a new parse tree node.
 * @memberof ln_ptree
 *
 * @param[in] ctx current library context. This MUST match the
 * 		context of the parent.
 * @param[in] parent pointer to the new node inside the parent
 *
 * @return pointer to new node or NULL on error
 */
struct ln_ptree* ln_newPTree(ln_ctx ctx, struct ln_ptree** parent);


/**
 * Free a parse tree node and destruct all members.
 * @memberof ln_ptree
 *
 * @param[in] tree pointer to ptree to free
 */
void ln_deletePTree(struct ln_ptree *tree);


/**
 * Add a field description to the a tree.
 * The field description will be added as last field. Fields are
 * parsed in the order they have been added, so be sure to care
 * about the order if that matters.
 * @memberof ln_ptree
 *
 * @param[in] tree pointer to ptree to modify
 * @param[in] fielddescr a fully populated (and initialized) 
 * 		field description node
 * @returns 0 on success, something else otherwise
 */
int ln_addFDescrToPTree(struct ln_ptree **tree, ln_fieldList_t *node);


/**
 * Traverse a (sub) tree according to a string.
 *
 * This functions traverses the provided tree according to the
 * provided string. It navigates to the deepest node possible.
 * Then, it returns this node as well as the position until which
 * the string could be parsed. If there is no match at all,
 * NULL is returned instead of a tree node. Note that this is
 * different from the case where the root of the subtree is
 * returned. In that case, there was at least a single match
 * inside that root.
 * @memberof ln_ptree
 *
 * @param[in] subtree root of subtree to traverse
 * @param[in] str string to parse
 * @param[in/out] parsedTo on entry: start position within string,
 * 	          on exist position of first unmatched byte
 *
 * @return pointer to found tree node or NULL if there was no match at all
 */
struct ln_ptree* ln_traversePTree(struct ln_ptree *subtree,
                               es_str_t *str, es_size_t *parsedTo);


/**
 * Add a literal to a ptree.
 * Creates new tree nodes as necessary.
 * @memberof ln_ptree
 *
 * @param[in] tree root of tree where to add
 * @param[in] str literal (string) to add
 * @param[in] offs offset of where in literal adding should start
 *
 * @return NULL on error, otherwise pointer to deepest tree added
 */
struct ln_ptree*
ln_addPTree(struct ln_ptree *tree, es_str_t *str, es_size_t offs);


/**
 * Display the content of a ptree (debug function).
 * This is a debug aid that spits out a textual representation
 * of the provided ptree via multiple calls of the debug callback.
 *
 * @param tree ptree to display
 * @param level recursion level, must be set to 0 on initial call
 */
void ln_displayPTree(struct ln_ptree *tree, int level);


/**
 * Generate a DOT graph.
 * Well, actually it does not generate the graph itself, but a
 * control file that is suitable for the GNU DOT tool. Such a file
 * can be very useful to understand complex sample databases
 * (not to mention that it is probably fun for those creating
 * samples).
 * The dot commands are appended to the provided string.
 *
 * @param[in] tree ptree to display
 * @param[out] str string which receives the DOT commands.
 */
void ln_genDotPTreeGraph(struct ln_ptree *tree, es_str_t **str);


/**
 * Build a ptree based on the provided string, but only if necessary.
 * The passed-in tree is searched and traversed for str. If a node exactly
 * matching str is found, that node is returned. If no exact match is found,
 * a new node is added. Existing nodes may be split, if a so-far common
 * prefix needs to be split in order to add the new node.
 *
 * @param[in] tree root of the current tree
 * @param[in] str string to be added
 * @param[in] offs offset into str where match needs to start
 *             (this is required for recursive calls to handle
 *             common prefixes)
 * @return NULL on error, otherwise the ptree leaf that
 *         corresponds to the parameters passed.
 */
struct ln_ptree * ln_buildPTree(struct ln_ptree *tree, es_str_t *str, es_size_t offs);

#endif /* #ifndef LOGNORM_PTREE_H_INCLUDED */
