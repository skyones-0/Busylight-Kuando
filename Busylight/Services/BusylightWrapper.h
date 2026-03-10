//
//  BusylightWrapper.h
//  Busylight
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BusylightWrapperDelegate <NSObject>
- (void)deviceConnected:(NSDictionary<NSString *, NSString *> *)devices;
- (void)deviceDisconnected:(NSDictionary<NSString *, NSString *> *)devices;
@end

@interface BusylightWrapper : NSObject

@property (nonatomic, weak) id<BusylightWrapperDelegate> delegate;

- (void)start;
- (void)stop;
- (NSArray *)getDevicesArray;

- (void)lightWithRed:(uint8_t)red green:(uint8_t)green blue:(uint8_t)blue;
- (void)pulseWithRed:(uint8_t)red green:(uint8_t)green blue:(uint8_t)blue;
- (void)blinkWithRed:(uint8_t)red green:(uint8_t)green blue:(uint8_t)blue ontime:(uint8_t)ontime offtime:(uint8_t)offtime;
- (void)alertWithRed:(uint8_t)red green:(uint8_t)green blue:(uint8_t)blue andSound:(uint8_t)sound andVolume:(uint8_t)volume;
- (void)jingleWithRed:(uint8_t)red green:(uint8_t)green blue:(uint8_t)blue sound:(uint8_t)sound andVolume:(uint8_t)volume;
- (void)off;

@end

NS_ASSUME_NONNULL_END
