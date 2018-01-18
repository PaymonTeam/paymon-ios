//
//  BR_BIP32Sequence.c
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

#include "BR_BIP32Sequence.h"
#include "BR_Crypto.h"
#include "BR_Base58.h"
#include <string.h>
#include <assert.h>

#define BIP32_HARD     0x80000000
#define BIP32_SEED_KEY "Bitcoin seed"
#define BIP32_XPRV     "\x04\x88\xAD\xE4"
#define BIP32_XPUB     "\x04\x88\xB2\x1E"

// BIP32 is a scheme for deriving chains of addresses from a seed value
// https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki

// Private parent key -> private child key
//
// CKDpriv((kpar, cpar), i) -> (ki, ci) computes a child extended private key from the parent extended private key:
//
// - Check whether i >= 2^31 (whether the child is a hardened key).
//     - If so (hardened child): let I = HMAC-SHA512(Key = cpar, Data = 0x00 || ser256(kpar) || ser32(i)).
//       (Note: The 0x00 pads the private key to make it 33 bytes long.)
//     - If not (normal child): let I = HMAC-SHA512(Key = cpar, Data = serP(point(kpar)) || ser32(i)).
// - Split I into two 32-byte sequences, IL and IR.
// - The returned child key ki is parse256(IL) + kpar (mod n).
// - The returned chain code ci is IR.
// - In case parse256(IL) >= n or ki = 0, the resulting key is invalid, and one should proceed with the next value for i
//   (Note: this has probability lower than 1 in 2^127.)
//
static void _CKDpriv(UInt256_t *k, UInt256_t *c, uint32_t i)
{
    uint8_t buf[sizeof(BR_ECPoint) + sizeof(i)];
    UInt512_t I;
    
    if (i & BIP32_HARD) {
        buf[0] = 0;
        UInt256Set(&buf[1], *k);
    }
    else BR_Secp256k1PointGen((BR_ECPoint *)buf, k);
    
    UInt32SetBE(&buf[sizeof(BR_ECPoint)], i);
    
    BR_HMAC(&I, BR_SHA512, sizeof(UInt512_t), c, sizeof(*c), buf, sizeof(buf)); // I = HMAC-SHA512(c, k|P(k) || i)
    
    BR_Secp256k1ModAdd(k, (UInt256_t *)&I); // k = IL + k (mod n)
    *c = *(UInt256_t *)&I.u8[sizeof(UInt256_t)]; // c = IR
    
    var_clean(&I);
    mem_clean(buf, sizeof(buf));
}

// Public parent key -> public child key
//
// CKDpub((Kpar, cpar), i) -> (Ki, ci) computes a child extended public key from the parent extended public key.
// It is only defined for non-hardened child keys.
//
// - Check whether i >= 2^31 (whether the child is a hardened key).
//     - If so (hardened child): return failure
//     - If not (normal child): let I = HMAC-SHA512(Key = cpar, Data = serP(Kpar) || ser32(i)).
// - Split I into two 32-byte sequences, IL and IR.
// - The returned child key Ki is point(parse256(IL)) + Kpar.
// - The returned chain code ci is IR.
// - In case parse256(IL) >= n or Ki is the point at infinity, the resulting key is invalid, and one should proceed with
//   the next value for i.
//
static void _CKDpub(BR_ECPoint *K, UInt256_t *c, uint32_t i)
{
    uint8_t buf[sizeof(*K) + sizeof(i)];
    UInt512_t I;

    if ((i & BIP32_HARD) != BIP32_HARD) { // can't derive private child key from public parent key
        *(BR_ECPoint *)buf = *K;
        UInt32SetBE(&buf[sizeof(*K)], i);
    
        BR_HMAC(&I, BR_SHA512, sizeof(UInt512_t), c, sizeof(*c), buf, sizeof(buf)); // I = HMAC-SHA512(c, P(K) || i)
        
        *c = *(UInt256_t *)&I.u8[sizeof(UInt256_t)]; // c = IR
        BR_Secp256k1PointAdd(K, (UInt256_t *)&I); // K = P(IL) + K

        var_clean(&I);
        mem_clean(buf, sizeof(buf));
    }
}

