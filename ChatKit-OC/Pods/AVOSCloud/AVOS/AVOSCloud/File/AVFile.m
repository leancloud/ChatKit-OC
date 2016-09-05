
#import <Foundation/Foundation.h>
#import "AVConstants.h"
#import "AVFile.h"
#import "AVFile_Internal.h"
#import "AVUploaderManager.h"
#import "AVPaasClient.h"
#import "AVUtils.h"
#import "AVNetworking.h"
#import "AVErrorUtils.h"
#import "AVPersistenceUtils.h"
#import "AVObjectUtils.h"
#import "AVACL_Internal.h"

#define AVFILE_REQUEST_TIMEOUT 60

static NSString * ownerTag = @"owner";
static NSString * fileSizeTag = @"size";
static NSString * fileMd5Tag =@"_checksum";

static NSMutableDictionary *downloadingMap = nil;

@interface _CallBack : NSObject
@property(nonatomic, strong) AVBooleanResultBlock resultBlock;
@property(nonatomic, strong) AVProgressBlock progressBlock;
@end
@implementation _CallBack

@end

@implementation AVFile

- (NSMutableDictionary *)metadata {
    return _metaData;
}

- (void)setMetadata:(NSMutableDictionary *)metadata {
    _metaData = metadata;
}

-(instancetype)init
{
    self = [super init];
    _metaData = [[NSMutableDictionary alloc] init];
    _isDirty = YES;
    _onceCallGetFileSize = NO;
    return self;
}

#pragma mark - Public Methods
+ (instancetype)fileWithData:(NSData *)data
{
    AVFile * file = [[self alloc] init];
    file.data = data;
    file.name = [AVUtils generateCompactUUID];
    file.cachePath = file.localPath;
    [data writeToFile:file.localPath atomically:YES];
    return file;
}

+ (instancetype)fileWithName:(NSString *)name data:(NSData *)data
{
    AVFile * file = [[self alloc] init];
    file.data = data;
    file.name = name;
    file.cachePath = file.localPath;
    [data writeToFile:file.localPath atomically:YES];
    return file;
}

+ (instancetype)fileWithURL:(NSString *)url
{
    AVFile * file = [[self alloc] init];
    file.url = url;
    file.name = [url lastPathComponent] ?: [url AVMD5String];
    file.metaData = [NSMutableDictionary dictionaryWithObject:@"external" forKey:@"__source"];
    return file;
}

+ (instancetype)fileWithName:(NSString *)name
    contentsAtPath:(NSString *)path
{
    AVFile * file = [[self alloc] init];
    file.name = name;
    file.localPath = path;
    NSError *error = nil;
    file.data = [[NSData alloc] initWithContentsOfFile:path options:NSDataReadingMapped error:&error];
//    file.data = [[NSData alloc] initWithContentsOfMappedFile:path];
    //FIXME: 这些数据一直在内存 如果文件大的话很危险
//    file.data = [NSData dataWithContentsOfFile:path];
    return file;
}

+ (instancetype)fileWithAVObject:(AVObject *)object {
    NSDictionary *dict = [object dictionaryForObject];
    AVFile *file = [[self alloc] init];
    [AVUtils copyPropertiesFromDictionary:dict toNSObject:file];
    if (file.objectId.length > 0) {
        file.isDirty = NO;
    }
    return file;
}

- (NSString *)localPath {
    if (!_localPath) {
        _localPath = [[AVPersistenceUtils avFileDirectory] stringByAppendingPathComponent:self.url.length > 0 ? [self.url AVMD5String] : [AVUtils generateCompactUUID]];
    }
    return _localPath;
}

- (void)dealloc {
//    VLog(@"%s", __FUNCTION__);
}

- (BOOL)save
{
    return [self save:nil];
}

- (BOOL)save:(NSError **)theError
{
    BOOL __block theResult = NO;
    BOOL __block hasCalledBack = NO;
    NSError __block *blockError = nil;
    
    [self saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        blockError = error;
        theResult = (error == nil);
        hasCalledBack = YES;
    } progressBlock:^(NSInteger percentDone) {
        AVLoggerI(@"progress %ld", (long)percentDone);
    }];
    
    // wait until called back if necessary
    [AVUtils warnMainThreadIfNecessary];
    AV_WAIT_TIL_TRUE(hasCalledBack, 0.1);
    
    if (theError != NULL) *theError = blockError;
    return theResult;
}

