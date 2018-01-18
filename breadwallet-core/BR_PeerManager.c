//
//  BR_PeerManager.c
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

#include "BR_PeerManager.h"
#include "BR_BloomFilter.h"
#include "BR_Set.h"
#include "BR_Array.h"
#include "BR_Int.h"
#include <stdlib.h>
#include <stdio.h>
#include <inttypes.h>
#include <limits.h>
#include <time.h>
#include <assert.h>
#include <pthread.h>
#include <errno.h>
#include <netdb.h>
#include <sys/socket.h>
#include <netinet/in.h>

#define PROTOCOL_TIMEOUT      20.0
#define MAX_CONNECT_FAILURES  20 // notify user of network problems after this many connect failures in a row
#define CHECKPOINT_COUNT      (sizeof(checkpoint_array)/sizeof(*checkpoint_array))
#define DNS_SEEDS_COUNT       (sizeof(dns_seeds)/sizeof(*dns_seeds))
#define GENESIS_BLOCK_HASH    (UInt256Reverse(u256_hex_decode(checkpoint_array[0].hash)))
#define PEER_FLAG_SYNCED      0x01
#define PEER_FLAG_NEEDSUPDATE 0x02

#if BITCOIN_TESTNET

static const struct { uint32_t height; const char *hash; uint32_t timestamp; uint32_t target; } checkpoint_array[] = {
    {       0, "000000000933ea01ad0ee984209779baaec3ced90fa3f408719526f8d77f4943", 1296688602, 0x1d00ffff },
    {  100800, "0000000000a33112f86f3f7b0aa590cb4949b84c2d9c673e9e303257b3be9000", 1376543922, 0x1c00d907 },
    {  201600, "0000000000376bb71314321c45de3015fe958543afcbada242a3b1b072498e38", 1393813869, 0x1b602ac0 },
    {  302400, "0000000000001c93ebe0a7c33426e8edb9755505537ef9303a023f80be29d32d", 1413766239, 0x1a33605e },
    {  403200, "0000000000ef8b05da54711e2106907737741ac0278d59f358303c71d500f3c4", 1431821666, 0x1c02346c },
    {  504000, "0000000000005d105473c916cd9d16334f017368afea6bcee71629e0fcf2f4f5", 1436951946, 0x1b00ab86 },
    {  604800, "00000000000008653c7e5c00c703c5a9d53b318837bb1b3586a3d060ce6fff2e", 1447484641, 0x1a092a20 },
    {  705600, "00000000004ee3bc2e2dd06c31f2d7a9c3e471ec0251924f59f222e5e9c37e12", 1455728685, 0x1c0ffff0 },
    {  806400, "0000000000000faf114ff29df6dbac969c6b4a3b407cd790d3a12742b50c2398", 1462006183, 0x1a34e280 },
    {  907200, "0000000000166938e6f172a21fe69fe335e33565539e74bf74eeb00d2022c226", 1469705562, 0x1c00ffff },
    { 1008000, "000000000000390aca616746a9456a0d64c1bd73661fd60a51b5bf1c92bae5a0", 1476926743, 0x1a52ccc0 },
    { 1108800, "00000000000288d9a219419d0607fb67cc324d4b6d2945ca81eaa5e739fab81e", 1490751239, 0x1b09ecf0 }
};

static const char *dns_seeds[] = {
    "testnet-seed.breadwallet.com.", "testnet-seed.bitcoin.petertodd.org.", "testnet-seed.bluematt.me.",
    "testnet-seed.bitcoin.schildbach.de."
};

#else // main net

// blockchain checkpoints - these are also used as starting points for partial chain downloads, so they need to be at
// difficulty transition boundaries in order to verify the block difficulty at the immediately following transition
static const struct { uint32_t height; const char *hash; uint32_t timestamp; uint32_t target; } checkpoint_array[] = {
    {      0, "000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f", 1231006505, 0x1d00ffff },
    {  20160, "000000000f1aef56190aee63d33a373e6487132d522ff4cd98ccfc96566d461e", 1248481816, 0x1d00ffff },
    {  40320, "0000000045861e169b5a961b7034f8de9e98022e7a39100dde3ae3ea240d7245", 1266191579, 0x1c654657 },
    {  60480, "000000000632e22ce73ed38f46d5b408ff1cff2cc9e10daaf437dfd655153837", 1276298786, 0x1c0eba64 },
    {  80640, "0000000000307c80b87edf9f6a0697e2f01db67e518c8a4d6065d1d859a3a659", 1284861847, 0x1b4766ed },
    { 100800, "000000000000e383d43cc471c64a9a4a46794026989ef4ff9611d5acb704e47a", 1294031411, 0x1b0404cb },
    { 120960, "0000000000002c920cf7e4406b969ae9c807b5c4f271f490ca3de1b0770836fc", 1304131980, 0x1b0098fa },
    { 141120, "00000000000002d214e1af085eda0a780a8446698ab5c0128b6392e189886114", 1313451894, 0x1a094a86 },
    { 161280, "00000000000005911fe26209de7ff510a8306475b75ceffd434b68dc31943b99", 1326047176, 0x1a0d69d7 },
    { 181440, "00000000000000e527fc19df0992d58c12b98ef5a17544696bbba67812ef0e64", 1337883029, 0x1a0a8b5f },
    { 201600, "00000000000003a5e28bef30ad31f1f9be706e91ae9dda54179a95c9f9cd9ad0", 1349226660, 0x1a057e08 },
    { 221760, "00000000000000fc85dd77ea5ed6020f9e333589392560b40908d3264bd1f401", 1361148470, 0x1a04985c },
    { 241920, "00000000000000b79f259ad14635739aaf0cc48875874b6aeecc7308267b50fa", 1371418654, 0x1a00de15 },
    { 262080, "000000000000000aa77be1c33deac6b8d3b7b0757d02ce72fffddc768235d0e2", 1381070552, 0x1916b0ca },
    { 282240, "0000000000000000ef9ee7529607286669763763e0c46acfdefd8a2306de5ca8", 1390570126, 0x1901f52c },
    { 302400, "0000000000000000472132c4daaf358acaf461ff1c3e96577a74e5ebf91bb170", 1400928750, 0x18692842 },
    { 322560, "000000000000000002df2dd9d4fe0578392e519610e341dd09025469f101cfa1", 1411680080, 0x181fb893 },
    { 342720, "00000000000000000f9cfece8494800d3dcbf9583232825da640c8703bcd27e7", 1423496415, 0x1818bb87 },
    { 362880, "000000000000000014898b8e6538392702ffb9450f904c80ebf9d82b519a77d5", 1435475246, 0x1816418e },
    { 383040, "00000000000000000a974fa1a3f84055ad5ef0b2f96328bc96310ce83da801c9", 1447236692, 0x1810b289 },
    { 403200, "000000000000000000c4272a5c68b4f55e5af734e88ceab09abf73e9ac3b6d01", 1458292068, 0x1806a4c3 },
    { 423360, "000000000000000001630546cde8482cc183708f076a5e4d6f51cd24518e8f85", 1470163842, 0x18057228 },
    { 443520, "00000000000000000345d0c7890b2c81ab5139c6e83400e5bed00d23a1f8d239", 1481765313, 0x18038b85 },
    { 463680, "000000000000000000431a2f4619afe62357cd16589b638bb638f2992058d88e", 1493259601, 0x18021b3e }
};

static const char *dns_seeds[] = {
    "seed.breadwallet.com.", "seed.bitcoin.sipa.be.", "dnsseed.bluematt.me.", "dnsseed.bitcoin.dashjr.org.",
    "seed.bitcoinstats.com.", "bitseed.xf2.org.", "seed.bitcoin.jonasschnelli.ch."
};

#endif

typedef struct {
    BR_PeerManager *manager;
    const char *hostname;
    uint64_t services;
} BR_FindPeersInfo;

typedef struct {
    BR_Peer *peer;
    BR_PeerManager *manager;
    UInt256_t hash;
} BR_PeerCallbackInfo;

typedef struct {
    BR_Transaction *tx;
    void *info;
    void (*callback)(void *info, int error);
} BR_PublishedTx;

typedef struct {
    UInt256_t txHash;
    BR_Peer *peers;
} BR_TxPeerList;

// true if peer is contained in the list of peers associated with txHash
static int _BR_TxPeerListHasPeer(const BR_TxPeerList *list, UInt256_t txHash, const BR_Peer *peer)
{
    for (size_t i = array_count(list); i > 0; i--) {
        if (! UInt256Eq(list[i - 1].txHash, txHash)) continue;

        for (size_t j = array_count(list[i - 1].peers); j > 0; j--) {
            if (BR_PeerEq(&list[i - 1].peers[j - 1], peer)) return 1;
        }
        
        break;
    }
    
    return 0;
}

// number of peers associated with txHash
static size_t _BR_TxPeerListCount(const BR_TxPeerList *list, UInt256_t txHash)
{
    for (size_t i = array_count(list); i > 0; i--) {
        if (UInt256Eq(list[i - 1].txHash, txHash)) return array_count(list[i - 1].peers);
    }
    
    return 0;
}

// adds peer to the list of peers associated with txHash and returns the new total number of peers
static size_t _BR_TxPeerListAddPeer(BR_TxPeerList **list, UInt256_t txHash, const BR_Peer *peer)
{
    for (size_t i = array_count(*list); i > 0; i--) {
        if (! UInt256Eq((*list)[i - 1].txHash, txHash)) continue;
        
        for (size_t j = array_count((*list)[i - 1].peers); j > 0; j--) {
            if (BR_PeerEq(&(*list)[i - 1].peers[j - 1], peer)) return array_count((*list)[i - 1].peers);
        }
        
        array_add((*list)[i - 1].peers, *peer);
        return array_count((*list)[i - 1].peers);
    }

    array_add(*list, ((BR_TxPeerList) { txHash, NULL }));
    array_new((*list)[array_count(*list) - 1].peers, PEER_MAX_CONNECTIONS);
    array_add((*list)[array_count(*list) - 1].peers, *peer);
    return 1;
}

// removes peer from the list of peers associated with txHash, returns true if peer was found
static int _BR_TxPeerListRemovePeer(BR_TxPeerList *list, UInt256_t txHash, const BR_Peer *peer)
{
    for (size_t i = array_count(list); i > 0; i--) {
        if (! UInt256Eq(list[i - 1].txHash, txHash)) continue;
        
        for (size_t j = array_count(list[i - 1].peers); j > 0; j--) {
            if (! BR_PeerEq(&list[i - 1].peers[j - 1], peer)) continue;
            array_rm(list[i - 1].peers, j - 1);
            return 1;
        }
        
        break;
    }
    
    return 0;
}

// comparator for sorting peers by timestamp, most recent first
inline static int _peerTimestampCompare(const void *peer, const void *otherPeer)
{
    if (((const BR_Peer *)peer)->timestamp < ((const BR_Peer *)otherPeer)->timestamp) return 1;
    if (((const BR_Peer *)peer)->timestamp > ((const BR_Peer *)otherPeer)->timestamp) return -1;
    return 0;
}

// returns a hash value for a block's prevBlock value suitable for use in a hashtable
inline static size_t _BR_PrevBlockHash(const void *block)
{
    return (size_t)((const BR_MerkleBlock *)block)->prevBlock.u32[0];
}

// true if block and otherBlock have equal prevBlock values
inline static int _BR_PrevBlockEq(const void *block, const void *otherBlock)
{
    return UInt256Eq(((const BR_MerkleBlock *)block)->prevBlock, ((const BR_MerkleBlock *)otherBlock)->prevBlock);
}

// returns a hash value for a block's height value suitable for use in a hashtable
inline static size_t _BR_BlockHeightHash(const void *block)
{
    // (FNV_OFFSET xor height)*FNV_PRIME
    return (size_t)((0x811C9dc5 ^ ((const BR_MerkleBlock *)block)->height)*0x01000193);
}

