//
//  ProxyConfHelper.m
//  ShadowsocksX-NG
//
//  Created by 邱宇舟 on 16/6/10.
//  Copyright © 2016年 qiuyuzhou. All rights reserved.
//

#import "ProxyConfHelper.h"
#import "proxy_conf_helper_version.h"

#define kShadowsocksHelper @"/Library/Application Support/kcptun/proxy_conf_helper"

@implementation ProxyConfHelper


+ (BOOL)isVersionOk {
    NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath:kShadowsocksHelper];
    
    NSArray *args;
    args = [NSArray arrayWithObjects:@"-v", nil];
    [task setArguments: args];
    
    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    
    NSFileHandle *fd;
    fd = [pipe fileHandleForReading];
    
    [task launch];
    
    NSData *data;
    data = [fd readDataToEndOfFile];
    
    NSString *str;
    str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if (![str isEqualToString:kProxyConfHelperVersion]) {
        return NO;
    }
    return YES;
}

+ (void)install {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:kShadowsocksHelper] || ![self isVersionOk]) {
        NSString *helperPath = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], @"install_helper.sh"];
        NSLog(@"run install script: %@", helperPath);
        NSDictionary *error;
        NSString *script = [NSString stringWithFormat:@"do shell script \"bash %@\" with administrator privileges", helperPath];
        NSAppleScript *appleScript = [[NSAppleScript new] initWithSource:script];
        if ([appleScript executeAndReturnError:&error]) {
            NSLog(@"installation success");
        } else {
            NSLog(@"installation failure");
        }
    }
}

+ (void)callHelper:(NSArray*) arguments {
    NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath:kShadowsocksHelper];

    // this log is very important
    NSLog(@"run shadowsocks helper: %@", kShadowsocksHelper);
    [task setArguments:arguments];

    NSPipe *stdoutpipe;
    stdoutpipe = [NSPipe pipe];
    [task setStandardOutput:stdoutpipe];

    NSPipe *stderrpipe;
    stderrpipe = [NSPipe pipe];
    [task setStandardError:stderrpipe];

    NSFileHandle *file;
    file = [stdoutpipe fileHandleForReading];

    [task launch];

    NSData *data;
    data = [file readDataToEndOfFile];

    NSString *string;
    string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (string.length > 0) {
        NSLog(@"%@", string);
    }

    file = [stderrpipe fileHandleForReading];
    data = [file readDataToEndOfFile];
    string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (string.length > 0) {
        NSLog(@"%@", string);
    }
}

+ (void)addArguments4ManualSpecifyNetworkServices:(NSMutableArray*) args {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    if (![defaults boolForKey:@"AutoConfigureNetworkServices"]) {
        NSArray* serviceKeys = [defaults arrayForKey:@"Proxy4NetworkServices"];
        if (serviceKeys) {
            for (NSString* key in serviceKeys) {
                [args addObject:@"--network-service"];
                [args addObject:key];
            }
        }
    }
}

+ (void)enablePACProxy {
    NSString* urlString = [NSString stringWithFormat:@"%@/.kcptun/gfwlist.js", NSHomeDirectory()];
    NSURL* url = [NSURL fileURLWithPath:urlString];
    
    NSMutableArray* args = [@[@"--mode", @"auto", @"--pac-url", [url absoluteString]]mutableCopy];
    
    [self addArguments4ManualSpecifyNetworkServices:args];
    
    [self callHelper:args];
}

+ (void)enableGlobalProxy {
    NSUInteger port = [[NSUserDefaults standardUserDefaults]integerForKey:@"LocalSocks5.ListenPort"];
    
    NSMutableArray* args = [@[@"--mode", @"global", @"--port"
                              , [NSString stringWithFormat:@"%lu", (unsigned long)port]]mutableCopy];
    
    [self addArguments4ManualSpecifyNetworkServices:args];
    
    [self callHelper:args];
}

+ (void)disableProxy {
    NSMutableArray* args = [@[@"--mode", @"off"]mutableCopy];
    [self addArguments4ManualSpecifyNetworkServices:args];
    [self callHelper:args];
}

@end
