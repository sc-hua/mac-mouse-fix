#import "Device.h"

// Supply HID identities without opening or capturing any real input device.
@interface TestDevice : Device
@property (nonatomic, strong) NSString *identity;
@end

@implementation TestDevice
- (IOHIDDeviceRef)iohidDevice {
    return (__bridge IOHIDDeviceRef)self.identity;
}
@end

static int checks = 0;
static void check(BOOL condition, NSString *message) {
    checks++;
    if (!condition) {
        NSLog(@"FAIL: %@", message);
        exit(1);
    }
}

int main(void) {
    @autoreleasepool {
        Device *remote = Device.strangeDevice;
        check(remote == Device.strangeDevice, @"Forwarded input shares a stable device");
        check([remote.uniqueID isEqual:@0], @"Forwarded input has a non-nil numeric ID");
        check([remote isEqual:remote], @"Forwarded device equals itself");
        check(![remote isEqual:nil], @"A missing device is distinct");
        check(![remote isEqual:@0], @"A device ID is not a device");

        TestDevice *first = [[TestDevice alloc] init];
        first.identity = @"mouse-a";
        TestDevice *same = [[TestDevice alloc] init];
        same.identity = [NSMutableString stringWithString:@"mouse-a"];
        TestDevice *other = [[TestDevice alloc] init];
        other.identity = @"mouse-b";

        check(![first isEqual:remote], @"Physical input differs from forwarded input");
        check(![remote isEqual:first], @"Device equality is symmetric");
        check([first isEqual:same] && [same isEqual:first], @"Matching HID identities compare equally");
        check(first.hash == same.hash, @"Equal HID identities have equal hashes");
        check(![first isEqual:other], @"Different HID identities remain distinct");
        check(![first isEqual:@0], @"Unrelated objects are rejected safely");
        check([NSSet setWithObjects:first, same, other, remote, nil].count == 3,
              @"Sets deduplicate physical identities without merging remote input");
    }
    printf("Device identity: %d checks passed\n", checks);
    return 0;
}
