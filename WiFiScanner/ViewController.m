//
//  ViewController.m
//  WiFiScanner
//
//  Created by 张海迪 on 15/3/5.
//  Copyright (c) 2015年 haidi. All rights reserved.
//

#import "ViewController.h"
#import "NetworksManager.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    MSNetworksManager *manager = [MSNetworksManager sharedNetworksManager];
    [manager scan];
   NSDictionary* networksDic = [manager networks];
    NSLog(@"----%@", networksDic);
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
