//
//  LCSSLChallenger.m
//  AVOS
//
//  Created by Tang Tianyong on 6/30/15.
//  Copyright (c) 2015 LeanCloud Inc. All rights reserved.
//

#import "LCSSLChallenger.h"
#import "AVHelpers.h"
#import "AVUtils.h"
#import <Security/Security.h>
#import <AssertMacros.h>

#define LC_ROOT_DOMAIN @"leancloud.cn"

#define LC_HTTPS_CERT @"MIIFDzCCA/egAwIBAgIQECg10GmSYWMKtzx/By5NMTANBgkqhkiG9w0BAQsFADBEMQswCQYDVQQGEwJVUzEWMBQGA1UEChMNR2VvVHJ1c3QgSW5jLjEdMBsGA1UEAxMUR2VvVHJ1c3QgU1NMIENBIC0gRzMwHhcNMTQxMTI4MDAwMDAwWhcNMTYwOTI0MjM1OTU5WjCBjDELMAkGA1UEBhMCQ04xEDAOBgNVBAgTB0JlaWppbmcxEDAOBgNVBAcUB0JlaWppbmcxMjAwBgNVBAoUKU1laSBXZWkgU2h1IFFpYW4gKCBCZWlqaW5nICkgSVQgQ28uLCBMdGQuMQwwCgYDVQQLFANPUFMxFzAVBgNVBAMUDioubGVhbmNsb3VkLmNuMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAzHX5I4zHZcHerO3x0l5pScvqKE8MlK/6hzrDONDsBuMnfkAPRpkPPGB6HfaAAGjyStsi5hZrPgOA3r+6lActiapjnRnfTSo57tJyF/5XexLOdzU45fhNO41mJYiSlGAK0L+EUQSlnSClxixPDIwkkpbF8XYrrpPnZeSCzm62Jk38Lx6GUheZH3UzmC5JPmcqBgmAidmi36wFk7UWT2c6fmmDA+DWJBxdt5+/MhLG7OcFEP0YeiSDXwirnSlQphMswIn1d+XprX/BHqnvlQgnTPZeIrYraVmTlA2qjOWZLKlZExhLaSnOqT/XLQN9q0fAHrKswhrBAzOycvvbt/9HswIDAQABo4IBsjCCAa4wJwYDVR0RBCAwHoIOKi5sZWFuY2xvdWQuY26CDGxlYW5jbG91ZC5jbjAJBgNVHRMEAjAAMA4GA1UdDwEB/wQEAwIFoDArBgNVHR8EJDAiMCCgHqAchhpodHRwOi8vZ24uc3ltY2IuY29tL2duLmNybDCBoQYDVR0gBIGZMIGWMIGTBgpghkgBhvhFAQc2MIGEMD8GCCsGAQUFBwIBFjNodHRwczovL3d3dy5nZW90cnVzdC5jb20vcmVzb3VyY2VzL3JlcG9zaXRvcnkvbGVnYWwwQQYIKwYBBQUHAgIwNQwzaHR0cHM6Ly93d3cuZ2VvdHJ1c3QuY29tL3Jlc291cmNlcy9yZXBvc2l0b3J5L2xlZ2FsMB0GA1UdJQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjAfBgNVHSMEGDAWgBTSb/eW9IU/cjwwfSPahXibo3xafDBXBggrBgEFBQcBAQRLMEkwHwYIKwYBBQUHMAGGE2h0dHA6Ly9nbi5zeW1jZC5jb20wJgYIKwYBBQUHMAKGGmh0dHA6Ly9nbi5zeW1jYi5jb20vZ24uY3J0MA0GCSqGSIb3DQEBCwUAA4IBAQDdrrEg1t+LtyE5Roy5dhe7yM0tb5pcy+hEP1ZXncwv4SMldTWPejuomwF5vt2lX0FEhzrd1k9Ndk5LJq5x5SrCHos1kTO/MxkRvg7eUkErOYM0AK3j3I37xZv/rRN4UOJVKh1i4e88hgrAXhxLLQn96d8zzMJbpRYiBz3cW6I8w+bR5BtwVpgzJU5Z3gLDDJLVqwSDUjNpFrlmBor0kh7izPc5WAg5xkZ5ovQgp5Mwc1l9FByIqNZvY/pfGZBkEzeSP73rfccWg3Y7vz+mORgHDpSxAqmyna2hXn8aiEl3FW1v0w1PgJAskNmxt8zNAg38Jpuv7I1sDNjX/tyC1je0"

