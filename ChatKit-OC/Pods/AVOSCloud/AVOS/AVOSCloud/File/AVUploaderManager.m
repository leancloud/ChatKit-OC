//
//  AVUploaderManager.m
//  IconMan
//
//  Created by Zhu Zeng on 3/16/13.
//  Copyright (c) 2013 AVOS. All rights reserved.
//

#import "AVUploaderManager.h"
#import "AVErrorUtils.h"
#import "AVNetworking.h"
#import "AVUtils.h"
#import "AVFile_Internal.h"
#import "AVPaasClient.h"
#import "AVFileHTTPRequestOperation.h"
#import "AVPartialInputStream.h"
#import "AVObjectUtils.h"

static NSString * const QiniuServerPath = @"https://up.qbox.me";
static NSString * const QCloudServerPath = @"https://web.file.myqcloud.com";
static NSString * const QCloudHOST = @"web.file.myqcloud.com";
static NSString * const S3BasePath = @"https://s3.amazonaws.com/avos-cloud";
static uint64_t const QCloudSliceSize = 512 * 1024;

@implementation AVHTTPClient (CancelMethods)
- (void)cancelOperationsLocalPath:(NSString *)path {
    for (NSOperation *operation in [self.operationQueue operations]) {
        if (![operation isKindOfClass:[AVFileHTTPRequestOperation class]]) {
            continue;
        }
        
        if ([[(AVFileHTTPRequestOperation *)operation localPath] isEqualToString:path]) {
            [operation cancel];
        }
    }
}
@end

@interface AVUploaderManager ()
@property (nonatomic, strong) AVHTTPClient *httpClient;
@end

@implementation AVUploaderManager

