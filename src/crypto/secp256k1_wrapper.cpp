// Copyright (c) 2026 - 2X2Coin Project
// Implementação de operações secp256k1 via OpenSSL

#include "secp256k1_wrapper.h"
#include "sha256.h"
#include <openssl/ec.h>
#include <openssl/ecdsa.h>
#include <openssl/bn.h>
#include <openssl/obj_mac.h>
#include <openssl/rand.h>
#include <QDebug>

namespace Coin2x2 {
namespace Crypto {

// Obter grupo secp256k1
static EC_GROUP* getGroup() {
    static EC_GROUP* group = EC_GROUP_new_by_curve_name(NID_secp256k1);
    return group;
}

bool isValidPrivateKey(const QByteArray& privkey) {
    if (privkey.size() != 32) return false;

    BIGNUM* bn = BN_bin2bn(
        reinterpret_cast<const unsigned char*>(privkey.constData()),
        32, nullptr
    );
    if (!bn) return false;

    EC_GROUP* group = getGroup();
    BIGNUM* order = BN_new();
    EC_GROUP_get_order(group, order, nullptr);

    bool valid = !BN_is_zero(bn) && BN_cmp(bn, order) < 0;

    BN_free(bn);
    BN_free(order);
    return valid;
}

QByteArray privateKeyToPublicKey(const QByteArray& privkey, bool compressed) {
    if (!isValidPrivateKey(privkey)) return QByteArray();

    EC_GROUP* group = getGroup();
    EC_KEY* key = EC_KEY_new();
    EC_KEY_set_group(key, group);

    BIGNUM* bn = BN_bin2bn(
        reinterpret_cast<const unsigned char*>(privkey.constData()),
        32, nullptr
    );

    EC_KEY_set_private_key(key, bn);

    // Calcular chave pública
    EC_POINT* pub = EC_POINT_new(group);
    EC_POINT_mul(group, pub, bn, nullptr, nullptr, nullptr);
    EC_KEY_set_public_key(key, pub);

    // Serializar
    point_conversion_form_t form = compressed ?
        POINT_CONVERSION_COMPRESSED : POINT_CONVERSION_UNCOMPRESSED;

    size_t len = EC_POINT_point2oct(group, pub, form, nullptr, 0, nullptr);
    QByteArray result(static_cast<int>(len), 0);
    EC_POINT_point2oct(group, pub, form,
        reinterpret_cast<unsigned char*>(result.data()), len, nullptr);

    EC_POINT_free(pub);
    BN_free(bn);
    EC_KEY_free(key);

    return result;
}

QByteArray publicKeyToAddress(const QByteArray& pubkey, uint8_t prefix) {
    // Hash160 da chave pública
    QByteArray h160 = hash160(pubkey);

    // Adicionar prefixo de versão
    QByteArray payload;
    payload.append(static_cast<char>(prefix));
    payload.append(h160);

    return payload;
}

bool privateKeyAdd(QByteArray& privkey, const QByteArray& tweak) {
    if (privkey.size() != 32 || tweak.size() != 32) return false;

    EC_GROUP* group = getGroup();
    BIGNUM* order = BN_new();
    EC_GROUP_get_order(group, order, nullptr);

    BIGNUM* key = BN_bin2bn(
        reinterpret_cast<const unsigned char*>(privkey.constData()), 32, nullptr);
    BIGNUM* t = BN_bin2bn(
        reinterpret_cast<const unsigned char*>(tweak.constData()), 32, nullptr);

    BN_CTX* ctx = BN_CTX_new();
    BN_mod_add(key, key, t, order, ctx);

    if (BN_is_zero(key)) {
        BN_free(key); BN_free(t); BN_free(order); BN_CTX_free(ctx);
        return false;
    }

    privkey.resize(32);
    BN_bn2binpad(key, reinterpret_cast<unsigned char*>(privkey.data()), 32);

    BN_free(key); BN_free(t); BN_free(order); BN_CTX_free(ctx);
    return true;
}

bool publicKeyAdd(QByteArray& pubkey, const QByteArray& tweak) {
    if (tweak.size() != 32) return false;

    EC_GROUP* group = getGroup();

    // Parsear chave pública existente
    EC_POINT* point = EC_POINT_new(group);
    if (!EC_POINT_oct2point(group, point,
            reinterpret_cast<const unsigned char*>(pubkey.constData()),
            pubkey.size(), nullptr)) {
        EC_POINT_free(point);
        return false;
    }

    // Calcular tweak*G
    BIGNUM* t = BN_bin2bn(
        reinterpret_cast<const unsigned char*>(tweak.constData()), 32, nullptr);
    EC_POINT* tweakPoint = EC_POINT_new(group);
    EC_POINT_mul(group, tweakPoint, t, nullptr, nullptr, nullptr);

    // Somar pontos
    EC_POINT_add(group, point, point, tweakPoint, nullptr);

    if (EC_POINT_is_at_infinity(group, point)) {
        EC_POINT_free(point); EC_POINT_free(tweakPoint); BN_free(t);
        return false;
    }

    // Serializar resultado (comprimido)
    size_t len = EC_POINT_point2oct(group, point,
        POINT_CONVERSION_COMPRESSED, nullptr, 0, nullptr);
    pubkey.resize(static_cast<int>(len));
    EC_POINT_point2oct(group, point, POINT_CONVERSION_COMPRESSED,
        reinterpret_cast<unsigned char*>(pubkey.data()), len, nullptr);

    EC_POINT_free(point); EC_POINT_free(tweakPoint); BN_free(t);
    return true;
}

QByteArray sign(const QByteArray& hash, const QByteArray& privkey) {
    if (hash.size() != 32 || !isValidPrivateKey(privkey)) return QByteArray();

    EC_KEY* key = EC_KEY_new_by_curve_name(NID_secp256k1);
    BIGNUM* bn = BN_bin2bn(
        reinterpret_cast<const unsigned char*>(privkey.constData()), 32, nullptr);
    EC_KEY_set_private_key(key, bn);

    // Calcular chave pública
    const EC_GROUP* group = EC_KEY_get0_group(key);
    EC_POINT* pub = EC_POINT_new(group);
    EC_POINT_mul(group, pub, bn, nullptr, nullptr, nullptr);
    EC_KEY_set_public_key(key, pub);

    ECDSA_SIG* sig = ECDSA_do_sign(
        reinterpret_cast<const unsigned char*>(hash.constData()),
        hash.size(), key
    );

    if (!sig) {
        EC_POINT_free(pub); BN_free(bn); EC_KEY_free(key);
        return QByteArray();
    }

    // Serializar DER
    int len = i2d_ECDSA_SIG(sig, nullptr);
    QByteArray result(len, 0);
    unsigned char* ptr = reinterpret_cast<unsigned char*>(result.data());
    i2d_ECDSA_SIG(sig, &ptr);

    ECDSA_SIG_free(sig);
    EC_POINT_free(pub);
    BN_free(bn);
    EC_KEY_free(key);

    return result;
}

bool verify(const QByteArray& hash, const QByteArray& signature, const QByteArray& pubkey) {
    EC_KEY* key = EC_KEY_new_by_curve_name(NID_secp256k1);
    const EC_GROUP* group = EC_KEY_get0_group(key);

    EC_POINT* point = EC_POINT_new(group);
    if (!EC_POINT_oct2point(group, point,
            reinterpret_cast<const unsigned char*>(pubkey.constData()),
            pubkey.size(), nullptr)) {
        EC_POINT_free(point); EC_KEY_free(key);
        return false;
    }
    EC_KEY_set_public_key(key, point);

    const unsigned char* sigPtr =
        reinterpret_cast<const unsigned char*>(signature.constData());
    ECDSA_SIG* sig = d2i_ECDSA_SIG(nullptr, &sigPtr, signature.size());
    if (!sig) {
        EC_POINT_free(point); EC_KEY_free(key);
        return false;
    }

    int result = ECDSA_do_verify(
        reinterpret_cast<const unsigned char*>(hash.constData()),
        hash.size(), sig, key
    );

    ECDSA_SIG_free(sig);
    EC_POINT_free(point);
    EC_KEY_free(key);

    return result == 1;
}

QByteArray generatePrivateKey() {
    QByteArray privkey(32, 0);

    do {
        RAND_bytes(reinterpret_cast<unsigned char*>(privkey.data()), 32);
    } while (!isValidPrivateKey(privkey));

    return privkey;
}

QByteArray serializePublicKey(const QByteArray& pubkey) {
    return pubkey; // Já está serializado
}

} // namespace Crypto
} // namespace Coin2x2
