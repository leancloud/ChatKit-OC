// Copyright (C) 2014 by Matthew York
//
// Permission is hereby granted, free of charge, to any
// person obtaining a copy of this software and
// associated documentation files (the "Software"), to
// deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge,
// publish, distribute, sublicense, and/or sell copies of the
// Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall
// be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "LCCKError.h"

#ifndef DateToolsLocalizedStrings
#define DateToolsLocalizedStrings(key) \
NSLocalizedStringFromTableInBundle(key, @"DateTools", [NSBundle bundleWithPath:[[[NSBundle bundleForClass:[LCCKError class]] resourcePath] stringByAppendingPathComponent:@"DateTools.bundle"]], nil)
#endif

#import <Foundation/Foundation.h>
#import "LCCKDateToolsConstants.h"

@interface NSDate (DateTools)

#pragma mark - Time Ago
+ (NSString *)lcck_timeAgoSinceDate:(NSDate *)date;
+ (NSString *)lcck_shortTimeAgoSinceDate:(NSDate *)date;
- (NSString *)lcck_timeAgoSinceNow;
- (NSString *)lcck_shortTimeAgoSinceNow;
- (NSString *)lcck_timeAgoSinceDate:(NSDate *)date;
- (NSString *)lcck_timeAgoSinceDate:(NSDate *)date numericDates:(BOOL)useNumericDates;
- (NSString *)lcck_timeAgoSinceDate:(NSDate *)date numericDates:(BOOL)useNumericDates numericTimes:(BOOL)useNumericTimes;
- (NSString *)lcck_shortTimeAgoSinceDate:(NSDate *)date;


#pragma mark - Date Components Without Calendar
- (NSInteger)lcck_era;
- (NSInteger)lcck_year;
- (NSInteger)lcck_month;
- (NSInteger)lcck_day;
- (NSInteger)lcck_hour;
- (NSInteger)lcck_minute;
- (NSInteger)lcck_second;
- (NSInteger)lcck_weekday;
- (NSInteger)lcck_weekdayOrdinal;
- (NSInteger)lcck_quarter;
- (NSInteger)lcck_weekOfMonth;
- (NSInteger)lcck_weekOfYear;
- (NSInteger)lcck_yearForWeekOfYear;
- (NSInteger)lcck_daysInMonth;
- (NSInteger)lcck_dayOfYear;
- (NSInteger)lcck_daysInYear;
- (BOOL)lcck_isInLeapYear;
- (BOOL)lcck_isToday;
- (BOOL)lcck_isTomorrow;
- (BOOL)lcck_isYesterday;
- (BOOL)lcck_isWeekend;
- (BOOL)lcck_isSameDay:(NSDate *)date;
+ (BOOL)lcck_isSameDay:(NSDate *)date asDate:(NSDate *)compareDate;

#pragma mark - Date Components With Calendar


- (NSInteger)lcck_eraWithCalendar:(NSCalendar *)calendar;
- (NSInteger)lcck_yearWithCalendar:(NSCalendar *)calendar;
- (NSInteger)lcck_monthWithCalendar:(NSCalendar *)calendar;
- (NSInteger)lcck_dayWithCalendar:(NSCalendar *)calendar;
- (NSInteger)lcck_hourWithCalendar:(NSCalendar *)calendar;
- (NSInteger)lcck_minuteWithCalendar:(NSCalendar *)calendar;
- (NSInteger)lcck_secondWithCalendar:(NSCalendar *)calendar;
- (NSInteger)lcck_weekdayWithCalendar:(NSCalendar *)calendar;
- (NSInteger)lcck_weekdayOrdinalWithCalendar:(NSCalendar *)calendar;
- (NSInteger)lcck_quarterWithCalendar:(NSCalendar *)calendar;
- (NSInteger)lcck_weekOfMonthWithCalendar:(NSCalendar *)calendar;
- (NSInteger)lcck_weekOfYearWithCalendar:(NSCalendar *)calendar;
- (NSInteger)lcck_yearForWeekOfYearWithCalendar:(NSCalendar *)calendar;


#pragma mark - Date Creating
+ (NSDate *)lcck_dateWithYear:(NSInteger)year month:(NSInteger)month day:(NSInteger)day;
+ (NSDate *)lcck_dateWithYear:(NSInteger)year month:(NSInteger)month day:(NSInteger)day hour:(NSInteger)hour minute:(NSInteger)minute second:(NSInteger)second;
+ (NSDate *)lcck_dateWithString:(NSString *)dateString formatString:(NSString *)formatString;
+ (NSDate *)lcck_dateWithString:(NSString *)dateString formatString:(NSString *)formatString timeZone:(NSTimeZone *)timeZone;