// returns the master public key for the default BIP32 wallet layout - derivation path N(m/0H)
BR_MasterPubKey BR_BIP32MasterPubKey(const void *seed, size_t seedLen)
{
    BR_MasterPubKey mpk = BR_MASTER_PUBKEY_NONE;
    UInt512_t I;
    UInt256_t secret, chain;
    BR_Key key;

    assert(seed != NULL || seedLen == 0);
    
    if (seed || seedLen == 0) {
        BR_HMAC(&I, BR_SHA512, sizeof(UInt512_t), BIP32_SEED_KEY, strlen(BIP32_SEED_KEY), seed, seedLen);
        secret = *(UInt256_t *)&I;
        chain = *(UInt256_t *)&I.u8[sizeof(UInt256_t)];
        var_clean(&I);
    
        BR_KeySetSecret(&key, &secret, 1);
        mpk.fingerPrint = BR_KeyHash160(&key).u32[0];
        
        _CKDpriv(&secret, &chain, 0 | BIP32_HARD); // path m/0H
    
        mpk.chainCode = chain;
        BR_KeySetSecret(&key, &secret, 1);
        var_clean(&secret, &chain);
        BR_KeyPubKey(&key, &mpk.pubKey, sizeof(mpk.pubKey)); // path N(m/0H)
        BR_KeyClean(&key);
    }
    
    return mpk;
}

// writes the public key for path N(m/0H/chain/index) to pubKey
// returns number of bytes written, or pubKeyLen needed if pubKey is NULL
size_t BR_BIP32PubKey(uint8_t *pubKey, size_t pubKeyLen, BR_MasterPubKey mpk, uint32_t chain, uint32_t index)
{
    UInt256_t chainCode = mpk.chainCode;
    
    assert(memcmp(&mpk, &BR_MASTER_PUBKEY_NONE, sizeof(mpk)) != 0);
    
    if (pubKey && sizeof(BR_ECPoint) <= pubKeyLen) {
        *(BR_ECPoint *)pubKey = *(BR_ECPoint *)mpk.pubKey;

        _CKDpub((BR_ECPoint *)pubKey, &chainCode, chain); // path N(m/0H/chain)
        _CKDpub((BR_ECPoint *)pubKey, &chainCode, index); // index'th key in chain
        var_clean(&chainCode);
    }
    
    return (! pubKey || sizeof(BR_ECPoint) <= pubKeyLen) ? sizeof(BR_ECPoint) : 0;
}

// sets the private key for path m/0H/chain/index to key
void BR_BIP32PrivKey(BR_Key *key, const void *seed, size_t seedLen, uint32_t chain, uint32_t index)
{
    assert(key != NULL);
    assert(seed != NULL || seedLen == 0);
    BR_BIP32PrivKeyList(key, 1, seed, seedLen, chain, &index);
}

// sets the private key for path m/0H/chain/index to each element in keys
void BR_BIP32PrivKeyList(BR_Key keys[], size_t keysCount, const void *seed, size_t seedLen, uint32_t chain,
                        const uint32_t indexes[])
{
    UInt512_t I;
    UInt256_t secret, chainCode, s, c;
    
    assert(keys != NULL || keysCount == 0);
    assert(seed != NULL || seedLen == 0);
    assert(indexes != NULL || keysCount == 0);
    
    if (keys && keysCount > 0 && (seed || seedLen == 0) && indexes) {
        BR_HMAC(&I, BR_SHA512, sizeof(UInt512_t), BIP32_SEED_KEY, strlen(BIP32_SEED_KEY), seed, seedLen);
        secret = *(UInt256_t *)&I;
        chainCode = *(UInt256_t *)&I.u8[sizeof(UInt256_t)];
        var_clean(&I);

        _CKDpriv(&secret, &chainCode, 0 | BIP32_HARD); // path m/0H
        _CKDpriv(&secret, &chainCode, chain); // path m/0H/chain
    
        for (size_t i = 0; i < keysCount; i++) {
            s = secret;
            c = chainCode;
            _CKDpriv(&s, &c, indexes[i]); // index'th key in chain
            BR_KeySetSecret(&keys[i], &s, 1);
        }
        
        var_clean(&secret, &chainCode, &c, &s);
    }
}

