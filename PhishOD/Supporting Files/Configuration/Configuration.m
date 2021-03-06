//
//  Configuration.m
//  Phish Tracks
//
//  From: http://mobile.tutsplus.com/tutorials/iphone/ios-quick-tip-managing-configurations-with-ease/
//
//  Created by Alexander Bird on 10/29/13.
//  Copyright (c) 2013 Alec Gorge. All rights reserved.
//

#import "Configuration.h"

#define ConfigurationStatsApiBaseUrl @"StatsApiBaseUrl"
#define ConfigurationStatsApiKey @"StatsApiKey"

@interface Configuration ()
@property (copy, nonatomic) NSString *configuration;
@property (nonatomic, strong) NSDictionary *variables;
@end

@implementation Configuration

#pragma mark -
#pragma mark Shared Configuration
+ (Configuration *)sharedConfiguration {
    static Configuration *_sharedConfiguration = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        _sharedConfiguration = [[self alloc] init];
    });

    return _sharedConfiguration;
}

#pragma mark -
#pragma mark Private Initialization
- (id)init {
    self = [super init];

    if (self) {
        NSBundle *mainBundle = [NSBundle mainBundle];
        self.configuration = [[mainBundle infoDictionary] objectForKey:@"Configuration"];
        NSString *path = [mainBundle pathForResource:@"Configurations" ofType:@"plist"];
        NSDictionary *configurations = [NSDictionary dictionaryWithContentsOfFile:path];
        self.variables = [configurations objectForKey:self.configuration];
    }
    return self;
}

#pragma mark -
+ (NSString *)configuration {
    return [[Configuration sharedConfiguration] configuration];
}

+ (NSString *)statsApiKey {
    Configuration *sharedConfiguration = [Configuration sharedConfiguration];

    if (sharedConfiguration.variables) {
        return [sharedConfiguration.variables objectForKey:ConfigurationStatsApiKey];
    }

    return nil;
}

+ (NSString *)statsApiBaseUrl {
    Configuration *sharedConfiguration = [Configuration sharedConfiguration];

    if (sharedConfiguration.variables) {
        return [sharedConfiguration.variables objectForKey:ConfigurationStatsApiBaseUrl];
    }

    return nil;
}

@end


