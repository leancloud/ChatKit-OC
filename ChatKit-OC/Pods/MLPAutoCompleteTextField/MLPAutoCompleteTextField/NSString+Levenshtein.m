//
//  NSString+Levenshtein.m
//
//  Created by Mark Aufflick on 9/11/09.
//  mark@aufflick.com <http://mark.aufflick.com/>
//
//  Based somewhat on the NSString(Levenshtein) code by Rick Bourner
//  rick@bourner.com <http://www.merriampark.com/ldobjc.htm>
//  which in turn implements a variation on the Wagner-Fischer algorithm
//

/*
 
 Copyright (c) 2009, Mark Aufflick
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 * Neither the name of the Mark Aufflick nor the
 names of contributors may be used to endorse or promote products
 derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY MARK AUFFLICK ''AS IS'' AND ANY
 EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL MARK AUFFLICK BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 */

#import "NSString+Levenshtein.h"

// private util function
int smallestOf(int a, int b, int c);

@implementation NSString (Levenshtein)

- (float) asciiLevenshteinDistanceWithString: (NSString *)stringB
{
    return [self asciiLevenshteinDistanceWithString:stringB
                               skippingCharacterSet:nil];
}


- (float) asciiLevenshteinDistanceWithString: (NSString *)stringB skippingCharacterSet: (NSCharacterSet *)charset
{
    // try to convince caller that a nil object is *really* different from any string
    if (!stringB)
        return LEV_INF_DISTANCE;
    
    // strip chars from the requested charset (if any)
    
    NSString *stringA;
    if (charset) {
        stringA = [[self componentsSeparatedByCharactersInSet:charset] componentsJoinedByString:@""];
        stringB = [[stringB componentsSeparatedByCharactersInSet:charset] componentsJoinedByString:@""];
    } else {
        stringA = self;
    }
    
    // converting to ASCII to normalize characters with accents etc.
    // and also so we can use treat the string as an array of char *
    
    NSData *dataA = [stringA dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSData *dataB = [stringB dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    
    // not really cstrings, since not nul terminated
    const char *cstringA = [dataA bytes];
    const char *cstringB = [dataB bytes];
    
    // Calculate Levenshtein distance
    
    // Step 1
    int k, i, j, cost, * d, distance;
    
    int n = [dataA length];
    int m = [dataB length];
    
    if( n++ != 0 && m++ != 0 ) {
        
        d = malloc( sizeof(int) * m * n );
        
        // Step 2
        for( k = 0; k < n; k++)
            d[k] = k;
        
        for( k = 0; k < m; k++)
            d[ k * n ] = k;
        
        // Step 3 and 4
        for( i = 1; i < n; i++ )
            for( j = 1; j < m; j++ ) {
                
                // Step 5
                if( cstringA[i-1] == cstringB[j-1] )
                    cost = 0;
                else
                    cost = 1;
                
                // Step 6
                d[ j * n + i ] = smallestOf( d[ (j - 1) * n + i ] + 1,
                                            d[ j * n + i - 1 ] +  1,
                                            d[ (j - 1) * n + i -1 ] + cost );
            }
        
        distance = d[ n * m - 1 ];
        
        free( d );
        
        return distance;
    }
    return 0.0;
}

// return the minimum of a, b and c
int smallestOf(int a, int b, int c)
{
    int min = a;
    if ( b < min )
        min = b;
    
    if( c < min )
        min = c;
    
    return min;
}


@end