- (void)saveInBackground
{
    [self saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        
    } progressBlock:^(NSInteger percentDone) {
        
    }];
}

- (void)saveInBackgroundWithBlock:(AVBooleanResultBlock)block
{
    [self saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        [AVUtils callBooleanResultBlock:block error:error];
    } progressBlock:^(NSInteger percentDone) {
        
    }];
}

- (BOOL)hasLocalFile {
    return [[NSFileManager defaultManager] fileExistsAtPath:_localPath] || self.data;
}

- (BOOL)hasExternalURL {
    NSURL *url = [NSURL URLWithString:self.url];
    return url && url.scheme && url.host;
}

- (void)saveInBackgroundWithBlock:(AVBooleanResultBlock)resultBlock
                    progressBlock:(AVProgressBlock)progressBlock
{
    /*
     * If has object id, do nothing.
     * Else, if local file exists, upload file.
     * Else, if has external URL, update the URL.
     * Else, nothing to save, report not found error.
     */
    if (self.objectId) {
        [AVUtils callProgressBlock:progressBlock percent:100];
        [AVUtils callBooleanResultBlock:resultBlock error:nil];
    } else if ([self hasLocalFile]) {
        [self uploadFileWithResultBlock:resultBlock progressBlock:progressBlock];
    } else if ([self hasExternalURL]) {
        [self updateURLWithResultBlock:resultBlock progressBlock:progressBlock];
    } else {
        [AVUtils callBooleanResultBlock:resultBlock error:[AVErrorUtils fileNotFoundError]];
    }
}

- (void)uploadFileWithResultBlock:(AVBooleanResultBlock)resultBlock progressBlock:(AVProgressBlock)progressBlock {
    __weak typeof(self) ws=self;
    [[AVUploaderManager sharedInstance] uploadWithAVFile:self progressBlock:progressBlock resultBlock:^(BOOL succeeded, NSError *error) {
        if (!succeeded) {
            [ws deleteInBackground];
        } else {
            ws.isDirty = NO;
        }
        resultBlock(succeeded,error);
    }];
}

- (void)updateURLWithResultBlock:(AVBooleanResultBlock)resultBlock progressBlock:(AVProgressBlock)progressBlock {
    NSDictionary *parameters = [AVFile dictionaryFromFile:self];

    __weak typeof(self) ws = self;
    [[AVPaasClient sharedInstance] postObject:@"files" withParameters:parameters block:^(NSDictionary *result, NSError *error) {
         if (!error) {
             ws.isDirty = NO;
             ws.objectId = result[@"objectId"];
             [AVUtils callProgressBlock:progressBlock percent:100];
         }
         [AVUtils callBooleanResultBlock:resultBlock error:error];
     }];
}

- (void)saveInBackgroundWithTarget:(id)target selector:(SEL)selector
{
    [self saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        [AVUtils performSelectorIfCould:target selector:selector object:@(succeeded) object:error];
    } progressBlock:^(NSInteger percentDone) {
    }];
}

- (NSData *)getData
{
    return [self getData:nil];
}

- (NSInputStream *)getDataStream
{
    return [self getDataStream:nil];
}

- (NSData *)getData:(NSError **)error
{
    if (self.data) {
        return self.data;
    }
    
    if ([AVPersistenceUtils fileExist:self.localPath]) {
        [self updateDataFromLocalFile];
        return self.data;
    }
    
    if (self.url) {
        self.data = [NSData dataWithContentsOfURL:[NSURL URLWithString:self.url]];
        if (self.data) [AVFile saveData:self.data withRemotePath:self.url];
        return self.data;
    }
    
    if (error) {
        *error = [AVErrorUtils fileNotFoundError];
    }
    return nil;
}

- (BOOL)isDataAvailable {
    return self.data != nil || [AVPersistenceUtils fileExist:self.localPath];
}

- (NSInputStream *)getDataStream:(NSError **)error
{
    NSString *path = self.localPath;
    if (![AVPersistenceUtils fileExist:path])
    {
        if (error) {
            *error = [AVErrorUtils fileNotFoundError];
        }
        return nil;
    }
    NSInputStream * inputStream = [[NSInputStream alloc] initWithFileAtPath:path];
    return inputStream;
}

