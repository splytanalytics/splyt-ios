//
//  ViewController.m
//  SplytSDKExampleApp
//
//  Created by Eric Turner on 9/1/15.
//  Copyright (c) 2015 Splyt. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


// button tapped
-(IBAction)buttonTapped:(id)sender{
    
    AppDelegate *appDel = (AppDelegate *)[[UIApplication sharedApplication] delegate];

    [appDel buttonTapped];
    
}

@end