+(AVUploaderManager *)sharedInstance
{
    static dispatch_once_t once;
    static AVUploaderManager * instance;
    dispatch_once(&once, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (AVHTTPClient *)httpClient {
    if (!_httpClient) {
        switch (self.storageType) {
            case AVStorageTypeQiniu:
            {
                NSURL *url = [NSURL URLWithString:QiniuServerPath];
                _httpClient = [[AVHTTPClient alloc] initWithBaseURL:url];
            }
                break;
            case AVStorageTypeParse:
                _httpClient = [AVPaasClient sharedInstance].clientImpl;
                break;
            case AVStorageTypeS3:
                _httpClient = [[AVHTTPClient alloc] init];
                break;
            case AVStorageTypeQCloud: {
                NSURL *url = [NSURL URLWithString:QCloudServerPath];
                _httpClient = [[AVHTTPClient alloc] initWithBaseURL:url];
            }
                break;
            default:
                NSAssert(NO, @"storage type error");
                break;
        }
    }
    return _httpClient;
}

- (void)setStorageType:(AVStorageType)storageType {
    if (_storageType != storageType) {
        _storageType = storageType;
        
        self.httpClient = nil;
    }
}

#pragma mark - AVFile POST Parameters

- (NSDictionary *)parametersForFile:(AVFile *)file {
    NSString *uuid = [AVUtils generateCompactUUID];
    NSString *extension = [file.pathExtension stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    NSString *key  = [extension length] > 0 ? [uuid stringByAppendingPathExtension:extension] : uuid;
    NSString *name = [file.name length] > 0 ? file.name : uuid;
    NSString *mimeType = [file mimeType];
    NSDictionary *metaData = [file updateMetaData] ?: @{};

    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:@{
        @"key": key,
        @"name": name,
        @"mime_type": mimeType,
        @"metaData": metaData,
        @"__type": [AVFile className]
    }];

    [file addACLToDict:parameters];

    return [parameters copy];
}

-(void)cancelWithLocalPath:(NSString *)path
{
    [self.httpClient cancelOperationsLocalPath:path];
}

- (void)uploadWithAVFile:(AVFile *)file progressBlock:(AVProgressBlock)progressBlock resultBlock:(AVBooleanResultBlock)resultBlock {
    NSDictionary *parameters = [self parametersForFile:file];
    [[AVPaasClient sharedInstance] postObject:@"fileTokens" withParameters:parameters block:^(id object, NSError *error) {
        id bucket = [object valueForKey:@"bucket"];
        if (error || !bucket || (bucket == [NSNull null])) {
            [AVUtils callBooleanResultBlock:resultBlock error:[NSError errorWithDomain:@"AVOSUploadFileDomain" code:0 userInfo:@{@"reason":[NSString stringWithFormat:@"file upload failed."]}]];
            return;
        }
        NSString *provider = [object valueForKey:@"provider"];
        if ([provider isEqualToString:@"qcloud"]) {
            self.storageType = AVStorageTypeQCloud;
            [self uploadToQCloudWithAVFile:file fileTokensInfo:object progressBlock:progressBlock resultBlock:resultBlock];
        } else if ([provider isEqualToString:@"qiniu"]) {
            self.storageType = AVStorageTypeQiniu;
            [self uploadToQiniuWithAVFile:file fileTokensInfo:object progressBlock:progressBlock resultBlock:resultBlock];
        } else if ([provider isEqualToString:@"s3"]) {
            self.storageType = AVStorageTypeS3;
            [self uploadToS3WithAVFile:file fileTokensInfo:object progressBlock:progressBlock resultBlock:resultBlock];
        }
    }];
}

#pragma mark - Upload to LeanCloud

- (void)uploadToLeanCloudWithAVFile:(AVFile *)file progressBlock:(AVProgressBlock)progressBlock resultBlock:(AVBooleanResultBlock)resultBlock {
    if (!file.data) file.data = [NSData dataWithContentsOfFile:file.localPath];
    NSData *uploadData = file.data;
    
    NSString *path = [@"files/" stringByAppendingString:file.name];
    NSMutableURLRequest *request = [self.httpClient requestWithMethod:@"POST" path:path parameters:nil];
    [request setHTTPBody:uploadData];
    
    AVFileHTTPRequestOperation *operation = [[AVFileHTTPRequestOperation alloc] initWithRequest:request];
    operation.localPath = file.localPath;
    [operation setUploadProgressBlock:^(AVURLConnectionOperation *operation, NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        float progress = totalBytesWritten / (float)totalBytesExpectedToWrite;
        [AVUtils callProgressBlock:progressBlock percent:progress * 100];
    }];
    
    [operation setCompletionBlockWithSuccess:^(AVHTTPRequestOperation *operation, id responseObject) {
        if (![operation isCancelled]) {
            NSError *error = [AVErrorUtils errorFromJSON:responseObject];
            if (!error) {
                file.url = [responseObject objectForKey:@"url"];
                file.name = [responseObject objectForKey:@"name"];
                
                [AVFile cacheFile:file];
                // NSLog(@"remote file link:%@", file.url);
            }
            
            [AVUtils callBooleanResultBlock:resultBlock error:error];
        };
    } failure:^(AVHTTPRequestOperation *operation, NSError *error) {
        [AVUtils callBooleanResultBlock:resultBlock error:error];
    }];
    
    [self.httpClient enqueueHTTPRequestOperation:operation];
}

#pragma mark - Upload to S3

- (void)uploadToS3WithAVFile:(AVFile *)file
              fileTokensInfo:(NSDictionary *)fileTokensInfo
               progressBlock:(AVProgressBlock)progressBlock
                 resultBlock:(AVBooleanResultBlock)resultBlock
{
    NSString *objectId = [fileTokensInfo valueForKey:@"objectId"];
    NSString *originUrl = [fileTokensInfo valueForKey:@"url"];
    NSString *uploadURLString = [fileTokensInfo valueForKey:@"upload_url"];
    
    [AVUtils copyPropertiesFromDictionary:fileTokensInfo toNSObject:file];
    // make sure file.data is not nil
    if (!file.data)
        file.data = [NSData dataWithContentsOfFile:file.localPath];
    // s3client only support upload from path
    if (![[NSFileManager defaultManager] fileExistsAtPath:file.localPath]) {
        [file.data writeToFile:file.localPath atomically:YES];
    }
    
    void (^uploadResultBlock)(BOOL succeeded, NSError *error) = ^(BOOL succeeded, NSError *error) {
        if (!error) {
            file.url = originUrl;
            file.objectId = objectId;
            if (file.name.length <= 0) {
                file.name = objectId;
            }
            
            [AVFile cacheFile:file];
        } else {
            [file deleteInBackground];
        }
        [AVUtils callBooleanResultBlock:resultBlock error:error];
    };

    NSURL *url = [NSURL URLWithString:uploadURLString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

    [request setValue:USER_AGENT    forHTTPHeaderField:@"User-Agent"];
    [request setValue:file.mimeType forHTTPHeaderField:@"Content-Type"];

    request.HTTPMethod = @"PUT";
    request.HTTPBody = file.data;

    self.httpClient = [[AVHTTPClient alloc] initWithBaseURL:url];
    [self uploadFile:file request:request progressBlock:progressBlock resultBlock:uploadResultBlock];
}

#pragma mark - Upload to Qiniu

- (void)uploadToQiniuWithAVFile:(AVFile *)file fileTokensInfo:(NSDictionary *)object progressBlock:(AVProgressBlock)progressBlock resultBlock:(AVBooleanResultBlock)resultBlock {
    NSString *token = [object valueForKey:@"token"];
    NSString *bucket = [object valueForKey:@"bucket"];
    NSString *objectId = [object valueForKey:@"objectId"];
    NSString *uploadURLString = [object valueForKey:@"url"];
    
    [AVUtils copyPropertiesFromDictionary:object toNSObject:file];
    
    const uint64_t maxSize = 1 << 22;
    void (^uploadResultBlock)(BOOL succeeded, NSError *error) = ^(BOOL succeeded, NSError *error) {
        if (!error) {
            file.url = uploadURLString;
            file.objectId = objectId;
            if (file.name.length <= 0) {
                file.name = objectId;
            }
            [AVFile cacheFile:file];
        }
        
        [AVUtils callBooleanResultBlock:resultBlock error:error];
    };
    NSString *boundaryFrontier = [uploadURLString lastPathComponent];
    NSString *key = boundaryFrontier;
    if (file.size > maxSize) {
        [self uploadLargeFileToQiNiuWithToken:token file:file key:key progressBlock:progressBlock resultBlock:uploadResultBlock];
    } else {
        [self uploadFileToBucket:bucket withToken:token file:file key:key progressBlock:progressBlock resultBlock:uploadResultBlock];
    }
}

#pragma mark - Upload to QCloud

- (void)uploadToQCloudWithAVFile:(AVFile *)file fileTokensInfo:(NSDictionary *)fileTokensInfo progressBlock:(AVProgressBlock)progressBlock resultBlock:(AVBooleanResultBlock)resultBlock {
    NSDictionary *parameters = [self parametersForFile:file];
    NSString *token = [fileTokensInfo valueForKey:@"token"];
    NSString *bucket = [fileTokensInfo valueForKey:@"bucket"];
    NSString *objectId = [fileTokensInfo valueForKey:@"objectId"];
    NSString *originUrl = [fileTokensInfo valueForKey:@"url"];
    NSString *uploadURLString = [fileTokensInfo valueForKey:@"upload_url"];
    
    [AVUtils copyPropertiesFromDictionary:fileTokensInfo toNSObject:file];
    
    const uint64_t maxSize = QCloudSliceSize;
    void (^uploadResultBlock)(BOOL succeeded, NSError *error) = ^(BOOL succeeded, NSError *error) {
        if (!error) {
            file.url = originUrl;
            file.objectId = objectId;
            if (file.name.length <= 0) {
                file.name = objectId;
            }
            
            [AVFile cacheFile:file];
        }
        [AVUtils callBooleanResultBlock:resultBlock error:error];
    };
    NSString *key = parameters[@"key"];
    if (file.size > maxSize) {
        [self uploadLargeFileControlPayloadToQCloudWithToken:token uploadURLString:uploadURLString file:file key:key progressBlock:progressBlock resultBlock:uploadResultBlock];
    } else {
        [self uploadFileToQCloudBucket:bucket withToken:token uploadURLString:uploadURLString file:file key:key progressBlock:progressBlock resultBlock:uploadResultBlock];
    }
}

- (NSString *)QCloudUploadPathFromOriginURLString:(NSString *)originURLString {
    NSError *error = NULL;
    NSString *path;
    NSString *pattern = [NSString stringWithFormat:@"(https?)://%@([^[\"|']]*)", QCloudHOST];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    NSArray *matches = [regex matchesInString:originURLString
                                      options:0
                                        range:NSMakeRange(0, originURLString.length)];
    for (NSTextCheckingResult *match in matches) {
        NSUInteger numberOfRanges = [match numberOfRanges];
        if (numberOfRanges != 3) {
            AVLoggerD(@"QCloud upload URL error:%@", error.localizedDescription);
            return nil;
        }
        NSRange pathRange = [match rangeAtIndex:2];
        path = [originURLString substringWithRange:pathRange];
    }
    return path;
}

-(void)uploadFileToBucket:(NSString *)bucket
                withToken:(NSString *)token
                     file:(AVFile *)file
                      key:(NSString *)key
            progressBlock:(AVProgressBlock)progressBlock
              resultBlock:(AVBooleanResultBlock)resultBlock
{
    [self uploadFileToBucket:bucket withToken:token file:file key:key method:@"POST" progressBlock:progressBlock resultBlock:resultBlock];
}

-(void)uploadFileToBucket:(NSString *)bucket
                withToken:(NSString *)token
                     file:(AVFile *)file
                      key:(NSString *)key
                   method:(NSString *)method
            progressBlock:(AVProgressBlock)progressBlock
              resultBlock:(AVBooleanResultBlock)resultBlock
{
    NSDictionary *param = @{@"token":token, @"key":key};
    
    if (!file.data) file.data = [NSData dataWithContentsOfFile:file.localPath];
    NSData *uploadData = file.data;
    NSMutableURLRequest *request = [self.httpClient multipartFormRequestWithMethod:method path:nil parameters:param constructingBodyWithBlock: ^(id <AVMultipartFormData>formData) {
        [formData appendPartWithFileData:uploadData name:@"file" fileName:file.name mimeType:file.mimeType];
    }];

    [self uploadFile:file request:request progressBlock:progressBlock resultBlock:resultBlock];
}

-(void)uploadFile:(AVFile *)file
          request:(NSURLRequest *)request
    progressBlock:(AVProgressBlock)progressBlock
      resultBlock:(AVBooleanResultBlock)resultBlock
{
    AVFileHTTPRequestOperation *operation = [[AVFileHTTPRequestOperation alloc] initWithRequest:request];
    operation.localPath = file.localPath;
    [operation setUploadProgressBlock:^(AVURLConnectionOperation *operation, NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        float progress = totalBytesWritten / (float)totalBytesExpectedToWrite;
        [AVUtils callProgressBlock:progressBlock percent:progress * 100];
    }];
    [operation setCompletionBlockWithSuccess:^(AVHTTPRequestOperation *operation, id responseObject) {
        if (![operation isCancelled]) {
            [AVUtils callBooleanResultBlock:resultBlock error:[AVErrorUtils errorFromJSON:responseObject]];
        };
    } failure:^(AVHTTPRequestOperation *operation, NSError *error) {
        [AVUtils callBooleanResultBlock:resultBlock error:error];
    }];
    [self.httpClient enqueueHTTPRequestOperation:operation];
}

- (void)uploadFileToQCloudBucket:(NSString *)bucket
                      withToken:(NSString *)token
                       uploadURLString:(NSString *)uploadURLString
                           file:(AVFile *)file
                            key:(NSString *)key
                  progressBlock:(AVProgressBlock)progressBlock
                    resultBlock:(AVBooleanResultBlock)resultBlock {
   NSString *QCloudUploadPath = [self QCloudUploadPathFromOriginURLString:uploadURLString];
    if (!QCloudUploadPath) {
        NSURL *url = [NSURL URLWithString:uploadURLString];
        self.httpClient = [[AVHTTPClient alloc] initWithBaseURL:url];
    }
    NSMutableURLRequest *request = [self.httpClient multipartFormRequestWithMethod:@"POST" path:QCloudUploadPath parameters:nil constructingBodyWithBlock: ^(id <AVMultipartFormData>formData) {
        if (!file.data) file.data = [NSData dataWithContentsOfFile:file.localPath];
        NSString *SHAForFile = [AVUtils SHAForFile:file.localPath];
        NSData *uploadData = file.data;
        [formData appendPartWithFileData:uploadData name:@"filecontent" fileName:key mimeType:file.mimeType];
        [formData appendPartWithFormData:[@"upload" dataUsingEncoding:NSUTF8StringEncoding] name:@"op"];
        [formData appendPartWithFormData:[SHAForFile dataUsingEncoding:NSUTF8StringEncoding] name:@"sha"];
    }];
    [request setValue:token forHTTPHeaderField:@"Authorization"];
    [request setValue:QCloudHOST forHTTPHeaderField:@"Host"];
    AVFileHTTPRequestOperation *operation = [[AVFileHTTPRequestOperation alloc] initWithRequest:request];
    operation.localPath = file.localPath;
    [operation setUploadProgressBlock:^(AVURLConnectionOperation *operation, NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        float progress = totalBytesWritten / (float)totalBytesExpectedToWrite;
        [AVUtils callProgressBlock:progressBlock percent:progress * 100];
    }];
    [operation setCompletionBlockWithSuccess:^(AVHTTPRequestOperation *operation, id responseObject) {
        if (![operation isCancelled]) {
            [AVUtils callBooleanResultBlock:resultBlock error:[AVErrorUtils errorFromJSON:responseObject]];
        };
    } failure:^(AVHTTPRequestOperation *operation, NSError *error) {
        NSString *recoverySuggestion = error.userInfo[@"NSLocalizedRecoverySuggestion"];
        NSDictionary *responesDict = [self JSONValue:recoverySuggestion];
        NSNumber *errorCode = responesDict[@"code"];
        if (errorCode && (errorCode.integerValue == 0)) {
            error = nil;
        }
        [AVUtils callBooleanResultBlock:resultBlock error:error];
    }];
    [self.httpClient enqueueHTTPRequestOperation:operation];
}

- (NSDictionary *)JSONValue:(id)data {
    if (!data) { return nil; }
    id result = nil;
    NSError* error = nil;
    if ([data isKindOfClass:[NSString class]]) {
        if ([data length] == 0) { return nil; }
        NSData *dataToBeParsed = [data dataUsingEncoding:NSUTF8StringEncoding];
        result = [NSJSONSerialization JSONObjectWithData:dataToBeParsed options:kNilOptions error:&error];
    } else {
        result = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    }
    if (![result isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    if ([result objectForKey:@"code"] == nil) {
        return nil;
    }
    return result;
}

- (void)enqueueBatchOfHTTPRequestOperations:(NSArray *)operations
                              progressBlock:(void (^)(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations))progressBlock
                            completionBlock:(void (^)(NSArray *operations))completionBlock
                                  semaphore:(dispatch_semaphore_t)semaphore
{
    __block dispatch_group_t dispatchGroup = dispatch_group_create();
    NSBlockOperation *batchedOperation = [NSBlockOperation blockOperationWithBlock:^{
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        dispatch_group_notify(dispatchGroup, dispatch_get_main_queue(), ^{
            if (completionBlock) {
                completionBlock(operations);
            }
        });
#if !OS_OBJECT_USE_OBJC
        dispatch_release(dispatchGroup);
#endif
    }];
    
    for (AVHTTPRequestOperation *operation in operations) {
        void (^originalCompletionBlock)(void) = [operation.completionBlock copy];
        __weak AVHTTPRequestOperation *weakOperation = operation;
        operation.completionBlock = ^{
            dispatch_queue_t queue = weakOperation.successCallbackQueue ?: dispatch_get_main_queue();
            dispatch_group_async(dispatchGroup, queue, ^{
                if (originalCompletionBlock) {
                    originalCompletionBlock();
                }
                
                __block NSUInteger numberOfFinishedOperations = 0;
                [operations enumerateObjectsUsingBlock:^(id obj, __unused NSUInteger idx, __unused BOOL *stop) {
                    if ([(NSOperation *)obj isFinished]) {
                        numberOfFinishedOperations++;
                    }
                }];
                
                if (progressBlock) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        progressBlock(numberOfFinishedOperations, [operations count]);
                    });
                }
                
                dispatch_group_leave(dispatchGroup);
            });
        };
        
        dispatch_group_enter(dispatchGroup);
        [batchedOperation addDependency:operation];
    }
    [self.httpClient.operationQueue addOperations:operations waitUntilFinished:NO];
    [self.httpClient.operationQueue addOperation:batchedOperation];
}

- (NSMutableURLRequest *)constructRequestWithFile:(AVFile *)file offset:(uint64_t)offset size:(uint64_t)size {
    uint64_t contentSize = size;
    if (contentSize <= 0) {
        AVLoggerD(@"warning:contentSize %llu", contentSize);
    }
    NSString *path = [NSString stringWithFormat:@"/mkblk/%llu", contentSize];
    //    AVPartialInputStream *inputStream = [[AVPartialInputStream alloc] initWithFileAtPath:file.localPath];
    //    inputStream.offset = offset;
    //    inputStream.maxLength = contentSize;
    NSMutableURLRequest *request = [self.httpClient requestWithMethod:@"POST" path:path parameters:nil];
    //    [request setHTTPBodyStream:inputStream];
    //    [request addValue:[NSString stringWithFormat:@"%llu", contentSize] forHTTPHeaderField:@"Content-Length"];
    
    NSRange range = NSMakeRange((NSUInteger)offset, (NSUInteger)contentSize);
    char *buf = (char *)malloc((unsigned long)contentSize);
    [file.data getBytes:buf range:range];
    NSData *bodyData = [[NSData alloc] initWithBytes:buf length:(NSUInteger)contentSize];
    [request setHTTPBody:bodyData];
    free(buf);
    
    return request;
}

- (NSMutableURLRequest *)constructQCloudSliceControlRequestWithFile:(AVFile *)file
                                        uploadURLString:(NSString *)uploadURLString
                                                   size:(uint64_t)size
                                                session:(NSString *)session {
    uint64_t contentSize = size;
    if (contentSize <= 0) {
        AVLoggerD(@"warning:contentSize %llu", contentSize);
    }
    NSString *QCloudUploadPath = [self QCloudUploadPathFromOriginURLString:uploadURLString];
    if (!QCloudUploadPath) {
        NSURL *url = [NSURL URLWithString:uploadURLString];
        self.httpClient = [[AVHTTPClient alloc] initWithBaseURL:url];
    }
    NSMutableURLRequest *request = [self.httpClient multipartFormRequestWithMethod:@"POST" path:QCloudUploadPath parameters:nil constructingBodyWithBlock: ^(id <AVMultipartFormData>formData) {
        if (!file.data) file.data = [NSData dataWithContentsOfFile:file.localPath];
        NSString *SHAForFile = [AVUtils SHAForFile:file.localPath];
        [formData appendPartWithFormData:[@"upload_slice" dataUsingEncoding:NSUTF8StringEncoding] name:@"op"];
        [formData appendPartWithFormData:[[@(contentSize) stringValue] dataUsingEncoding:NSUTF8StringEncoding] name:@"filesize"];
        [formData appendPartWithFormData:[SHAForFile dataUsingEncoding:NSUTF8StringEncoding] name:@"sha"];
        if (session) {
            [formData appendPartWithFormData:[session dataUsingEncoding:NSUTF8StringEncoding] name:@"session"];
        }
    }];
    [request setValue:QCloudHOST forHTTPHeaderField:@"Host"];
    return request;
}

- (NSMutableURLRequest *)constructQCloudSliceRequestWithFile:(AVFile *)file
                                        uploadURLString:(NSString *)uploadURLString
                                                 offset:(uint64_t)offset
                                                   size:(uint64_t)size
                                                session:(NSString *)session {
    uint64_t contentSize = size;
    if (contentSize <= 0) {
        AVLoggerD(@"warning:contentSize %llu", contentSize);
    }
    NSString *QCloudUploadPath = [self QCloudUploadPathFromOriginURLString:uploadURLString];
    if (!QCloudUploadPath) {
        NSURL *url = [NSURL URLWithString:uploadURLString];
        self.httpClient = [[AVHTTPClient alloc] initWithBaseURL:url];
    }
    NSMutableURLRequest *request = [self.httpClient multipartFormRequestWithMethod:@"POST" path:QCloudUploadPath parameters:nil constructingBodyWithBlock: ^(id <AVMultipartFormData>formData) {
        if (!file.data) file.data = [NSData dataWithContentsOfFile:file.localPath];
        NSRange range = NSMakeRange((NSUInteger)offset, (NSUInteger)contentSize);
        char *buf = (char *)malloc((unsigned long)contentSize);
        [file.data getBytes:buf range:range];
        NSData *bodyData = [[NSData alloc] initWithBytes:buf length:(NSUInteger)contentSize];
        [formData appendPartWithFileData:bodyData name:@"filecontent" fileName:file.name mimeType:file.mimeType];
        free(buf);
        
        [formData appendPartWithFormData:[@"upload_slice" dataUsingEncoding:NSUTF8StringEncoding] name:@"op"];
        [formData appendPartWithFormData:[[@(size) stringValue] dataUsingEncoding:NSUTF8StringEncoding] name:@"slice_size"];
        //TODO:QCloud暂不支持分片文件的sha校验
        //[formData appendPartWithFormData:[SHAForSliceFile dataUsingEncoding:NSUTF8StringEncoding] name:@"sha"];
        [formData appendPartWithFormData:[session dataUsingEncoding:NSUTF8StringEncoding] name:@"session"];
        [formData appendPartWithFormData:[[@(offset) stringValue] dataUsingEncoding:NSUTF8StringEncoding] name:@"offset"];
    }];
    [request setValue:QCloudHOST forHTTPHeaderField:@"Host"];
    return request;
}

-(void)makeFileForQiNiuWithKey:(NSString *)key size:(uint64_t)size contexts:(NSMutableArray *)contexts resultBlock:(AVBooleanResultBlock)resultBlock {
    NSString *path = [NSString stringWithFormat:@"/mkfile/%llu/key/%@", size, [[key dataUsingEncoding:NSUTF8StringEncoding] AVbase64EncodedString]];
    BOOL isFirst = YES;
    NSMutableString *bodyString = [[NSMutableString alloc] init];
    for (NSString *ctx in contexts) {
        if (isFirst) {
            [bodyString appendString:ctx];
            isFirst = NO;
        } else {
            [bodyString appendFormat:@",%@", ctx];
        }
    }
    NSMutableURLRequest *request = [self.httpClient requestWithMethod:@"POST" path:path parameters:nil];
    
    NSData *bodyData = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:bodyData];
    AVFileHTTPRequestOperation *operation = [[AVFileHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AVHTTPRequestOperation *operation, id responseObject) {
        if (![operation isCancelled]) {
            [AVUtils callBooleanResultBlock:resultBlock error:nil];
        } else {
            [AVUtils callBooleanResultBlock:resultBlock error:[NSError errorWithDomain:@"AVOSUploadFileDomain" code:700 userInfo:@{@"reason":[NSString stringWithFormat:@"Operation is cancelled."]}]];
        }
    } failure:^(AVHTTPRequestOperation *operation, NSError *error) {
        [AVUtils callBooleanResultBlock:resultBlock error:error];
    }];
    
    [self.httpClient enqueueHTTPRequestOperation:operation];
}

- (void)updateProgressWithProgressDict:(NSMutableDictionary *)progressDict
                                 index:(NSNumber *)index
                                 bytes:(int64_t)bytes
                            totalBytes:(int64_t)totalBytes
                        reachedPercent:(NSMutableString *)reachedPercent
                         progressBlock:(AVProgressBlock)progressBlock {
    [progressDict setObject:@(bytes) forKey:index];
    int64_t totalLoadedBytes = 0;
    for (NSNumber *val in [progressDict allValues]) {
        totalLoadedBytes += [val longLongValue];
    }
    float percent = 1.0 * totalLoadedBytes / totalBytes;
    float reached = [reachedPercent floatValue];
    if (percent > reached) {
        [reachedPercent setString:[NSString stringWithFormat:@"%f", percent]];
        [AVUtils callProgressBlock:progressBlock percent:percent * 100];
    }
}

#pragma mark -
#pragma mark QCloud large File update

/*!
 *  有别于Qiniu的分块上传，QCloud的上传是先发送meta信息(filesize,sha,op)，这里只有meta信息，然后拿着返回的sessionid，做真实的文件上传。
 如果同一个文件之前上传过，第一次meta信息发送以后，返回的结果中间会直接带access_url而没有session信息，相当于不需要重新上传文件，在QCloud实现了一次"软链接"
 
 分片上传需要按照这个流程哦：
 1、传控制包，传成功会返回 offset、session
 2、传数据包，用1中返回的offset和session
 每个数据包传完，也会返回offset，下个数据包的offset在上个数据包返回的offset上加上分片大小。
 循环直到数据包传完
 */
- (void)uploadLargeFileControlPayloadToQCloudWithToken:(NSString *)token
                         uploadURLString:(NSString *)uploadURLString
                                       file:(AVFile *)file
                                        key:(NSString *)key
                              progressBlock:(AVProgressBlock)progressBlock
                                resultBlock:(AVBooleanResultBlock)resultBlock {
    [self.httpClient setDefaultHeader:@"Authorization" value:token];
    NSError *error = nil;
    NSDictionary *fileDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:file.localPath error:&error];
    if (error) {
        [AVUtils callBooleanResultBlock:resultBlock error:error];
        return;
    }
    const uint64_t dataSize = [fileDictionary fileSize];
    NSMutableURLRequest *request = [self constructQCloudSliceControlRequestWithFile:file uploadURLString:uploadURLString size:dataSize session:nil];
    
    AVFileHTTPRequestOperation *operation = [[AVFileHTTPRequestOperation alloc] initWithRequest:request];
    operation.localPath = file.localPath;
    [operation setCompletionBlockWithSuccess:^(AVHTTPRequestOperation *operation, id responseObject) {
        if (![operation isCancelled]) {
            [AVUtils callBooleanResultBlock:resultBlock error:[AVErrorUtils errorFromJSON:responseObject]];
        };
    } failure:^(AVHTTPRequestOperation *operation, NSError *error) {
        NSString *recoverySuggestion = error.userInfo[@"NSLocalizedRecoverySuggestion"];
        NSDictionary *responesDict = [self JSONValue:recoverySuggestion];
        NSNumber *errorCode = responesDict[@"code"];
        if (errorCode && (errorCode.integerValue == 0)) {
            error = nil;
            //        {"code":0,"message":"成功","data":{"offset":0,"session":"593bf8ab-a4c5-4235-b7f8-ac58f5901740+CtQXI9EHAA==","slice_size":524288}
            //        }
            //            {"code":0,"message":"成功","data":{"access_url":"http://38clkuihwyb6w0dv-10007535.file.myqcloud.com/iIWH8GSFn6y5IGmiVscQIuC","resource_path":"/iIWH8GSFn6y5IGmiVscQIuC","source_url":"http://38clkuihwyb6w0dv-10007535.cos.myqcloud.com/iIWH8GSFn6y5IGmiVscQIuC","url":"http://web.file.myqcloud.com/files/v1/iIWH8GSFn6y5IGmiVscQIuC"}
            NSString *accessURLString = responesDict[@"data"][@"access_url"];
            if (accessURLString) {
                [AVUtils callBooleanResultBlock:resultBlock error:error];
                return;
            }
            uint64_t offSet = [responesDict[@"data"][@"offset"] unsignedLongLongValue];
            NSString *session = responesDict[@"data"][@"session"];
            //            NSUInteger sliceSize = [responesDict[@"data"][@"slice_size"] unsignedLongLongValue];
            [self uploadLargeFileToQCloudWithToken:token offSet:offSet session:session uploadURLString:uploadURLString file:file key:key progressBlock:progressBlock resultBlock:resultBlock];
        }
    }];
    [self.httpClient enqueueHTTPRequestOperation:operation];
}

