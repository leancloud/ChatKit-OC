// AVJSONRequestOperation.m
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

#import "AVJSONRequestOperation.h"
#import "AVUtils.h"
static dispatch_queue_t AV_json_request_operation_processing_queue;
static dispatch_queue_t json_request_operation_processing_queue() {
    if (AV_json_request_operation_processing_queue == NULL) {
        AV_json_request_operation_processing_queue = dispatch_queue_create("cn.leancloud.networking.json-request.processing", 0);
    }
    
    return AV_json_request_operation_processing_queue;
}

@interface AVJSONRequestOperation ()
@property (readwrite, nonatomic, strong) id responseJSON;
@property (readwrite, nonatomic, strong) NSError *JSONError;
@end

@implementation AVJSONRequestOperation
@synthesize responseJSON = _responseJSON;
@synthesize JSONReadingOptions = _JSONReadingOptions;
@synthesize JSONError = _JSONError;

+ (instancetype)JSONRequestOperationWithRequest:(NSURLRequest *)urlRequest
										success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, id JSON))success
										failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON))failure
{
    AVJSONRequestOperation *requestOperation = [(AVJSONRequestOperation *)[self alloc] initWithRequest:urlRequest];
    [requestOperation setCompletionBlockWithSuccess:^(AVHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(operation.request, operation.response, responseObject);
        }
    } failure:^(AVHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(operation.request, operation.response, error, [(AVJSONRequestOperation *)operation responseJSON]);
        }
    }];
    
    return requestOperation;
}


- (id)responseJSON {
    if (!_responseJSON && [self.responseData length] > 0 && [self isFinished] && !self.JSONError) {
        NSError *error = nil;

        // Workaround for behavior of Rails to return a single space for `head :ok` (a workaround for a bug in SAVari), which is not interpreted as valid input by NSJSONSerialization.
        // See https://github.com/rails/rails/issues/1742
        if ([self.responseData length] == 0 || [self.responseString isEqualToString:@" "]) {
            self.responseJSON = nil;
        } else {
            // Workaround for a bug in NSJSONSerialization when Unicode character escape codes are used instead of the actual character
            // See http://stackoverflow.com/a/12843465/157142
            NSData *JSONData = [self.responseString dataUsingEncoding:self.responseStringEncoding];
            self.responseJSON = [NSJSONSerialization JSONObjectWithData:JSONData options:self.JSONReadingOptions error:&error];
        }
        
        self.JSONError = error;
    }
    
    if ([_responseJSON isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:_responseJSON];
        [self removeNSNullValueFromDictionary:dict];
        _responseJSON = dict;
    }
    return _responseJSON;
}

- (void)removeNSNullValueFromArray:(NSMutableArray *)array {
    NSMutableArray *objToRemove = nil;
    NSMutableIndexSet *indexToReplace = [[NSMutableIndexSet alloc] init];
    NSMutableArray *objForReplace = [[NSMutableArray alloc] init];
    for (int i = 0; i < array.count; ++i) {
        id value = [array objectAtIndex:i];
        if ([value isKindOfClass:[NSNull class]]) {
            if (!objToRemove) {
                objToRemove = [[NSMutableArray alloc] init];
            }
            [objToRemove addObject:value];
        } else if ([value isKindOfClass:[NSDictionary class]]) {
            NSMutableDictionary *mutableDict = [NSMutableDictionary dictionaryWithDictionary:value];
            [self removeNSNullValueFromDictionary:mutableDict];
            [indexToReplace addIndex:i];
            [objForReplace addObject:mutableDict];
        } else if ([value isKindOfClass:[NSArray class]]) {
            NSMutableArray *v = [value mutableCopy];
            [self removeNSNullValueFromArray:v];
            [indexToReplace addIndex:i];
            [objForReplace addObject:v];
        }
    }
    [array replaceObjectsAtIndexes:indexToReplace withObjects:objForReplace];
    if (objToRemove) {
        [array removeObjectsInArray:objToRemove];
    }
}

- (void)removeNSNullValueFromDictionary:(NSMutableDictionary *)dict {
    for (id key in [dict allKeys]) {
        id value = [dict objectForKey:key];
        if ([value isKindOfClass:[NSNull class]]) {
            [dict removeObjectForKey:key];
        } else if ([value isKindOfClass:[NSDictionary class]]) {
            NSMutableDictionary *mutableDict = [NSMutableDictionary dictionaryWithDictionary:value];
            [self removeNSNullValueFromDictionary:mutableDict];
            [dict setObject:mutableDict forKey:key];
        } else if ([value isKindOfClass:[NSArray class]]) {
            NSMutableArray *v = [value mutableCopy];
            [self removeNSNullValueFromArray:v];
            [dict setObject:v forKey:key];
        }
    }
}

- (NSError *)error {
    if (_JSONError) {
        return _JSONError;
    } else {
        return [super error];
    }
}

#pragma mark - AVHTTPRequestOperation

+ (NSSet *)acceptableContentTypes {
    return [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", nil];
}

+ (BOOL)canProcessRequest:(NSURLRequest *)request {
    return [[[request URL] pathExtension] isEqualToString:@"json"] || [super canProcessRequest:request];
}

- (void)setCompletionBlockWithSuccess:(void (^)(AVHTTPRequestOperation *operation, id responseObject))success
                              failure:(void (^)(AVHTTPRequestOperation *operation, NSError *error))failure
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
   self.completionBlock = ^ {
        // NSLog(@"AVJSON completion block");
        if (self.error) {
            if (failure) {
                dispatch_async(self.failureCallbackQueue ?: dispatch_get_main_queue(), ^{
                    failure(self, self.error);
                });
            }
        } else {
            dispatch_async(json_request_operation_processing_queue(), ^{
                id JSON = self.responseJSON;
                
                if (self.JSONError) {
                    if (failure) {
                        dispatch_async(self.failureCallbackQueue ?: dispatch_get_main_queue(), ^{
                            failure(self, self.error);
                        });
                    }
                } else {
                    if (success) {
                        dispatch_async(self.successCallbackQueue ?: dispatch_get_main_queue(), ^{
                            success(self, JSON);
                        });
                    }                    
                }
            });
        }
    };
#pragma clang diagnostic pop
}

@end
