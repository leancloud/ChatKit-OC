// AVImageRequestOperation.m
//
// Copyright (c) 2011 Gowalla (http://gowalla.com/)
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "AVImageRequestOperation.h"

static dispatch_queue_t AV_image_request_operation_processing_queue;
static dispatch_queue_t image_request_operation_processing_queue() {
    if (AV_image_request_operation_processing_queue == NULL) {
        AV_image_request_operation_processing_queue = dispatch_queue_create("cn.leancloud.networking.image-request.processing", 0);
    }
    
    return AV_image_request_operation_processing_queue;
}

@interface AVImageRequestOperation ()
#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
@property (readwrite, nonatomic, strong) UIImage *responseImage;
#elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
@property (readwrite, nonatomic, strong) NSImage *responseImage;
#endif
@end

@implementation AVImageRequestOperation
@synthesize responseImage = _responseImage;
#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
@synthesize imageScale = _imageScale;
#endif

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
+ (instancetype)imageRequestOperationWithRequest:(NSURLRequest *)urlRequest                
										 success:(void (^)(UIImage *image))success
{
    return [self imageRequestOperationWithRequest:urlRequest imageProcessingBlock:nil success:^(NSURLRequest __unused *request, NSHTTPURLResponse __unused *response, UIImage *image) {
        if (success) {
            success(image);
        }
    } failure:nil];
}
#elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
+ (instancetype)imageRequestOperationWithRequest:(NSURLRequest *)urlRequest                
										 success:(void (^)(NSImage *image))success
{
    return [self imageRequestOperationWithRequest:urlRequest imageProcessingBlock:nil success:^(NSURLRequest __unused *request, NSHTTPURLResponse __unused *response, NSImage *image) {
        if (success) {
            success(image);
        }
    } failure:nil];
}
#endif


#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
+ (instancetype)imageRequestOperationWithRequest:(NSURLRequest *)urlRequest
							imageProcessingBlock:(UIImage *(^)(UIImage *))imageProcessingBlock
										 success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image))success
										 failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure
{
    AVImageRequestOperation *requestOperation = [[AVImageRequestOperation alloc] initWithRequest:urlRequest];
    [requestOperation setCompletionBlockWithSuccess:^(AVHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            UIImage *image = responseObject;
            if (imageProcessingBlock) {
                dispatch_async(image_request_operation_processing_queue(), ^(void) {
                    UIImage *processedImage = imageProcessingBlock(image);

                    dispatch_async(operation.successCallbackQueue ?: dispatch_get_main_queue(), ^(void) {
                        success(operation.request, operation.response, processedImage);
                    });
                });
            } else {
                success(operation.request, operation.response, image);
            }
        }
    } failure:^(AVHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(operation.request, operation.response, error);
        }
    }];
    
    
    return requestOperation;
}
#elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
+ (instancetype)imageRequestOperationWithRequest:(NSURLRequest *)urlRequest
							imageProcessingBlock:(NSImage *(^)(NSImage *))imageProcessingBlock
										 success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSImage *image))success
										 failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure
{
    AVImageRequestOperation *requestOperation = [[AVImageRequestOperation alloc] initWithRequest:urlRequest];
    [requestOperation setCompletionBlockWithSuccess:^(AVHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            NSImage *image = responseObject;
            if (imageProcessingBlock) {
                dispatch_async(image_request_operation_processing_queue(), ^(void) {
                    NSImage *processedImage = imageProcessingBlock(image);

                    dispatch_async(operation.successCallbackQueue ?: dispatch_get_main_queue(), ^(void) {
                        success(operation.request, operation.response, processedImage);
                    });
                });
            } else {
                success(operation.request, operation.response, image);
            }
        }
    } failure:^(AVHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(operation.request, operation.response, error);
        }
    }];
    
    return requestOperation;
}
#endif

- (id)initWithRequest:(NSURLRequest *)urlRequest {
    self = [super initWithRequest:urlRequest];
    if (!self) {
        return nil;
    }

#if TARGET_OS_WATCH
    self.imageScale = [WKInterfaceDevice currentDevice].screenScale;
#elif defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
    self.imageScale = [[UIScreen mainScreen] scale];
#endif
    
    return self;
}