- (void)getDataInBackgroundWithBlock:(AVDataResultBlock)block
{
    [self getDataInBackgroundWithBlock:block progressBlock:NULL];
}

- (void)getDataInBackgroundWithBlock:(AVDataResultBlock)resultBlock
                       progressBlock:(AVProgressBlock)progressBlock
{
    [self checkAndDownloadFile:^(BOOL succeeded, NSError *error) {
        if (succeeded)
        {
            [self updateDataFromLocalFile];
            if (resultBlock) resultBlock(self.data, nil);
        }
        else
        {
            if (resultBlock) resultBlock(nil, error);
        }
    } progressBlock:^(NSInteger percentDone) {
        if (progressBlock) progressBlock(percentDone);
    }];
}

- (void)getDataStreamInBackgroundWithBlock:(AVDataStreamResultBlock)block
{
    [self getDataStreamInBackgroundWithBlock:^(NSInputStream *stream, NSError *error) {
        if (block) block(stream, error);
    } progressBlock:NULL];
}

- (void)getDataStreamInBackgroundWithBlock:(AVDataStreamResultBlock)resultBlock
                             progressBlock:(AVProgressBlock)progressBlock
{
    [self downloadFileImpl:^(BOOL succeeded, NSError *error) {
        NSString *path = self.localPath;
        NSInputStream * inputStream = [[NSInputStream alloc] initWithFileAtPath:path];
        if (resultBlock) resultBlock(inputStream, nil);
    } progressBlock:^(NSInteger percentDone) {
        if (progressBlock) progressBlock(percentDone);
    }];
}

- (void)getDataInBackgroundWithTarget:(id)target selector:(SEL)selector
{
    [self getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        [AVUtils performSelectorIfCould:target selector:selector object:data object:error];
    }];
}

- (void)cancel
{
    [self.downloadOperation cancel];
    [[AVUploaderManager sharedInstance] cancelWithLocalPath:self.localPath];
}

#pragma mark - Private Methods

- (void)addACLToDict:(NSMutableDictionary *)dict {
    if (self.ACL == nil) {
        self.ACL = [AVPaasClient sharedInstance].updatedDefaultACL;
    }
    if (self.ACL) {
        [dict setObject:[AVObjectUtils dictionaryFromACL:self.ACL] forKey:ACLTag];
    }
}

- (NSString *)mimeType
{
    NSString * type = nil;
    if (self.name.length > 0) {
        type = [AVUtils MIMEType:self.name];
    } else if (self.localPath.length > 0) {
        type = [AVUtils MIMETypeFromPath:self.localPath];
    } else if (self.data.length > 0) {
        type = [AVUtils contentTypeForImageData:self.data];
    } else if (self.url) {
        type = [AVUtils MIMEType:self.url];
    }
    if (type != nil) {
        return type;
    }
    return @"application/octet-stream";
}

-(NSDictionary *)updateMetaData
{
    if ([self.metaData objectForKey:ownerTag] == nil) {
        NSString * objectId = [AVPaasClient sharedInstance].currentUser.objectId;
        if (objectId.length > 0) {
            [self.metaData setObject:objectId forKey:ownerTag];
        }
    }
    
    if ([self.metaData objectForKey:fileSizeTag] == nil) {
        if (self.data.length > 0) {
            [self.metaData setObject:@(self.data.length) forKey:fileSizeTag];
        }
    }

    if ([self.metaData objectForKey:fileMd5Tag] == nil) {
        if (self.localPath.length > 0) {
            NSString *md5= [AVUtils MD5ForFile:self.localPath];
            if (md5) {
                [self.metaData setObject:md5 forKey:fileMd5Tag];
            }
        }
    }
    return self.metaData;
}

-(void)updateDataFromLocalFile
{
    NSString *path = self.localPath;
    if ([AVPersistenceUtils fileExist:path])
    {
        NSError *error = nil;
        self.data = [[NSData alloc] initWithContentsOfFile:path options:NSDataReadingMapped error:&error];
//        self.data = [[NSData alloc] initWithContentsOfMappedFile:path];
//        self.data = [NSData dataWithContentsOfFile:path];
    }
}

