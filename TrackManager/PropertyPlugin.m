//
//  PropertyPlugin.m
//  NiuNiuRent
//
//  Created by Q Z on 2023/7/21.
//

#import "PropertyPlugin.h"
#import "NiuNiuRent-Swift.h"

@implementation PropertyPlugin

- (BOOL)isMatchedWithFilter:(id<SAPropertyPluginEventFilter>)filter {
    return filter.type & SAEventTypeDefault;
}

- (SAPropertyPluginPriority)priority {
    return SAPropertyPluginPriorityDefault;
}

- (NSDictionary<NSString *,id> *)properties {
    NSDictionary *data = [[SensorsAnalyticsSDK sharedInstance] getPresetProperties];
    return @{@"tenant": @"YLA1182365",
             @"deviceId": data[@"$device_id"],
             @"deviceType": @"iOS Phone"
    };
}
@end
