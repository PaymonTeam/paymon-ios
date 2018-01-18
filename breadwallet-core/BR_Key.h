//
//  BR_Key.h
//
//  Created by Aaron Voisine on 8/19/15.
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

#ifndef BR_Key_h
#define BR_Key_h

#include "BR_Int.h"
#include <stddef.h>
#include <inttypes.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    uint8_t p[33];
} BR_ECPoint;

// adds 256bit big endian ints a and b (mod secp256k1 order) and stores the result in a
// returns true on success
int BR_Secp256k1ModAdd(UInt256_t *a, const UInt256_t *b);

// multiplies 256bit big endian ints a and b (mod secp256k1 order) and stores the result in a
// returns true on success
int BR_Secp256k1ModMul(UInt256_t *a, const UInt256_t *b);

// multiplies secp256k1 generator by 256bit big endian int i and stores the result in p
// returns true on success
int BR_Secp256k1PointGen(BR_ECPoint *p, const UInt256_t *i);

// multiplies secp256k1 generator by 256bit big endian int i and adds the result to ec-point p
// returns true on success
int BR_Secp256k1PointAdd(BR_ECPoint *p, const UInt256_t *i);

// multiplies secp256k1 ec-point p by 256bit big endian int i and stores the result in p
// returns true on success
int BR_Secp256k1PointMul(BR_ECPoint *p, const UInt256_t *i);

// returns true if privKey is a valid private key
// supported formats are wallet import format (WIF), mini private key format, or hex string
int BR_PrivKeyIsValid(const char *privKey);

typedef struct {
    UInt256_t secret;
    uint8_t pubKey[65];
    int compressed;
} BR_Key;

// assigns secret to key and returns true on success
int BR_KeySetSecret(BR_Key *key, const UInt256_t *secret, int compressed);

// assigns privKey to key and returns true on success
// privKey must be wallet import format (WIF), mini private key format, or hex string
int BR_KeySetPrivKey(BR_Key *key, const char *privKey);

// assigns DER encoded pubKey to key and returns true on success
int BR_KeySetPubKey(BR_Key *key, const uint8_t *pubKey, size_t pkLen);

// writes the WIF private key to privKey and returns the number of bytes writen, or pkLen needed if privKey is NULL
// returns 0 on failure
size_t BR_KeyPrivKey(const BR_Key *key, char *privKey, size_t pkLen);

// writes the DER encoded public key to pubKey and returns number of bytes written, or pkLen needed if pubKey is NULL
size_t BR_KeyPubKey(BR_Key *key, void *pubKey, size_t pkLen);

// returns the ripemd160 hash of the sha256 hash of the public key, or UINT160_ZERO on error
UInt160_t BR_KeyHash160(BR_Key *key);

// writes the pay-to-pubkey-hash bitcoin address for key to addr
// returns the number of bytes written, or addrLen needed if addr is NULL
size_t BR_KeyAddress(BR_Key *key, char *addr, size_t addrLen);

// signs md with key and writes signature to sig
// returns the number of bytes written, or sigLen needed if sig is NULL
// returns 0 on failure
size_t BR_KeySign(const BR_Key *key, void *sig, size_t sigLen, UInt256_t md);

// returns true if the signature for md is verified to have been made by key
int BR_KeyVerify(BR_Key *key, UInt256_t md, const void *sig, size_t sigLen);

// wipes key material from key
void BR_KeyClean(BR_Key *key);

// Pieter Wuille's compact signature encoding used for bitcoin message signing
// to verify a compact signature, recover a public key from the signature and verify that it matches the signer's pubkey
size_t BR_KeyCompactSign(const BR_Key *key, void *compactSig, size_t sigLen, UInt256_t md);

// assigns pubKey recovered from compactSig to key and returns true on success
int BR_KeyRecoverPubKey(BR_Key *key, UInt256_t md, const void *compactSig, size_t sigLen);

#ifdef __cplusplus
}
#endif

#endif // BR_Key_h