// true if block and otherBlock have equal height values
inline static int _BR_BlockHeightEq(const void *block, const void *otherBlock)
{
    return (((const BR_MerkleBlock *)block)->height == ((const BR_MerkleBlock *)otherBlock)->height);
}

struct BR_PeerManagerStruct {
    BR_Wallet *wallet;
    int isConnected, connectFailureCount, misbehavinCount, dnsThreadCount, maxConnectCount;
    BR_Peer *peers, *downloadPeer, fixedPeer, **connectedPeers;
    char downloadPeerName[INET6_ADDRSTRLEN + 6];
    uint32_t earliestKeyTime, syncStartHeight, filterUpdateHeight, estimatedHeight;
    BR_BloomFilter *bloomFilter;
    double fpRate, averageTxPerBlock;
    BR_Set *blocks, *orphans, *checkpoints;
    BR_MerkleBlock *lastBlock, *lastOrphan;
    BR_TxPeerList *txRelays, *txRequests;
    BR_PublishedTx *publishedTx;
    UInt256_t *publishedTxHashes;
    void *info;
    void (*syncStarted)(void *info);
    void (*syncStopped)(void *info, int error);
    void (*txStatusUpdate)(void *info);
    void (*saveBlocks)(void *info, int replace, BR_MerkleBlock *blocks[], size_t blocksCount);
    void (*savePeers)(void *info, int replace, const BR_Peer peers[], size_t peersCount);
    int (*networkIsReachable)(void *info);
    void (*threadCleanup)(void *info);
    pthread_mutex_t lock;
};

static void _BR_PeerManagerPeerMisbehavin(BR_PeerManager *manager, BR_Peer *peer)
{
    for (size_t i = array_count(manager->peers); i > 0; i--) {
        if (BR_PeerEq(&manager->peers[i - 1], peer)) array_rm(manager->peers, i - 1);
    }

    if (++manager->misbehavinCount >= 10) { // clear out stored peers so we get a fresh list from DNS for next connect
        manager->misbehavinCount = 0;
        array_clear(manager->peers);
    }

    BR_PeerDisconnect(peer);
}

static void _BR_PeerManagerSyncStopped(BR_PeerManager *manager)
{
    manager->syncStartHeight = 0;

    if (manager->downloadPeer) {
        // don't cancel timeout if there's a pending tx publish callback
        for (size_t i = array_count(manager->publishedTx); i > 0; i--) {
            if (manager->publishedTx[i - 1].callback != NULL) return;
        }
    
        BR_PeerScheduleDisconnect(manager->downloadPeer, -1); // cancel sync timeout
    }
}

// adds transaction to list of tx to be published, along with any unconfirmed inputs
static void _BR_PeerManagerAddTxToPublishList(BR_PeerManager *manager, BR_Transaction *tx, void *info,
                                             void (*callback)(void *, int))
{
    if (tx && tx->blockHeight == TX_UNCONFIRMED) {
        for (size_t i = array_count(manager->publishedTx); i > 0; i--) {
            if (BR_TransactionEq(manager->publishedTx[i - 1].tx, tx)) return;
        }
        
        array_add(manager->publishedTx, ((BR_PublishedTx) { tx, info, callback }));
        array_add(manager->publishedTxHashes, tx->txHash);

        for (size_t i = 0; i < tx->inCount; i++) {
            _BR_PeerManagerAddTxToPublishList(manager, BR_WalletTransactionForHash(manager->wallet, tx->inputs[i].txHash),
                                             NULL, NULL);
        }
    }
}

static size_t _BR_PeerManagerBlockLocators(BR_PeerManager *manager, UInt256_t locators[], size_t locatorsCount)
{
    // append 10 most recent block hashes, decending, then continue appending, doubling the step back each time,
    // finishing with the genesis block (top, -1, -2, -3, -4, -5, -6, -7, -8, -9, -11, -15, -23, -39, -71, -135, ..., 0)
    BR_MerkleBlock *block = manager->lastBlock;
    int32_t step = 1, i = 0, j;
    
    while (block && block->height > 0) {
        if (locators && i < locatorsCount) locators[i] = block->blockHash;
        if (++i >= 10) step *= 2;
        
        for (j = 0; block && j < step; j++) {
            block = BR_SetGet(manager->blocks, &block->prevBlock);
        }
    }
    
    if (locators && i < locatorsCount) locators[i] = GENESIS_BLOCK_HASH;
    return ++i;
}

static void _setApplyFreeBlock(void *info, void *block)
{
    BR_MerkleBlockFree(block);
}

static void _BR_PeerManagerLoadBloomFilter(BR_PeerManager *manager, BR_Peer *peer)
{
    // every time a new wallet address is added, the bloom filter has to be rebuilt, and each address is only used
    // for one transaction, so here we generate some spare addresses to avoid rebuilding the filter each time a
    // wallet transaction is encountered during the chain sync
    BR_WalletUnusedAddrs(manager->wallet, NULL, SEQUENCE_GAP_LIMIT_EXTERNAL + 100, 0);
    BR_WalletUnusedAddrs(manager->wallet, NULL, SEQUENCE_GAP_LIMIT_INTERNAL + 100, 1);

    BR_SetApply(manager->orphans, NULL, _setApplyFreeBlock);
    BR_SetClear(manager->orphans); // clear out orphans that may have been received on an old filter
    manager->lastOrphan = NULL;
    manager->filterUpdateHeight = manager->lastBlock->height;
    manager->fpRate = BLOOM_REDUCED_FALSEPOSITIVE_RATE;
    
    size_t addrsCount = BR_WalletAllAddrs(manager->wallet, NULL, 0);
    BR_Address *addrs = malloc(addrsCount*sizeof(*addrs));
    size_t utxosCount = BR_WalletUTXOs(manager->wallet, NULL, 0);
    BR_UTXO *utxos = malloc(utxosCount*sizeof(*utxos));
    uint32_t blockHeight = (manager->lastBlock->height > 100) ? manager->lastBlock->height - 100 : 0;
    size_t txCount = BR_WalletTxUnconfirmedBefore(manager->wallet, NULL, 0, blockHeight);
    BR_Transaction **transactions = malloc(txCount*sizeof(*transactions));
    BR_BloomFilter *filter;
    
    assert(addrs != NULL);
    assert(utxos != NULL);
    assert(transactions != NULL);
    addrsCount = BR_WalletAllAddrs(manager->wallet, addrs, addrsCount);
    utxosCount = BR_WalletUTXOs(manager->wallet, utxos, utxosCount);
    txCount = BR_WalletTxUnconfirmedBefore(manager->wallet, transactions, txCount, blockHeight);
    filter = BR_BloomFilterNew(manager->fpRate, addrsCount + utxosCount + txCount + 100, (uint32_t)BR_PeerHash(peer),
                              BLOOM_UPDATE_ALL); // BUG: XXX txCount not the same as number of spent wallet outputs
    
    for (size_t i = 0; i < addrsCount; i++) { // add addresses to watch for tx receiveing money to the wallet
        UInt160_t hash = UINT160_ZERO;
        
        BR_AddressHash160(&hash, addrs[i].s);
        
        if (! UInt160IsZero(hash) && ! BR_BloomFilterContainsData(filter, hash.u8, sizeof(hash))) {
            BR_BloomFilterInsertData(filter, hash.u8, sizeof(hash));
        }
    }

    free(addrs);
        
    for (size_t i = 0; i < utxosCount; i++) { // add UTXOs to watch for tx sending money from the wallet
        uint8_t o[sizeof(UInt256_t) + sizeof(uint32_t)];
        
        UInt256Set(o, utxos[i].hash);
        UInt32SetLE(&o[sizeof(UInt256_t)], utxos[i].n);
        if (! BR_BloomFilterContainsData(filter, o, sizeof(o))) BR_BloomFilterInsertData(filter, o, sizeof(o));
    }
    
    free(utxos);
        
    for (size_t i = 0; i < txCount; i++) { // also add TXOs spent within the last 100 blocks
        for (size_t j = 0; j < transactions[i]->inCount; j++) {
            BR_TxInput *input = &transactions[i]->inputs[j];
            BR_Transaction *tx = BR_WalletTransactionForHash(manager->wallet, input->txHash);
            uint8_t o[sizeof(UInt256_t) + sizeof(uint32_t)];
            
            if (tx && input->index < tx->outCount &&
                BR_WalletContainsAddress(manager->wallet, tx->outputs[input->index].address)) {
                UInt256Set(o, input->txHash);
                UInt32SetLE(&o[sizeof(UInt256_t)], input->index);
                if (! BR_BloomFilterContainsData(filter, o, sizeof(o))) BR_BloomFilterInsertData(filter, o,sizeof(o));
            }
        }
    }
    
    free(transactions);
    if (manager->bloomFilter) BR_BloomFilterFree(manager->bloomFilter);
    manager->bloomFilter = filter;
    // TODO: XXX if already synced, recursively add inputs of unconfirmed receives

    uint8_t data[BR_BloomFilterSerialize(filter, NULL, 0)];
    size_t len = BR_BloomFilterSerialize(filter, data, sizeof(data));
    
    BR_PeerSendFilterload(peer, data, len);
}

static void _updateFilterRerequestDone(void *info, int success)
{
    BR_Peer *peer = ((BR_PeerCallbackInfo *)info)->peer;
    BR_PeerManager *manager = ((BR_PeerCallbackInfo *)info)->manager;
    
    free(info);
    
    if (success) {
        pthread_mutex_lock(&manager->lock);

        if ((peer->flags & PEER_FLAG_NEEDSUPDATE) == 0) {
            UInt256_t locators[_BR_PeerManagerBlockLocators(manager, NULL, 0)];
            size_t count = _BR_PeerManagerBlockLocators(manager, locators, sizeof(locators)/sizeof(*locators));
            
            BR_PeerSendGetblocks(peer, locators, count, UINT256_ZERO);
        }

        pthread_mutex_unlock(&manager->lock);
    }
}

static void _updateFilterLoadDone(void *info, int success)
{
    BR_Peer *peer = ((BR_PeerCallbackInfo *)info)->peer;
    BR_PeerManager *manager = ((BR_PeerCallbackInfo *)info)->manager;
    BR_PeerCallbackInfo *peerInfo;

    free(info);
    
    if (success) {
        pthread_mutex_lock(&manager->lock);
        BR_PeerSetNeedsFilterUpdate(peer, 0);
        peer->flags &= ~PEER_FLAG_NEEDSUPDATE;
        
        if (manager->lastBlock->height < manager->estimatedHeight) { // if syncing, rerequest blocks
            peerInfo = calloc(1, sizeof(*peerInfo));
            assert(peerInfo != NULL);
            peerInfo->peer = peer;
            peerInfo->manager = manager;
            BR_PeerRerequestBlocks(manager->downloadPeer, manager->lastBlock->blockHash);
            BR_PeerSendPing(manager->downloadPeer, peerInfo, _updateFilterRerequestDone);
        }
        else BR_PeerSendMempool(peer, NULL, 0, NULL, NULL); // if not syncing, request mempool
        
        pthread_mutex_unlock(&manager->lock);
    }
}

