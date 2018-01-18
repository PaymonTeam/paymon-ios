//
//  BR_Set.h
//
//  Created by Aaron Voisine on 9/11/15.
//  Copyright (c) 2015 breadwallet LLC
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#ifndef BR_Set_h
#define BR_Set_h

#include <stddef.h>
#include <inttypes.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct BR_SetStruct BR_Set;

// retruns a newly allocated empty set that must be freed by calling BR_SetFree()
// size_t hash(const void *) is a function that returns a hash value for a given set item
// int eq(const void *, const void *) is a function that returns true if two set items are equal
// any two items that are equal must also have identical hash values
// capacity is the initial number of items the set can hold, which will be auto-increased as needed
BR_Set *BR_SetNew(size_t (*hash)(const void *), int (*eq)(const void *, const void *), size_t capacity);

// adds given item to set or replaces an equivalent existing item and returns item replaced if any
void *BR_SetAdd(BR_Set *set, void *item);

// removes item equivalent to given item from set and returns item removed if any
void *BR_SetRemove(BR_Set *set, const void *item);

// removes all items from set
void BR_SetClear(BR_Set *set);

// returns the number of items in set
size_t BR_SetCount(const BR_Set *set);

// true if an item equivalant to the given item is contained in set
int BR_SetContains(const BR_Set *set, const void *item);

// true if any items in otherSet are contained in set
int BR_SetIntersects(const BR_Set *set, const BR_Set *otherSet);

// returns member item from set equivalent to given item, or NULL if there is none
void *BR_SetGet(const BR_Set *set, const void *item);

// interates over set and returns the next item after previous, or NULL if no more items are available
// if previous is NULL, an initial item is returned
void *BR_SetIterate(const BR_Set *set, const void *previous);

// writes up to count items from set to allItems and returns number of items written
size_t BR_SetAll(const BR_Set *set, void *allItems[], size_t count);

// calls apply() with each item in set
void BR_SetApply(const BR_Set *set, void *info, void (*apply)(void *info, void *item));

// adds or replaces items from otherSet into set
void BR_SetUnion(BR_Set *set, const BR_Set *otherSet);

// removes items contained in otherSet from set
void BR_SetMinus(BR_Set *set, const BR_Set *otherSet);

// removes items not contained in otherSet from set
void BR_SetIntersect(BR_Set *set, const BR_Set *otherSet);

// frees memory allocated for set
void BR_SetFree(BR_Set *set);

#ifdef __cplusplus
}
#endif

#endif // BR_Set_h
