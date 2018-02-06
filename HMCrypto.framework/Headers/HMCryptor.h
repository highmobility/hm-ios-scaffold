//
//  HMCrypto.h
//  Crypto
//
//  Created by tõnis on 03/03/15.
//  Copyright (c) 2015 High-Mobility. All rights reserved.
//
//  All Crypto data is in raw big-endian bytes. Signature consists of r and s bytes, public key x and y bytes.
//

@import Foundation;

@class HMKeyPair;

@interface HMCryptor: NSObject

NS_ASSUME_NONNULL_BEGIN

/// ECDSA

+ (HMKeyPair *)generateKeyPair;
+ (HMKeyPair *)generateKeyPairFromPrivateKey:(NSData *)privateKey;
+ (NSData *)sharedKeyForPrivateKey:(NSData *)privateKey otherPublicKey:(NSData *)publicKey;

+ (NSData *)signatureForData:(NSData *)data privateKey:(NSData *)privateKey;
+ (BOOL)verifySignature:(NSData *)signature forData:(NSData *)data publicKey:(NSData *)publicKey;

/// AES CTR

/// Creates an IV with original nonce and the incremented nonce.
/// 7 bytes from original nonce and 9 bytes from transaction noce are used.
+ (NSData *)IVWithNonce:(NSData *)nonce transactionNonce:(NSData *)transactionNonce;

/// Encrypt/Decrypt data with AES CTR.
/// key and the IV have to be 16 bytes
+ (NSData *)encryptDecrypt:(NSData *)data key:(NSData *)key IV:(NSData *)IV;

/// Helpers
+ (NSData *)HMACForData:(NSData *)data key:(NSData *)key;
+ (BOOL)verifyHMAC:(NSData *)hmac forData:(NSData *)data key:(NSData *)key;


+ (NSData *)sha256ForData:(NSData *)data;

// helpers
+ (NSData *)DEREncodedSignatureForRawSignature:(NSData *)data;

NS_ASSUME_NONNULL_END

@end

@interface HMKeyPair: NSObject

NS_ASSUME_NONNULL_BEGIN

- (instancetype)initWithPrivateKey:(NSData *)privateKey publicKey:(NSData *)publicKey;

@property (nonatomic, readonly) NSData *publicKey;
@property (nonatomic, readonly) NSData *DERPublicKey;

@property (nonatomic, readonly) NSData *privateKey;

NS_ASSUME_NONNULL_END

@end