static void _updateFilterPingDone(void *info, int success)
{
    BR_Peer *peer = ((BR_PeerCallbackInfo *)info)->peer;
    BR_PeerManager *manager = ((BR_PeerCallbackInfo *)info)->manager;
    BR_PeerCallbackInfo *peerInfo;
    
    if (success) {
        pthread_mutex_lock(&manager->lock);
        peer_log(peer, "updating filter with newly created wallet addresses");
        if (manager->bloomFilter) BR_BloomFilterFree(manager->bloomFilter);
        manager->bloomFilter = NULL;

        if (manager->lastBlock->height < manager->estimatedHeight) { // if we're syncing, only update download peer
            if (manager->downloadPeer) {
                _BR_PeerManagerLoadBloomFilter(manager, manager->downloadPeer);
                BR_PeerSendPing(manager->downloadPeer, info, _updateFilterLoadDone); // wait for pong so filter is loaded
            }
            else free(info);
        }
        else {
            free(info);
            
            for (size_t i = array_count(manager->connectedPeers); i > 0; i--) {
                if (BR_PeerConnectStatus(manager->connectedPeers[i - 1]) != BR_PeerStatusConnected) continue;
                peerInfo = calloc(1, sizeof(*peerInfo));
                assert(peerInfo != NULL);
                peerInfo->peer = manager->connectedPeers[i - 1];
                peerInfo->manager = manager;
                _BR_PeerManagerLoadBloomFilter(manager, peerInfo->peer);
                BR_PeerSendPing(peerInfo->peer, peerInfo, _updateFilterLoadDone); // wait for pong so filter is loaded
            }
        }

         pthread_mutex_unlock(&manager->lock);
    }
    else free(info);
}

static void _BR_PeerManagerUpdateFilter(BR_PeerManager *manager)
{
    BR_PeerCallbackInfo *info;

    if (manager->downloadPeer && (manager->downloadPeer->flags & PEER_FLAG_NEEDSUPDATE) == 0) {
        BR_PeerSetNeedsFilterUpdate(manager->downloadPeer, 1);
        manager->downloadPeer->flags |= PEER_FLAG_NEEDSUPDATE;
        peer_log(manager->downloadPeer, "filter update needed, waiting for pong");
        info = calloc(1, sizeof(*info));
        assert(info != NULL);
        info->peer = manager->downloadPeer;
        info->manager = manager;
        // wait for pong so we're sure to include any tx already sent by the peer in the updated filter
        BR_PeerSendPing(manager->downloadPeer, info, _updateFilterPingDone);
    }
}

static void _BR_PeerManagerUpdateTx(BR_PeerManager *manager, const UInt256_t txHashes[], size_t txCount,
                                   uint32_t blockHeight, uint32_t timestamp)
{
    if (blockHeight != TX_UNCONFIRMED) { // remove confirmed tx from publish list and relay counts
        for (size_t i = 0; i < txCount; i++) {
            for (size_t j = array_count(manager->publishedTx); j > 0; j--) {
                BR_Transaction *tx = manager->publishedTx[j - 1].tx;
                
                if (! UInt256Eq(txHashes[i], tx->txHash)) continue;
                array_rm(manager->publishedTx, j - 1);
                array_rm(manager->publishedTxHashes, j - 1);
                if (! BR_WalletTransactionForHash(manager->wallet, tx->txHash)) BR_TransactionFree(tx);
            }
            
            for (size_t j = array_count(manager->txRelays); j > 0; j--) {
                if (! UInt256Eq(txHashes[i], manager->txRelays[j - 1].txHash)) continue;
                array_free(manager->txRelays[j - 1].peers);
                array_rm(manager->txRelays, j - 1);
            }
        }
    }
    
    BR_WalletUpdateTransactions(manager->wallet, txHashes, txCount, blockHeight, timestamp);
}

// unconfirmed transactions that aren't in the mempools of any of connected peers have likely dropped off the network
static void _requestUnrelayedTxGetdataDone(void *info, int success)
{
    BR_Peer *peer = ((BR_PeerCallbackInfo *)info)->peer;
    BR_PeerManager *manager = ((BR_PeerCallbackInfo *)info)->manager;
    int isPublishing;
    size_t count = 0;

    free(info);
    pthread_mutex_lock(&manager->lock);
    if (success) peer->flags |= PEER_FLAG_SYNCED;
    
    for (size_t i = array_count(manager->connectedPeers); i > 0; i--) {
        peer = manager->connectedPeers[i - 1];
        if (BR_PeerConnectStatus(peer) == BR_PeerStatusConnected) count++;
        if ((peer->flags & PEER_FLAG_SYNCED) != 0) continue;
        count = 0;
        break;
    }

    // don't remove transactions until we're connected to maxConnectCount peers, and all peers have finished
    // relaying their mempools
    if (count >= manager->maxConnectCount) {
        size_t txCount = BR_WalletTxUnconfirmedBefore(manager->wallet, NULL, 0, TX_UNCONFIRMED);
        BR_Transaction *tx[(txCount < 10000) ? txCount : 10000];
        
        txCount = BR_WalletTxUnconfirmedBefore(manager->wallet, tx, sizeof(tx)/sizeof(*tx), TX_UNCONFIRMED);

        for (size_t i = 0; i < txCount; i++) {
            isPublishing = 0;
            
            for (size_t j = array_count(manager->publishedTx); ! isPublishing && j > 0; j--) {
                if (BR_TransactionEq(manager->publishedTx[j - 1].tx, tx[i]) &&
                    manager->publishedTx[j - 1].callback != NULL) isPublishing = 1;
            }
            
            if (! isPublishing && _BR_TxPeerListCount(manager->txRelays, tx[i]->txHash) == 0 &&
                _BR_TxPeerListCount(manager->txRequests, tx[i]->txHash) == 0) {
                BR_WalletRemoveTransaction(manager->wallet, tx[i]->txHash);
            }
            else if (! isPublishing && _BR_TxPeerListCount(manager->txRelays, tx[i]->txHash) < manager->maxConnectCount){
                // set timestamp 0 to mark as unverified
                _BR_PeerManagerUpdateTx(manager, &tx[i]->txHash, 1, TX_UNCONFIRMED, 0);
            }
        }
    }

    pthread_mutex_unlock(&manager->lock);
}

static void _BR_PeerManagerRequestUnrelayedTx(BR_PeerManager *manager, BR_Peer *peer)
{
    BR_PeerCallbackInfo *info;
    UInt256_t hash, txHashes[array_count(manager->publishedTxHashes)];
    size_t count = 0;

    for (size_t i = array_count(manager->publishedTxHashes); i > 0; i--) {
        hash = manager->publishedTxHashes[i - 1];
        
        if (! _BR_TxPeerListHasPeer(manager->txRelays, hash, peer) &&
            ! _BR_TxPeerListHasPeer(manager->txRequests, hash, peer)) {
            txHashes[count++] = hash;
            _BR_TxPeerListAddPeer(&manager->txRequests, hash, peer);
        }
    }

    if (count > 0) {
        BR_PeerSendGetdata(peer, txHashes, count, NULL, 0);
    
        if ((peer->flags & PEER_FLAG_SYNCED) == 0) {
            info = calloc(1, sizeof(*info));
            assert(info != NULL);
            info->peer = peer;
            info->manager = manager;
            BR_PeerSendPing(peer, info, _requestUnrelayedTxGetdataDone);
        }
    }
    else peer->flags |= PEER_FLAG_SYNCED;
}

static void _BR_PeerManagerPublishPendingTx(BR_PeerManager *manager, BR_Peer *peer)
{
    for (size_t i = array_count(manager->publishedTx); i > 0; i--) {
        if (manager->publishedTx[i - 1].callback == NULL) continue;
        BR_PeerScheduleDisconnect(peer, PROTOCOL_TIMEOUT); // schedule publish timeout
        break;
    }
    
    BR_PeerSendInv(peer, manager->publishedTxHashes, array_count(manager->publishedTxHashes));
}

static void _mempoolDone(void *info, int success)
{
    BR_Peer *peer = ((BR_PeerCallbackInfo *)info)->peer;
    BR_PeerManager *manager = ((BR_PeerCallbackInfo *)info)->manager;
    int syncFinished = 0;
    
    free(info);
    
    if (success) {
        peer_log(peer, "mempool request finished");
        pthread_mutex_lock(&manager->lock);
        if (manager->syncStartHeight > 0) {
            peer_log(peer, "sync succeeded");
            syncFinished = 1;
            _BR_PeerManagerSyncStopped(manager);
        }

        _BR_PeerManagerRequestUnrelayedTx(manager, peer);
        BR_PeerSendGetaddr(peer); // request a list of other bitcoin peers
        pthread_mutex_unlock(&manager->lock);
        if (manager->txStatusUpdate) manager->txStatusUpdate(manager->info);
        if (syncFinished && manager->syncStopped) manager->syncStopped(manager->info, 0);
    }
    else peer_log(peer, "mempool request failed");
}

static void _loadBloomFilterDone(void *info, int success)
{
    BR_Peer *peer = ((BR_PeerCallbackInfo *)info)->peer;
    BR_PeerManager *manager = ((BR_PeerCallbackInfo *)info)->manager;

    pthread_mutex_lock(&manager->lock);
    
    if (success) {
        BR_PeerSendMempool(peer, manager->publishedTxHashes, array_count(manager->publishedTxHashes), info,
                          _mempoolDone);
        pthread_mutex_unlock(&manager->lock);
    }
    else {
        free(info);
        
        if (peer == manager->downloadPeer) {
            peer_log(peer, "sync succeeded");
            _BR_PeerManagerSyncStopped(manager);
            pthread_mutex_unlock(&manager->lock);
            if (manager->syncStopped) manager->syncStopped(manager->info, 0);
        }
        else pthread_mutex_unlock(&manager->lock);
    }
}

static void _BR_PeerManagerLoadMempools(BR_PeerManager *manager)
{
    // after syncing, load filters and get mempools from other peers
    for (size_t i = array_count(manager->connectedPeers); i > 0; i--) {
        BR_Peer *peer = manager->connectedPeers[i - 1];
        BR_PeerCallbackInfo *info;

        if (BR_PeerConnectStatus(peer) != BR_PeerStatusConnected) continue;
        info = calloc(1, sizeof(*info));
        assert(info != NULL);
        info->peer = peer;
        info->manager = manager;
        
        if (peer != manager->downloadPeer || manager->fpRate > BLOOM_REDUCED_FALSEPOSITIVE_RATE*5.0) {
            _BR_PeerManagerLoadBloomFilter(manager, peer);
            _BR_PeerManagerPublishPendingTx(manager, peer);
            BR_PeerSendPing(peer, info, _loadBloomFilterDone); // load mempool after updating bloomfilter
        }
        else BR_PeerSendMempool(peer, manager->publishedTxHashes, array_count(manager->publishedTxHashes), info,
                               _mempoolDone);
    }
}

// returns a UINT128_ZERO terminated array of addresses for hostname that must be freed, or NULL if lookup failed
static UInt128_t *_addressLookup(const char *hostname)
{
    struct addrinfo *servinfo, *p;
    UInt128_t *addrList = NULL;
    size_t count = 0, i = 0;
    
    if (getaddrinfo(hostname, NULL, NULL, &servinfo) == 0) {
        for (p = servinfo; p != NULL; p = p->ai_next) count++;
        if (count > 0) addrList = calloc(count + 1, sizeof(*addrList));
        assert(addrList != NULL || count == 0);
        
        for (p = servinfo; p != NULL; p = p->ai_next) {
            if (p->ai_family == AF_INET) {
                addrList[i].u16[5] = 0xffff;
                addrList[i].u32[3] = ((struct sockaddr_in *)p->ai_addr)->sin_addr.s_addr;
                i++;
            }
//            else if (p->ai_family == AF_INET6) {
//                addrList[i++] = *(UInt128_t *)&((struct sockaddr_in6 *)p->ai_addr)->sin6_addr;
//            }
        }
        
        freeaddrinfo(servinfo);
    }
    
    return addrList;
}

static void *_findPeersThreadRoutine(void *arg)
{
    BR_PeerManager *manager = ((BR_FindPeersInfo *)arg)->manager;
    uint64_t services = ((BR_FindPeersInfo *)arg)->services;
    UInt128_t *addrList, *addr;
    time_t now = time(NULL), age;
    
    pthread_cleanup_push(manager->threadCleanup, manager->info);
    addrList = _addressLookup(((BR_FindPeersInfo *)arg)->hostname);
    free(arg);
    pthread_mutex_lock(&manager->lock);
    
    for (addr = addrList; addr && ! UInt128IsZero(*addr); addr++) {
        age = 24*60*60 + BR_Rand(2*24*60*60); // add between 1 and 3 days
        array_add(manager->peers, ((BR_Peer) { *addr, STANDARD_PORT, services, now - age, 0 }));
    }

    manager->dnsThreadCount--;
    pthread_mutex_unlock(&manager->lock);
    if (addrList) free(addrList);
    pthread_cleanup_pop(1);
    return NULL;
}

