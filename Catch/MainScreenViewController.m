//
//  MainScreenViewController.m
//  Catch
//
//  Created by Poulose Matthen on 04/06/15.
//  Copyright (c) 2015 Zettanode. All rights reserved.
//

#import "MainScreenViewController.h"
#import "FindFriendsViewController.h"

@import CoreMotion;

@interface MainScreenViewController ()

@property (nonatomic, strong) CMMotionManager * motionManager;
@property (nonatomic, strong) UIView * ball;
@property (nonatomic, strong) NSMutableArray *toFBdetailsArray;

@end

@implementation MainScreenViewController
@synthesize findFriendsButton, throwBallButton, fBUsername, fBID, toFBdetailsArray;

float X = 0;
float Y = 0;
float R = 300;

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    NSArray *fontFamilies = [UIFont familyNames];
//    for (int i = 0; i < [fontFamilies count]; i++)
//    {
//        NSString *fontFamily = [fontFamilies objectAtIndex:i];
//        NSArray *fontNames = [UIFont fontNamesForFamilyName:[fontFamilies objectAtIndex:i]];
//        NSLog (@"%@: %@", fontFamily, fontNames);
//    }
    
    //        "AvenirNextCondensed-BoldItalic",
    //        "AvenirNextCondensed-Heavy",
    //        "AvenirNextCondensed-Medium",
    //        "AvenirNextCondensed-Regular",
    //        "AvenirNextCondensed-HeavyItalic",
    //        "AvenirNextCondensed-MediumItalic",
    //        "AvenirNextCondensed-Italic",
    //        "AvenirNextCondensed-UltraLightItalic",
    //        "AvenirNextCondensed-DemiBold",
    //        "AvenirNextCondensed-UltraLight",
    //        "AvenirNextCondensed-Bold",
    //        "AvenirNextCondensed-DemiBoldItalic"
    
    toFBdetailsArray = [NSMutableArray new];
    
    findFriendsButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    findFriendsButton.contentEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 0);
    findFriendsButton.titleLabel.font = [UIFont fontWithName:@"AvenirNextCondensed-Bold" size:28];
    findFriendsButton.titleLabel.textColor = [UIColor redColor];
    findFriendsButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    NSLog(@"fBID = %@", fBID);
    NSLog(@"fBUsername = %@", fBUsername);
    [self timeTillBallArrives];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

-(void)viewDidLayoutSubviews {
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        [self setNeedsStatusBarAppearanceUpdate];
    }
}

- (void)initBall {
    self.ball = [[UIView alloc] initWithFrame:CGRectMake(160, 250, R, R)];
    self.ball.layer.cornerRadius = 150;
    self.ball.backgroundColor = [UIColor redColor];
    [self.view addSubview:self.ball];
}

- (void)updateBallWithRoll:(float)roll Pitch:(float)pitch Yaw:(float)yaw accX:(float)accX accY:(float)accY accZ:(float)accZ {
    X += 2 * roll;
    Y += 2 * pitch;
    
    X *= 0.8;
    Y *= 0.8;
    
    CGFloat newX = self.ball.frame.origin.x + X;
    CGFloat newY = self.ball.frame.origin.y + Y;
    
    newX = fmin(20, fmax(0, newX));
    newY = fmin(267, fmax(0, newY));
    
    CGFloat newR = R + 10 * accZ;
    
    self.ball.frame = CGRectMake(newX, newY, newR, newR);
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSLog(@"Has user selected friend to throw ball to?? = %@", ([[NSUserDefaults standardUserDefaults] boolForKey:@"friend_selected_to_throw_ball_to"]) ? @"YES" : @"NO");
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"friend_selected_to_throw_ball_to"]) {
        [throwBallButton setHidden:NO];
    } else {
        [throwBallButton setHidden:YES];
    }
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"user_ball_thrown"]) {
        [findFriendsButton setHidden:YES];
    } else {
        [findFriendsButton setHidden:NO];
        [self initBall];
    }
    
    [self.ball removeFromSuperview];
    [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(updateDeviceMotion) userInfo:nil repeats:YES];
    
    // TODO: 2.1
    
    // 2.1 Create a CMMotionManager instance and store it in the property "motionManager"
    self.motionManager = [[CMMotionManager alloc] init];
    
    // 2.1 Set the motion update interval to 1/60
    self.motionManager.deviceMotionUpdateInterval = 1.0 / 60.0;
    
    // 2.1 Start updating the motion using the reference frame CMAttitudeReferenceFrameXArbitraryCorrectedZVertical
    [self.motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryCorrectedZVertical];
    
}

