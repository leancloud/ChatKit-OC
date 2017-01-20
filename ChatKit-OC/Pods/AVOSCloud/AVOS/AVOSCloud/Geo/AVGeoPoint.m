//
//  AVGeoPoint.h
//  LeanCloud
//


#import "AVGeoPoint.h"
#import "AVLocationManager.h"
#import <CoreLocation/CoreLocation.h>

@implementation  AVGeoPoint

@synthesize latitude = _latitude;
@synthesize longitude = _longitude;

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];

    if (self) {
        _latitude = [aDecoder decodeDoubleForKey:@"latitude"];
        _longitude = [aDecoder decodeDoubleForKey:@"longitude"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeDouble:_latitude forKey:@"latitude"];
    [aCoder encodeDouble:_longitude forKey:@"longitude"];
}

- (id)copyWithZone:(NSZone *)zone
{
    AVGeoPoint *point = [[[self class] allocWithZone:zone] init];
    point.longitude = self.longitude;
    point.latitude = self.latitude;
    return point;
}

+ (AVGeoPoint *)geoPoint
{
    AVGeoPoint * result = [[AVGeoPoint alloc] init];
    return result;
}

+ (AVGeoPoint *)geoPointWithLocation:(CLLocation *)location
{
    AVGeoPoint * point = [AVGeoPoint geoPoint];
    point.latitude = location.coordinate.latitude;
    point.longitude = location.coordinate.longitude;
    return point;
}

+ (AVGeoPoint *)geoPointWithLatitude:(double)latitude longitude:(double)longitude
{
    AVGeoPoint * point = [AVGeoPoint geoPoint];
    point.latitude = latitude;
    point.longitude = longitude;
    return point;
}

- (CLLocation *)location {
    return [[CLLocation alloc] initWithLatitude:self.latitude longitude:self.longitude];
}

#if AV_IOS_ONLY
+ (void)geoPointForCurrentLocationInBackground:(void(^)(AVGeoPoint *geoPoint, NSError *error))geoPointHandler
{
    [[AVLocationManager sharedInstance] updateWithBlock:geoPointHandler];
}
#endif

- (double)distanceInRadiansTo:(AVGeoPoint*)point
{
    // 6378.140 is the Radius of the earth 
    return ([self distanceInKilometersTo:point] / 6378.140);
}

- (double)distanceInMilesTo:(AVGeoPoint*)point
{
    return [self distanceInKilometersTo:point] / 1.609344;
}

- (double)distanceInKilometersTo:(AVGeoPoint*)point
{
    return [[self location] distanceFromLocation:[point location]] / 1000.0;
}

+(NSDictionary *)dictionaryFromGeoPoint:(AVGeoPoint *)point
{
    return @{ @"__type": @"GeoPoint", @"latitude": @(point.latitude), @"longitude": @(point.longitude) };
}

+(AVGeoPoint *)geoPointFromDictionary:(NSDictionary *)dict
{
    AVGeoPoint * point = [[AVGeoPoint alloc]init];
    point.latitude = [[dict objectForKey:@"latitude"] doubleValue];
    point.longitude = [[dict objectForKey:@"longitude"] doubleValue];
    return point;
}

@end