-(void)checkAndDownloadFile:(AVBooleanResultBlock)resultBlock
              progressBlock:(AVProgressBlock)progressBlock
{
    if ([AVPersistenceUtils fileExist:self.localPath]) {
        NSError *error = nil;
        NSDictionary *dict = [[NSFileManager defaultManager] attributesOfItemAtPath:self.localPath error:&error];
        if (!error) {
            unsigned long long fileSize = [dict fileSize];
            if (fileSize > 0) {
                [self updateDataFromLocalFile];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [AVUtils callProgressBlock:progressBlock percent:100];
                });
                dispatch_async(dispatch_get_main_queue(), ^{
                    [AVUtils callBooleanResultBlock:resultBlock error:nil];
                });
                return;
            }
        }
    }
    [self downloadFileImpl:^(BOOL succeeded, NSError *error) {
        [AVUtils callBooleanResultBlock:resultBlock error:error];
    } progressBlock:^(NSInteger percentDone) {
        [AVUtils callProgressBlock:progressBlock percent:percentDone];
    }];
}

-(void)downloadFileImpl:(AVBooleanResultBlock)resultBlock
          progressBlock:(AVProgressBlock)progressBlock
{
    if (!self.url) {
        if (resultBlock) {
            resultBlock(NO, [AVErrorUtils errorWithCode:kAVErrorProductDownloadFileSystemFailure errorText:@"file url is nil"]);
        }
        return;
    }

    @synchronized(downloadingMap) {
        if (!downloadingMap) {
            downloadingMap = [[NSMutableDictionary alloc] init];
        }
        _CallBack *callback = [[_CallBack alloc] init];
        callback.resultBlock = resultBlock;
        callback.progressBlock = progressBlock;
        NSMutableArray *callbackArray = [downloadingMap objectForKey:self.url];
        if (!callbackArray) {
            callbackArray = [[NSMutableArray alloc] init];
        }
        [callbackArray addObject:callback];
        [downloadingMap setObject:callbackArray forKey:self.url];
        if (callbackArray.count > 1) {
            // 已经有相同的下载任务在执行
            return;
        }
    }
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.url]
                                             cachePolicy:NSURLRequestReloadIgnoringCacheData
                                         timeoutInterval:AVFILE_REQUEST_TIMEOUT];

    _downloadOperation = [[AVHTTPRequestOperation alloc] initWithRequest:request];
    
    NSString * path = self.localPath;
    path = [path stringByAppendingString:@".downloading"];
    [AVPersistenceUtils removeFile:path];
    [AVPersistenceUtils createFile:path];
    self.downloadOperation.outputStream = [NSOutputStream outputStreamToFileAtPath:path append:NO];
    
    AVFile __weak *weakSelf = self;
    void (^downloadComplete)(NSError *error) = ^(NSError *error) {
        @synchronized(downloadingMap) {
            NSMutableArray *array = [downloadingMap objectForKey:weakSelf.url];
            [downloadingMap removeObjectForKey:weakSelf.url];
            for (_CallBack *c in [array copy]) {
                AVBooleanResultBlock resultBlock = c.resultBlock;
                BOOL result = error == nil ? YES : NO;
                if (resultBlock) resultBlock(result, error);
            }
        }
    };
    [self.downloadOperation setCompletionBlockWithSuccess:^(AVHTTPRequestOperation *operation, id responseObject) {
        BOOL shouldSave=YES;
        
        //检查md5
        NSString *correctMd5 =weakSelf.metaData[fileMd5Tag];
        if (correctMd5) {
            shouldSave=[correctMd5 isEqualToString:[AVUtils MD5ForFile:path]];
        }
        if (shouldSave) {
            NSError *error = nil;
            [[NSFileManager defaultManager] moveItemAtPath:path toPath:weakSelf.localPath error:&error];
            if (error) {
                weakSelf.data = nil;
                downloadComplete(error);
            } else {
                downloadComplete(nil);
            }
        } else {
            //文件下载错误
            downloadComplete([AVErrorUtils errorWithCode:kAVErrorProductDownloadFileSystemFailure errorText:@"file checksum incorrect"]);
        }
        
    } failure:^(AVHTTPRequestOperation *operation, NSError *error) {
        weakSelf.data = nil;
        downloadComplete(error);
    }];
    
    void (^downloadProgress)(NSInteger) = ^(NSInteger percentDone){
        @synchronized(downloadingMap) {
            NSMutableArray *array = [downloadingMap objectForKey:weakSelf.url];
            for (_CallBack *c in [array copy]) {
                AVProgressBlock progressBlock = c.progressBlock;
                if (progressBlock) progressBlock(percentDone);
            }
        }
    };
    
    self.onceCallGetFileSize = NO;
    
    [self.downloadOperation setDownloadProgressBlock:^(AVURLConnectionOperation *operation, NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        
        @synchronized(downloadingMap) {
            BOOL __block hasProgressBlock = NO;
            NSMutableArray *array = [downloadingMap objectForKey:weakSelf.url];
            for (_CallBack *c in [array copy]) {
                if (c.progressBlock) {
                    hasProgressBlock = YES;
                    break;
                }
            }
            if (hasProgressBlock == NO) {
                return;
            }
        }
        
        if (totalBytesExpectedToRead == NSURLResponseUnknownLength) {
            // https://github.com/leancloud/paas/issues/793
            [weakSelf getFileSizeWithBlock:^(long long fileSize) {
                if (fileSize > 0) {
                    NSInteger percentDone = (NSInteger)((double)totalBytesRead * 100 / (double)fileSize);
                    downloadProgress(percentDone);
                }
            }];
        } else {
            NSInteger percentDone = (NSInteger)((double)totalBytesRead * 100 / (double)totalBytesExpectedToRead);
            downloadProgress(percentDone);
        }
    }];
    [self.downloadOperation start];
}

