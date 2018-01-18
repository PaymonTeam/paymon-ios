//
//  BR_Transaction.c
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

#include "BR_Transaction.h"
#include "BR_Key.h"
#include "BR_Address.h"
#include "BR_Array.h"
#include <stdlib.h>
#include <inttypes.h>
#include <limits.h>
#include <time.h>
#include <unistd.h>

#define TX_VERSION           0x00000001
#define TX_LOCKTIME          0x00000000
#define SIGHASH_ALL          0x01 // default, sign all of the outputs
#define SIGHASH_NONE         0x02 // sign none of the outputs, I don't care where the bitcoins go
#define SIGHASH_SINGLE       0x03 // sign one of the outputs, I don't care where the other outputs go
#define SIGHASH_ANYONECANPAY 0x80 // let other people add inputs, I don't care where the rest of the bitcoins come from
#define SIGHASH_FORKID       0x40 // use BIP143 digest method (for b-cash signatures)

// returns a random number less than upperBound, for non-cryptographic use only
uint32_t BR_Rand(uint32_t upperBound)
{
    static int first = 1;
    uint32_t r;
    
    // seed = (((FNV_OFFSET xor time)*FNV_PRIME) xor pid)*FNV_PRIME
    if (first) srand((((0x811C9dc5 ^ (unsigned)time(NULL))*0x01000193) ^ (unsigned)getpid())*0x01000193);
    first = 0;
    if (upperBound == 0 || upperBound > BR_RAND_MAX) upperBound = BR_RAND_MAX;
    
    do { // to avoid modulo bias, find a rand value not less than 0x100000000 % upperBound
        r = rand();
    } while (r < ((0xffffffff - upperBound*2) + 1) % upperBound); // (((0xffffffff - x*2) + 1) % x) == (0x100000000 % x)

    return r % upperBound;
}

void BR_TxInputSetAddress(BR_TxInput *input, const char *address)
{
    assert(input != NULL);
    assert(address == NULL || BR_AddressIsValid(address));
    if (input->script) array_free(input->script);
    input->script = NULL;
    input->scriptLen = 0;
    memset(input->address, 0, sizeof(input->address));

    if (address) {
        strncpy(input->address, address, sizeof(input->address) - 1);
        input->scriptLen = BR_AddressScriptPubKey(NULL, 0, address);
        array_new(input->script, input->scriptLen);
        array_set_count(input->script, input->scriptLen);
        BR_AddressScriptPubKey(input->script, input->scriptLen, address);
    }
}

void BR_TxInputSetScript(BR_TxInput *input, const uint8_t *script, size_t scriptLen)
{
    assert(input != NULL);
    assert(script != NULL || scriptLen == 0);
    if (input->script) array_free(input->script);
    input->script = NULL;
    input->scriptLen = 0;
    memset(input->address, 0, sizeof(input->address));
    
    if (script) {
        input->scriptLen = scriptLen;
        array_new(input->script, scriptLen);
        array_add_array(input->script, script, scriptLen);
        BR_AddressFromScriptPubKey(input->address, sizeof(input->address), script, scriptLen);
    }
}

void BR_TxInputSetSignature(BR_TxInput *input, const uint8_t *signature, size_t sigLen)
{
    assert(input != NULL);
    assert(signature != NULL || sigLen == 0);
    if (input->signature) array_free(input->signature);
    input->signature = NULL;
    input->sigLen = 0;
    
    if (signature) {
        input->sigLen = sigLen;
        array_new(input->signature, sigLen);
        array_add_array(input->signature, signature, sigLen);
        if (! input->address[0]) BR_AddressFromScriptSig(input->address, sizeof(input->address), signature, sigLen);
    }
}

