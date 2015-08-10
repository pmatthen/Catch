//
//  InfoViewController.m
//  Catch
//
//  Created by Poulose Matthen on 09/07/15.
//  Copyright (c) 2015 Zettanode. All rights reserved.
//

#import "InfoViewController.h"

@interface InfoViewController () <UIGestureRecognizerDelegate>

@end

@implementation InfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapFrom:)];
    
    [self.view addGestureRecognizer:tapGestureRecognizer];
}

-(void) handleTapFrom:(UITapGestureRecognizer *)recognizer {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
