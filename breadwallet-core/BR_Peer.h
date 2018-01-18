//
//  BR_Peer.h
//
//  Created by Aaron Voisine on 9/2/15.
//  Copyright (c) 2015 breadwallet LLC.
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

#ifndef BR_Peer_h
#define BR_Peer_h

#include "BR_Transaction.h"
#include "BR_MerkleBlock.h"
#include "BR_Address.h"
#include "BR_Int.h"
#include <stddef.h>
#include <inttypes.h>

#define peer_log(peer, ...) _peer_log("%s:%"PRIu16" " _va_first(__VA_ARGS__, NULL) "\n", BR_PeerHost(peer),\
                                      (peer)->port, _va_rest(__VA_ARGS__, NULL))
#define _va_first(first, ...) first
#define _va_rest(first, ...) __VA_ARGS__

#if defined(TARGET_OS_MAC)
#include <Foundation/Foundation.h>
#define _peer_log(...) NSLog(__VA_ARGS__)
#elif defined(__ANDROID__)
#include <android/log.h>
#define _peer_log(...) __android_log_print(ANDROID_LOG_INFO, "bread", __VA_ARGS__)
#else
#include <stdio.h>
#define _peer_log(...) printf(__VA_ARGS__)
#endif

#ifdef __cplusplus
extern "C" {
#endif

#ifndef STANDARD_PORT

#if BITCOIN_TESTNET
#define STANDARD_PORT 18333
#else
#define STANDARD_PORT 8333
#endif

#define SERVICES_NODE_NETWORK 0x01 // services value indicating a node carries full blocks, not just headers
#define SERVICES_NODE_BLOOM   0x04 // BIP111: https://github.com/bitcoin/bips/blob/master/bip-0111.mediawiki

#define BR_VERSION "0.6.2"
#define USER_AGENT "/breadwallet:" BR_VERSION "/"

// explanation of message types at: https://en.bitcoin.it/wiki/Protocol_specification
#define MSG_VERSION     "version"
#define MSG_VERACK      "verack"
#define MSG_ADDR        "addr"
#define MSG_INV         "inv"
#define MSG_GETDATA     "getdata"
#define MSG_NOTFOUND    "notfound"
#define MSG_GETBLOCKS   "getblocks"
#define MSG_GETHEADERS  "getheaders"
#define MSG_TX          "tx"
#define MSG_BLOCK       "block"
#define MSG_HEADERS     "headers"
#define MSG_GETADDR     "getaddr"
#define MSG_MEMPOOL     "mempool"
#define MSG_PING        "ping"
#define MSG_PONG        "pong"
#define MSG_FILTERLOAD  "filterload"
#define MSG_FILTERADD   "filteradd"
#define MSG_FILTERCLEAR "filterclear"
#define MSG_MERKLEBLOCK "merkleblock"
#define MSG_ALERT       "alert"
#define MSG_REJECT      "reject"   // described in BIP61: https://github.com/bitcoin/bips/blob/master/bip-0061.mediawiki
#define MSG_FEEFILTER   "feefilter"// described in BIP133 https://github.com/bitcoin/bips/blob/master/bip-0133.mediawiki

#define REJECT_INVALID     0x10 // transaction is invalid for some reason (invalid signature, output value > input, etc)
#define REJECT_SPENT       0x12 // an input is already spent
#define REJECT_NONSTANDARD 0x40 // not mined/relayed because it is "non-standard" (type or version unknown by server)
#define REJECT_DUST        0x41 // one or more output amounts are below the 'dust' threshold
#define REJECT_LOWFEE      0x42 // transaction does not have enough fee/priority to be relayed or mined

#endif

typedef enum {
    BR_PeerStatusDisconnected = 0,
    BR_PeerStatusConnecting,
    BR_PeerStatusConnected
} BR_PeerStatus;

typedef struct {
    UInt128_t address; // IPv6 address of peer
    uint16_t port; // port number for peer connection
    uint64_t services; // bitcoin network services supported by peer
    uint64_t timestamp; // timestamp reported by peer
    uint8_t flags; // scratch variable
} BR_Peer;

#define BR_PEER_NONE ((BR_Peer) { UINT128_ZERO, 0, 0, 0, 0 })

// NOTE: BR_Peer functions are not thread-safe

// returns a newly allocated BR_Peer struct that must be freed by calling BR_PeerFree()
BR_Peer *BR_PeerNew(void);

// info is a void pointer that will be passed along with each callback call
// void connected(void *) - called when peer handshake completes successfully
// void disconnected(void *, int) - called when peer connection is closed, error is an errno.h code
// void relayedPeers(void *, const BR_Peer[], size_t) - called when an "addr" message is received from peer
// void relayedTx(void *, BR_Transaction *) - called when a "tx" message is received from peer
// void hasTx(void *, UInt256_t txHash) - called when an "inv" message with an already-known tx hash is received from peer
// void rejectedTx(void *, UInt256_t txHash, uint8_t) - called when a "reject" message is received from peer
// void relayedBlock(void *, BR_MerkleBlock *) - called when a "merkleblock" or "headers" message is received from peer
// void notfound(void *, const UInt256[], size_t, const UInt256[], size_t) - called when "notfound" message is received
// BR_Transaction *requestedTx(void *, UInt256) - called when "getdata" message with a tx hash is received from peer
// int networkIsReachable(void *) - must return true when networking is available, false otherwise
// void threadCleanup(void *) - called before a thread terminates to faciliate any needed cleanup    
void BR_PeerSetCallbacks(BR_Peer *peer, void *info,
                        void (*connected)(void *info),
                        void (*disconnected)(void *info, int error),
                        void (*relayedPeers)(void *info, const BR_Peer peers[], size_t peersCount),
                        void (*relayedTx)(void *info, BR_Transaction *tx),
                        void (*hasTx)(void *info, UInt256_t txHash),
                        void (*rejectedTx)(void *info, UInt256_t txHash, uint8_t code),
                        void (*relayedBlock)(void *info, BR_MerkleBlock *block),
                        void (*notfound)(void *info, const UInt256_t txHashes[], size_t txCount,
                                         const UInt256_t blockHashes[], size_t blockCount),
                        void (*setFeePerKb)(void *info, uint64_t feePerKb),
                        BR_Transaction *(*requestedTx)(void *info, UInt256_t txHash),
                        int (*networkIsReachable)(void *info),
                        void (*threadCleanup)(void *info));

// set earliestKeyTime to wallet creation time in order to speed up initial sync
void BR_PeerSetEarliestKeyTime(BR_Peer *peer, uint32_t earliestKeyTime);

// call this when local best block height changes (helps detect tarpit nodes)
void BR_PeerSetCurrentBlockHeight(BR_Peer *peer, uint32_t currentBlockHeight);

// current connection status
BR_PeerStatus BR_PeerConnectStatus(BR_Peer *peer);

// open connection to peer and perform handshake
void BR_PeerConnect(BR_Peer *peer);

// close connection to peer
void BR_PeerDisconnect(BR_Peer *peer);

// call this to (re)schedule a disconnect in the given number of seconds, or < 0 to cancel (useful for sync timeout)
void BR_PeerScheduleDisconnect(BR_Peer *peer, double seconds);

// set this to true when wallet addresses need to be added to bloom filter
void BR_PeerSetNeedsFilterUpdate(BR_Peer *peer, int needsFilterUpdate);

// display name of peer address
const char *BR_PeerHost(BR_Peer *peer);

// connected peer version number
uint32_t BR_PeerVersion(BR_Peer *peer);

// connected peer user agent string
const char *BR_PeerUserAgent(BR_Peer *peer);

// best block height reported by connected peer
uint32_t BR_PeerLastBlock(BR_Peer *peer);

// minimum tx fee rate peer will accept
uint64_t BR_PeerFeePerKb(BR_Peer *peer);

// average ping time for connected peer
double BR_PeerPingTime(BR_Peer *peer);

// sends a bitcoin protocol message to peer
void BR_PeerSendMessage(BR_Peer *peer, const uint8_t *msg, size_t msgLen, const char *type);
void BR_PeerSendFilterload(BR_Peer *peer, const uint8_t *filter, size_t filterLen);
void BR_PeerSendMempool(BR_Peer *peer, const UInt256_t knownTxHashes[], size_t knownTxCount, void *info,
                       void (*completionCallback)(void *info, int success));
void BR_PeerSendGetheaders(BR_Peer *peer, const UInt256_t locators[], size_t locatorsCount, UInt256_t hashStop);
void BR_PeerSendGetblocks(BR_Peer *peer, const UInt256_t locators[], size_t locatorsCount, UInt256_t hashStop);
void BR_PeerSendInv(BR_Peer *peer, const UInt256_t txHashes[], size_t txCount);
void BR_PeerSendGetdata(BR_Peer *peer, const UInt256_t txHashes[], size_t txCount, const UInt256_t blockHashes[],
                       size_t blockCount);
void BR_PeerSendGetaddr(BR_Peer *peer);
void BR_PeerSendPing(BR_Peer *peer, void *info, void (*pongCallback)(void *info, int success));

// useful to get additional tx after a bloom filter update
void BR_PeerRerequestBlocks(BR_Peer *peer, UInt256_t fromBlock);

// returns a hash value for peer suitable for use in a hashtable
inline static size_t BR_PeerHash(const void *peer)
{
    uint32_t address = ((const BR_Peer *)peer)->address.u32[3], port = ((const BR_Peer *)peer)->port;
 
    // (((FNV_OFFSET xor address)*FNV_PRIME) xor port)*FNV_PRIME
    return (size_t)((((0x811C9dc5 ^ address)*0x01000193) ^ port)*0x01000193);
}

// true if a and b have the same address and port
inline static int BR_PeerEq(const void *peer, const void *otherPeer)
{
    return (peer == otherPeer ||
            (UInt128Eq(((const BR_Peer *)peer)->address, ((const BR_Peer *)otherPeer)->address) &&
             ((const BR_Peer *)peer)->port == ((const BR_Peer *)otherPeer)->port));
}

// frees memory allocated for peer
void BR_PeerFree(BR_Peer *peer);

#ifdef __cplusplus
}
#endif

#endif // BR_Peer_h