// DNS peer discovery
static void _BR_PeerManagerFindPeers(BR_PeerManager *manager)
{
    static const uint64_t services = SERVICES_NODE_NETWORK | SERVICES_NODE_BLOOM;
    time_t now = time(NULL);
    struct timespec ts;
    pthread_t thread;
    pthread_attr_t attr;
    UInt128_t *addr, *addrList;
    BR_FindPeersInfo *info;
    
    if (! UInt128IsZero(manager->fixedPeer.address)) {
        array_set_count(manager->peers, 1);
        manager->peers[0] = manager->fixedPeer;
        manager->peers[0].services = services;
        manager->peers[0].timestamp = now;
    }
    else {
        for (size_t i = 1; i < DNS_SEEDS_COUNT; i++) {
            info = calloc(1, sizeof(BR_FindPeersInfo));
            assert(info != NULL);
            info->manager = manager;
            info->hostname = dns_seeds[i];
            info->services = services;
            if (pthread_attr_init(&attr) == 0 && pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED) == 0 &&
                pthread_create(&thread, &attr, _findPeersThreadRoutine, info) == 0) manager->dnsThreadCount++;
        }

        for (addr = addrList = _addressLookup(dns_seeds[0]); addr && ! UInt128IsZero(*addr); addr++) {
            array_add(manager->peers, ((BR_Peer) { *addr, STANDARD_PORT, services, now, 0 }));
        }

        if (addrList) free(addrList);
        ts.tv_sec = 0;
        ts.tv_nsec = 1;

        do {
            pthread_mutex_unlock(&manager->lock);
            nanosleep(&ts, NULL); // pthread_yield() isn't POSIX standard :(
            pthread_mutex_lock(&manager->lock);
        } while (manager->dnsThreadCount > 0 && array_count(manager->peers) < PEER_MAX_CONNECTIONS);
    
        qsort(manager->peers, array_count(manager->peers), sizeof(*manager->peers), _peerTimestampCompare);
    }
}

static void _peerConnected(void *info)
{
    BR_Peer *peer = ((BR_PeerCallbackInfo *)info)->peer;
    BR_PeerManager *manager = ((BR_PeerCallbackInfo *)info)->manager;
    BR_PeerCallbackInfo *peerInfo;
    time_t now = time(NULL);
    
    pthread_mutex_lock(&manager->lock);
    if (peer->timestamp > now + 2*60*60 || peer->timestamp < now - 2*60*60) peer->timestamp = now; // sanity check
    
    // drop peers that don't carry full blocks, or aren't synced yet
    // TODO: XXX does this work with 0.11 pruned nodes?
    if (! (peer->services & SERVICES_NODE_NETWORK) ||
        BR_PeerLastBlock(peer) + 10 < manager->lastBlock->height) {
        BR_PeerDisconnect(peer);
    }
    else if (BR_PeerVersion(peer) >= 70011 && ! (peer->services & SERVICES_NODE_BLOOM)) {
        BR_PeerDisconnect(peer); // drop peers that don't support SPV filtering
    }
    else if (manager->downloadPeer && // check if we should stick with the existing download peer
             (BR_PeerLastBlock(manager->downloadPeer) >= BR_PeerLastBlock(peer) ||
              manager->lastBlock->height >= BR_PeerLastBlock(peer))) {
        if (manager->lastBlock->height >= BR_PeerLastBlock(peer)) { // only load bloom filter if we're done syncing
            manager->connectFailureCount = 0; // also reset connect failure count if we're already synced
            _BR_PeerManagerLoadBloomFilter(manager, peer);
            _BR_PeerManagerPublishPendingTx(manager, peer);
            peerInfo = calloc(1, sizeof(*peerInfo));
            assert(peerInfo != NULL);
            peerInfo->peer = peer;
            peerInfo->manager = manager;
            BR_PeerSendPing(peer, peerInfo, _loadBloomFilterDone);
        }
    }
    else { // select the peer with the lowest ping time to download the chain from if we're behind
        // BUG: XXX a malicious peer can report a higher lastblock to make us select them as the download peer, if
        // two peers agree on lastblock, use one of those two instead
        for (size_t i = array_count(manager->connectedPeers); i > 0; i--) {
            BR_Peer *p = manager->connectedPeers[i - 1];
            
            if (BR_PeerConnectStatus(p) != BR_PeerStatusConnected) continue;
            if ((BR_PeerPingTime(p) < BR_PeerPingTime(peer) && BR_PeerLastBlock(p) >= BR_PeerLastBlock(peer)) ||
                BR_PeerLastBlock(p) > BR_PeerLastBlock(peer)) peer = p;
        }
        
        if (manager->downloadPeer) BR_PeerDisconnect(manager->downloadPeer);
        manager->downloadPeer = peer;
        manager->isConnected = 1;
        manager->estimatedHeight = BR_PeerLastBlock(peer);
        _BR_PeerManagerLoadBloomFilter(manager, peer);
        BR_PeerSetCurrentBlockHeight(peer, manager->lastBlock->height);
        _BR_PeerManagerPublishPendingTx(manager, peer);
            
        if (manager->lastBlock->height < BR_PeerLastBlock(peer)) { // start blockchain sync
            UInt256_t locators[_BR_PeerManagerBlockLocators(manager, NULL, 0)];
            size_t count = _BR_PeerManagerBlockLocators(manager, locators, sizeof(locators)/sizeof(*locators));
            
            BR_PeerScheduleDisconnect(peer, PROTOCOL_TIMEOUT); // schedule sync timeout

            // request just block headers up to a week before earliestKeyTime, and then merkleblocks after that
            // we do not reset connect failure count yet incase this request times out
            if (manager->lastBlock->timestamp + 7*24*60*60 >= manager->earliestKeyTime) {
                BR_PeerSendGetblocks(peer, locators, count, UINT256_ZERO);
            }
            else BR_PeerSendGetheaders(peer, locators, count, UINT256_ZERO);
        }
        else { // we're already synced
            manager->connectFailureCount = 0; // reset connect failure count
            _BR_PeerManagerLoadMempools(manager);
        }
    }

    pthread_mutex_unlock(&manager->lock);
}

static void _peerDisconnected(void *info, int error)
{
    BR_Peer *peer = ((BR_PeerCallbackInfo *)info)->peer;
    BR_PeerManager *manager = ((BR_PeerCallbackInfo *)info)->manager;
    BR_TxPeerList *peerList;
    int willSave = 0, willReconnect = 0, txError = 0;
    size_t txCount = 0;
    
    //free(info);
    pthread_mutex_lock(&manager->lock);

    void *txInfo[array_count(manager->publishedTx)];
    void (*txCallback[array_count(manager->publishedTx)])(void *, int);
    
    if (error == EPROTO) { // if it's protocol error, the peer isn't following standard policy
        _BR_PeerManagerPeerMisbehavin(manager, peer);
    }
    else if (error) { // timeout or some non-protocol related network error
        for (size_t i = array_count(manager->peers); i > 0; i--) {
            if (BR_PeerEq(&manager->peers[i - 1], peer)) array_rm(manager->peers, i - 1);
        }
        
        manager->connectFailureCount++;
        
        // if it's a timeout and there's pending tx publish callbacks, the tx publish timed out
        // BUG: XXX what if it's a connect timeout and not a publish timeout?
        if (error == ETIMEDOUT && (peer != manager->downloadPeer || manager->syncStartHeight == 0 ||
                                   array_count(manager->connectedPeers) == 1)) txError = ETIMEDOUT;
    }
    
    for (size_t i = array_count(manager->txRelays); i > 0; i--) {
        peerList = &manager->txRelays[i - 1];

        for (size_t j = array_count(peerList->peers); j > 0; j--) {
            if (BR_PeerEq(&peerList->peers[j - 1], peer)) array_rm(peerList->peers, j - 1);
        }
    }

    if (peer == manager->downloadPeer) { // download peer disconnected
        manager->isConnected = 0;
        manager->downloadPeer = NULL;
        if (manager->connectFailureCount > MAX_CONNECT_FAILURES) manager->connectFailureCount = MAX_CONNECT_FAILURES;
    }

    if (! manager->isConnected && manager->connectFailureCount == MAX_CONNECT_FAILURES) {
        _BR_PeerManagerSyncStopped(manager);
        
        // clear out stored peers so we get a fresh list from DNS on next connect attempt
        array_clear(manager->peers);
        txError = ENOTCONN; // trigger any pending tx publish callbacks
        willSave = 1;
        peer_log(peer, "sync failed");
    }
    else if (manager->connectFailureCount < MAX_CONNECT_FAILURES) willReconnect = 1;
    
    if (txError) {
        for (size_t i = array_count(manager->publishedTx); i > 0; i--) {
            if (manager->publishedTx[i - 1].callback == NULL) continue;
            peer_log(peer, "transaction canceled: %s", strerror(txError));
            txInfo[txCount] = manager->publishedTx[i - 1].info;
            txCallback[txCount] = manager->publishedTx[i - 1].callback;
            txCount++;
            BR_TransactionFree(manager->publishedTx[i - 1].tx);
            array_rm(manager->publishedTxHashes, i - 1);
            array_rm(manager->publishedTx, i - 1);
        }
    }
    
    for (size_t i = array_count(manager->connectedPeers); i > 0; i--) {
        if (manager->connectedPeers[i - 1] != peer) continue;
        array_rm(manager->connectedPeers, i - 1);
        break;
    }

    BR_PeerFree(peer);
    pthread_mutex_unlock(&manager->lock);
    
    for (size_t i = 0; i < txCount; i++) {
        txCallback[i](txInfo[i], txError);
    }
    
    if (willSave && manager->savePeers) manager->savePeers(manager->info, 1, NULL, 0);
    if (willSave && manager->syncStopped) manager->syncStopped(manager->info, error);
    if (willReconnect) BR_PeerManagerConnect(manager); // try connecting to another peer
    if (manager->txStatusUpdate) manager->txStatusUpdate(manager->info);
}

static void _peerRelayedPeers(void *info, const BR_Peer peers[], size_t peersCount)
{
    BR_Peer *peer = ((BR_PeerCallbackInfo *)info)->peer;
    BR_PeerManager *manager = ((BR_PeerCallbackInfo *)info)->manager;
    time_t now = time(NULL);

    pthread_mutex_lock(&manager->lock);
    peer_log(peer, "relayed %zu peer(s)", peersCount);

    array_add_array(manager->peers, peers, peersCount);
    qsort(manager->peers, array_count(manager->peers), sizeof(*manager->peers), _peerTimestampCompare);

    // limit total to 2500 peers
    if (array_count(manager->peers) > 2500) array_set_count(manager->peers, 2500);
    peersCount = array_count(manager->peers);
    
    // remove peers more than 3 hours old, or until there are only 1000 left
    while (peersCount > 1000 && manager->peers[peersCount - 1].timestamp + 3*60*60 < now) peersCount--;
    array_set_count(manager->peers, peersCount);
    
    BR_Peer save[peersCount];

    for (size_t i = 0; i < peersCount; i++) save[i] = manager->peers[i];
    pthread_mutex_unlock(&manager->lock);
    
    // peer relaying is complete when we receive <1000
    if (peersCount > 1 && peersCount < 1000 &&
        manager->savePeers) manager->savePeers(manager->info, 1, save, peersCount);
}

