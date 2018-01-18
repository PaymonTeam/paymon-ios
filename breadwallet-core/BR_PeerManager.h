//
//  BR_PeerManager.h
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

#ifndef BR_PeerManager_h
#define BR_PeerManager_h

#include "BR_Peer.h"
#include "BR_MerkleBlock.h"
#include "BR_Transaction.h"
#include "BR_Wallet.h"
#include <stddef.h>
#include <inttypes.h>

#ifdef __cplusplus
extern "C" {
#endif

#define PEER_MAX_CONNECTIONS 3

typedef struct BR_PeerManagerStruct BR_PeerManager;

// returns a newly allocated BR_PeerManager struct that must be freed by calling BR_PeerManagerFree()
BR_PeerManager *BR_PeerManagerNew(BR_Wallet *wallet, uint32_t earliestKeyTime, BR_MerkleBlock *blocks[], size_t blocksCount,
                                const BR_Peer peers[], size_t peersCount);

// not thread-safe, set callbacks once before calling BR_PeerManagerConnect()
// info is a void pointer that will be passed along with each callback call
// void syncStarted(void *) - called when blockchain syncing starts
// void syncStopped(void *, int) - called when blockchain syncing stops, error is an errno.h code
// void txStatusUpdate(void *) - called when transaction status may have changed such as when a new block arrives
// void saveBlocks(void *, int, BR_MerkleBlock *[], size_t) - called when blocks should be saved to the persistent store
// - if replace is true, remove any previously saved blocks first
// void savePeers(void *, int, const BR_Peer[], size_t) - called when peers should be saved to the persistent store
// - if replace is true, remove any previously saved peers first
// int networkIsReachable(void *) - must return true when networking is available, false otherwise
// void threadCleanup(void *) - called before a thread terminates to faciliate any needed cleanup
void BR_PeerManagerSetCallbacks(BR_PeerManager *manager, void *info,
                               void (*syncStarted)(void *info),
                               void (*syncStopped)(void *info, int error),
                               void (*txStatusUpdate)(void *info),
                               void (*saveBlocks)(void *info, int replace, BR_MerkleBlock *blocks[], size_t blocksCount),
                               void (*savePeers)(void *info, int replace, const BR_Peer peers[], size_t peersCount),
                               int (*networkIsReachable)(void *info),
                               void (*threadCleanup)(void *info));

// specifies a single fixed peer to use when connecting to the bitcoin network
// set address to UINT128_ZERO to revert to default behavior
void BR_PeerManagerSetFixedPeer(BR_PeerManager *manager, UInt128_t address, uint16_t port);

// true if currently connected to at least one peer
int BR_PeerManagerIsConnected(BR_PeerManager *manager);

// connect to bitcoin peer-to-peer network (also call this whenever networkIsReachable() status changes)
void BR_PeerManagerConnect(BR_PeerManager *manager);

// disconnect from bitcoin peer-to-peer network (may cause syncFailed(), saveBlocks() or savePeers() callbacks to fire)
void BR_PeerManagerDisconnect(BR_PeerManager *manager);

// rescans blocks and transactions after earliestKeyTime (a new random download peer is also selected due to the
// possibility that a malicious node might lie by omitting transactions that match the bloom filter)
void BR_PeerManagerRescan(BR_PeerManager *manager);

// the (unverified) best block height reported by connected peers
uint32_t BR_PeerManagerEstimatedBlockHeight(BR_PeerManager *manager);

// current proof-of-work verified best block height
uint32_t BR_PeerManagerLastBlockHeight(BR_PeerManager *manager);

// current proof-of-work verified best block timestamp (time interval since unix epoch)
uint32_t BR_PeerManagerLastBlockTimestamp(BR_PeerManager *manager);

// current network sync progress from 0 to 1
// startHeight is the block height of the most recent fully completed sync
double BR_PeerManagerSyncProgress(BR_PeerManager *manager, uint32_t startHeight);

// returns the number of currently connected peers
size_t BR_PeerManagerPeerCount(BR_PeerManager *manager);

// description of the peer most recently used to sync blockchain data
const char *BR_PeerManagerDownloadPeerName(BR_PeerManager *manager);

// publishes tx to bitcoin network (do not call BR_TransactionFree() on tx afterward)
void BR_PeerManagerPublishTx(BR_PeerManager *manager, BR_Transaction *tx, void *info,
                            void (*callback)(void *info, int error));

// number of connected peers that have relayed the given unconfirmed transaction
size_t BR_PeerManagerRelayCount(BR_PeerManager *manager, UInt256_t txHash);

// frees memory allocated for manager (call BR_PeerManagerDisconnect() first if connected)
void BR_PeerManagerFree(BR_PeerManager *manager);

#ifdef __cplusplus
}
#endif

#endif // BR_PeerManager_h