static size_t _BR_TxInputData(const BR_TxInput *input, uint8_t *data, size_t dataLen)
{
    size_t off = 0;
    
    if (data && off + sizeof(UInt256_t) <= dataLen) memcpy(&data[off], &input->txHash, sizeof(UInt256_t)); // previous out
    off += sizeof(UInt256_t);
    if (data && off + sizeof(uint32_t) <= dataLen) UInt32SetLE(&data[off], input->index);
    off += sizeof(uint32_t);
    off += BR_VarIntSet((data ? &data[off] : NULL), (off <= dataLen ? dataLen - off : 0), input->sigLen);
    if (data && off + input->sigLen <= dataLen) memcpy(&data[off], input->signature, input->sigLen); // scriptSig
    off += input->sigLen;

    if (input->amount != 0) {
        if (data && off + sizeof(uint64_t) <= dataLen) UInt64SetLE(&data[off], input->amount);
        off += sizeof(uint64_t);
    }

    if (data && off + sizeof(uint32_t) <= dataLen) UInt32SetLE(&data[off], input->sequence);
    off += sizeof(uint32_t);
    return (! data || off <= dataLen) ? off : 0;
}

void BR_TxOutputSetAddress(BR_TxOutput *output, const char *address)
{
    assert(output != NULL);
    assert(address == NULL || BR_AddressIsValid(address));
    if (output->script) array_free(output->script);
    output->script = NULL;
    output->scriptLen = 0;
    memset(output->address, 0, sizeof(output->address));

    if (address) {
        strncpy(output->address, address, sizeof(output->address) - 1);
        output->scriptLen = BR_AddressScriptPubKey(NULL, 0, address);
        array_new(output->script, output->scriptLen);
        array_set_count(output->script, output->scriptLen);
        BR_AddressScriptPubKey(output->script, output->scriptLen, address);
    }
}

void BR_TxOutputSetScript(BR_TxOutput *output, const uint8_t *script, size_t scriptLen)
{
    assert(output != NULL);
    if (output->script) array_free(output->script);
    output->script = NULL;
    output->scriptLen = 0;
    memset(output->address, 0, sizeof(output->address));

    if (script) {
        output->scriptLen = scriptLen;
        array_new(output->script, scriptLen);
        array_add_array(output->script, script, scriptLen);
        BR_AddressFromScriptPubKey(output->address, sizeof(output->address), script, scriptLen);
    }
}

static size_t _BR_TransactionOutputData(const BR_Transaction *tx, uint8_t *data, size_t dataLen, size_t index)
{
    BR_TxOutput *output;
    size_t i, off = 0;
    
    for (i = (index == SIZE_MAX ? 0 : index); i < tx->outCount && (index == SIZE_MAX || index == i); i++) {
        output = &tx->outputs[i];
        if (data && off + sizeof(uint64_t) <= dataLen) UInt64SetLE(&data[off], output->amount);
        off += sizeof(uint64_t);
        off += BR_VarIntSet((data ? &data[off] : NULL), (off <= dataLen ? dataLen - off : 0), output->scriptLen);
        if (data && off + output->scriptLen <= dataLen) memcpy(&data[off], output->script, output->scriptLen);
        off += output->scriptLen;
    }
    
    return (! data || off <= dataLen) ? off : 0;
}

