//
//  BusylightWrapper.m
//  Busylight
//

#import "BusylightWrapper.h"
#import <BusylightSDK_Swift/BusylightSDK_Swift.h>

@interface BusylightWrapper () <BusylightDelegate>
@property (nonatomic, strong) Busylight *busylight;
@end

@implementation BusylightWrapper

- (instancetype)init {
    self = [super init];
    if (self) {
        _busylight = [[Busylight alloc] init];
        _busylight.delegate = self;
    }
    return self;
}

- (void)start {
    [_busylight start];
}

- (void)stop {
    [_busylight stop];
}

- (NSArray *)getDevicesArray {
    return [_busylight getDevicesArray];
}

- (void)lightWithRed:(uint8_t)red green:(uint8_t)green blue:(uint8_t)blue {
    [_busylight LightWithRed:red green:green blue:blue];
}

- (void)pulseWithRed:(uint8_t)red green:(uint8_t)green blue:(uint8_t)blue {
    [_busylight PulseWithRed:red green:green blue:blue];
}

- (void)blinkWithRed:(uint8_t)red green:(uint8_t)green blue:(uint8_t)blue ontime:(uint8_t)ontime offtime:(uint8_t)offtime {
    [_busylight BlinkWithRed:red green:green blue:blue ontime:ontime offtime:offtime];
}

- (void)alertWithRed:(uint8_t)red green:(uint8_t)green blue:(uint8_t)blue andSound:(uint8_t)sound andVolume:(uint8_t)volume {
    [_busylight AlertWithRed:red green:green blue:blue andSound:sound andVolume:volume];
}

- (void)jingleWithRed:(uint8_t)red green:(uint8_t)green blue:(uint8_t)blue sound:(uint8_t)sound andVolume:(uint8_t)volume {
    [_busylight JingleWithRed:red green:green blue:blue Sound:sound andVolume:volume];
}

- (void)off {
    [_busylight Off];
}

#pragma mark - BusylightDelegate

- (void)deviceConnectedWithDevices:(NSDictionary<NSString *, NSString *> *)devices {
    if ([self.delegate respondsToSelector:@selector(deviceConnected:)]) {
        [self.delegate deviceConnected:devices];
    }
}

- (void)deviceDisconnectedWithDevices:(NSDictionary<NSString *, NSString *> *)devices {
    if ([self.delegate respondsToSelector:@selector(deviceDisconnected:)]) {
        [self.delegate deviceDisconnected:devices];
    }
}

@end