static void _peerRelayedTx(void *info, BR_Transaction *tx)
{
    BR_Peer *peer = ((BR_PeerCallbackInfo *)info)->peer;
    BR_PeerManager *manager = ((BR_PeerCallbackInfo *)info)->manager;
    void *txInfo = NULL;
    void (*txCallback)(void *, int) = NULL;
    int isWalletTx = 0, hasPendingCallbacks = 0;
    size_t relayCount = 0;
    
    pthread_mutex_lock(&manager->lock);
    peer_log(peer, "relayed tx: %s", u256_hex_encode(tx->txHash));
    
    for (size_t i = array_count(manager->publishedTx); i > 0; i--) { // see if tx is in list of published tx
        if (UInt256Eq(manager->publishedTxHashes[i - 1], tx->txHash)) {
            txInfo = manager->publishedTx[i - 1].info;
            txCallback = manager->publishedTx[i - 1].callback;
            manager->publishedTx[i - 1].info = NULL;
            manager->publishedTx[i - 1].callback = NULL;
            relayCount = _BR_TxPeerListAddPeer(&manager->txRelays, tx->txHash, peer);
        }
        else if (manager->publishedTx[i - 1].callback != NULL) hasPendingCallbacks = 1;
    }

    // cancel tx publish timeout if no publish callbacks are pending, and syncing is done or this is not downloadPeer
    if (! hasPendingCallbacks && (manager->syncStartHeight == 0 || peer != manager->downloadPeer)) {
        BR_PeerScheduleDisconnect(peer, -1); // cancel publish tx timeout
    }

    if (manager->syncStartHeight == 0 || BR_WalletContainsTransaction(manager->wallet, tx)) {
        isWalletTx = BR_WalletRegisterTransaction(manager->wallet, tx);
        if (isWalletTx) tx = BR_WalletTransactionForHash(manager->wallet, tx->txHash);
    }
    else {
        BR_TransactionFree(tx);
        tx = NULL;
    }
    
    if (tx && isWalletTx) {
        // reschedule sync timeout
        if (manager->syncStartHeight > 0 && peer == manager->downloadPeer) {
            BR_PeerScheduleDisconnect(peer, PROTOCOL_TIMEOUT);
        }
        
        if (BR_WalletAmountSentByTx(manager->wallet, tx) > 0 && BR_WalletTransactionIsValid(manager->wallet, tx)) {
            _BR_PeerManagerAddTxToPublishList(manager, tx, NULL, NULL); // add valid send tx to mempool
        }

        // keep track of how many peers have or relay a tx, this indicates how likely the tx is to confirm
        // (we only need to track this after syncing is complete)
        if (manager->syncStartHeight == 0) relayCount = _BR_TxPeerListAddPeer(&manager->txRelays, tx->txHash, peer);
        
        _BR_TxPeerListRemovePeer(manager->txRequests, tx->txHash, peer);
        
        if (manager->bloomFilter != NULL) { // check if bloom filter is already being updated
            BR_Address addrs[SEQUENCE_GAP_LIMIT_EXTERNAL + SEQUENCE_GAP_LIMIT_INTERNAL];
            UInt160_t hash;

            // the transaction likely consumed one or more wallet addresses, so check that at least the next <gap limit>
            // unused addresses are still matched by the bloom filter
            BR_WalletUnusedAddrs(manager->wallet, addrs, SEQUENCE_GAP_LIMIT_EXTERNAL, 0);
            BR_WalletUnusedAddrs(manager->wallet, addrs + SEQUENCE_GAP_LIMIT_EXTERNAL, SEQUENCE_GAP_LIMIT_INTERNAL, 1);

            for (size_t i = 0; i < SEQUENCE_GAP_LIMIT_EXTERNAL + SEQUENCE_GAP_LIMIT_INTERNAL; i++) {
                if (! BR_AddressHash160(&hash, addrs[i].s) ||
                    BR_BloomFilterContainsData(manager->bloomFilter, hash.u8, sizeof(hash))) continue;
                if (manager->bloomFilter) BR_BloomFilterFree(manager->bloomFilter);
                manager->bloomFilter = NULL; // reset bloom filter so it's recreated with new wallet addresses
                _BR_PeerManagerUpdateFilter(manager);
                break;
            }
        }
    }
    
    // set timestamp when tx is verified
    if (tx && relayCount >= manager->maxConnectCount && tx->blockHeight == TX_UNCONFIRMED && tx->timestamp == 0) {
        _BR_PeerManagerUpdateTx(manager, &tx->txHash, 1, TX_UNCONFIRMED, (uint32_t)time(NULL));
    }
    
    pthread_mutex_unlock(&manager->lock);
    if (txCallback) txCallback(txInfo, 0);
}

static void _peerHasTx(void *info, UInt256_t txHash)
{
    BR_Peer *peer = ((BR_PeerCallbackInfo *)info)->peer;
    BR_PeerManager *manager = ((BR_PeerCallbackInfo *)info)->manager;
    BR_Transaction *tx;
    void *txInfo = NULL;
    void (*txCallback)(void *, int) = NULL;
    int isWalletTx = 0, hasPendingCallbacks = 0;
    size_t relayCount = 0;
    
    pthread_mutex_lock(&manager->lock);
    tx = BR_WalletTransactionForHash(manager->wallet, txHash);
    peer_log(peer, "has tx: %s", u256_hex_encode(txHash));

    for (size_t i = array_count(manager->publishedTx); i > 0; i--) { // see if tx is in list of published tx
        if (UInt256Eq(manager->publishedTxHashes[i - 1], txHash)) {
            if (! tx) tx = manager->publishedTx[i - 1].tx;
            txInfo = manager->publishedTx[i - 1].info;
            txCallback = manager->publishedTx[i - 1].callback;
            manager->publishedTx[i - 1].info = NULL;
            manager->publishedTx[i - 1].callback = NULL;
            relayCount = _BR_TxPeerListAddPeer(&manager->txRelays, txHash, peer);
        }
        else if (manager->publishedTx[i - 1].callback != NULL) hasPendingCallbacks = 1;
    }
    
    // cancel tx publish timeout if no publish callbacks are pending, and syncing is done or this is not downloadPeer
    if (! hasPendingCallbacks && (manager->syncStartHeight == 0 || peer != manager->downloadPeer)) {
        BR_PeerScheduleDisconnect(peer, -1); // cancel publish tx timeout
    }

    if (tx) {
        isWalletTx = BR_WalletRegisterTransaction(manager->wallet, tx);
        if (isWalletTx) tx = BR_WalletTransactionForHash(manager->wallet, tx->txHash);

        // reschedule sync timeout
        if (manager->syncStartHeight > 0 && peer == manager->downloadPeer && isWalletTx) {
            BR_PeerScheduleDisconnect(peer, PROTOCOL_TIMEOUT);
        }
        
        // keep track of how many peers have or relay a tx, this indicates how likely the tx is to confirm
        // (we only need to track this after syncing is complete)
        if (manager->syncStartHeight == 0) relayCount = _BR_TxPeerListAddPeer(&manager->txRelays, txHash, peer);

        // set timestamp when tx is verified
        if (relayCount >= manager->maxConnectCount && tx && tx->blockHeight == TX_UNCONFIRMED && tx->timestamp == 0) {
            _BR_PeerManagerUpdateTx(manager, &txHash, 1, TX_UNCONFIRMED, (uint32_t)time(NULL));
        }

        _BR_TxPeerListRemovePeer(manager->txRequests, txHash, peer);
    }
    
    pthread_mutex_unlock(&manager->lock);
    if (txCallback) txCallback(txInfo, 0);
}

static void _peerRejectedTx(void *info, UInt256_t txHash, uint8_t code)
{
    BR_Peer *peer = ((BR_PeerCallbackInfo *)info)->peer;
    BR_PeerManager *manager = ((BR_PeerCallbackInfo *)info)->manager;
    BR_Transaction *tx, *t;

    pthread_mutex_lock(&manager->lock);
    peer_log(peer, "rejected tx: %s", u256_hex_encode(txHash));
    tx = BR_WalletTransactionForHash(manager->wallet, txHash);
    _BR_TxPeerListRemovePeer(manager->txRequests, txHash, peer);

    if (tx) {
        if (_BR_TxPeerListRemovePeer(manager->txRelays, txHash, peer) && tx->blockHeight == TX_UNCONFIRMED) {
            // set timestamp 0 to mark tx as unverified
            _BR_PeerManagerUpdateTx(manager, &txHash, 1, TX_UNCONFIRMED, 0);
        }

        // if we get rejected for any reason other than double-spend, the peer is likely misconfigured
        if (code != REJECT_SPENT && BR_WalletAmountSentByTx(manager->wallet, tx) > 0) {
            for (size_t i = 0; i < tx->inCount; i++) { // check that all inputs are confirmed before dropping peer
                t = BR_WalletTransactionForHash(manager->wallet, tx->inputs[i].txHash);
                if (! t || t->blockHeight != TX_UNCONFIRMED) continue;
                tx = NULL;
                break;
            }
            
            if (tx) _BR_PeerManagerPeerMisbehavin(manager, peer);
        }
    }

    pthread_mutex_unlock(&manager->lock);
    if (manager->txStatusUpdate) manager->txStatusUpdate(manager->info);
}

static int _BR_PeerManagerVerifyBlock(BR_PeerManager *manager, BR_MerkleBlock *block, BR_MerkleBlock *prev, BR_Peer *peer)
{
    uint32_t transitionTime = 0;
    int r = 1;
    
    // check if we hit a difficulty transition, and find previous transition time
    if ((block->height % BLOCK_DIFFICULTY_INTERVAL) == 0) {
        BR_MerkleBlock *b = block;
        UInt256_t prevBlock;

        for (uint32_t i = 0; b && i < BLOCK_DIFFICULTY_INTERVAL; i++) {
            b = BR_SetGet(manager->blocks, &b->prevBlock);
        }

        if (! b) {
            peer_log(peer, "missing previous difficulty tansition time, can't verify blockHash: %s",
                     u256_hex_encode(block->blockHash));
            r = 0;
        }
        else {
            transitionTime = b->timestamp;
            prevBlock = b->prevBlock;
        }
        
        while (b) { // free up some memory
            b = BR_SetGet(manager->blocks, &prevBlock);
            if (b) prevBlock = b->prevBlock;

            if (b && (b->height % BLOCK_DIFFICULTY_INTERVAL) != 0) {
                BR_SetRemove(manager->blocks, b);
                BR_MerkleBlockFree(b);
            }
        }
    }

    // verify block difficulty
    if (r && ! BR_MerkleBlockVerifyDifficulty(block, prev, transitionTime)) {
        peer_log(peer, "relayed block with invalid difficulty target %x, blockHash: %s", block->target,
                 u256_hex_encode(block->blockHash));
        r = 0;
    }
    
    if (r) {
        BR_MerkleBlock *checkpoint = BR_SetGet(manager->checkpoints, block);

        // verify blockchain checkpoints
        if (checkpoint && ! BR_MerkleBlockEq(block, checkpoint)) {
            peer_log(peer, "relayed a block that differs from the checkpoint at height %"PRIu32", blockHash: %s, "
                     "expected: %s", block->height, u256_hex_encode(block->blockHash),
                     u256_hex_encode(checkpoint->blockHash));
            r = 0;
        }
    }

    return r;
}