// writes the BIP143 witness program data that needs to be hashed and signed for the tx input at index
// https://github.com/bitcoin/bips/blob/master/bip-0143.mediawiki
// an index of SIZE_MAX will write the entire signed transaction
// returns number of bytes written, or total len needed if data is NULL
static size_t _BR_TransactionWitnessData(const BR_Transaction *tx, uint8_t *data, size_t dataLen, size_t index,
                                        int hashType)
{
    BR_TxInput input;
    int anyoneCanPay = (hashType & SIGHASH_ANYONECANPAY), sigHash = (hashType & 0x1f);
    size_t i, off = 0;
    
    if (index >= tx->inCount) return 0;
    if (data && off + sizeof(uint32_t) <= dataLen) UInt32SetLE(&data[off], tx->version); // tx version
    off += sizeof(uint32_t);
    
    if (! anyoneCanPay) {
        uint8_t buf[(sizeof(UInt256_t) + sizeof(uint32_t))*tx->inCount];
        
        for (i = 0; i < tx->inCount; i++) {
            UInt256Set(&buf[(sizeof(UInt256_t) + sizeof(uint32_t))*i], tx->inputs[i].txHash);
            UInt32SetLE(&buf[(sizeof(UInt256_t) + sizeof(uint32_t))*i + sizeof(UInt256_t)], tx->inputs[i].index);
        }
        
        if (data && off + sizeof(UInt256_t) <= dataLen) BR_SHA256_2(&data[off], buf, sizeof(buf)); // inputs hash
    }
    else if (data && off + sizeof(UInt256_t) <= dataLen) UInt256Set(&data[off], UINT256_ZERO); // anyone-can-pay
    
    off += sizeof(UInt256_t);
    
    if (! anyoneCanPay && sigHash != SIGHASH_SINGLE && sigHash != SIGHASH_NONE) {
        uint8_t buf[sizeof(uint32_t)*tx->inCount];
        
        for (i = 0; i < tx->inCount; i++) UInt32SetLE(&buf[sizeof(uint32_t)*i], tx->inputs[i].sequence);
        if (data && off + sizeof(UInt256_t) <= dataLen) BR_SHA256_2(&data[off], buf, sizeof(buf)); // sequence hash
    }
    else if (data && off + sizeof(UInt256_t) <= dataLen) UInt256Set(&data[off], UINT256_ZERO);
    
    off += sizeof(UInt256_t);
    input = tx->inputs[index];
    input.signature = input.script; // TODO: handle OP_CODESEPARATOR
    input.sigLen = input.scriptLen;
    off += _BR_TxInputData(&input, (data ? &data[off] : NULL), (off <= dataLen ? dataLen - off : 0));
    
    if (sigHash != SIGHASH_SINGLE && sigHash != SIGHASH_NONE) {
        size_t bufLen = _BR_TransactionOutputData(tx, NULL, 0, SIZE_MAX);
        uint8_t _buf[(bufLen <= 0x1000) ? bufLen : 0], *buf = (bufLen <= 0x1000) ? _buf : malloc(bufLen);
        
        bufLen = _BR_TransactionOutputData(tx, buf, bufLen, SIZE_MAX);
        if (data && off + sizeof(UInt256_t) <= dataLen) BR_SHA256_2(&data[off], buf, bufLen); // SIGHASH_ALL outputs hash
        if (buf != _buf) free(buf);
    }
    else if (sigHash == SIGHASH_SINGLE && index < tx->outCount) {
        uint8_t buf[_BR_TransactionOutputData(tx, NULL, 0, index)];
        size_t bufLen = _BR_TransactionOutputData(tx, buf, sizeof(buf), index);
        
        if (data && off + sizeof(UInt256_t) <= dataLen) BR_SHA256_2(&data[off], buf, bufLen); //SIGHASH_SINGLE outputs hash
    }
    else if (data && off + sizeof(UInt256_t) <= dataLen) UInt256Set(&data[off], UINT256_ZERO); // SIGHASH_NONE
    
    off += sizeof(UInt256_t);
    if (data && off + sizeof(uint32_t) <= dataLen) UInt32SetLE(&data[off], tx->lockTime); // locktime
    off += sizeof(uint32_t);
    if (data && off + sizeof(uint32_t) <= dataLen) UInt32SetLE(&data[off], hashType); // hash type
    off += sizeof(uint32_t);
    return (! data || off <= dataLen) ? off : 0;
}