// writes the base58check encoded serialized master private key (xprv) to str
// returns number of bytes written including NULL terminator, or strLen needed if str is NULL
size_t BR_BIP32SerializeMasterPrivKey(char *str, size_t strLen, const void *seed, size_t seedLen)
{
    // TODO: XXX implement
    return 0;
}

// writes a master private key to seed given a base58check encoded serialized master private key (xprv)
// returns number of bytes written, or seedLen needed if seed is NULL
size_t BR_BIP32ParseMasterPrivKey(void *seed, size_t seedLen, const char *str)
{
    // TODO: XXX implement
    return 0;
}

// writes the base58check encoded serialized master public key (xpub) to str
// returns number of bytes written including NULL terminator, or strLen needed if str is NULL
size_t BR_BIP32SerializeMasterPubKey(char *str, size_t strLen, BR_MasterPubKey mpk)
{
    // TODO: XXX implement
    return 0;
}

// returns a master public key give a base58check encoded serialized master public key (xpub)
BR_MasterPubKey BR_BIP32ParseMasterPubKey(const char *str)
{
    // TODO: XXX implement
    return BR_MASTER_PUBKEY_NONE;
}

// key used for authenticated API calls, i.e. bitauth: https://github.com/bitpay/bitauth - path m/1H/0
void BR_BIP32APIAuthKey(BR_Key *key, const void *seed, size_t seedLen)
{
    UInt512_t I;
    UInt256_t secret, chainCode;
    
    assert(key != NULL);
    assert(seed != NULL || seedLen == 0);
    
    if (key && (seed || seedLen == 0)) {
        BR_HMAC(&I, BR_SHA512, sizeof(UInt512_t), BIP32_SEED_KEY, strlen(BIP32_SEED_KEY), seed, seedLen);
        secret = *(UInt256_t *)&I;
        chainCode = *(UInt256_t *)&I.u8[sizeof(UInt256_t)];
        var_clean(&I);

        _CKDpriv(&secret, &chainCode, 1 | BIP32_HARD); // path m/1H
        _CKDpriv(&secret, &chainCode, 0); // path m/1H/0
        
        BR_KeySetSecret(key, &secret, 1);
        var_clean(&secret, &chainCode);
    }
}

// key used for BitID: https://github.com/bitid/bitid/blob/master/BIP_draft.md
void BR_BIP32BitIDKey(BR_Key *key, const void *seed, size_t seedLen, uint32_t index, const char *uri)
{
    assert(key != NULL);
    assert(seed != NULL || seedLen == 0);
    assert(uri != NULL);
    
    if (key && (seed || seedLen == 0) && uri) {
        UInt512_t I;
        UInt256_t secret, chainCode, hash;
        size_t uriLen = strlen(uri);
        uint8_t data[sizeof(index) + uriLen];

        UInt32SetLE(data, index);
        memcpy(&data[sizeof(index)], uri, uriLen);
        BR_SHA256(&hash, data, sizeof(data));
    
        BR_HMAC(&I, BR_SHA512, sizeof(UInt512_t), BIP32_SEED_KEY, strlen(BIP32_SEED_KEY), seed, seedLen);
        secret = *(UInt256_t *)&I;
        chainCode = *(UInt256_t *)&I.u8[sizeof(UInt256_t)];
        var_clean(&I);
        
        _CKDpriv(&secret, &chainCode, 13 | BIP32_HARD); // path m/13H
        _CKDpriv(&secret, &chainCode, UInt32GetLE(&hash.u32[0]) | BIP32_HARD); // path m/13H/aH
        _CKDpriv(&secret, &chainCode, UInt32GetLE(&hash.u32[1]) | BIP32_HARD); // path m/13H/aH/bH
        _CKDpriv(&secret, &chainCode, UInt32GetLE(&hash.u32[2]) | BIP32_HARD); // path m/13H/aH/bH/cH
        _CKDpriv(&secret, &chainCode, UInt32GetLE(&hash.u32[3]) | BIP32_HARD); // path m/13H/aH/bH/cH/dH
        
        BR_KeySetSecret(key, &secret, 1);
        var_clean(&secret, &chainCode);
    }
}