typedef void (^AVFileSizeBlock)(long long fileSize);
- (void)getFileSizeWithBlock:(AVFileSizeBlock)block {
    if (self.size > 0 || self.onceCallGetFileSize) {
        block(self.size);
    } else {
        self.onceCallGetFileSize = YES;
        if (self.bucket.length == 0) {
            block(0);
        } else {
            // 七牛文件
            NSURL *URL = [NSURL URLWithString:self.url];
            if (URL.query.length > 0) {
                // 有其它 query 参数
                // See https://github.com/leancloud/ios-sdk/pull/446#discussion_r42840988
                block(0);
            } else {
                NSString *statUrl = [NSString stringWithFormat:@"%@?stat", self.url];
                [[AVPaasClient sharedInstance] getObject:statUrl withParameters:nil block:^(id object, NSError *error) {
                    if (error) {
                        block(0);
                    } else {
                        if (object[@"fsize"] == nil) {
                            AVLoggerInfo(AVLoggerDomainStorage, @"Qiniu ?stat route should return fsize data");
                            block(0);
                        } else {
                            long long fsize = [object[@"fsize"] longLongValue];
                            self.metaData[@"size"] = @(fsize);
                            block(fsize);
                        }
                    }
                }];
            }
        }
    }
}

+ (void)saveData:(NSData *)data withRemotePath:(NSString *)remotePath {
    NSParameterAssert(data);
    NSParameterAssert(remotePath);

    // maybe self.localPath == realLocalPath, maybe not
    NSString *realLocalPath = [[AVPersistenceUtils avFileDirectory] stringByAppendingPathComponent:[remotePath AVMD5String]];
    if (![AVPersistenceUtils fileExist:realLocalPath]) {
        [data writeToFile:realLocalPath atomically:YES];
    }
}

+ (void)saveDataWithPath:(NSString *)localPath withRemotePath:(NSString *)remotePath {
    NSParameterAssert(localPath);
    NSParameterAssert(remotePath);
    
    // maybe self.localPath == realLocalPath, maybe not
    NSString *realLocalPath = [[AVPersistenceUtils avFileDirectory] stringByAppendingPathComponent:[remotePath AVMD5String]];
    if (![AVPersistenceUtils fileExist:realLocalPath]) {
        [[NSFileManager defaultManager] copyItemAtPath:localPath toPath:remotePath error:NULL];
    }
}

