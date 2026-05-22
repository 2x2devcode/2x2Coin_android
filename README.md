# 2X2Coin Android Qt Wallet

Professional Android wallet for the 2X2Coin cryptocurrency, built with Qt 6 and QML.

## Features

- **HD Wallet**: BIP32/BIP44/BIP39 support for secure key management.
- **Modern UI**: Fluid Material Design interface with Dark Theme support.
- **Security**: AES-256 encryption for wallet data and Biometric unlock support.
- **Network**: Direct P2P/RPC communication with the 2X2Coin network.
- **Staking**: Support for Proof-of-Stake (PoS) monitoring.

## Prerequisites for Building (Ubuntu 22.04)

The included `build_android.sh` script will automatically attempt to install these dependencies:

- **Qt 6.5.3+** (with Android support)
- **Android SDK & NDK** (API 34, NDK 25)
- **OpenJDK 17**
- **OpenSSL for Android** (automatically downloaded by the script)

## How to Build

1. **Configure Environment**:
   Ensure you have the Qt and Android SDK paths correctly set in your environment or edit the `build_android.sh` script.

2. **Run Build Script**:
   ```bash
   chmod +x build_android.sh
   ./build_android.sh
   ```

3. **Output**:
   The generated APK will be located at the root directory as `2x2coin-wallet-release.apk`.

## Project Structure

- `src/`: C++ Backend (Core, Crypto, Wallet, Network)
- `qml/`: QML Frontend (Pages, Components, Themes)
- `android/`: Android-specific configuration (Manifest, Gradle)
- `assets/`: Icons, Images, and Fonts

## License

Based on the 2X2Coin source code: [https://github.com/coinsdevcode/2x2Coin](https://github.com/coinsdevcode/2x2Coin)