static void _peerRelayedBlock(void *info, BR_MerkleBlock *block)
{
    BR_Peer *peer = ((BR_PeerCallbackInfo *)info)->peer;
    BR_PeerManager *manager = ((BR_PeerCallbackInfo *)info)->manager;
    size_t txCount = BR_MerkleBlockTxHashes(block, NULL, 0);
    UInt256_t _txHashes[(sizeof(UInt256_t)*txCount <= 0x1000) ? txCount : 0],
            *txHashes = (sizeof(UInt256_t)*txCount <= 0x1000) ? _txHashes : malloc(txCount*sizeof(*txHashes));
    size_t i, j, fpCount = 0, saveCount = 0;
    BR_MerkleBlock orphan, *b, *b2, *prev, *next = NULL;
    uint32_t txTime = 0;
    
    assert(txHashes != NULL);
    txCount = BR_MerkleBlockTxHashes(block, txHashes, txCount);
    pthread_mutex_lock(&manager->lock);
    prev = BR_SetGet(manager->blocks, &block->prevBlock);

    if (prev) {
        txTime = block->timestamp/2 + prev->timestamp/2;
        block->height = prev->height + 1;
    }
    
    // track the observed bloom filter false positive rate using a low pass filter to smooth out variance
    if (peer == manager->downloadPeer && block->totalTx > 0) {
        for (i = 0; i < txCount; i++) { // wallet tx are not false-positives
            if (! BR_WalletTransactionForHash(manager->wallet, txHashes[i])) fpCount++;
        }
        
        // moving average number of tx-per-block
        manager->averageTxPerBlock = manager->averageTxPerBlock*0.999 + block->totalTx*0.001;
        
        // 1% low pass filter, also weights each block by total transactions, compared to the avarage
        manager->fpRate = manager->fpRate*(1.0 - 0.01*block->totalTx/manager->averageTxPerBlock) +
                          0.01*fpCount/manager->averageTxPerBlock;
        
        // false positive rate sanity check
        if (BR_PeerConnectStatus(peer) == BR_PeerStatusConnected &&
            manager->fpRate > BLOOM_DEFAULT_FALSEPOSITIVE_RATE*10.0) {
            peer_log(peer, "bloom filter false positive rate %f too high after %"PRIu32" blocks, disconnecting...",
                     manager->fpRate, manager->lastBlock->height + 1 - manager->filterUpdateHeight);
            BR_PeerDisconnect(peer);
        }
        else if (manager->lastBlock->height + 500 < BR_PeerLastBlock(peer) &&
                 manager->fpRate > BLOOM_REDUCED_FALSEPOSITIVE_RATE*10.0) {
            _BR_PeerManagerUpdateFilter(manager); // rebuild bloom filter when it starts to degrade
        }
    }

    // ignore block headers that are newer than one week before earliestKeyTime (it's a header if it has 0 totalTx)
    if (block->totalTx == 0 && block->timestamp + 7*24*60*60 > manager->earliestKeyTime + 2*60*60) {
        BR_MerkleBlockFree(block);
        block = NULL;
    }
    else if (manager->bloomFilter == NULL) { // ingore potentially incomplete blocks when a filter update is pending
        BR_MerkleBlockFree(block);
        block = NULL;

        if (peer == manager->downloadPeer && manager->lastBlock->height < manager->estimatedHeight) {
            BR_PeerScheduleDisconnect(peer, PROTOCOL_TIMEOUT); // reschedule sync timeout
            manager->connectFailureCount = 0; // reset failure count once we know our initial request didn't timeout
        }
    }
    else if (! prev) { // block is an orphan
        peer_log(peer, "relayed orphan block %s, previous %s, last block is %s, height %"PRIu32,
                 u256_hex_encode(block->blockHash), u256_hex_encode(block->prevBlock),
                 u256_hex_encode(manager->lastBlock->blockHash), manager->lastBlock->height);
        
        if (block->timestamp + 7*24*60*60 < time(NULL)) { // ignore orphans older than one week ago
            BR_MerkleBlockFree(block);
            block = NULL;
        }
        else {
            // call getblocks, unless we already did with the previous block, or we're still syncing
            if (manager->lastBlock->height >= BR_PeerLastBlock(peer) &&
                (! manager->lastOrphan || ! UInt256Eq(manager->lastOrphan->blockHash, block->prevBlock))) {
                UInt256_t locators[_BR_PeerManagerBlockLocators(manager, NULL, 0)];
                size_t locatorsCount = _BR_PeerManagerBlockLocators(manager, locators,
                                                                   sizeof(locators)/sizeof(*locators));
                
                peer_log(peer, "calling getblocks");
                BR_PeerSendGetblocks(peer, locators, locatorsCount, UINT256_ZERO);
            }
            
            BR_SetAdd(manager->orphans, block); // BUG: limit total orphans to avoid memory exhaustion attack
            manager->lastOrphan = block;
        }
    }
    else if (! _BR_PeerManagerVerifyBlock(manager, block, prev, peer)) { // block is invalid
        peer_log(peer, "relayed invalid block");
        BR_MerkleBlockFree(block);
        block = NULL;
        _BR_PeerManagerPeerMisbehavin(manager, peer);
    }
    else if (UInt256Eq(block->prevBlock, manager->lastBlock->blockHash)) { // new block extends main chain
        if ((block->height % 500) == 0 || txCount > 0 || block->height >= BR_PeerLastBlock(peer)) {
            peer_log(peer, "adding block #%"PRIu32", false positive rate: %f", block->height, manager->fpRate);
        }
        
        BR_SetAdd(manager->blocks, block);
        manager->lastBlock = block;
        if (txCount > 0) _BR_PeerManagerUpdateTx(manager, txHashes, txCount, block->height, txTime);
        if (manager->downloadPeer) BR_PeerSetCurrentBlockHeight(manager->downloadPeer, block->height);
            
        if (block->height < manager->estimatedHeight && peer == manager->downloadPeer) {
            BR_PeerScheduleDisconnect(peer, PROTOCOL_TIMEOUT); // reschedule sync timeout
            manager->connectFailureCount = 0; // reset failure count once we know our initial request didn't timeout
        }
        
        if ((block->height % BLOCK_DIFFICULTY_INTERVAL) == 0) saveCount = 1; // save transition block immediately
        
        if (block->height == manager->estimatedHeight) { // chain download is complete
            saveCount = (block->height % BLOCK_DIFFICULTY_INTERVAL) + BLOCK_DIFFICULTY_INTERVAL + 1;
            _BR_PeerManagerLoadMempools(manager);
        }
    }
    else if (BR_SetContains(manager->blocks, block)) { // we already have the block (or at least the header)
        if ((block->height % 500) == 0 || txCount > 0 || block->height >= BR_PeerLastBlock(peer)) {
            peer_log(peer, "relayed existing block #%"PRIu32, block->height);
        }
        
        b = manager->lastBlock;
        while (b && b->height > block->height) b = BR_SetGet(manager->blocks, &b->prevBlock); // is block in main chain?
        
        if (BR_MerkleBlockEq(b, block)) { // if it's not on a fork, set block heights for its transactions
            if (txCount > 0) _BR_PeerManagerUpdateTx(manager, txHashes, txCount, block->height, txTime);
            if (block->height == manager->lastBlock->height) manager->lastBlock = block;
        }
        
        b = BR_SetAdd(manager->blocks, block);

        if (b != block) {
            if (BR_SetGet(manager->orphans, b) == b) BR_SetRemove(manager->orphans, b);
            if (manager->lastOrphan == b) manager->lastOrphan = NULL;
            BR_MerkleBlockFree(b);
        }
    }
    else if (manager->lastBlock->height < BR_PeerLastBlock(peer) &&
             block->height > manager->lastBlock->height + 1) { // special case, new block mined durring rescan
        peer_log(peer, "marking new block #%"PRIu32" as orphan until rescan completes", block->height);
        BR_SetAdd(manager->orphans, block); // mark as orphan til we're caught up
        manager->lastOrphan = block;
    }
    else if (block->height <= checkpoint_array[CHECKPOINT_COUNT - 1].height) { // fork is older than last checkpoint
        peer_log(peer, "ignoring block on fork older than most recent checkpoint, block #%"PRIu32", hash: %s",
                 block->height, u256_hex_encode(block->blockHash));
        BR_MerkleBlockFree(block);
        block = NULL;
    }
    else { // new block is on a fork
        peer_log(peer, "chain fork reached height %"PRIu32, block->height);
        BR_SetAdd(manager->blocks, block);

        if (block->height > manager->lastBlock->height) { // check if fork is now longer than main chain
            b = block;
            b2 = manager->lastBlock;
            
            while (b && b2 && ! BR_MerkleBlockEq(b, b2)) { // walk back to where the fork joins the main chain
                b = BR_SetGet(manager->blocks, &b->prevBlock);
                if (b && b->height < b2->height) b2 = BR_SetGet(manager->blocks, &b2->prevBlock);
            }
            
            peer_log(peer, "reorganizing chain from height %"PRIu32", new height is %"PRIu32, b->height, block->height);
        
            BR_WalletSetTxUnconfirmedAfter(manager->wallet, b->height); // mark tx after the join point as unconfirmed

            b = block;
        
            while (b && b2 && b->height > b2->height) { // set transaction heights for new main chain
                size_t count = BR_MerkleBlockTxHashes(b, NULL, 0);
                uint32_t height = b->height, timestamp = b->timestamp;
                
                if (count > txCount) {
                    txHashes = (txHashes != _txHashes) ? realloc(txHashes, count*sizeof(*txHashes)) :
                               malloc(count*sizeof(*txHashes));
                    assert(txHashes != NULL);
                    txCount = count;
                }
                
                count = BR_MerkleBlockTxHashes(b, txHashes, count);
                b = BR_SetGet(manager->blocks, &b->prevBlock);
                if (b) timestamp = timestamp/2 + b->timestamp/2;
                if (count > 0) BR_WalletUpdateTransactions(manager->wallet, txHashes, count, height, timestamp);
            }
        
            manager->lastBlock = block;
            
            if (block->height == manager->estimatedHeight) { // chain download is complete
                saveCount = (block->height % BLOCK_DIFFICULTY_INTERVAL) + BLOCK_DIFFICULTY_INTERVAL + 1;
                _BR_PeerManagerLoadMempools(manager);
            }
        }
    }
   
    if (txHashes != _txHashes) free(txHashes);
   
    if (block && block->height != BLOCK_UNKNOWN_HEIGHT) {
        if (block->height > manager->estimatedHeight) manager->estimatedHeight = block->height;
        
        // check if the next block was received as an orphan
        orphan.prevBlock = block->blockHash;
        next = BR_SetRemove(manager->orphans, &orphan);
    }
    
    BR_MerkleBlock *saveBlocks[saveCount];
    
    for (i = 0, b = block; b && i < saveCount; i++) {
        saveBlocks[i] = b;
        b = BR_SetGet(manager->blocks, &b->prevBlock);
    }
    
    // make sure the set of blocks to be saved starts at a difficulty interval
    j = (i > 0) ? saveBlocks[i - 1]->height % BLOCK_DIFFICULTY_INTERVAL : 0;
    if (j > 0) i -= (i > BLOCK_DIFFICULTY_INTERVAL - j) ? BLOCK_DIFFICULTY_INTERVAL - j : i;
    assert(i == 0 || (saveBlocks[i - 1]->height % BLOCK_DIFFICULTY_INTERVAL) == 0);
    pthread_mutex_unlock(&manager->lock);
    if (i > 0 && manager->saveBlocks) manager->saveBlocks(manager->info, (i > 1 ? 1 : 0), saveBlocks, i);
    
    if (block && block->height != BLOCK_UNKNOWN_HEIGHT && block->height >= BR_PeerLastBlock(peer) &&
        manager->txStatusUpdate) {
        manager->txStatusUpdate(manager->info); // notify that transaction confirmations may have changed
    }
    
    if (next) _peerRelayedBlock(info, next);
}

static void _peerDataNotfound(void *info, const UInt256_t txHashes[], size_t txCount,
                             const UInt256_t blockHashes[], size_t blockCount)
{
    BR_Peer *peer = ((BR_PeerCallbackInfo *)info)->peer;
    BR_PeerManager *manager = ((BR_PeerCallbackInfo *)info)->manager;

    pthread_mutex_lock(&manager->lock);

    for (size_t i = 0; i < txCount; i++) {
        _BR_TxPeerListRemovePeer(manager->txRelays, txHashes[i], peer);
        _BR_TxPeerListRemovePeer(manager->txRequests, txHashes[i], peer);
    }

    pthread_mutex_unlock(&manager->lock);
}