+ (void)cacheFile:(AVFile *)file {
    NSString *url = file.url;
    NSString *realLocalPath = [[AVPersistenceUtils avFileDirectory] stringByAppendingPathComponent:[url AVMD5String]];
    if (file.cachePath && ![file.cachePath isEqualToString:realLocalPath]) {
        [[NSFileManager defaultManager] moveItemAtPath:file.cachePath toPath:realLocalPath error:NULL];
        file.cachePath = realLocalPath;
    }
    if (![AVPersistenceUtils fileExist:realLocalPath]) {
        NSData *data = file.data;
        [data writeToFile:realLocalPath atomically:YES];
    }

}

#pragma mark - Local Cache 
- (void)clearCachedFile
{
    if (self.url) {
        NSString *realLocalPath = [[AVPersistenceUtils avFileDirectory] stringByAppendingPathComponent:[self.url AVMD5String]];
        [AVPersistenceUtils removeFile:realLocalPath];
    }
    
    // remove local path file anyway, though maybe already removed
    [AVPersistenceUtils removeFile:self.localPath];
}

+ (BOOL)clearAllCachedFiles {
    BOOL ret = [[NSFileManager defaultManager] removeItemAtPath:[AVPersistenceUtils avFileDirectory] error:NULL];
    [[NSFileManager defaultManager] createDirectoryAtPath:[AVPersistenceUtils avFileDirectory]
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:NULL];
    return ret;
}

+ (BOOL)clearCacheMoreThanDays:(NSInteger)numberOfDays {
    return [AVPersistenceUtils deleteFilesInDirectory:[AVPersistenceUtils avFileDirectory] moreThanDays:numberOfDays];
}

#pragma mark - JSON <-> Object
/*
 // from qiniu
 {
    "__type": "File",
    "bucket": "x5ocz6du3qyn5jiay7xw",
    "createdAt": "2013-05-23T07:38:18.000Z",
    "key": "8dyu9yShs6hi47co",
    "mime_type": "application/octet-stream",
    "name": "sample.apk",
    "objectId": "519dc76ae4b034b9cc5170a8",
    "updatedAt": "2013-05-23T07:38:18.000Z"
 }
 
 // from s3
 {
    "__type": "File",
    "createdAt": "2013-05-27T07:10:52.000Z",
    "objectId": "51a306fce4b06e53feb1d95f",
    "updatedAt": "2013-05-27T07:10:52.000Z",
    "name" : "b60b1e29-5314-4538-9759-2cb6d6c74185",
    "url": "https://s3-ap-northeast-1.amazonaws.com/avos-cloud/b60b1e29-5314-4538-9759-2cb6d6c74185"
 }
 */
+ (AVFile *)fileFromDictionary:(NSDictionary *)dict
{
    AVFile * file = [[AVFile alloc] init];

    [AVUtils copyPropertiesFromDictionary:dict toNSObject:file];

    if (!file.objectId) {
        if (dict[@"id"]) {
            file.objectId = dict[@"id"];
        } else if (dict[@"objId"]) {
            file.objectId = dict[@"objId"];
        }
    }

    if ([dict objectForKey:@"metaData"]) {
        file.metaData = [dict objectForKey:@"metaData"];
    } else if ([dict objectForKey:@"metadata"]) {
        file.metaData = [dict objectForKey:@"metadata"];
    }
    
    if ([dict objectForKey:ACLTag]) {
        file.ACL = [AVObjectUtils aclFromDictionary:[dict objectForKey:ACLTag]];
    }

    file.isDirty = NO;

    return file;
}

- (NSDictionary *)dictionary {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

    [dictionary setObject:[AVFile className] forKey:@"__type"];

    if (_name)             [dictionary setObject:_name forKey:@"name"];
    if (_objectId)         [dictionary setObject:_objectId forKey:@"id"];
    if (_url)              [dictionary setObject:_url forKey:@"url"];
    if (_localPath)        [dictionary setObject:_localPath forKey:@"localPath"];
    if ([_metaData count]) [dictionary setObject:_metaData forKey:@"metaData"];

    [dictionary setObject:[self mimeType] forKey:@"mime_type"];

    [self addACLToDict:dictionary];

    return dictionary;
}

+ (NSDictionary *)dictionaryFromFile:(AVFile *)file
{
    return [file dictionary];
}

+ (NSString *)className
{
    return @"File";
}

+(NSString *)objectPath:(NSString *)objectId
{
    if (objectId.length > 0) {
        return [NSString stringWithFormat:@"classes/_file/%@", objectId];
    }
    return [NSString stringWithFormat:@"classes/_file"];
}

