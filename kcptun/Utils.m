//
//  QRCodeUtils.m
//  ShadowsocksX-NG
//
//  Created by 邱宇舟 on 16/6/8.
//  Copyright © 2016年 qiuyuzhou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreImage/CoreImage.h>

void ScanQRCodeOnScreen() {
    /* displays[] Quartz display ID's */
    CGDirectDisplayID   *displays = nil;
    
    CGError             err = CGDisplayNoErr;
    CGDisplayCount      dspCount = 0;
    
    /* How many active displays do we have? */
    err = CGGetActiveDisplayList(0, NULL, &dspCount);
    
    /* If we are getting an error here then their won't be much to display. */
    if(err != CGDisplayNoErr)
    {
        NSLog(@"Could not get active display count (%d)\n", err);
        return;
    }
    
    /* Allocate enough memory to hold all the display IDs we have. */
    displays = calloc((size_t)dspCount, sizeof(CGDirectDisplayID));
    
    // Get the list of active displays
    err = CGGetActiveDisplayList(dspCount,
                                 displays,
                                 &dspCount);
    
    /* More error-checking here. */
    if(err != CGDisplayNoErr)
    {
        NSLog(@"Could not get active display list (%d)\n", err);
        return;
    }
    
    NSMutableArray* foundSSUrls = [NSMutableArray array];
    
    CIDetector *detector = [CIDetector detectorOfType:@"CIDetectorTypeQRCode"
                                              context:nil
                                              options:@{ CIDetectorAccuracy:CIDetectorAccuracyHigh }];
    
    for (unsigned int displaysIndex = 0; displaysIndex < dspCount; displaysIndex++)
    {
        /* Make a snapshot image of the current display. */
        CGImageRef image = CGDisplayCreateImage(displays[displaysIndex]);
        NSArray *features = [detector featuresInImage:[CIImage imageWithCGImage:image]];
        for (CIQRCodeFeature *feature in features) {
            NSLog(@"%@", feature.messageString);
            if ( [feature.messageString hasPrefix:@"ss://"] )
            {
                [foundSSUrls addObject:[NSURL URLWithString:feature.messageString]];
            }
        }
    }
    
    free(displays);
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"NOTIFY_FOUND_SS_URL"
     object:nil
     userInfo: @{ @"urls": foundSSUrls,
                  @"source": @"qrcode"
                 }
     ];
}

// 解析SS URL，如果成功则返回一个与ServerProfile类兼容的dict
NSDictionary<NSString *, id>* ParseSSURL(NSURL* url) {
    if (!url || !url.host) {
        return nil;
    }
    
    NSString *urlString = [url absoluteString];
    NSString *errorReason = nil;
    
    NSString* host = url.host;
    if ([host length]%4!=0) {
        int n = 4 - [host length]%4;
        if (1==n) {
            host = [host stringByAppendingString:@"="];
        } else if (2==n) {
            host = [host stringByAppendingString:@"=="];
        }
    }
    
    NSData *data = [[NSData alloc] initWithBase64EncodedString:host options:0];
    NSString *decodedString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    urlString = decodedString;
    
    urlString = [urlString stringByReplacingOccurrencesOfString:@"ss://" withString:@"" options:NSAnchoredSearch range:NSMakeRange(0, urlString.length)];
    
    if (!urlString || urlString.length == 0) {
        errorReason = @"invalid url";
        return nil;
    }
    
    NSArray* args = [urlString componentsSeparatedByString:@"|"];
    if (args.count != 4) {
        errorReason = @"nvalid url";
        return nil;
    }
    
    NSArray* hostData = [[args objectAtIndex:0] componentsSeparatedByString:@":"];
    if (hostData.count != 2) {
        errorReason = @"nvalid url";
        return nil;
    }
    
    NSString *IP = [hostData objectAtIndex:0];
    NSString *Port = [hostData objectAtIndex:1];
    
    NSString *Crypt = [args objectAtIndex:1];
    NSString *Key = [args objectAtIndex:2];
    NSString *Nocomp = [args objectAtIndex:3];
    
    return @{@"ServerHost": IP,
             @"ServerPort": @([Port integerValue]),
             @"Crypt": Crypt,
             @"Key": Key,
             @"Nocomp": @([Nocomp isEqual: @"1"]),
             };
    
    return nil;
}
