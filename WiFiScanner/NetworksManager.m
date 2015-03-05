//
//  NetworksManager.m
//  WiFiScanner
//
//  Created by 张海迪 on 15/3/5.
//  Copyright (c) 2015年 haidi. All rights reserved.
//

#import "NetworksManager.h"
static MSNetworksManager *NetworksManager;
@implementation MSNetworksManager
+ (MSNetworksManager *)sharedNetworksManager
{
    if (!NetworksManager)
        NetworksManager = [[MSNetworksManager alloc] init];
    return NetworksManager;
}

+ (NSNumber *)numberFromBSSID:(NSString *) bssid
{
    int x = 0;
    uint64_t longmac;
    int MAC_LEN = 6;
    short unsigned int *bs_in = malloc(sizeof(short unsigned int) * MAC_LEN);
    if (sscanf([bssid cStringUsingEncoding: [NSString defaultCStringEncoding]],"％hX:％hX:％hX:％hX:％hX:％hX", &bs_in[0],  &bs_in[1], &bs_in[2], &bs_in[3], &bs_in[4], &bs_in[5]) == MAC_LEN)
    {
        for (x = 0; x < MAC_LEN; x++)
            longmac |= (uint64_t) bs_in[x] << ((MAC_LEN - x - 1));
    } else {
        NSLog(@"WARN: invalid mac address! ％＠",self);
    }
    free(bs_in);
    return [NSNumber numberWithUnsignedLongLong:longmac];
}

- (NSDictionary *)networks
{
    // TODO: Implement joining of network types
    return networks;
}
- (NSDictionary *)networks:(int) type
{
    // TODO: Implement ing of network types
    if(type != 0)
        NSLog(@"WARN: Non 80211 networks are not supported. ％＠", self);
    return networks;
}

- (NSDictionary *)network:(NSString *) aNetwork
{
    return [networks objectForKey: aNetwork];
}

- (id)init
{
    self = [super init];
    NetworksManager = self;
    networks = [[NSMutableDictionary alloc] init];
    types = [NSArray arrayWithObjects:@"80211", @"Bluetooth", @"GSM", nil];
    autoScanInterval = 5; //seconds
    // For iPhone 2.0
    libHandle = dlopen("/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Apple80211", RTLD_LAZY);
    // For iPhone 3.0
    
//    libHandle = dlopen("/System/Library/SystemConfiguration/WiFiManager.bundle/WiFiManager", RTLD_LAZY);
    open = dlsym(libHandle, "Apple80211Open");
    bind = dlsym(libHandle, "Apple80211BindToInterface");
    close = dlsym(libHandle, "Apple80211Close");
    scan = dlsym(libHandle, "Apple80211Scan");
    associate = dlsym(libHandle, "Apple80211Associate");
    getpower = dlsym(libHandle, "Apple80211GetPower");
    setpower = dlsym(libHandle, "Apple80211SetPower");
    
    open(&airportHandle);
    bind(airportHandle, @"en0");
    
    return self;
}

- (void)dealloc
{
    close(&airportHandle);
//    [super dealloc];
}

- (int)numberOfNetworks
{
    return [networks count];
}
- (int)numberOfNetworks:(int) type
{
    // TODO: Implement ing of network types
    if(type != 0)
        NSLog(@"WARN: Non 80211 networks are not supported. ％＠", self);
    return [networks count];
}

- (int)autoScanInterval
{
    return autoScanInterval;
}

- (void)scan
{
    //    NSLog（＠"Scanning…");
    scanning = true;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"startedScanning" object:self];
    NSArray *scan_networks;
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setObject:@"YES" forKey:@"SCAN_MERGE"];
    scan(airportHandle, &scan_networks, (__bridge void *)(parameters));
    int i;
    //bool changed;
    [networks removeAllObjects];
    for (i = 0; i < [scan_networks count]; i++) {
        [networks setObject:[[scan_networks objectAtIndex: i] objectForKey:@"BSSID"] forKey:[[scan_networks objectAtIndex: i] objectForKey:@"RSSI"]];
    }
    NSLog(@"Scan Finished…");
}

- (void)removeNetwork:(NSString *)aNetwork
{
    [networks removeObjectForKey:aNetwork];
}

- (void)removeAllNetworks
{
    [networks removeAllObjects];
}

- (void)removeAllNetworks:(int) type
{
    if(type != 0)
        NSLog(@"WARN: Non 80211 networks are not supported. ％＠", self);
    [networks removeAllObjects];
}

- (void)autoScan:(bool) bScan
{
    autoScanning = bScan;
    if(bScan) {
        [self scan];
        [NSTimer scheduledTimerWithTimeInterval:autoScanInterval target:self selector:@selector(scanSelector:) userInfo:nil repeats:NO];
        
    }
    NSLog(@"WARN: Automatic scanning not fully supported yet. ％＠",self);
}

- (bool)autoScan
{
    return autoScanning;
}

- (void)scanSelector:(id)param {
    if(autoScanning) {
        [self scan];
        [NSTimer scheduledTimerWithTimeInterval:autoScanInterval target:self selector:@selector (scanSelector:) userInfo:nil repeats:NO];
    }
}

- (void)setAutoScanInterval:(int) scanInterval
{
    autoScanInterval = scanInterval;
}

- (int)associateNetwork:(NSDictionary *)bss  :(NSString *)password
{
    if(bss!=nil)
    {
        NSLog(@"associateNetwork");
        int ret = associate(airportHandle, bss, password);
        return ret;
    }else
        return -1;
}

- (int)getPower: (char *)power
{
    return getpower(airportHandle, power);
}

- (int)setPower: (char *)power
{
    return setpower(airportHandle, power);
}

- (NSString *) localIPAddress
{
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    
    // retrieve the current interfaces – returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0)
    {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL)
        {
            if(temp_addr->ifa_addr->sa_family == AF_INET)
            {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"])
                {
                    // Get NSString C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            
            temp_addr = temp_addr->ifa_next;
        }
    }
    
    // Free memory
    freeifaddrs(interfaces);
    return address;
}
@end
