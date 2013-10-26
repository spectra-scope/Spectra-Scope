/*Copyright (c) <2013>, <Tian Lin Tan>
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditionsare met:

1.	Redistributions of source code must retain the above copyright notice,
	this list of conditions and the following disclaimer.
2.	Redistributions in binary form must reproduce the above copyright
	notice, this list of conditions and the following disclaimer in the
	documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
*/
#ifndef HASHSETV_H
#define HASHSETV_H
typedef unsigned (*hs_hash)(void const *);
typedef int (*hs_cmp)(void const *, void const *);
struct hashset;
struct hashset * hashset_new(unsigned ele_size, hs_cmp cmp, hs_hash);
void hashset_del(struct hashset *);
void * hashset_get(struct hashset *, void const *);
int hashset_insert(struct hashset *, void const *);
int hashset_insert_s(struct hashset *, void const *, unsigned size);
int hashset_remove(struct hashset *, void const *);

struct hashset_iter;
struct hashset_iter * hashset_iter_new(struct hashset *);
void hashset_iter_del(struct hashset_iter *);
int hashset_iter_next(struct hashset_iter *);
void const * hashset_iter_get(struct hashset_iter *);
#endif
