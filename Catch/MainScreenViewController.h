//
//  MainScreenViewController.h
//  Catch
//
//  Created by Poulose Matthen on 04/06/15.
//  Copyright (c) 2015 Zettanode. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Parse/Parse.h"

@interface MainScreenViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIButton *infoButton;
@property (strong, nonatomic) NSString *fBUsername;
@property (strong, nonatomic) NSString *fBID;
@property (strong, nonatomic) PFObject *myUser;

@property (strong, nonatomic) IBOutlet UIScrollView *myScrollView;

@end