// writes the data that needs to be hashed and signed for the tx input at index
// an index of SIZE_MAX will write the entire signed transaction
// returns number of bytes written, or total dataLen needed if data is NULL
static size_t _BR_TransactionData(const BR_Transaction *tx, uint8_t *data, size_t dataLen, size_t index, int hashType)
{
    BR_TxInput input;
    int anyoneCanPay = (hashType & SIGHASH_ANYONECANPAY), sigHash = (hashType & 0x1f);
    size_t i, off = 0;
    
    if (hashType & SIGHASH_FORKID) return _BR_TransactionWitnessData(tx, data, dataLen, index, hashType);
    if (anyoneCanPay && index >= tx->inCount) return 0;
    if (data && off + sizeof(uint32_t) <= dataLen) UInt32SetLE(&data[off], tx->version); // tx version
    off += sizeof(uint32_t);
    
    if (! anyoneCanPay) {
        off += BR_VarIntSet((data ? &data[off] : NULL), (off <= dataLen ? dataLen - off : 0), tx->inCount);
        
        for (i = 0; i < tx->inCount; i++) { // inputs
            input = tx->inputs[i];
            
            if (index == i || (index == SIZE_MAX && ! input.signature)) {
                input.signature = input.script; // TODO: handle OP_CODESEPARATOR
                input.sigLen = input.scriptLen;
                if (index == i) input.amount = 0;
            }
            else if (index != SIZE_MAX) {
                input.sigLen = 0;
                if (sigHash == SIGHASH_NONE || sigHash == SIGHASH_SINGLE) input.sequence = 0;
            }
            else input.amount = 0;
            
            off += _BR_TxInputData(&input, (data ? &data[off] : NULL), (off <= dataLen ? dataLen - off : 0));
        }
    }
    else {
        off += BR_VarIntSet((data ? &data[off] : NULL), (off <= dataLen ? dataLen - off : 0), 1);
        input = tx->inputs[index];
        input.signature = input.script; // TODO: handle OP_CODESEPARATOR
        input.sigLen = input.scriptLen;
        input.amount = 0;
        off += _BR_TxInputData(&input, (data ? &data[off] : NULL), (off <= dataLen ? dataLen - off : 0));
    }
    
    if (sigHash != SIGHASH_SINGLE && sigHash != SIGHASH_NONE) { // SIGHASH_ALL outputs
        off += BR_VarIntSet((data ? &data[off] : NULL), (off <= dataLen ? dataLen - off : 0), tx->outCount);
        off += _BR_TransactionOutputData(tx, (data ? &data[off] : NULL), (off <= dataLen ? dataLen - off : 0), SIZE_MAX);
    }
    else if (sigHash == SIGHASH_SINGLE && index < tx->outCount) { // SIGHASH_SINGLE outputs
        off += BR_VarIntSet((data ? &data[off] : NULL), (off <= dataLen ? dataLen - off : 0), index + 1);
        
        for (i = 0; i < index; i++)  {
            if (data && off + sizeof(uint64_t) <= dataLen) UInt64SetLE(&data[off], -1LL);
            off += sizeof(uint64_t);
            off += BR_VarIntSet((data ? &data[off] : NULL), (off <= dataLen ? dataLen - off : 0), 0);
        }
        
        off += _BR_TransactionOutputData(tx, (data ? &data[off] : NULL), (off <= dataLen ? dataLen - off : 0), index);
    }
    else off += BR_VarIntSet((data ? &data[off] : NULL), (off <= dataLen ? dataLen - off : 0), 0); //SIGHASH_NONE outputs
    
    if (data && off + sizeof(uint32_t) <= dataLen) UInt32SetLE(&data[off], tx->lockTime); // locktime
    off += sizeof(uint32_t);
    
    if (index != SIZE_MAX) {
        if (data && off + sizeof(uint32_t) <= dataLen) UInt32SetLE(&data[off], hashType); // hash type
        off += sizeof(uint32_t);
    }
    
    return (! data || off <= dataLen) ? off : 0;
}

// returns a newly allocated empty transaction that must be freed by calling BR_TransactionFree()
BR_Transaction *BR_TransactionNew(void)
{
    BR_Transaction *tx = calloc(1, sizeof(*tx));

    assert(tx != NULL);
    tx->version = TX_VERSION;
    array_new(tx->inputs, 1);
    array_new(tx->outputs, 2);
    tx->lockTime = TX_LOCKTIME;
    tx->blockHeight = TX_UNCONFIRMED;
    return tx;
}

