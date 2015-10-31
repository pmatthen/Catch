//
//  MainScreenViewController.h
//  Catch
//
//  Created by Poulose Matthen on 04/06/15.
//  Copyright (c) 2015 Zettanode. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Parse/Parse.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

@interface MainScreenViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIButton *infoButton;
@property (strong, nonatomic) NSString *fBID;
@property (strong, nonatomic) PFObject *myUser;
@property (nonatomic, strong) NSMutableArray *activityArray;

@property (strong, nonatomic) IBOutlet UIView *myViewBack;
@property (strong, nonatomic) IBOutlet UIView *myViewMiddle;
@property (strong, nonatomic) IBOutlet UIView *myViewFront;
@property (strong, nonatomic) IBOutlet UIButton *rightArrowButton;
@property (strong, nonatomic) IBOutlet UILabel *rightArrowLabel;
@property (strong, nonatomic) IBOutlet UILabel *rightArrowLabel35;
@property (nonatomic, retain) AVAudioPlayer *player;
@property (nonatomic, strong) NSNumber *refreshTime;
@property BOOL shouldAnimateIncomingBall;

@property (strong, nonatomic) IBOutlet UIScrollView *myScrollView;

- (IBAction)rightArrowButtonPressed:(id)sender;


@end