- (void)uploadLargeFileToQCloudWithToken:(NSString *)token
                                  offSet:(uint64_t)offSet
                                 session:(NSString *)session
                         uploadURLString:(NSString *)uploadURLString
                                    file:(AVFile *)file
                                     key:(NSString *)key
                           progressBlock:(AVProgressBlock)progressBlock
                             resultBlock:(AVBooleanResultBlock)resultBlock {
    __block NSMutableArray *contexts = [[NSMutableArray alloc] init];

    NSError * error = nil;
    if (!file.data) file.data = [NSData dataWithContentsOfFile:file.localPath
                                                       options:NSDataReadingMapped
                                                         error:&error];
    if (error) {
        [AVUtils callBooleanResultBlock:resultBlock error:error];
        return;
    }
    NSDictionary *fileDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:file.localPath error:&error];
    if (error) {
        [AVUtils callBooleanResultBlock:resultBlock error:error];
        return;
    }
    
    const uint64_t maxSize = QCloudSliceSize;
    const uint64_t dataSize = [fileDictionary fileSize] - offSet;
    int blockCount = ceil(1.0f*dataSize/maxSize);
    __block int finishedCount = 0;
    __block NSMutableDictionary *progressDict = [[NSMutableDictionary alloc] initWithCapacity:blockCount];
    __block NSMutableString *reachedPercent = [[NSMutableString alloc] initWithFormat:@"0"];
    __block dispatch_semaphore_t semaphore = NULL;
    NSMutableArray *operations = [[NSMutableArray alloc] init];
    for (int i = 0; i < blockCount; ++i) {
        uint64_t offset_ = maxSize * i + offSet;
        uint64_t contentSize = maxSize;
        if (dataSize - offset_ < contentSize) {
            contentSize = dataSize - offset_;
        }
        if (contentSize <= 0) {
            break;
        }
        NSMutableURLRequest *request = [self constructQCloudSliceRequestWithFile:file uploadURLString:uploadURLString offset:offset_ size:contentSize session:session];
        
        [contexts addObject:@""];
        AVFileHTTPRequestOperation *operation = [[AVFileHTTPRequestOperation alloc] initWithRequest:request];
        operation.localPath = file.localPath;
        operation.userInfo = @{@"index":@(i), @"offset":@(offset_), @"size":@(contentSize)};
        [operation setUploadProgressBlock:^(AVURLConnectionOperation *operation, NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
            NSNumber *index = [operation.userInfo objectForKey:@"index"];
            if (!operation.isCancelled) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self updateProgressWithProgressDict:progressDict index:index bytes:totalBytesWritten totalBytes:dataSize reachedPercent:reachedPercent progressBlock:progressBlock];
                });
            }
        }];
        
        [operation setCompletionBlockWithSuccess:^(AVHTTPRequestOperation *operation, id responseObject) {
            ++finishedCount;
            if (![operation isCancelled]) {
                NSNumber *numIndex = [operation.userInfo objectForKey:@"index"];
                NSNumber *numSize = [operation.userInfo objectForKey:@"size"];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self updateProgressWithProgressDict:progressDict index:numIndex bytes:[numSize longLongValue] totalBytes:dataSize reachedPercent:reachedPercent progressBlock:progressBlock];
                });
                int index = [numIndex intValue];
                NSString *ctx = [responseObject objectForKey:@"ctx"];
                [contexts replaceObjectAtIndex:index withObject:ctx];
            }
            if (finishedCount == operations.count) {
                dispatch_semaphore_signal(semaphore);
            }
        } failure:^(AVHTTPRequestOperation *operation, NSError *error) {
            ++finishedCount;
            NSNumber *numIndex = [operation.userInfo objectForKey:@"index"];
            if (!operation.isCancelled) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self updateProgressWithProgressDict:progressDict index:numIndex bytes:0 totalBytes:dataSize reachedPercent:reachedPercent progressBlock:progressBlock];
                });
            }
            if (finishedCount == operations.count) {
                dispatch_semaphore_signal(semaphore);
            }
        }];
        [operations addObject:operation];
    }
    semaphore = dispatch_semaphore_create(0);
    [self enqueueBatchOfHTTPRequestOperations:operations progressBlock:^(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations) {
        AVLoggerD(@"%@ of %@", @(numberOfFinishedOperations), @(totalNumberOfOperations));
    } completionBlock:^(NSArray *operations) {
        BOOL cancelled = NO;
        int failedCount = 0;
        AVLoggerD(@"operations %@", @(operations.count));
        for (AVFileHTTPRequestOperation *operation in operations) {
            if (operation.isCancelled) {
                cancelled = YES;
                break;
            }
            
            NSInteger statusCode = operation.response.statusCode;
            BOOL uploadFailed = YES;
            NSString *responseString = operation.responseString;
            NSDictionary *responesDict = [self JSONValue:responseString];
            NSNumber *errorCode = responesDict[@"code"];
            if (responseString && (errorCode.integerValue == 0)) {
                uploadFailed = NO;
            }
            if ((operation.response && (statusCode != 200)) || uploadFailed) {
                ++failedCount;
            }
        }
        if (cancelled) {
            [AVUtils callBooleanResultBlock:resultBlock error:[NSError errorWithDomain:@"AVOSUploadFileDomain" code:701 userInfo:@{@"reason":@"File upload cancelled."}]];
        } else if (failedCount > 0) {
            [self uploadLargeFileToQCloudWithToken:token offSet:offSet session:session uploadURLString:uploadURLString file:file key:key progressBlock:progressBlock resultBlock:resultBlock contexts:contexts maxSize:maxSize progressDictionary:progressDict reachedPercent:reachedPercent tryCount:1];
        } else {
            [AVUtils callBooleanResultBlock:resultBlock error:nil];
        }
    } semaphore:semaphore];
}