// buf must contain a serialized tx
// retruns a transaction that must be freed by calling BR_TransactionFree()
BR_Transaction *BR_TransactionParse(const uint8_t *buf, size_t bufLen)
{
    assert(buf != NULL || bufLen == 0);
    if (! buf) return NULL;
    
    int isSigned = 1;
    size_t i, off = 0, sLen = 0, len = 0;
    BR_Transaction *tx = BR_TransactionNew();
    BR_TxInput *input;
    BR_TxOutput *output;
    
    tx->version = (off + sizeof(uint32_t) <= bufLen) ? UInt32GetLE(&buf[off]) : 0;
    off += sizeof(uint32_t);
    tx->inCount = (size_t)BR_VarInt(&buf[off], (off <= bufLen ? bufLen - off : 0), &len);
    off += len;
    array_set_count(tx->inputs, tx->inCount);
    
    for (i = 0; off <= bufLen && i < tx->inCount; i++) {
        input = &tx->inputs[i];
        input->txHash = (off + sizeof(UInt256_t) <= bufLen) ? UInt256Get(&buf[off]) : UINT256_ZERO;
        off += sizeof(UInt256_t);
        input->index = (off + sizeof(uint32_t) <= bufLen) ? UInt32GetLE(&buf[off]) : 0;
        off += sizeof(uint32_t);
        sLen = (size_t)BR_VarInt(&buf[off], (off <= bufLen ? bufLen - off : 0), &len);
        off += len;
        
        if (off + sLen <= bufLen && BR_AddressFromScriptPubKey(NULL, 0, &buf[off], sLen) > 0) {
            BR_TxInputSetScript(input, &buf[off], sLen);
            input->amount = (off + sLen + sizeof(uint64_t) <= bufLen) ? UInt64GetLE(&buf[off + sLen]) : 0;
            off += sizeof(uint64_t);
            isSigned = 0;
        }
        else if (off + sLen <= bufLen) BR_TxInputSetSignature(input, &buf[off], sLen);
        
        off += sLen;
        input->sequence = (off + sizeof(uint32_t) <= bufLen) ? UInt32GetLE(&buf[off]) : 0;
        off += sizeof(uint32_t);
    }
    
    tx->outCount = (size_t)BR_VarInt(&buf[off], (off <= bufLen ? bufLen - off : 0), &len);
    off += len;
    array_set_count(tx->outputs, tx->outCount);
    
    for (i = 0; off <= bufLen && i < tx->outCount; i++) {
        output = &tx->outputs[i];
        output->amount = (off + sizeof(uint64_t) <= bufLen) ? UInt64GetLE(&buf[off]) : 0;
        off += sizeof(uint64_t);
        sLen = (size_t)BR_VarInt(&buf[off], (off <= bufLen ? bufLen - off : 0), &len);
        off += len;
        if (off + sLen <= bufLen) BR_TxOutputSetScript(output, &buf[off], sLen);
        off += sLen;
    }
    
    tx->lockTime = (off + sizeof(uint32_t) <= bufLen) ? UInt32GetLE(&buf[off]) : 0;
    off += sizeof(uint32_t);
    
    if (tx->inCount == 0 || off > bufLen) {
        BR_TransactionFree(tx);
        tx = NULL;
    }
    else if (isSigned) BR_SHA256_2(&tx->txHash, buf, off);
    
    return tx;
}

// returns number of bytes written to buf, or total bufLen needed if buf is NULL
// (tx->blockHeight and tx->timestamp are not serialized)
size_t BR_TransactionSerialize(const BR_Transaction *tx, uint8_t *buf, size_t bufLen)
{
    assert(tx != NULL);
    return (tx) ? _BR_TransactionData(tx, buf, bufLen, SIZE_MAX, SIGHASH_ALL) : 0;
}

