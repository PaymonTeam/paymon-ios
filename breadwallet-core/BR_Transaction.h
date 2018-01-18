//
//  BR_Transaction.h
//
//  Created by Aaron Voisine on 8/31/15.
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

#ifndef BR_Transaction_h
#define BR_Transaction_h

#include "BR_Key.h"
#include <stddef.h>
#include <inttypes.h>

#ifdef __cplusplus
extern "C" {
#endif

#define TX_FEE_PER_KB        1000ULL     // standard tx fee per kb of tx size, rounded up to nearest kb
#define TX_OUTPUT_SIZE       34          // estimated size for a typical transaction output
#define TX_INPUT_SIZE        148         // estimated size for a typical compact pubkey transaction input
#define TX_MIN_OUTPUT_AMOUNT (TX_FEE_PER_KB*3*(TX_OUTPUT_SIZE + TX_INPUT_SIZE)/1000) //no txout can be below this amount
// 1000*3*(34+148)/1000
#define TX_MAX_SIZE          100000      // no tx can be larger than this size in bytes
#define TX_FREE_MAX_SIZE     1000        // tx must not be larger than this size in bytes without a fee
#define TX_FREE_MIN_PRIORITY 57600000ULL // tx must not have a priority below this value without a fee
#define TX_UNCONFIRMED       INT32_MAX   // block height indicating transaction is unconfirmed
#define TX_MAX_LOCK_HEIGHT   500000000   // a lockTime below this value is a block height, otherwise a timestamp

#define TXIN_SEQUENCE        UINT32_MAX  // sequence number for a finalized tx input

#define SATOSHIS             100000000LL
#define MAX_MONEY            (21000000LL*SATOSHIS)

#define BR_RAND_MAX          ((RAND_MAX > 0x7fffffff) ? 0x7fffffff : RAND_MAX)

// returns a random number less than upperBound (for non-cryptographic use only)
uint32_t BR_Rand(uint32_t upperBound);

typedef struct {
    UInt256_t txHash;
    uint32_t index;
    char address[36];
    uint64_t amount;
    uint8_t *script;
    size_t scriptLen;
    uint8_t *signature;
    size_t sigLen;
    uint32_t sequence;
} BR_TxInput;

void BR_TxInputSetAddress(BR_TxInput *input, const char *address);
void BR_TxInputSetScript(BR_TxInput *input, const uint8_t *script, size_t scriptLen);
void BR_TxInputSetSignature(BR_TxInput *input, const uint8_t *signature, size_t sigLen);

typedef struct {
    char address[36];
    uint64_t amount;
    uint8_t *script;
    size_t scriptLen;
} BR_TxOutput;

#define BR_TX_OUTPUT_NONE ((BR_TxOutput) { "", 0, NULL, 0 })

// when creating a BR_TxOutput struct outside of a BR_Transaction, set address or script to NULL when done to free memory
void BR_TxOutputSetAddress(BR_TxOutput *output, const char *address);
void BR_TxOutputSetScript(BR_TxOutput *output, const uint8_t *script, size_t scriptLen);

typedef struct {
    UInt256_t txHash;
    uint32_t version;
    BR_TxInput *inputs;
    size_t inCount;
    BR_TxOutput *outputs;
    size_t outCount;
    uint32_t lockTime;
    uint32_t blockHeight;
    uint32_t timestamp; // time interval since unix epoch
} BR_Transaction;

// returns a newly allocated empty transaction that must be freed by calling BR_TransactionFree()
BR_Transaction *BR_TransactionNew(void);

// buf must contain a serialized tx
// retruns a transaction that must be freed by calling BR_TransactionFree()
BR_Transaction *BR_TransactionParse(const uint8_t *buf, size_t bufLen);

// returns number of bytes written to buf, or total bufLen needed if buf is NULL
// (tx->blockHeight and tx->timestamp are not serialized)
size_t BR_TransactionSerialize(const BR_Transaction *tx, uint8_t *buf, size_t bufLen);

// adds an input to tx
void BR_TransactionAddInput(BR_Transaction *tx, UInt256_t txHash, uint32_t index, uint64_t amount,
                           const uint8_t *script, size_t scriptLen, const uint8_t *signature, size_t sigLen,
                           uint32_t sequence);

// adds an output to tx
void BR_TransactionAddOutput(BR_Transaction *tx, uint64_t amount, const uint8_t *script, size_t scriptLen);

// shuffles order of tx outputs
void BR_TransactionShuffleOutputs(BR_Transaction *tx);

// size in bytes if signed, or estimated size assuming compact pubkey sigs
size_t BR_TransactionSize(const BR_Transaction *tx);

// minimum transaction fee needed for tx to relay across the bitcoin network
uint64_t BR_TransactionStandardFee(const BR_Transaction *tx);

// checks if all signatures exist, but does not verify them
int BR_TransactionIsSigned(const BR_Transaction *tx);

// adds signatures to any inputs with NULL signatures that can be signed with any keys
// forkId is 0 for bitcoin, 0x40 for b-cash
// returns true if tx is signed
int BR_TransactionSign(BR_Transaction *tx, int forkId, BR_Key keys[], size_t keysCount);

// true if tx meets IsStandard() rules: https://bitcoin.org/en/developer-guide#standard-transactions
int BR_TransactionIsStandard(const BR_Transaction *tx);

// returns a hash value for tx suitable for use in a hashtable
inline static size_t BR_TransactionHash(const void *tx)
{
    return (size_t)((const BR_Transaction *)tx)->txHash.u32[0];
}

// true if tx and otherTx have equal txHash values
inline static int BR_TransactionEq(const void *tx, const void *otherTx)
{
    return (tx == otherTx || UInt256Eq(((const BR_Transaction *)tx)->txHash, ((const BR_Transaction *)otherTx)->txHash));
}

// frees memory allocated for tx
void BR_TransactionFree(BR_Transaction *tx);

#ifdef __cplusplus
}
#endif

#endif // BR_Transaction_h