+ (void)getFileWithObjectId:(NSString*)objectId
                  withBlock:(AVFileResultBlock)block
{
    [[AVPaasClient sharedInstance]
        getObject:[AVFile objectPath:objectId]
        withParameters:nil
                 block:^(id object, NSError* error) {
                     if (error == nil) {
                         AVFile* file = [[AVFile alloc] init];
                         [AVUtils copyPropertiesFromDictionary:object toNSObject:file];
                         if (file.objectId.length > 0) {
                             file.isDirty = NO;
                             [AVUtils callFileResultBlock:block AVFile:file error:error];
                         }
                         else {
                             [AVUtils callFileResultBlock:block AVFile:nil error:[AVErrorUtils errorWithCode:kAVErrorObjectNotFound]];
                         }
                     }
                     else {
                         [AVUtils callFileResultBlock:block AVFile:nil error:error];
                     }
                 }];
}

#define QINIU_THUMBNAIL_FORMAT @"%@?imageView/%d/w/%d/h/%d/q/%d"

- (NSString *)getThumbnailURLWithScaleToFit:(BOOL)scaleToFit
                                      width:(int)width
                                     height:(int)height
                                    quality:(int)quality
                                     format:(NSString *)format
{
    if (width < 0) {
        [NSException raise:NSInvalidArgumentException format:@"Invalid thumbnail width."];
    }

    if (height < 0) {
        [NSException raise:NSInvalidArgumentException format:@"Invalid thumbnail height."];
    }

    if (quality < 1 || quality > 100) {
        [NSException raise:NSInvalidArgumentException format:@"Invalid quality, valid range is 1 - 100."];
    }

    int mode = scaleToFit ? 2 : 1;

    NSString *url = [NSString stringWithFormat:QINIU_THUMBNAIL_FORMAT, self.url, mode, width, height, quality];

    format = [format stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if ([format length]) {
        url = [NSString stringWithFormat:@"%@/format/%@", url, format];
    }

    return url;
}

- (NSString *)getThumbnailURLWithScaleToFit:(BOOL)scaleToFit
                                      width:(int)width
                                     height:(int)height
{
    return [self getThumbnailURLWithScaleToFit:scaleToFit width:width height:height quality:100 format:nil];
}

-(void)getThumbnail:(BOOL)scaleToFit
              width:(int)width
             height:(int)height
          withBlock:(AVImageResultBlock)block
{
    NSString *url = [self getThumbnailURLWithScaleToFit:scaleToFit width:width height:height];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    AVImageRequestOperation * operation = [AVImageRequestOperation imageRequestOperationWithRequest:request imageProcessingBlock:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        [AVUtils callImageResultBlock:block image:image error:nil];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        [AVUtils callImageResultBlock:block image:nil error:error];
    }];
    [[AVPaasClient sharedInstance].clientImpl enqueueHTTPRequestOperation:operation];
}

-(void)setOwnerId:(NSString *)ownerId
{
    [self.metaData setObject:ownerId forKey:ownerTag];
}

-(NSString *)ownerId
{
    return [self.metaData objectForKey:ownerTag];
}

-(NSUInteger)size {
    id object = [self.metaData objectForKey:fileSizeTag];
    if (object != nil) {
        return [object unsignedIntegerValue];
    }
    if (self.data.length > 0) {
        return self.data.length;
    }
    return 0;
}

-(NSString *)pathExtension {
    if (self.url.length > 0) {
        return [self.url pathExtension];
    } else if (self.name.length > 0) {
        return [self.name pathExtension];
    } else if (_localPath.length > 0) {
        return [_localPath pathExtension];
    }
    return nil;
}

- (void)deleteInBackgroundWithBlock:(AVBooleanResultBlock)block
{
    [[AVPaasClient sharedInstance] deleteObject:[AVFile objectPath:self.objectId]
                                 withParameters:nil
                                          block:^(id object, NSError *error) {
                                              [AVUtils callBooleanResultBlock:block error:error];
                                          }];
}

- (void)deleteInBackground {
    [self deleteInBackgroundWithBlock:nil];
}

+ (AVQuery *)query {
    return [AVFileQuery query];
}

@end
