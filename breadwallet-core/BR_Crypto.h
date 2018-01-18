//
//  BR_Crypto.h
//
//  Created by Aaron Voisine on 8/8/15.
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

#ifndef BR_Crypto_h
#define BR_Crypto_h

#include <stdarg.h>
#include <stddef.h>
#include <inttypes.h>

#ifdef __cplusplus
extern "C" {
#endif

// sha-1 - not recommended for cryptographic use
void BR_SHA1(void *md20, const void *data, size_t len);

void BR_SHA256(void *md32, const void *data, size_t len);

void BR_SHA224(void *md28, const void *data, size_t len);

// double-sha-256 = sha-256(sha-256(x))
void BR_SHA256_2(void *md32, const void *data, size_t len);

void BR_SHA384(void *md48, const void *data, size_t len);

void BR_SHA512(void *md64, const void *data, size_t len);

// ripemd-160: http://homes.esat.kuleuven.be/~bosselae/ripemd160.html
void BR_RMD160(void *md20, const void *data, size_t len);

// bitcoin hash-160 = ripemd-160(sha-256(x))
void BR_Hash160(void *md20, const void *data, size_t len);

// md5 - for non-cryptographic use only
void BR_MD5(void *md16, const void *data, size_t len);

// murmurHash3 (x86_32): https://code.google.com/p/smhasher/ - for non cryptographic use only
uint32_t BR_Murmur3_32(const void *data, size_t len, uint32_t seed);

void BR_HMAC(void *mac, void (*hash)(void *, const void *, size_t), size_t hashLen, const void *key, size_t keyLen,
            const void *data, size_t dataLen);

// hmac-drbg with no prediction resistance or additional input
// K and V must point to buffers of size hashLen, and ps (personalization string) may be NULL
// to generate additional drbg output, use K and V from the previous call, and set seed, nonce and ps to NULL
void BR_HMACDRBG(void *out, size_t outLen, void *K, void *V, void (*hash)(void *, const void *, size_t), size_t hashLen,
                const void *seed, size_t seedLen, const void *nonce, size_t nonceLen, const void *ps, size_t psLen);

// poly1305 authenticator: https://tools.ietf.org/html/rfc7539
// NOTE: must use constant time mem comparison when verifying mac to defend against timing attacks
void BR_Poly1305(void *mac16, const void *key32, const void *data, size_t len);

// chacha20 stream cypher: https://cr.yp.to/chacha.html
void BR_Chacha20(void *out, const void *key32, const void *iv8, const void *data, size_t len, uint64_t counter);
    
// chacha20-poly1305 authenticated encryption with associated data (AEAD): https://tools.ietf.org/html/rfc7539
size_t BR_Chacha20Poly1305AEADEncrypt(void *out, size_t outLen, const void *key32, const void *nonce12,
                                     const void *data, size_t dataLen, const void *ad, size_t adLen);

size_t BR_Chacha20Poly1305AEADDecrypt(void *out, size_t outLen, const void *key32, const void *nonce12,
                                     const void *data, size_t dataLen, const void *ad, size_t adLen);
    
void BR_PBKDF2(void *dk, size_t dkLen, void (*hash)(void *, const void *, size_t), size_t hashLen,
              const void *pw, size_t pwLen, const void *salt, size_t saltLen, unsigned rounds);

// scrypt key derivation: http://www.tarsnap.com/scrypt.html
void BR_Scrypt(void *dk, size_t dkLen, const void *pw, size_t pwLen, const void *salt, size_t saltLen,
              unsigned n, unsigned r, unsigned p);

// zeros out memory in a way that can't be optimized out by the compiler
inline static void mem_clean(void *ptr, size_t len)
{
    void *(*volatile const memset_ptr)(void *, int, size_t) = memset;
    memset_ptr(ptr, 0, len);
}

#define var_clean(...) _var_clean(sizeof(*(_va_first(__VA_ARGS__))), __VA_ARGS__, NULL)
#define _va_first(first, ...) first

inline static void _var_clean(size_t size, ...)
{
    va_list args;
    va_start(args, size);
    for (void *ptr = va_arg(args, void *); ptr; ptr = va_arg(args, void *)) mem_clean(ptr, size);
    va_end(args);
}
    
#ifdef __cplusplus
}
#endif

#endif // BR_Crypto_h