static void _peerSetFeePerKb(void *info, uint64_t feePerKb)
{
    BR_Peer *p, *peer = ((BR_PeerCallbackInfo *)info)->peer;
    BR_PeerManager *manager = ((BR_PeerCallbackInfo *)info)->manager;
    uint64_t maxFeePerKb = 0, secondFeePerKb = 0;
    
    pthread_mutex_lock(&manager->lock);
    
    for (size_t i = array_count(manager->connectedPeers); i > 0; i--) { // find second highest fee rate
        p = manager->connectedPeers[i - 1];
        if (BR_PeerConnectStatus(p) != BR_PeerStatusConnected) continue;
        if (BR_PeerFeePerKb(p) > maxFeePerKb) secondFeePerKb = maxFeePerKb, maxFeePerKb = BR_PeerFeePerKb(p);
    }
    
    if (secondFeePerKb*3/2 > DEFAULT_FEE_PER_KB && secondFeePerKb*3/2 <= MAX_FEE_PER_KB &&
        secondFeePerKb*3/2 > BR_WalletFeePerKb(manager->wallet)) {
        peer_log(peer, "increasing feePerKb to %llu based on feefilter messages from peers", secondFeePerKb*3/2);
        BR_WalletSetFeePerKb(manager->wallet, secondFeePerKb*3/2);
    }

    pthread_mutex_unlock(&manager->lock);
}

//static void _peerRequestedTxPingDone(void *info, int success)
//{
//    BR_Peer *peer = ((BR_PeerCallbackInfo *)info)->peer;
//    BR_PeerManager *manager = ((BR_PeerCallbackInfo *)info)->manager;
//    UInt256_t txHash = ((BR_PeerCallbackInfo *)info)->hash;
//
//    free(info);
//    pthread_mutex_lock(&manager->lock);
//
//    if (success && ! _BR_TxPeerListHasPeer(manager->txRequests, txHash, peer)) {
//        _BR_TxPeerListAddPeer(&manager->txRequests, txHash, peer);
//        BR_PeerSendGetdata(peer, &txHash, 1, NULL, 0); // check if peer will relay the transaction back
//    }
//    
//    pthread_mutex_unlock(&manager->lock);
//}

static BR_Transaction *_peerRequestedTx(void *info, UInt256_t txHash)
{
    BR_Peer *peer = ((BR_PeerCallbackInfo *)info)->peer;
    BR_PeerManager *manager = ((BR_PeerCallbackInfo *)info)->manager;
//    BR_PeerCallbackInfo *pingInfo;
    BR_Transaction *tx = NULL;
    void *txInfo = NULL;
    void (*txCallback)(void *, int) = NULL;
    int hasPendingCallbacks = 0, error = 0;

    pthread_mutex_lock(&manager->lock);

    for (size_t i = array_count(manager->publishedTx); i > 0; i--) {
        if (UInt256Eq(manager->publishedTxHashes[i - 1], txHash)) {
            tx = manager->publishedTx[i - 1].tx;
            txInfo = manager->publishedTx[i - 1].info;
            txCallback = manager->publishedTx[i - 1].callback;
            manager->publishedTx[i - 1].info = NULL;
            manager->publishedTx[i - 1].callback = NULL;
        
            if (tx && ! BR_WalletTransactionIsValid(manager->wallet, tx)) {
                error = EINVAL;
                array_rm(manager->publishedTx, i - 1);
                array_rm(manager->publishedTxHashes, i - 1);
                
                if (! BR_WalletTransactionForHash(manager->wallet, txHash)) {
                    BR_TransactionFree(tx);
                    tx = NULL;
                }
            }
        }
        else if (manager->publishedTx[i - 1].callback != NULL) hasPendingCallbacks = 1;
    }

    // cancel tx publish timeout if no publish callbacks are pending, and syncing is done or this is not downloadPeer
    if (! hasPendingCallbacks && (manager->syncStartHeight == 0 || peer != manager->downloadPeer)) {
        BR_PeerScheduleDisconnect(peer, -1); // cancel publish tx timeout
    }

    if (tx && ! error) {
        _BR_TxPeerListAddPeer(&manager->txRelays, txHash, peer);
        BR_WalletRegisterTransaction(manager->wallet, tx);
    }
    
//    pingInfo = calloc(1, sizeof(*pingInfo));
//    assert(pingInfo != NULL);
//    pingInfo->peer = peer;
//    pingInfo->manager = manager;
//    pingInfo->hash = txHash;
//    BR_PeerSendPing(peer, pingInfo, _peerRequestedTxPingDone);
    pthread_mutex_unlock(&manager->lock);
    if (txCallback) txCallback(txInfo, error);
    return tx;
}

static int _peerNetworkIsReachable(void *info)
{
    BR_PeerManager *manager = ((BR_PeerCallbackInfo *)info)->manager;

    return (manager->networkIsReachable) ? manager->networkIsReachable(manager->info) : 1;
}

static void _peerThreadCleanup(void *info)
{
    BR_PeerManager *manager = ((BR_PeerCallbackInfo *)info)->manager;

    free(info);
    if (manager->threadCleanup) manager->threadCleanup(manager->info);
}

static void _dummyThreadCleanup(void *info)
{
}

// returns a newly allocated BR_PeerManager struct that must be freed by calling BR_PeerManagerFree()
BR_PeerManager *BR_PeerManagerNew(BR_Wallet *wallet, uint32_t earliestKeyTime, BR_MerkleBlock *blocks[], size_t blocksCount,
                                const BR_Peer peers[], size_t peersCount)
{
    BR_PeerManager *manager = calloc(1, sizeof(*manager));
    BR_MerkleBlock orphan, *block = NULL;
    
    assert(manager != NULL);
    assert(wallet != NULL);
    assert(blocks != NULL || blocksCount == 0);
    assert(peers != NULL || peersCount == 0);
    manager->wallet = wallet;
    manager->earliestKeyTime = earliestKeyTime;
    manager->averageTxPerBlock = 1400;
    manager->maxConnectCount = PEER_MAX_CONNECTIONS;
    array_new(manager->peers, peersCount);
    if (peers) array_add_array(manager->peers, peers, peersCount);
    qsort(manager->peers, array_count(manager->peers), sizeof(*manager->peers), _peerTimestampCompare);
    array_new(manager->connectedPeers, PEER_MAX_CONNECTIONS);
    manager->blocks = BR_SetNew(BR_MerkleBlockHash, BR_MerkleBlockEq, blocksCount);
    manager->orphans = BR_SetNew(_BR_PrevBlockHash, _BR_PrevBlockEq, blocksCount); // orphans are indexed by prevBlock
    manager->checkpoints = BR_SetNew(_BR_BlockHeightHash, _BR_BlockHeightEq, 100); // checkpoints are indexed by height

    for (size_t i = 0; i < CHECKPOINT_COUNT; i++) {
        block = BR_MerkleBlockNew();
        block->height = checkpoint_array[i].height;
        block->blockHash = UInt256Reverse(u256_hex_decode(checkpoint_array[i].hash));
        block->timestamp = checkpoint_array[i].timestamp;
        block->target = checkpoint_array[i].target;
        BR_SetAdd(manager->checkpoints, block);
        BR_SetAdd(manager->blocks, block);
        if (i == 0 || block->timestamp + 7*24*60*60 < manager->earliestKeyTime) manager->lastBlock = block;
    }

    block = NULL;
    
    for (size_t i = 0; blocks && i < blocksCount; i++) {
        assert(blocks[i]->height != BLOCK_UNKNOWN_HEIGHT); // height must be saved/restored along with serialized block
        BR_SetAdd(manager->orphans, blocks[i]);

        if ((blocks[i]->height % BLOCK_DIFFICULTY_INTERVAL) == 0 &&
            (! block || blocks[i]->height > block->height)) block = blocks[i]; // find last transition block
    }
    
    while (block) {
        BR_SetAdd(manager->blocks, block);
        manager->lastBlock = block;
        orphan.prevBlock = block->prevBlock;
        BR_SetRemove(manager->orphans, &orphan);
        orphan.prevBlock = block->blockHash;
        block = BR_SetGet(manager->orphans, &orphan);
    }
    
    array_new(manager->txRelays, 10);
    array_new(manager->txRequests, 10);
    array_new(manager->publishedTx, 10);
    array_new(manager->publishedTxHashes, 10);
    pthread_mutex_init(&manager->lock, NULL);
    manager->threadCleanup = _dummyThreadCleanup;
    return manager;
}

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
                               void (*threadCleanup)(void *info))
{
    assert(manager != NULL);
    manager->info = info;
    manager->syncStarted = syncStarted;
    manager->syncStopped = syncStopped;
    manager->txStatusUpdate = txStatusUpdate;
    manager->saveBlocks = saveBlocks;
    manager->savePeers = savePeers;
    manager->networkIsReachable = networkIsReachable;
    manager->threadCleanup = (threadCleanup) ? threadCleanup : _dummyThreadCleanup;
}

// specifies a single fixed peer to use when connecting to the bitcoin network
// set address to UINT128_ZERO to revert to default behavior
void BR_PeerManagerSetFixedPeer(BR_PeerManager *manager, UInt128_t address, uint16_t port)
{
    assert(manager != NULL);
    BR_PeerManagerDisconnect(manager);
    pthread_mutex_lock(&manager->lock);
    manager->maxConnectCount = UInt128IsZero(address) ? PEER_MAX_CONNECTIONS : 1;
    manager->fixedPeer = ((BR_Peer) { address, port, 0, 0, 0 });
    array_clear(manager->peers);
    pthread_mutex_unlock(&manager->lock);
}

// true if currently connected to at least one peer
int BR_PeerManagerIsConnected(BR_PeerManager *manager)
{
    int isConnected;
    
    assert(manager != NULL);
    pthread_mutex_lock(&manager->lock);
    isConnected = manager->isConnected;
    pthread_mutex_unlock(&manager->lock);
    return isConnected;
}

// connect to bitcoin peer-to-peer network (also call this whenever networkIsReachable() status changes)
void BR_PeerManagerConnect(BR_PeerManager *manager)
{
    assert(manager != NULL);
    pthread_mutex_lock(&manager->lock);
    if (manager->connectFailureCount >= MAX_CONNECT_FAILURES) manager->connectFailureCount = 0; //this is a manual retry
    
    if ((! manager->downloadPeer || manager->lastBlock->height < manager->estimatedHeight) &&
        manager->syncStartHeight == 0) {
        manager->syncStartHeight = manager->lastBlock->height + 1;
        pthread_mutex_unlock(&manager->lock);
        if (manager->syncStarted) manager->syncStarted(manager->info);
        pthread_mutex_lock(&manager->lock);
    }
    
    for (size_t i = array_count(manager->connectedPeers); i > 0; i--) {
        BR_Peer *p = manager->connectedPeers[i - 1];

        if (BR_PeerConnectStatus(p) == BR_PeerStatusConnecting) BR_PeerConnect(p);
    }
    
    if (array_count(manager->connectedPeers) < manager->maxConnectCount) {
        time_t now = time(NULL);
        BR_Peer *peers;

        if (array_count(manager->peers) < manager->maxConnectCount ||
            manager->peers[manager->maxConnectCount - 1].timestamp + 3*24*60*60 < now) {
            _BR_PeerManagerFindPeers(manager);
        }
        
        array_new(peers, 100);
        array_add_array(peers, manager->peers,
                        (array_count(manager->peers) < 100) ? array_count(manager->peers) : 100);

        while (array_count(peers) > 0 && array_count(manager->connectedPeers) < manager->maxConnectCount) {
            size_t i = BR_Rand((uint32_t)array_count(peers)); // index of random peer
            BR_PeerCallbackInfo *info;
            
            i = i*i/array_count(peers); // bias random peer selection toward peers with more recent timestamp
        
            for (size_t j = array_count(manager->connectedPeers); i != SIZE_MAX && j > 0; j--) {
                if (! BR_PeerEq(&peers[i], manager->connectedPeers[j - 1])) continue;
                array_rm(peers, i); // already in connectedPeers
                i = SIZE_MAX;
            }
            
            if (i != SIZE_MAX) {
                info = calloc(1, sizeof(*info));
                assert(info != NULL);
                info->manager = manager;
                info->peer = BR_PeerNew();
                *info->peer = peers[i];
                array_rm(peers, i);
                array_add(manager->connectedPeers, info->peer);
                BR_PeerSetCallbacks(info->peer, info, _peerConnected, _peerDisconnected, _peerRelayedPeers,
                                   _peerRelayedTx, _peerHasTx, _peerRejectedTx, _peerRelayedBlock, _peerDataNotfound,
                                   _peerSetFeePerKb, _peerRequestedTx, _peerNetworkIsReachable, _peerThreadCleanup);
                BR_PeerSetEarliestKeyTime(info->peer, manager->earliestKeyTime);
                BR_PeerConnect(info->peer);
            }
        }

        array_free(peers);
    }
    
    if (array_count(manager->connectedPeers) == 0) {
        peer_log(&BR_PEER_NONE, "sync failed");
        _BR_PeerManagerSyncStopped(manager);
        pthread_mutex_unlock(&manager->lock);
        if (manager->syncStopped) manager->syncStopped(manager->info, ENETUNREACH);
    }
    else pthread_mutex_unlock(&manager->lock);
}

