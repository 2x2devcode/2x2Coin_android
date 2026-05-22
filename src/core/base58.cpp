// Copyright (c) 2026 - 2X2Coin Project
// Distributed under the MIT software license
//
// Implementação de Base58Check para endereços 2X2Coin

#include "base58.h"
#include <QCryptographicHash>
#include <QVector>
#include <algorithm>

namespace Coin2x2 {

const QString Base58::BASE58_CHARS =
    "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";

QByteArray Base58::sha256d(const QByteArray& data) {
    QByteArray first  = QCryptographicHash::hash(data, QCryptographicHash::Sha256);
    QByteArray second = QCryptographicHash::hash(first, QCryptographicHash::Sha256);
    return second;
}

QString Base58::encode(const QByteArray& data) {
    // Contar zeros à esquerda
    int leadingZeros = 0;
    for (int i = 0; i < data.size() && (unsigned char)data[i] == 0; ++i) {
        ++leadingZeros;
    }

    // Converter para big integer e dividir por 58
    QVector<uint8_t> digits;
    for (int i = 0; i < data.size(); ++i) {
        int carry = (unsigned char)data[i];
        for (int j = 0; j < digits.size(); ++j) {
            carry += 256 * digits[j];
            digits[j] = carry % 58;
            carry /= 58;
        }
        while (carry > 0) {
            digits.push_back(carry % 58);
            carry /= 58;
        }
    }

    // Construir string resultado
    QString result;
    // Adicionar '1' para cada zero à esquerda
    for (int i = 0; i < leadingZeros; ++i) {
        result += '1';
    }
    // Adicionar dígitos em ordem reversa
    for (int i = digits.size() - 1; i >= 0; --i) {
        result += BASE58_CHARS[digits[i]];
    }

    return result;
}

bool Base58::decode(const QString& str, QByteArray& out) {
    // Contar '1's à esquerda (zeros)
    int leadingOnes = 0;
    for (int i = 0; i < str.size() && str[i] == '1'; ++i) {
        ++leadingOnes;
    }

    // Decodificar cada caractere
    QVector<uint8_t> bytes;
    for (int i = 0; i < str.size(); ++i) {
        int digit = BASE58_CHARS.indexOf(str[i]);
        if (digit < 0) return false;

        int carry = digit;
        for (int j = 0; j < bytes.size(); ++j) {
            carry += 58 * bytes[j];
            bytes[j] = carry % 256;
            carry /= 256;
        }
        while (carry > 0) {
            bytes.push_back(carry % 256);
            carry /= 256;
        }
    }

    // Construir resultado
    out.clear();
    for (int i = 0; i < leadingOnes; ++i) {
        out.append('\0');
    }
    for (int i = bytes.size() - 1; i >= 0; --i) {
        out.append((char)bytes[i]);
    }

    return true;
}

QString Base58::encodeCheck(const QByteArray& data) {
    QByteArray checksum = sha256d(data).left(4);
    QByteArray payload = data + checksum;
    return encode(payload);
}

bool Base58::decodeCheck(const QString& str, QByteArray& out) {
    QByteArray decoded;
    if (!decode(str, decoded)) return false;
    if (decoded.size() < 4) return false;

    QByteArray payload  = decoded.left(decoded.size() - 4);
    QByteArray checksum = decoded.right(4);
    QByteArray expected = sha256d(payload).left(4);

    if (checksum != expected) return false;

    out = payload;
    return true;
}

QString Base58::pubkeyHashToAddress(const QByteArray& hash160, uint8_t prefix) {
    QByteArray payload;
    payload.append((char)prefix);
    payload.append(hash160);
    return encodeCheck(payload);
}

QString Base58::scriptHashToAddress(const QByteArray& hash160, uint8_t prefix) {
    QByteArray payload;
    payload.append((char)prefix);
    payload.append(hash160);
    return encodeCheck(payload);
}

QString Base58::privateKeyToWIF(const QByteArray& privkey, bool compressed, uint8_t prefix) {
    QByteArray payload;
    payload.append((char)prefix);
    payload.append(privkey);
    if (compressed) {
        payload.append('\x01');
    }
    return encodeCheck(payload);
}

bool Base58::wifToPrivateKey(const QString& wif, QByteArray& privkey,
                              bool& compressed, uint8_t prefix) {
    QByteArray decoded;
    if (!decodeCheck(wif, decoded)) return false;
    if (decoded.size() < 33) return false;
    if ((unsigned char)decoded[0] != prefix) return false;

    if (decoded.size() == 34 && decoded[33] == '\x01') {
        compressed = true;
        privkey = decoded.mid(1, 32);
    } else if (decoded.size() == 33) {
        compressed = false;
        privkey = decoded.mid(1, 32);
    } else {
        return false;
    }

    return true;
}

bool Base58::isValidAddress(const QString& address, uint8_t prefix) {
    QByteArray decoded;
    if (!decodeCheck(address, decoded)) return false;
    if (decoded.size() != 21) return false;
    if ((unsigned char)decoded[0] != prefix) return false;
    return true;
}

} // namespace Coin2x2