#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
- (UIImage *)responseImage {
    if (!_responseImage && [self.responseData length] > 0 && [self isFinished]) {
        UIImage *image = [UIImage imageWithData:self.responseData];
        
        self.responseImage = [UIImage imageWithCGImage:[image CGImage] scale:self.imageScale orientation:image.imageOrientation];
    }
    
    return _responseImage;
}

- (void)setImageScale:(CGFloat)imageScale {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wfloat-equal"
    if (imageScale == _imageScale) {
        return;
    }
#pragma clang diagnostic pop
    
    _imageScale = imageScale;
    
    self.responseImage = nil;
}
#elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
- (NSImage *)responseImage {
    if (!_responseImage && [self.responseData length] > 0 && [self isFinished]) {
        // Ensure that the image is set to it's correct pixel width and height
        NSBitmapImageRep *bitimage = [[NSBitmapImageRep alloc] initWithData:self.responseData];
        self.responseImage = [[NSImage alloc] initWithSize:NSMakeSize([bitimage pixelsWide], [bitimage pixelsHigh])];
        [self.responseImage addRepresentation:bitimage];
    }
    
    return _responseImage;
}
#endif

#pragma mark - AVHTTPRequestOperation

+ (NSSet *)acceptableContentTypes {
    return [NSSet setWithObjects:@"image/tiff", @"image/jpeg", @"image/gif", @"image/png", @"image/ico", @"image/x-icon", @"image/bmp", @"image/x-bmp", @"image/x-xbitmap", @"image/x-win-bitmap", nil];
}

+ (BOOL)canProcessRequest:(NSURLRequest *)request {
    static NSSet * _acceptablePathExtension = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _acceptablePathExtension = [[NSSet alloc] initWithObjects:@"tif", @"tiff", @"jpg", @"jpeg", @"gif", @"png", @"ico", @"bmp", @"cur", nil];
    });
    
    return [_acceptablePathExtension containsObject:[[request URL] pathExtension]] || [super canProcessRequest:request];    
}

- (void)setCompletionBlockWithSuccess:(void (^)(AVHTTPRequestOperation *operation, id responseObject))success
                              failure:(void (^)(AVHTTPRequestOperation *operation, NSError *error))failure
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
    self.completionBlock = ^ {
        dispatch_async(image_request_operation_processing_queue(), ^(void) {
            if (self.error) {
                if (failure) {
                    dispatch_async(self.failureCallbackQueue ?: dispatch_get_main_queue(), ^{
                        failure(self, self.error);
                    });
                }
            } else {            
                if (success) {
#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
                    UIImage *image = nil;
#elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
                    NSImage *image = nil;
#endif

                    image = self.responseImage;

                    dispatch_async(self.successCallbackQueue ?: dispatch_get_main_queue(), ^{
                        success(self, image);
                    });
                }
            }
        });        
    };
#pragma clang diagnostic pop
}

@end