void BR_PeerManagerDisconnect(BR_PeerManager *manager)
{
    struct timespec ts;
    size_t peerCount, dnsThreadCount;
    
    assert(manager != NULL);
    pthread_mutex_lock(&manager->lock);
    peerCount = array_count(manager->connectedPeers);
    dnsThreadCount = manager->dnsThreadCount;
    
    for (size_t i = peerCount; i > 0; i--) {
        manager->connectFailureCount = MAX_CONNECT_FAILURES; // prevent futher automatic reconnect attempts
        BR_PeerDisconnect(manager->connectedPeers[i - 1]);
    }
    
    pthread_mutex_unlock(&manager->lock);
    ts.tv_sec = 0;
    ts.tv_nsec = 1;
    
    while (peerCount > 0 || dnsThreadCount > 0) {
        nanosleep(&ts, NULL); // pthread_yield() isn't POSIX standard :(
        pthread_mutex_lock(&manager->lock);
        peerCount = array_count(manager->connectedPeers);
        dnsThreadCount = manager->dnsThreadCount;
        pthread_mutex_unlock(&manager->lock);
    }
}

// rescans blocks and transactions after earliestKeyTime (a new random download peer is also selected due to the
// possibility that a malicious node might lie by omitting transactions that match the bloom filter)
void BR_PeerManagerRescan(BR_PeerManager *manager)
{
    assert(manager != NULL);
    pthread_mutex_lock(&manager->lock);
    
    if (manager->isConnected) {
        // start the chain download from the most recent checkpoint that's at least a week older than earliestKeyTime
        for (size_t i = CHECKPOINT_COUNT; i > 0; i--) {
            if (i - 1 == 0 || checkpoint_array[i - 1].timestamp + 7*24*60*60 < manager->earliestKeyTime) {
                UInt256_t hash = UInt256Reverse(u256_hex_decode(checkpoint_array[i - 1].hash));

                manager->lastBlock = BR_SetGet(manager->blocks, &hash);
                break;
            }
        }
        
        if (manager->downloadPeer) { // disconnect the current download peer so a new random one will be selected
            for (size_t i = array_count(manager->peers); i > 0; i--) {
                if (BR_PeerEq(&manager->peers[i - 1], manager->downloadPeer)) array_rm(manager->peers, i - 1);
            }
            
            BR_PeerDisconnect(manager->downloadPeer);
        }

        manager->syncStartHeight = 0; // a syncStartHeight of 0 indicates that syncing hasn't started yet
        pthread_mutex_unlock(&manager->lock);
        BR_PeerManagerConnect(manager);
    }
    else pthread_mutex_unlock(&manager->lock);
}

// the (unverified) best block height reported by connected peers
uint32_t BR_PeerManagerEstimatedBlockHeight(BR_PeerManager *manager)
{
    uint32_t height;
    
    assert(manager != NULL);
    pthread_mutex_lock(&manager->lock);
    height = (manager->lastBlock->height < manager->estimatedHeight) ? manager->estimatedHeight :
             manager->lastBlock->height;
    pthread_mutex_unlock(&manager->lock);
    return height;
}

// current proof-of-work verified best block height
uint32_t BR_PeerManagerLastBlockHeight(BR_PeerManager *manager)
{
    uint32_t height;
    
    assert(manager != NULL);
    pthread_mutex_lock(&manager->lock);
    height = manager->lastBlock->height;
    pthread_mutex_unlock(&manager->lock);
    return height;
}

// current proof-of-work verified best block timestamp (time interval since unix epoch)
uint32_t BR_PeerManagerLastBlockTimestamp(BR_PeerManager *manager)
{
    uint32_t timestamp;
    
    assert(manager != NULL);
    pthread_mutex_lock(&manager->lock);
    timestamp = manager->lastBlock->timestamp;
    pthread_mutex_unlock(&manager->lock);
    return timestamp;
}

// current network sync progress from 0 to 1
// startHeight is the block height of the most recent fully completed sync
double BR_PeerManagerSyncProgress(BR_PeerManager *manager, uint32_t startHeight)
{
    double progress;
    
    assert(manager != NULL);
    pthread_mutex_lock(&manager->lock);
    if (startHeight == 0) startHeight = manager->syncStartHeight;
    
    if (! manager->downloadPeer && manager->syncStartHeight == 0) {
        progress = 0.0;
    }
    else if (! manager->downloadPeer || manager->lastBlock->height < manager->estimatedHeight) {
        if (manager->lastBlock->height > startHeight && manager->estimatedHeight > startHeight) {
            progress = 0.1 + 0.9*(manager->lastBlock->height - startHeight)/(manager->estimatedHeight - startHeight);
        }
        else progress = 0.05;
    }
    else progress = 1.0;

    pthread_mutex_unlock(&manager->lock);
    return progress;
}

// returns the number of currently connected peers
size_t BR_PeerManagerPeerCount(BR_PeerManager *manager)
{
    size_t count = 0;
    
    assert(manager != NULL);
    pthread_mutex_lock(&manager->lock);
    
    for (size_t i = array_count(manager->connectedPeers); i > 0; i--) {
        if (BR_PeerConnectStatus(manager->connectedPeers[i - 1]) == BR_PeerStatusConnected) count++;
    }
    
    pthread_mutex_unlock(&manager->lock);
    return count;
}

// description of the peer most recently used to sync blockchain data
const char *BR_PeerManagerDownloadPeerName(BR_PeerManager *manager)
{
    assert(manager != NULL);
    pthread_mutex_lock(&manager->lock);

    if (manager->downloadPeer) {
        sprintf(manager->downloadPeerName, "%s:%d", BR_PeerHost(manager->downloadPeer), manager->downloadPeer->port);
    }
    else manager->downloadPeerName[0] = '\0';
    
    pthread_mutex_unlock(&manager->lock);
    return manager->downloadPeerName;
}

static void _publishTxInvDone(void *info, int success)
{
    BR_Peer *peer = ((BR_PeerCallbackInfo *)info)->peer;
    BR_PeerManager *manager = ((BR_PeerCallbackInfo *)info)->manager;
    
    free(info);
    pthread_mutex_lock(&manager->lock);
    _BR_PeerManagerRequestUnrelayedTx(manager, peer);
    pthread_mutex_unlock(&manager->lock);
}

// publishes tx to bitcoin network (do not call BR_TransactionFree() on tx afterward)
void BR_PeerManagerPublishTx(BR_PeerManager *manager, BR_Transaction *tx, void *info,
                            void (*callback)(void *info, int error))
{
    assert(manager != NULL);
    assert(tx != NULL && BR_TransactionIsSigned(tx));
    if (tx) pthread_mutex_lock(&manager->lock);
    
    if (tx && ! BR_TransactionIsSigned(tx)) {
        pthread_mutex_unlock(&manager->lock);
        BR_TransactionFree(tx);
        tx = NULL;
        if (callback) callback(info, EINVAL); // transaction not signed
    }
    else if (tx && ! manager->isConnected) {
        int connectFailureCount = manager->connectFailureCount;

        pthread_mutex_unlock(&manager->lock);

        if (connectFailureCount >= MAX_CONNECT_FAILURES ||
            (manager->networkIsReachable && ! manager->networkIsReachable(manager->info))) {
            BR_TransactionFree(tx);
            tx = NULL;
            if (callback) callback(info, ENOTCONN); // not connected to bitcoin network
        }
        else pthread_mutex_lock(&manager->lock);
    }
    
    if (tx) {
        size_t i, count = 0;
        
        tx->timestamp = (uint32_t)time(NULL); // set timestamp to publish time
        _BR_PeerManagerAddTxToPublishList(manager, tx, info, callback);

        for (i = array_count(manager->connectedPeers); i > 0; i--) {
            if (BR_PeerConnectStatus(manager->connectedPeers[i - 1]) == BR_PeerStatusConnected) count++;
        }

        for (i = array_count(manager->connectedPeers); i > 0; i--) {
            BR_Peer *peer = manager->connectedPeers[i - 1];
            BR_PeerCallbackInfo *peerInfo;

            if (BR_PeerConnectStatus(peer) != BR_PeerStatusConnected) continue;
            
            // instead of publishing to all peers, leave out downloadPeer to see if tx propogates/gets relayed back
            // TODO: XXX connect to a random peer with an empty or fake bloom filter just for publishing
            if (peer != manager->downloadPeer || count == 1) {
                _BR_PeerManagerPublishPendingTx(manager, peer);
                peerInfo = calloc(1, sizeof(*peerInfo));
                assert(peerInfo != NULL);
                peerInfo->peer = peer;
                peerInfo->manager = manager;
                BR_PeerSendPing(peer, peerInfo, _publishTxInvDone);
            }
        }

        pthread_mutex_unlock(&manager->lock);
    }
}

// number of connected peers that have relayed the given unconfirmed transaction
size_t BR_PeerManagerRelayCount(BR_PeerManager *manager, UInt256_t txHash)
{
    size_t count = 0;

    assert(manager != NULL);
    assert(! UInt256IsZero(txHash));
    pthread_mutex_lock(&manager->lock);
    
    for (size_t i = array_count(manager->txRelays); i > 0; i--) {
        if (! UInt256Eq(manager->txRelays[i - 1].txHash, txHash)) continue;
        count = array_count(manager->txRelays[i - 1].peers);
        break;
    }
    
    pthread_mutex_unlock(&manager->lock);
    return count;
}

// frees memory allocated for manager
void BR_PeerManagerFree(BR_PeerManager *manager)
{
    assert(manager != NULL);
    pthread_mutex_lock(&manager->lock);
    array_free(manager->peers);
    for (size_t i = array_count(manager->connectedPeers); i > 0; i--) BR_PeerFree(manager->connectedPeers[i - 1]);
    array_free(manager->connectedPeers);
    BR_SetApply(manager->blocks, NULL, _setApplyFreeBlock);
    BR_SetFree(manager->blocks);
    BR_SetApply(manager->orphans, NULL, _setApplyFreeBlock);
    BR_SetFree(manager->orphans);
    BR_SetFree(manager->checkpoints);
    for (size_t i = array_count(manager->txRelays); i > 0; i--) free(manager->txRelays[i - 1].peers);
    array_free(manager->txRelays);
    for (size_t i = array_count(manager->txRequests); i > 0; i--) free(manager->txRequests[i - 1].peers);
    array_free(manager->txRequests);
    array_free(manager->publishedTx);
    array_free(manager->publishedTxHashes);
    pthread_mutex_unlock(&manager->lock);
    pthread_mutex_destroy(&manager->lock);
    free(manager);
}
