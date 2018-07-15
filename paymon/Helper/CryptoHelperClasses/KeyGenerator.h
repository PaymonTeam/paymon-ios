//
// Created by negi on 18.05.17.
//

#ifndef PAYMON_KEYGENERATOR_H
#define PAYMON_KEYGENERATOR_H

#include <sys/types.h>
#include "SerializedBuffer.h"
#include "Defines.h"

#include "cryptopp/cryptlib.h"
#include "cryptopp/hex.h"

#include <stdexcept>
#include "cryptopp/osrng.h"
#include "cryptopp/integer.h"
#include "cryptopp/nbtheory.h"
#include "cryptopp/dh.h"
#include "cryptopp/secblock.h"
#include <cryptopp/filters.h>

extern SerializedBuffer* restOfTheData;
extern uint lastPacketLength;

using CryptoPP::AutoSeededRandomPool;
using CryptoPP::PublicKey;
using CryptoPP::HashFilter;
using CryptoPP::HexEncoder;
using CryptoPP::ModularExponentiation;
using CryptoPP::SecByteBlock;
using CryptoPP::StringSink;
using CryptoPP::Integer;

struct KeyGenerator {
public:
    static KeyGenerator &getInstance();

    ~KeyGenerator();

    SerializedBuffer *wrapData(int64_t &messageID, byte *authKey, int64_t &authKeyID, SerializedBuffer* buffer);
    bool decryptMessage(int64_t &authKeyID, SerializedBuffer* buffer, uint32_t &length, int32_t &mark);
    void reset();
    bool generateKeyPair(Integer p, Integer q);
    bool generateShared(SecByteBlock publicKeyB);

    const SecByteBlock &getPublicKeyA();
    const SecByteBlock &getPrivateKeyA();
    const SecByteBlock &getPublicKeyB();
    const SecByteBlock &getPrivateKeyB();
    const SecByteBlock &getSharedKey();
    const Integer &getP() const;
    const Integer &getG() const;
    const Integer &getQ() const;
private:
    Integer p;
    Integer g;
    Integer q;

    inline void
    generateMessageKey(uint8_t *authKey, uint8_t *messageKey, uint8_t *result, bool incoming);

    SerializedBuffer *aesIGE(int64_t messageID, uint8_t *authKey, int64_t authKeyID, SerializedBuffer *sb, byte *&buff);

    void aesIgeEncryption(uint8_t *buffer, uint8_t *key, uint8_t *iv, bool encrypt, bool changeIv,
                          uint32_t length);

    bool decryptAESIGE(uint8_t *authKey, uint8_t *key, uint8_t *data, uint32_t length);

    CryptoPP::DH dh;
    AutoSeededRandomPool rnd;
    SecByteBlock publicKeyA, privateKeyA, publicKeyB, privateKeyB, sharedKey;
    std::unique_ptr<ByteArray> sharedKeyBytes;
};
#endif //PAYMON_KEYGENERATOR_H
