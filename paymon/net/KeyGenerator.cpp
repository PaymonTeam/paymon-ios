#include <time.h>
#include <cstdlib>
//#include "../../openssl/openssl/rand.h"
//#include "../../openssl/openssl/sha.h"
//#include "../../openssl/openssl/aes.h"
#include "KeyGenerator.h"
#include <openssl/aes.h>
#include <openssl/rand.h>
#include <openssl/sha.h>

KeyGenerator& KeyGenerator::getInstance() {
    static KeyGenerator instance;
    return instance;
}

KeyGenerator::~KeyGenerator() {

}

SerializedBuffer *KeyGenerator::wrapData(int64_t &messageID, byte *authKey, int64_t &authKeyID, SerializedBuffer* buffer) {
    SerializedBuffer *request = buffer;
    
    CryptoPP::DH dh;
    
    int addr = 0;
    SerializedBuffer *sbuffer;

    if (authKeyID != 0) {
        byte* buffer;
//        addr = aesIGE(messageID, authKey, authKeyID, request, buffer);
        sbuffer = aesIGE(messageID, authKey, authKeyID, request, buffer);
    } else {
        uint32_t messageLength = request->capacity();

        sbuffer = BuffersStorage::getInstance().getFreeBuffer(8 + 8 + 4 + messageLength);
        sbuffer->position(0);
        sbuffer->writeInt64(0);
        sbuffer->writeInt64(messageID);
        sbuffer->writeInt32(messageLength);
        sbuffer->writeBytes(request);
        //buffer->reuse();
//        addr = (int) (&*buffer);
    }

    if (sbuffer != nullptr) {
        return sbuffer;
    } else {
        printf("Error wrapping packet data\n");
        return nullptr;
    }
}

bool KeyGenerator::decryptMessage(int64_t &authKeyID, SerializedBuffer* buffer, uint32_t &length, int32_t &mark) {
    if (sharedKeyBytes == nullptr) {
        return false;
    }
    return decryptAESIGE(sharedKeyBytes->bytes, buffer->bytes() + mark + 8, buffer->bytes() + mark + 24, length);
}

void KeyGenerator::reset() {
    p = 0;
    q = 0;
    g = 0;
    privateKeyA.CleanNew(0);
    privateKeyB.CleanNew(0);
    publicKeyA.CleanNew(0);
    publicKeyB.CleanNew(0);
    sharedKey.CleanNew(0);
}

bool KeyGenerator::generateKeyPair(Integer p, Integer q) {
    dh.AccessGroupParameters().Initialize(p, q);
//    if (!dh.GetGroupParameters().ValidateGroup(rnd, 3)) {
//        perror("Failed to validate prime and generator");
//        return false;
//    }

    p = dh.GetGroupParameters().GetModulus();
    q = dh.GetGroupParameters().GetSubgroupOrder();
    g = dh.GetGroupParameters().GetGenerator();

    Integer v = ModularExponentiation(g, q, p);
    if (v != Integer::One()) {
        perror("Failed to verify order of the subgroup");
        return false;
    }

    privateKeyA = SecByteBlock(dh.PrivateKeyLength());
    publicKeyA = SecByteBlock(dh.PublicKeyLength());

    dh.GenerateKeyPair(rnd, privateKeyA, publicKeyA);

    return true;
}

bool KeyGenerator::generateShared(SecByteBlock publicKeyB) {
    sharedKey = SecByteBlock(dh.AgreedValueLength());
    this->publicKeyB = publicKeyB;
    sharedKeyBytes = std::unique_ptr<ByteArray>(new ByteArray(128));
    bool b = dh.Agree(sharedKey, privateKeyA, publicKeyB);
    if (b) {
        memcpy(sharedKeyBytes->bytes, sharedKey.begin(), 128);
    }
    return b;
}