-(void)uploadLargeFileToQiNiuWithToken:(NSString *)token
                                  file:(AVFile *)file
                                   key:(NSString *)key
                         progressBlock:(AVProgressBlock)progressBlock
                           resultBlock:(AVBooleanResultBlock)resultBlock {
    __block NSMutableArray *contexts = [[NSMutableArray alloc] init];
    [self.httpClient setDefaultHeader:@"Authorization" value:[NSString stringWithFormat:@"UpToken %@", token]];
    
    NSError * error = nil;
    if (!file.data) file.data = [NSData dataWithContentsOfFile: file.localPath
                                                       options: NSDataReadingMapped
                                                         error: &error];
    if (error) {
        [AVUtils callBooleanResultBlock:resultBlock error:error];
        return;
    }
    NSDictionary *fileDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:file.localPath error:&error];
    if (error) {
        [AVUtils callBooleanResultBlock:resultBlock error:error];
        return;
    }
    const uint64_t maxSize = 1 << 22;
    const uint64_t dataSize = [fileDictionary fileSize];
    int blockCount = ceil(1.0f*dataSize/maxSize);
    __block int finishedCount = 0;
    __block NSMutableDictionary *progressDict = [[NSMutableDictionary alloc] initWithCapacity:blockCount];
    __block NSMutableString *reachedPercent = [[NSMutableString alloc] initWithFormat:@"0"];
    __block dispatch_semaphore_t semaphore = NULL;
    NSMutableArray *operations = [[NSMutableArray alloc] init];
    for (int i = 0; i < blockCount; ++i) {
        uint64_t offset = maxSize * i;
        uint64_t contentSize = maxSize;
        if (dataSize - offset < contentSize) {
            contentSize = dataSize - offset;
        }
        if (contentSize <= 0) {
            break;
        }
        NSMutableURLRequest *request = [self constructRequestWithFile:file offset:offset size:contentSize];
        
        [contexts addObject:@""];
        AVFileHTTPRequestOperation *operation = [[AVFileHTTPRequestOperation alloc] initWithRequest:request];
        operation.localPath = file.localPath;
        operation.userInfo = @{@"index":@(i), @"offset":@(offset), @"size":@(contentSize)};
        [operation setUploadProgressBlock:^(AVURLConnectionOperation *operation, NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
            NSNumber *index = [operation.userInfo objectForKey:@"index"];
            if (!operation.isCancelled) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self updateProgressWithProgressDict:progressDict index:index bytes:totalBytesWritten totalBytes:dataSize reachedPercent:reachedPercent progressBlock:progressBlock];
                });
            }
        }];
        
        [operation setCompletionBlockWithSuccess:^(AVHTTPRequestOperation *operation, id responseObject) {
            ++finishedCount;
            if (![operation isCancelled]) {
                NSNumber *numIndex = [operation.userInfo objectForKey:@"index"];
                NSNumber *numSize = [operation.userInfo objectForKey:@"size"];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self updateProgressWithProgressDict:progressDict index:numIndex bytes:[numSize longLongValue] totalBytes:dataSize reachedPercent:reachedPercent progressBlock:progressBlock];
                });
                int index = [numIndex intValue];
                NSString *ctx = [responseObject objectForKey:@"ctx"];
                [contexts replaceObjectAtIndex:index withObject:ctx];
            } else {
                int index = [[operation.userInfo objectForKey:@"index"] intValue];
                AVLoggerD(@"cancelled index:%d object:%@", index, responseObject);
            }
            if (finishedCount == operations.count) {
                dispatch_semaphore_signal(semaphore);
            }
        } failure:^(AVHTTPRequestOperation *operation, NSError *error) {
            ++finishedCount;
            NSNumber *numIndex = [operation.userInfo objectForKey:@"index"];
            if (!operation.isCancelled) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self updateProgressWithProgressDict:progressDict index:numIndex bytes:0 totalBytes:dataSize reachedPercent:reachedPercent progressBlock:progressBlock];
                });
            }
            int index = [numIndex intValue];
            AVLoggerD(@"index:%d error:%@", index, error);
            if (finishedCount == operations.count) {
                dispatch_semaphore_signal(semaphore);
            }
        }];
        [operations addObject:operation];
    }
    semaphore = dispatch_semaphore_create(0);
    [self enqueueBatchOfHTTPRequestOperations:operations progressBlock:^(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations) {
        AVLoggerD(@"%@ of %@", @(numberOfFinishedOperations), @(totalNumberOfOperations));
    } completionBlock:^(NSArray *operations) {
        BOOL cancelled = NO;
        int failedCount = 0;
        AVLoggerD(@"operations %@", @(operations.count));
        for (AVFileHTTPRequestOperation *operation in operations) {
            if (operation.isCancelled) {
                cancelled = YES;
                break;
            }
            if (operation.response.statusCode != 200) {
                ++failedCount;
            }
        }
        if (cancelled) {
            [AVUtils callBooleanResultBlock:resultBlock error:[NSError errorWithDomain:@"AVOSUploadFileDomain" code:701 userInfo:@{@"reason":@"File upload cancelled."}]];
        } else if (failedCount > 0) {
            [self uploadLargeFileToQiNiuWithToken:token file:file key:key progressBlock:progressBlock resultBlock:resultBlock contexts:contexts maxSize:maxSize progressDictionary:progressDict reachedPercent:reachedPercent tryCount:1];
        } else {
            [self makeFileForQiNiuWithKey:key size:dataSize contexts:contexts resultBlock:resultBlock];
        }
    } semaphore:semaphore];
}