// adds an input to tx
void BR_TransactionAddInput(BR_Transaction *tx, UInt256_t txHash, uint32_t index, uint64_t amount,
                           const uint8_t *script, size_t scriptLen, const uint8_t *signature, size_t sigLen,
                           uint32_t sequence)
{
    BR_TxInput input = { txHash, index, "", amount, NULL, 0, NULL, 0, sequence };

    assert(tx != NULL);
    assert(! UInt256IsZero(txHash));
    assert(script != NULL || scriptLen == 0);
    assert(signature != NULL || sigLen == 0);
    
    if (tx) {
        if (script) BR_TxInputSetScript(&input, script, scriptLen);
        if (signature) BR_TxInputSetSignature(&input, signature, sigLen);
        array_add(tx->inputs, input);
        tx->inCount = array_count(tx->inputs);
    }
}

// adds an output to tx
void BR_TransactionAddOutput(BR_Transaction *tx, uint64_t amount, const uint8_t *script, size_t scriptLen)
{
    BR_TxOutput output = { "", amount, NULL, 0 };
    
    assert(tx != NULL);
    assert(script != NULL || scriptLen == 0);
    
    if (tx) {
        BR_TxOutputSetScript(&output, script, scriptLen);
        array_add(tx->outputs, output);
        tx->outCount = array_count(tx->outputs);
    }
}

// shuffles order of tx outputs
void BR_TransactionShuffleOutputs(BR_Transaction *tx)
{
    assert(tx != NULL);
    
    for (uint32_t i = 0; tx && i + 1 < tx->outCount; i++) { // fischer-yates shuffle
        uint32_t j = i + BR_Rand((uint32_t)tx->outCount - i);
        BR_TxOutput t;
        
        if (j != i) {
            t = tx->outputs[i];
            tx->outputs[i] = tx->outputs[j];
            tx->outputs[j] = t;
        }
    }
}

// size in bytes if signed, or estimated size assuming compact pubkey sigs
size_t BR_TransactionSize(const BR_Transaction *tx)
{
    BR_TxInput *input;
    size_t size;

    assert(tx != NULL);
    size = (tx) ? 8 + BR_VarIntSize(tx->inCount) + BR_VarIntSize(tx->outCount) : 0;
    
    for (size_t i = 0; tx && i < tx->inCount; i++) {
        input = &tx->inputs[i];
        
        if (input->signature) {
            size += sizeof(UInt256_t) + sizeof(uint32_t) + BR_VarIntSize(input->sigLen) + input->sigLen + sizeof(uint32_t);
        }
        else size += TX_INPUT_SIZE;
    }
    
    for (size_t i = 0; tx && i < tx->outCount; i++) {
        size += sizeof(uint64_t) + BR_VarIntSize(tx->outputs[i].scriptLen) + tx->outputs[i].scriptLen;
    }
    
    return size;
}

// minimum transaction fee needed for tx to relay across the bitcoin network
uint64_t BR_TransactionStandardFee(const BR_Transaction *tx)
{
    assert(tx != NULL);
    return ((BR_TransactionSize(tx) + 999)/1000)*TX_FEE_PER_KB;
}

// checks if all signatures exist, but does not verify them
int BR_TransactionIsSigned(const BR_Transaction *tx)
{
    assert(tx != NULL);
    
    for (size_t i = 0; tx && i < tx->inCount; i++) {
        if (! tx->inputs[i].signature) return 0;
    }

    return (tx) ? 1 : 0;
}