inline void KeyGenerator::generateMessageKey(uint8_t *authKey, uint8_t *messageKey, uint8_t *result, bool incoming) {
    uint32_t x = incoming ? 8 : 0;

    static uint8_t sha[68];

    memcpy(sha + 20, messageKey, 16);
    memcpy(sha + 20 + 16, authKey + x, 32);
    SHA1(sha + 20, 48, sha);
    memcpy(result, sha, 8);
    memcpy(result + 32, sha + 8, 12);

    memcpy(sha + 20, authKey + 32 + x, 16);
    memcpy(sha + 20 + 16, messageKey, 16);
    memcpy(sha + 20 + 16 + 16, authKey + 48 + x, 16);
    SHA1(sha + 20, 48, sha);
    memcpy(result + 8, sha + 8, 12);
    memcpy(result + 32 + 12, sha, 8);

    memcpy(sha + 20, authKey + 64 + x, 32);
    memcpy(sha + 20 + 32, messageKey, 16);
    SHA1(sha + 20, 48, sha);
    memcpy(result + 8 + 12, sha + 4, 12);
    memcpy(result + 32 + 12 + 8, sha + 16, 4);

    memcpy(sha + 20, messageKey, 16);
    memcpy(sha + 20 + 16, authKey + 96 + x, 32);
    SHA1(sha + 20, 48, sha);
    memcpy(result + 32 + 12 + 8 + 4, sha, 8);
}

void KeyGenerator::aesIgeEncryption(uint8_t *buffer, uint8_t *key, uint8_t *iv, bool encrypt, bool changeIv, uint32_t length) {
    uint8_t *ivBytes = iv;
//    uint8_t *lol = iv;
    if (!changeIv) {
        ivBytes = new uint8_t[32];
        memcpy(ivBytes, iv, 32);
    }
    AES_KEY akey;
    if (!encrypt) {
        AES_set_decrypt_key(key, 32 * 8, &akey);
        AES_ige_encrypt(buffer, buffer, length, &akey, ivBytes, AES_DECRYPT);
    } else {
        AES_set_encrypt_key(key, 32 * 8, &akey);
        AES_ige_encrypt(buffer, buffer, length, &akey, ivBytes, AES_ENCRYPT);
    }
    if (!changeIv) {
        delete [] ivBytes;
    }
}


SerializedBuffer *KeyGenerator::aesIGE(int64_t messageID, uint8_t* authKey, int64_t authKeyID, SerializedBuffer *sb, byte *&buff) {
    uint32_t messageSize = sb->capacity();//(int) msg.size();
    uint32_t additionalSize = (12 + messageSize) % 16;
    if (additionalSize != 0) {
        additionalSize = 16 - additionalSize;
    }

    SerializedBuffer *buffer = BuffersStorage::getInstance().getFreeBuffer(24 + 12 + messageSize + additionalSize);
    buffer->writeInt64(authKeyID);
    buffer->position(24);
    buffer->writeInt64(messageID);
    buffer->writeInt32(messageSize);
    buffer->writeBytes(sb);

    if (additionalSize != 0) {
        RAND_bytes(buffer->bytes() + 24 + 12 + messageSize, additionalSize);
    }

    static uint8_t messageKey[84];

    SHA1(buffer->bytes() + 24, 12 + messageSize, messageKey);
    memcpy(buffer->bytes() + 8, messageKey + 4, 16);
    generateMessageKey(authKey, messageKey + 4, messageKey + 20, false);
    aesIgeEncryption(buffer->bytes() + 24, messageKey + 20, messageKey + 52, true, false, buffer->limit() - 24);//4 + messageSize + additionalSize);

//    buff = buffer->bytes();
//    int addr = (int) (&*buffer);
//    return addr;
    return buffer;
}

bool KeyGenerator::decryptAESIGE(uint8_t *authKey, uint8_t *key, uint8_t *data, uint32_t length) {
    if (length % 16 != 0) {
        printf("length %% 16 != 0\n");
        return false;
    }
    static uint8_t messageKey[84];
    generateMessageKey(authKey, key, messageKey + 20, false);
    aesIgeEncryption(data, messageKey + 20, messageKey + 52, false, false, length);

    uint32_t messageLength;
    memcpy(&messageLength, data + 8, sizeof(uint32_t));
    if (messageLength > length - 12) {
        printf("messageLength > length - 12 <> %u > %u - 12\n", messageLength, length);
        return false;
    }
    messageLength += 12;
    if (messageLength > length) {
        messageLength = length;
    }

    SHA1(data, messageLength, messageKey);
    return memcmp(messageKey + 4, key, 16) == 0;
}

const SecByteBlock &KeyGenerator::getPublicKeyA() {

    return publicKeyA;
}

const SecByteBlock &KeyGenerator::getPrivateKeyA() {
    return privateKeyA;
}

const SecByteBlock &KeyGenerator::getPublicKeyB() {
    return publicKeyB;
}

const SecByteBlock &KeyGenerator::getPrivateKeyB() {
    return privateKeyB;
}

const SecByteBlock &KeyGenerator::getSharedKey() {
    return sharedKey;
}