-(void)uploadLargeFileToQCloudWithToken:(NSString *)token
                                 offSet:(uint64_t)offSet
                                session:(NSString *)session
                        uploadURLString:(NSString *)uploadURLString
                                  file:(AVFile *)file
                                   key:(NSString *)key
                         progressBlock:(AVProgressBlock)progressBlock
                           resultBlock:(AVBooleanResultBlock)resultBlock
                              contexts:(NSMutableArray *)contexts
                               maxSize:(uint64_t)maxSize
                    progressDictionary:(NSMutableDictionary *)progressDict
                        reachedPercent:(NSMutableString *)reachedPercent
                              tryCount:(int)tryCount {
    NSError * error = nil;
    NSDictionary *fileDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:file.localPath error:&error];
    if (error) {
        [AVUtils callBooleanResultBlock:resultBlock error:error];
        return;
    }
    const uint64_t dataSize = [fileDictionary fileSize] - offSet;
    int blockCount = ceil(1.0f*dataSize/maxSize);
    __block int finishedCount = 0;
    __block dispatch_semaphore_t semaphore = NULL;
    
    NSMutableArray *operations = [[NSMutableArray alloc] init];
    for (int i = 0; i < blockCount; ++i) {
        if (![[contexts objectAtIndex:i] isEqualToString:@""]) {
            continue;
        }
        uint64_t offset_ = maxSize * i + offSet;
        uint64_t contentSize = maxSize;
        if (dataSize - offset_ < contentSize) {
            contentSize = dataSize - offset_;
        }
        if (contentSize <= 0) {
            break;
        }
        
        
        NSMutableURLRequest *request = [self constructQCloudSliceRequestWithFile:file uploadURLString:uploadURLString offset:offset_ size:contentSize session:session];
        
        AVFileHTTPRequestOperation *operation = [[AVFileHTTPRequestOperation alloc] initWithRequest:request];
        operation.localPath = file.localPath;
        operation.userInfo = @{@"index":@(i), @"offset":@(offset_), @"size":@(contentSize)};
        [operation setUploadProgressBlock:^(AVURLConnectionOperation *operation, NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
            NSNumber *index = [operation.userInfo objectForKey:@"index"];
            if (!operation.isCancelled) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self updateProgressWithProgressDict:progressDict index:index bytes:totalBytesWritten totalBytes:dataSize reachedPercent:reachedPercent progressBlock:progressBlock];
                });
            }
        }];
        
        [operation setCompletionBlockWithSuccess:^(AVHTTPRequestOperation *operation, id responseObject) {
            ++finishedCount;
            if (![operation isCancelled]) {
                NSNumber *numIndex = [operation.userInfo objectForKey:@"index"];
                NSNumber *numSize = [operation.userInfo objectForKey:@"size"];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self updateProgressWithProgressDict:progressDict index:numIndex bytes:[numSize longLongValue] totalBytes:dataSize reachedPercent:reachedPercent progressBlock:progressBlock];
                });
                int index = [numIndex intValue];
                NSString *ctx = [responseObject objectForKey:@"ctx"];
                [contexts replaceObjectAtIndex:index withObject:ctx];
            } else {
                int index = [[operation.userInfo objectForKey:@"index"] intValue];
                AVLoggerD(@"cancelled index:%d object:%@", index, responseObject);
            }
            if (finishedCount == operations.count) {
                dispatch_semaphore_signal(semaphore);
            }
        } failure:^(AVHTTPRequestOperation *operation, NSError *error) {
            ++finishedCount;
            NSNumber *numIndex = [operation.userInfo objectForKey:@"index"];
            if (!operation.isCancelled) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self updateProgressWithProgressDict:progressDict index:numIndex bytes:0 totalBytes:dataSize reachedPercent:reachedPercent progressBlock:progressBlock];
                });
            }
            if (finishedCount == operations.count) {
                dispatch_semaphore_signal(semaphore);
            }
        }];
        [operations addObject:operation];
    }
    semaphore = dispatch_semaphore_create(0);
    [self enqueueBatchOfHTTPRequestOperations:operations progressBlock:^(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations) {
        AVLoggerD(@"%@ of %@", @(numberOfFinishedOperations), @(totalNumberOfOperations));
    } completionBlock:^(NSArray *operations) {
        int failedCount = 0;
        BOOL cancelled = NO;
        AVLoggerD(@"operations %@", @(operations.count));
        for (AVFileHTTPRequestOperation *operation in operations) {
            if (operation.isCancelled) {
                cancelled = YES;
                break;
            }
            NSInteger statusCode = operation.response.statusCode;
            BOOL uploadFailed = YES;
            NSString *responseString = operation.responseString;
            NSDictionary *responesDict = [self JSONValue:responseString];
            NSNumber *errorCode = responesDict[@"code"];
            if (responseString && (errorCode.integerValue == 0)) {
                uploadFailed = NO;
            }
            if ((operation.response && (statusCode != 200)) || uploadFailed) {
                ++failedCount;
            }
        }
        if (cancelled) {
            [AVUtils callBooleanResultBlock:resultBlock error:[NSError errorWithDomain:@"AVOSUploadFileDomain" code:701 userInfo:@{@"reason":@"File upload cancelled."}]];
        } else if (tryCount > 3) {
            [AVUtils callBooleanResultBlock:resultBlock error:[NSError errorWithDomain:@"AVOSUploadFileDomain" code:700 userInfo:@{@"reason":[NSString stringWithFormat:@"Try to upload %d times but not success.", tryCount]}]];
        } else {
            if (failedCount > 0) {
                [self uploadLargeFileToQCloudWithToken:token offSet:offSet session:session uploadURLString:uploadURLString file:file key:key progressBlock:progressBlock resultBlock:resultBlock contexts:contexts maxSize:maxSize progressDictionary:progressDict reachedPercent:reachedPercent tryCount:tryCount + 1];
            } else {
                [AVUtils callBooleanResultBlock:resultBlock error:nil];
            }
        }
    } semaphore:semaphore];
}