#pragma mark - Date Editing
#pragma mark Date By Adding
- (NSDate *)lcck_dateByAddingYears:(NSInteger)years;
- (NSDate *)lcck_dateByAddingMonths:(NSInteger)months;
- (NSDate *)lcck_dateByAddingWeeks:(NSInteger)weeks;
- (NSDate *)lcck_dateByAddingDays:(NSInteger)days;
- (NSDate *)lcck_dateByAddingHours:(NSInteger)hours;
- (NSDate *)lcck_dateByAddingMinutes:(NSInteger)minutes;
- (NSDate *)lcck_dateByAddingSeconds:(NSInteger)seconds;
#pragma mark Date By Subtracting
- (NSDate *)lcck_dateBySubtractingYears:(NSInteger)years;
- (NSDate *)lcck_dateBySubtractingMonths:(NSInteger)months;
- (NSDate *)lcck_dateBySubtractingWeeks:(NSInteger)weeks;
- (NSDate *)lcck_dateBySubtractingDays:(NSInteger)days;
- (NSDate *)lcck_dateBySubtractingHours:(NSInteger)hours;
- (NSDate *)lcck_dateBySubtractingMinutes:(NSInteger)minutes;
- (NSDate *)lcck_dateBySubtractingSeconds:(NSInteger)seconds;

#pragma mark - Date Comparison
#pragma mark Time From
-(NSInteger)lcck_yearsFrom:(NSDate *)date;
-(NSInteger)lcck_monthsFrom:(NSDate *)date;
-(NSInteger)lcck_weeksFrom:(NSDate *)date;
-(NSInteger)lcck_daysFrom:(NSDate *)date;
-(double)lcck_hoursFrom:(NSDate *)date;
-(double)lcck_minutesFrom:(NSDate *)date;
-(double)lcck_secondsFrom:(NSDate *)date;
#pragma mark Time From With Calendar
-(NSInteger)lcck_yearsFrom:(NSDate *)date calendar:(NSCalendar *)calendar;
-(NSInteger)lcck_monthsFrom:(NSDate *)date calendar:(NSCalendar *)calendar;
-(NSInteger)lcck_weeksFrom:(NSDate *)date calendar:(NSCalendar *)calendar;
-(NSInteger)lcck_daysFrom:(NSDate *)date calendar:(NSCalendar *)calendar;

#pragma mark Time Until
-(NSInteger)lcck_yearsUntil;
-(NSInteger)lcck_monthsUntil;
-(NSInteger)lcck_weeksUntil;
-(NSInteger)lcck_daysUntil;
-(double)lcck_hoursUntil;
-(double)lcck_minutesUntil;
-(double)lcck_secondsUntil;
#pragma mark Time Ago
-(NSInteger)lcck_yearsAgo;
-(NSInteger)lcck_monthsAgo;
-(NSInteger)lcck_weeksAgo;
-(NSInteger)lcck_daysAgo;
-(double)lcck_hoursAgo;
-(double)lcck_minutesAgo;
-(double)lcck_secondsAgo;
#pragma mark Earlier Than
-(NSInteger)lcck_yearsEarlierThan:(NSDate *)date;
-(NSInteger)lcck_monthsEarlierThan:(NSDate *)date;
-(NSInteger)lcck_weeksEarlierThan:(NSDate *)date;
-(NSInteger)lcck_daysEarlierThan:(NSDate *)date;
-(double)lcck_hoursEarlierThan:(NSDate *)date;
-(double)lcck_minutesEarlierThan:(NSDate *)date;
-(double)lcck_secondsEarlierThan:(NSDate *)date;
#pragma mark Later Than
-(NSInteger)lcck_yearsLaterThan:(NSDate *)date;
-(NSInteger)lcck_monthsLaterThan:(NSDate *)date;
-(NSInteger)lcck_weeksLaterThan:(NSDate *)date;
-(NSInteger)lcck_daysLaterThan:(NSDate *)date;
-(double)lcck_hoursLaterThan:(NSDate *)date;
-(double)lcck_minutesLaterThan:(NSDate *)date;
-(double)lcck_secondsLaterThan:(NSDate *)date;
#pragma mark Comparators
-(BOOL)lcck_isEarlierThan:(NSDate *)date;
-(BOOL)lcck_isLaterThan:(NSDate *)date;
-(BOOL)lcck_isEarlierThanOrEqualTo:(NSDate *)date;
-(BOOL)lcck_isLaterThanOrEqualTo:(NSDate *)date;

#pragma mark - Formatted Dates
#pragma mark Formatted With Style
-(NSString *)lcck_formattedDateWithStyle:(NSDateFormatterStyle)style;
-(NSString *)lcck_formattedDateWithStyle:(NSDateFormatterStyle)style timeZone:(NSTimeZone *)timeZone;
-(NSString *)lcck_formattedDateWithStyle:(NSDateFormatterStyle)style locale:(NSLocale *)locale;
-(NSString *)lcck_formattedDateWithStyle:(NSDateFormatterStyle)style timeZone:(NSTimeZone *)timeZone locale:(NSLocale *)locale;
#pragma mark Formatted With Format
-(NSString *)lcck_formattedDateWithFormat:(NSString *)format;
-(NSString *)lcck_formattedDateWithFormat:(NSString *)format timeZone:(NSTimeZone *)timeZone;
-(NSString *)lcck_formattedDateWithFormat:(NSString *)format locale:(NSLocale *)locale;
-(NSString *)lcck_formattedDateWithFormat:(NSString *)format timeZone:(NSTimeZone *)timeZone locale:(NSLocale *)locale;

#pragma mark - Helpers
+(NSString *)lcck_defaultCalendarIdentifier;
+ (void)lcck_setDefaultCalendarIdentifier:(NSString *)identifier;
@end