-(void)updateDeviceMotion {
    // TODO: 2.2
    
    // 2.2 Get the deviceMotion from motionManager
    CMDeviceMotion *deviceMotion = self.motionManager.deviceMotion;
    
    // 2.2 Return if the returned CMDeviceMotion object is nil
    if(deviceMotion == nil) {
        return;
    }
    
    // 2.2 Get the attitude from CMDeviceMotion
    CMAttitude *attitude = deviceMotion.attitude;
    
    // 2.2 Get the userAcceleration from CMDeviceMotion
    CMAcceleration userAcceleration = deviceMotion.userAcceleration;
    
    // 2.2 Call "updateBallWithRoll:Pitch:Yaw:accX:accY:accZ:" on self with the appropriate arguments
    
    float roll = attitude.roll;
    float pitch = attitude.pitch;
    float yaw = attitude.yaw;
    
    float accX = userAcceleration.x;
    float accY = userAcceleration.y;
    float accZ = userAcceleration.z;
    
    [self updateBallWithRoll:roll Pitch:pitch Yaw:yaw accX:accX accY:accY accZ:accZ];
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    if(self.motionManager != nil){
        
        // TODO: 2.3
        
        // 2.3 Stop updating the motionManager
        [self.motionManager stopDeviceMotionUpdates];
        
        // 2.3 Set the ivar "motionManager" to nil
        self.motionManager = nil;
        
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"FriendsScreenSegue"]) {
        FindFriendsViewController *myFindFriendsViewController = (FindFriendsViewController *) segue.destinationViewController;
        myFindFriendsViewController.delegate = self;
    }
}

-(void)sendFriendDetailsToMainScreen:(NSMutableArray *) detailsArray {
    NSLog(@"Selected Name = %@", detailsArray[0]);
    NSLog(@"Selected ID = %@", detailsArray[1]);
    
    toFBdetailsArray = detailsArray;
}

- (IBAction)findFriendsButtonPressed:(id)sender {
    [self performSegueWithIdentifier:@"FriendsScreenSegue" sender:self];
}

- (IBAction)throwBallButtonPressed:(id)sender {
    PFObject *throwBallActivity = [PFObject objectWithClassName:@"Activity"];
    throwBallActivity[@"FromFBID"] = [NSNumber numberWithLongLong:[fBID longLongValue]];
    throwBallActivity[@"ToFBID"] = [NSNumber numberWithLongLong:[[toFBdetailsArray objectAtIndex:1] longLongValue]];
    throwBallActivity[@"OnItsWay"] = [NSNumber numberWithBool:YES];
    throwBallActivity[@"BeingReturned"] = [NSNumber numberWithBool:NO];
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"user_ball_thrown"];
    
    [throwBallActivity saveInBackground];
    [self.ball removeFromSuperview];
}

-(void) timeTillBallArrives {
    __block PFObject *myUser = [PFObject objectWithClassName:@"User"];
    __block PFObject *myFriend = [PFObject objectWithClassName:@"User"];
    __block PFObject *myActivity = [PFObject objectWithClassName:@"Activity"];
    
    PFQuery *UserQuery = [PFQuery queryWithClassName:@"User"];
    [UserQuery findObjectsInBackgroundWithBlock:^(NSArray *userObjects, NSError *error) {
        for (PFObject *user in userObjects) {
            if (user[@"facebookID"] == fBID) {
                myUser = user;
            }
        }
        
        NSLog(@"User Name = %@", myUser[@"username"]);
        
        PFQuery *ActivityQuery = [PFQuery queryWithClassName:@"Activity"];
        [ActivityQuery findObjectsInBackgroundWithBlock:^(NSArray *activityObjects, NSError *error) {
            for (PFObject *activity in activityObjects) {
                if (activity[@"FromFBID"] == myUser[@"facebookID"]) {
                    myActivity = activity;
                }
            }
            
            PFQuery *FriendQuery = [PFQuery queryWithClassName:@"User"];
            [FriendQuery findObjectsInBackgroundWithBlock:^(NSArray *friendObjects, NSError *error) {
                for (PFObject *friend in friendObjects) {
                    if (friend[@"facebookID"] == myActivity[@"ToFBID"]) {
                        myFriend = friend;
                    }
                }
                
                NSLog(@"Friend Name = %@", myFriend[@"username"]);
                
                PFGeoPoint *myUserGeoPoint = myUser[@"location"];
                PFGeoPoint *myFriendGeoPoint = myFriend[@"location"];
                
                CLLocation *userLocation = [[CLLocation alloc] initWithLatitude:myUserGeoPoint.latitude longitude:myUserGeoPoint.longitude];
                CLLocation *friendsLocation = [[CLLocation alloc] initWithLatitude:myFriendGeoPoint.latitude longitude:myFriendGeoPoint.longitude];
                
                CLLocationDistance distance = [userLocation distanceFromLocation:friendsLocation];
                
                NSLog(@"The distance from user location to friends location is %f meters", distance);
            }];
        }];
    }];
}

- (IBAction)backButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