static id publicKeyForCertificate(NSData *certificate) {
    id allowedPublicKey = nil;
    SecCertificateRef allowedCertificate;
    SecCertificateRef allowedCertificates[1];
    CFArrayRef tempCertificates = nil;
    SecPolicyRef policy = nil;
    SecTrustRef allowedTrust = nil;
    SecTrustResultType result;

    allowedCertificate = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)certificate);
    __Require_Quiet(allowedCertificate != NULL, _out);

    allowedCertificates[0] = allowedCertificate;
    tempCertificates = CFArrayCreate(NULL, (const void **)allowedCertificates, 1, NULL);

    policy = SecPolicyCreateBasicX509();
    __Require_noErr_Quiet(SecTrustCreateWithCertificates(tempCertificates, policy, &allowedTrust), _out);
    __Require_noErr_Quiet(SecTrustEvaluate(allowedTrust, &result), _out);

    allowedPublicKey = (__bridge_transfer id)SecTrustCopyPublicKey(allowedTrust);

_out:
    if (allowedTrust) {
        CFRelease(allowedTrust);
    }

    if (policy) {
        CFRelease(policy);
    }

    if (tempCertificates) {
        CFRelease(tempCertificates);
    }

    if (allowedCertificate) {
        CFRelease(allowedCertificate);
    }
    
    return allowedPublicKey;
}

static NSArray * publicKeysForServerTrust(SecTrustRef serverTrust) {
    SecPolicyRef policy = SecPolicyCreateBasicX509();
    CFIndex certificateCount = SecTrustGetCertificateCount(serverTrust);
    NSMutableArray *trustChain = [NSMutableArray arrayWithCapacity:(NSUInteger)certificateCount];
    for (CFIndex i = 0; i < certificateCount; i++) {
        SecCertificateRef certificate = SecTrustGetCertificateAtIndex(serverTrust, i);

        SecCertificateRef someCertificates[] = {certificate};
        CFArrayRef certificates = CFArrayCreate(NULL, (const void **)someCertificates, 1, NULL);

        SecTrustRef trust;
        __Require_noErr_Quiet(SecTrustCreateWithCertificates(certificates, policy, &trust), _out);

        SecTrustResultType result;
        __Require_noErr_Quiet(SecTrustEvaluate(trust, &result), _out);

        [trustChain addObject:(__bridge_transfer id)SecTrustCopyPublicKey(trust)];

    _out:
        if (trust) {
            CFRelease(trust);
        }

        if (certificates) {
            CFRelease(certificates);
        }

        continue;
    }
    CFRelease(policy);
    
    return [NSArray arrayWithArray:trustChain];
}

#if !TARGET_OS_IOS && !TARGET_OS_WATCH && !TARGET_OS_TV
static NSData * LCSecKeyGetData(SecKeyRef key) {
    CFDataRef data = NULL;

    __Require_noErr_Quiet(SecItemExport(key, kSecFormatUnknown, kSecItemPemArmour, NULL, &data), _out);

    return (__bridge_transfer NSData *)data;

_out:
    if (data) {
        CFRelease(data);
    }

    return nil;
}
#endif

static BOOL LCSecKeyIsEqualToKey(SecKeyRef key1, SecKeyRef key2) {
#if TARGET_OS_IOS || TARGET_OS_WATCH || TARGET_OS_TV
    return [(__bridge id)key1 isEqual:(__bridge id)key2];
#else
    return [LCSecKeyGetData(key1) isEqual:LCSecKeyGetData(key2)];
#endif
}

@implementation LCSSLChallenger

+ (instancetype)sharedInstance {
    static LCSSLChallenger *instance = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        instance = [[LCSSLChallenger alloc] init];
    });

    return instance;
}

- (NSArray *)pinnedPublicKeys {
    NSData *certData = [NSData AVdataFromBase64String:LC_HTTPS_CERT];
    id publicKey = publicKeyForCertificate(certData);
    return @[publicKey];
}

- (BOOL)shouldTrustServerTrust:(SecTrustRef)serverTrust {
    NSArray *publicKeys = publicKeysForServerTrust(serverTrust);

    for (id publicKey in publicKeys) {
        for (id pinnedPublicKey in self.pinnedPublicKeys) {
            if (LCSecKeyIsEqualToKey((__bridge SecKeyRef)publicKey, (__bridge SecKeyRef)pinnedPublicKey)) {
                return YES;
            }
        }
    }

    return NO;
}

- (void)acceptChallenge:(NSURLAuthenticationChallenge *)challenge {
    NSString *host = challenge.protectionSpace.host;

    if ([host hasSuffix:LC_ROOT_DOMAIN]) {
        if ([self shouldTrustServerTrust:challenge.protectionSpace.serverTrust]) {
            NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
            [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
        } else {
            AVLoggerError(AVLoggerDomainNetwork, @"Request is rejected because SSL validation did fail.");
            [[challenge sender] cancelAuthenticationChallenge:challenge];
        }
    }
}

@end