////
//// Copyright (c) 2011 Gowalla (http://gowalla.com/)
////
//// Permission is hereby granted, free of charge, to any person obtaining a copy
//// of this software and associated documentation files (the "Software"), to deal
//// in the Software without restriction, including without limitation the rights
//// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//// copies of the Software, and to permit persons to whom the Software is
//// furnished to do so, subject to the following conditions:
////
//// The above copyright notice and this permission notice shall be included in
//// all copies or substantial portions of the Software.
////
//// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//// THE SOFTWARE.
//
//#import <Foundation/Foundation.h>
//#import <objc/runtime.h>
//
//#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
//
//@interface AVImageCache : NSCache
//- (UIImage *)cachedImageForRequest:(NSURLRequest *)request;
//- (void)cacheImage:(UIImage *)image
//        forRequest:(NSURLRequest *)request;
//@end
//
//#pragma mark -
//
//static char kAVImageRequestOperationObjectKey;
//
//@interface UIImageView (_AVNetworking)
//@property (readwrite, nonatomic, strong, setter = af_setImageRequestOperation:) AVImageRequestOperation *af_imageRequestOperation;
//@end
//
//@implementation UIImageView (_AVNetworking)
//@dynamic af_imageRequestOperation;
//@end
//
//#pragma mark -
//
//@implementation UIImageView (AVNetworking)
//
//- (AVHTTPRequestOperation *)af_imageRequestOperation {
//    return (AVHTTPRequestOperation *)objc_getAssociatedObject(self, &kAVImageRequestOperationObjectKey);
//}
//
//- (void)af_setImageRequestOperation:(AVImageRequestOperation *)imageRequestOperation {
//    objc_setAssociatedObject(self, &kAVImageRequestOperationObjectKey, imageRequestOperation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
//}
//
//+ (NSOperationQueue *)af_sharedImageRequestOperationQueue {
//    static NSOperationQueue *_af_imageRequestOperationQueue = nil;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        _af_imageRequestOperationQueue = [[NSOperationQueue alloc] init];
//        [_af_imageRequestOperationQueue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];
//    });
//    
//    return _af_imageRequestOperationQueue;
//}
//
//+ (AVImageCache *)af_sharedImageCache {
//    static AVImageCache *_af_imageCache = nil;
//    static dispatch_once_t oncePredicate;
//    dispatch_once(&oncePredicate, ^{
//        _af_imageCache = [[AVImageCache alloc] init];
//    });
//    
//    return _af_imageCache;
//}
//
//#pragma mark -
//
//- (void)setImageWithURL:(NSURL *)url {
//    [self setImageWithURL:url placeholderImage:nil];
//}
//
//- (void)setImageWithURL:(NSURL *)url
//       placeholderImage:(UIImage *)placeholderImage
//{
//    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
//    [request setHTTPShouldHandleCookies:NO];
//    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
//    
//    [self setImageWithURLRequest:request placeholderImage:placeholderImage success:nil failure:nil];
//}
//
//- (void)setImageWithURLRequest:(NSURLRequest *)urlRequest
//              placeholderImage:(UIImage *)placeholderImage
//                       success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image))success
//                       failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure
//{
//    [self cancelImageRequestOperation];
//    
//    UIImage *cachedImage = [[[self class] af_sharedImageCache] cachedImageForRequest:urlRequest];
//    if (cachedImage) {
//        self.image = cachedImage;
//        self.af_imageRequestOperation = nil;
//        
//        if (success) {
//            success(nil, nil, cachedImage);
//        }
//    } else {
//        self.image = placeholderImage;
//        
//        AVImageRequestOperation *requestOperation = [[AVImageRequestOperation alloc] initWithRequest:urlRequest];
//        [requestOperation setCompletionBlockWithSuccess:^(AVHTTPRequestOperation *operation, id responseObject) {
//            if ([[urlRequest URL] isEqual:[[self.af_imageRequestOperation request] URL]]) {
//                if (success) {
//                    success(operation.request, operation.response, responseObject);
//                } else {
//                    self.image = responseObject;
//                }
//                
//                self.af_imageRequestOperation = nil;
//            }
//            
//            [[[self class] af_sharedImageCache] cacheImage:responseObject forRequest:urlRequest];
//        } failure:^(AVHTTPRequestOperation *operation, NSError *error) {
//            if ([[urlRequest URL] isEqual:[[self.af_imageRequestOperation request] URL]]) {
//                if (failure) {
//                    failure(operation.request, operation.response, error);
//                }
//                
//                self.af_imageRequestOperation = nil;
//            }
//        }];
//        
//        self.af_imageRequestOperation = requestOperation;
//        
//        [[[self class] af_sharedImageRequestOperationQueue] addOperation:self.af_imageRequestOperation];
//    }
//}
//
//- (void)cancelImageRequestOperation {
//    [self.af_imageRequestOperation cancel];
//    self.af_imageRequestOperation = nil;
//}
//
//@end
//
//#pragma mark -
//
//static inline NSString * AVImageCacheKeyFromURLRequest(NSURLRequest *request) {
//    return [[request URL] absoluteString];
//}
//
//@implementation AVImageCache
//
//- (UIImage *)cachedImageForRequest:(NSURLRequest *)request {
//    switch ([request cachePolicy]) {
//        case NSURLRequestReloadIgnoringCacheData:
//        case NSURLRequestReloadIgnoringLocalAndRemoteCacheData:
//            return nil;
//        default:
//            break;
//    }
//    
//	return [self objectForKey:AVImageCacheKeyFromURLRequest(request)];
//}
//
//- (void)cacheImage:(UIImage *)image
//        forRequest:(NSURLRequest *)request
//{
//    if (image && request) {
//        [self setObject:image forKey:AVImageCacheKeyFromURLRequest(request)];
//    }
//}
//
//@end
//
//#endif