// adds signatures to any inputs with NULL signatures that can be signed with any keys
// forkId is 0 for bitcoin, 0x40 for b-cash
// returns true if tx is signed
int BR_TransactionSign(BR_Transaction *tx, int forkId, BR_Key keys[], size_t keysCount)
{
    BR_Address addrs[keysCount], address;
    size_t i, j;
    
    assert(tx != NULL);
    assert(keys != NULL || keysCount == 0);
    
    for (i = 0; tx && i < keysCount; i++) {
        if (! BR_KeyAddress(&keys[i], addrs[i].s, sizeof(addrs[i]))) addrs[i] = BR_ADDRESS_NONE;
    }
    
    for (i = 0; tx && i < tx->inCount; i++) {
        BR_TxInput *input = &tx->inputs[i];
        
        if (! BR_AddressFromScriptPubKey(address.s, sizeof(address), input->script, input->scriptLen)) continue;
        j = 0;
        while (j < keysCount && ! BR_AddressEq(&addrs[j], &address)) j++;
        if (j >= keysCount) continue;
        
        const uint8_t *elems[BR_ScriptElements(NULL, 0, input->script, input->scriptLen)];
        size_t elemsCount = BR_ScriptElements(elems, sizeof(elems)/sizeof(*elems), input->script, input->scriptLen);
        uint8_t pubKey[BR_KeyPubKey(&keys[j], NULL, 0)];
        size_t pkLen = BR_KeyPubKey(&keys[j], pubKey, sizeof(pubKey));
        uint8_t sig[73], script[1 + sizeof(sig) + 1 + sizeof(pubKey)];
        size_t sigLen, scriptLen;
        UInt256_t md = UINT256_ZERO;
        
        if (elemsCount >= 2 && *elems[elemsCount - 2] == OP_EQUALVERIFY) { // pay-to-pubkey-hash
            uint8_t data[_BR_TransactionData(tx, NULL, 0, i, forkId | SIGHASH_ALL)];
            size_t dataLen = _BR_TransactionData(tx, data, sizeof(data), i, forkId | SIGHASH_ALL);
            
            BR_SHA256_2(&md, data, dataLen);
            sigLen = BR_KeySign(&keys[j], sig, sizeof(sig) - 1, md);
            sig[sigLen++] = forkId | SIGHASH_ALL;
            scriptLen = BR_ScriptPushData(script, sizeof(script), sig, sigLen);
            scriptLen += BR_ScriptPushData(&script[scriptLen], sizeof(script) - scriptLen, pubKey, pkLen);
            BR_TxInputSetSignature(input, script, scriptLen);
        }
        else { // pay-to-pubkey
            uint8_t data[_BR_TransactionData(tx, NULL, 0, i, forkId | SIGHASH_ALL)];
            size_t dataLen = _BR_TransactionData(tx, data, sizeof(data), i, forkId | SIGHASH_ALL);
            
            BR_SHA256_2(&md, data, dataLen);
            sigLen = BR_KeySign(&keys[j], sig, sizeof(sig) - 1, md);
            sig[sigLen++] = forkId | SIGHASH_ALL;
            scriptLen = BR_ScriptPushData(script, sizeof(script), sig, sigLen);
            BR_TxInputSetSignature(input, script, scriptLen);
        }
    }
    
    if (tx && BR_TransactionIsSigned(tx)) {
        uint8_t data[_BR_TransactionData(tx, NULL, 0, SIZE_MAX, 0)];
        size_t len = _BR_TransactionData(tx, data, sizeof(data), SIZE_MAX, 0);
        
        BR_SHA256_2(&tx->txHash, data, len);
        return 1;
    }
    else return 0;
}

// true if tx meets IsStandard() rules: https://bitcoin.org/en/developer-guide#standard-transactions
int BR_TransactionIsStandard(const BR_Transaction *tx)
{
    int r = 1;
    
    // TODO: XXX implement
    
    return r;
}

// frees memory allocated for tx
void BR_TransactionFree(BR_Transaction *tx)
{
    assert(tx != NULL);
    
    if (tx) {
        for (size_t i = 0; i < tx->inCount; i++) {
            BR_TxInputSetScript(&tx->inputs[i], NULL, 0);
            BR_TxInputSetSignature(&tx->inputs[i], NULL, 0);
        }

        for (size_t i = 0; i < tx->outCount; i++) {
            BR_TxOutputSetScript(&tx->outputs[i], NULL, 0);
        }

        array_free(tx->outputs);
        array_free(tx->inputs);
        free(tx);
    }
}