-(void)uploadLargeFileToQiNiuWithToken:(NSString *)token
                                  file:(AVFile *)file
                                   key:(NSString *)key
                         progressBlock:(AVProgressBlock)progressBlock
                           resultBlock:(AVBooleanResultBlock)resultBlock
                              contexts:(NSMutableArray *)contexts
                               maxSize:(uint64_t)maxSize
                    progressDictionary:(NSMutableDictionary *)progressDict
                        reachedPercent:(NSMutableString *)reachedPercent
                              tryCount:(int)tryCount {
    NSError * error = nil;
    NSDictionary *fileDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:file.localPath error:&error];
    if (error) {
        [AVUtils callBooleanResultBlock:resultBlock error:error];
        return;
    }
    const uint64_t dataSize = [fileDictionary fileSize];
    int blockCount = ceil(1.0f*dataSize/maxSize);
    __block int finishedCount = 0;
    __block dispatch_semaphore_t semaphore = NULL;
    
    NSMutableArray *operations = [[NSMutableArray alloc] init];
    for (int i = 0; i < blockCount; ++i) {
        if (![[contexts objectAtIndex:i] isEqualToString:@""]) {
            continue;
        }
        uint64_t offset = maxSize * i;
        uint64_t contentSize = maxSize;
        if (dataSize - offset < contentSize) {
            contentSize = dataSize - offset;
        }
        if (contentSize <= 0) {
            break;
        }
        NSMutableURLRequest *request = [self constructRequestWithFile:file offset:offset size:contentSize];
        
        AVFileHTTPRequestOperation *operation = [[AVFileHTTPRequestOperation alloc] initWithRequest:request];
        operation.localPath = file.localPath;
        operation.userInfo = @{@"index":@(i), @"offset":@(offset), @"size":@(contentSize)};
        [operation setUploadProgressBlock:^(AVURLConnectionOperation *operation, NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
            NSNumber *index = [operation.userInfo objectForKey:@"index"];
            if (!operation.isCancelled) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self updateProgressWithProgressDict:progressDict index:index bytes:totalBytesWritten totalBytes:dataSize reachedPercent:reachedPercent progressBlock:progressBlock];
                });
            }
        }];
        
        [operation setCompletionBlockWithSuccess:^(AVHTTPRequestOperation *operation, id responseObject) {
            ++finishedCount;
            if (![operation isCancelled]) {
                NSNumber *numIndex = [operation.userInfo objectForKey:@"index"];
                NSNumber *numSize = [operation.userInfo objectForKey:@"size"];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self updateProgressWithProgressDict:progressDict index:numIndex bytes:[numSize longLongValue] totalBytes:dataSize reachedPercent:reachedPercent progressBlock:progressBlock];
                });
                int index = [numIndex intValue];
                NSString *ctx = [responseObject objectForKey:@"ctx"];
                [contexts replaceObjectAtIndex:index withObject:ctx];
            } else {
                int index = [[operation.userInfo objectForKey:@"index"] intValue];
                AVLoggerD(@"cancelled index:%d object:%@", index, responseObject);
            }
            if (finishedCount == operations.count) {
                dispatch_semaphore_signal(semaphore);
            }
        } failure:^(AVHTTPRequestOperation *operation, NSError *error) {
            ++finishedCount;
            NSNumber *numIndex = [operation.userInfo objectForKey:@"index"];
            if (!operation.isCancelled) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self updateProgressWithProgressDict:progressDict index:numIndex bytes:0 totalBytes:dataSize reachedPercent:reachedPercent progressBlock:progressBlock];
                });
            }
            int index = [numIndex intValue];
            AVLoggerD(@"index:%d error:%@", index, error);
            if (finishedCount == operations.count) {
                dispatch_semaphore_signal(semaphore);
            }
        }];
        [operations addObject:operation];
    }
    semaphore = dispatch_semaphore_create(0);
    [self enqueueBatchOfHTTPRequestOperations:operations progressBlock:^(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations) {
        AVLoggerD(@"%@ of %@", @(numberOfFinishedOperations), @(totalNumberOfOperations));
    } completionBlock:^(NSArray *operations) {
        int failedCount = 0;
        BOOL cancelled = NO;
        AVLoggerD(@"operations %@", @(operations.count));
        for (AVFileHTTPRequestOperation *operation in operations) {
            if (operation.isCancelled) {
                cancelled = YES;
                break;
            }
            if (operation.response.statusCode != 200) {
                ++failedCount;
            }
        }
        if (cancelled) {
            [AVUtils callBooleanResultBlock:resultBlock error:[NSError errorWithDomain:@"AVOSUploadFileDomain" code:701 userInfo:@{@"reason":@"File upload cancelled."}]];
        } else if (tryCount > 3) {
            [AVUtils callBooleanResultBlock:resultBlock error:[NSError errorWithDomain:@"AVOSUploadFileDomain" code:700 userInfo:@{@"reason":[NSString stringWithFormat:@"Try to upload %d times but not success.", tryCount]}]];
        } else {
            if (failedCount > 0) {
                [self uploadLargeFileToQiNiuWithToken:token file:file key:key progressBlock:progressBlock resultBlock:resultBlock contexts:contexts maxSize:maxSize progressDictionary:progressDict reachedPercent:reachedPercent tryCount:tryCount + 1];
            } else {
                [self makeFileForQiNiuWithKey:key size:dataSize contexts:contexts resultBlock:resultBlock];
            }
        }
    } semaphore:semaphore];
}

+ (NSString *)generateQiniuKey
{
    return [AVUploaderManager generateRandomString:16];
}

+ (NSString *)generateRandomString:(int)length
{
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity: length];
    
    for (int i=0; i<length; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random() % [letters length]]];
    }
    return randomString;
}


@end
