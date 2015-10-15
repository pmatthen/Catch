//
//  MainScreenViewController.m
//  Catch
//
//  Created by Poulose Matthen on 04/06/15.
//  Copyright (c) 2015 Zettanode. All rights reserved.
//

#import "MainScreenViewController.h"
#import "FindFriendsViewController.h"
#import "AfterThrowingViewController.h"

@import CoreMotion;

@interface MainScreenViewController () <UIScrollViewDelegate>

@property (nonatomic, strong) CMMotionManager * motionManager;
@property (nonatomic, strong) UIView * ball;
@property (nonatomic, strong) NSMutableArray *toFBdetailsArray;
@property BOOL is35;

@property (nonatomic, strong) NSMutableArray *tempActivityArray;
@property (nonatomic, strong) NSMutableArray *activityArray;
@property BOOL isBuildActivityStarted;
@property BOOL isViewBuilt;
@property int currentPage;
@property int previousPage;
@property float startingX;

@end

@implementation MainScreenViewController
@synthesize fBUsername, fBID, toFBdetailsArray, myUser, is35, tempActivityArray, activityArray, isBuildActivityStarted, isViewBuilt, myScrollView, currentPage, previousPage, startingX;

float X = 0;
float Y = 0;
float R = 300;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    is35 = NO;
    isViewBuilt = NO;
    isBuildActivityStarted = NO;
    
    CGRect bounds = self.view.bounds;
    CGFloat height = bounds.size.height;
    
    if (height == 480) {
        is35 = YES;
    }
    
    if (is35) {
        R = 254;
    }
    
    toFBdetailsArray = [NSMutableArray new];
    tempActivityArray = [NSMutableArray new];
    activityArray = [NSMutableArray new];
    
    currentPage = 0;
    previousPage = 0;
    
    NSLog(@"myUser[facebookID] = %@", myUser[@"facebookID"]);
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (isViewBuilt) {
        currentPage = 0;
        previousPage = 0;
        startingX = (int)currentPage * (int)self.view.frame.size.width;
        CGFloat width = self.view.frame.size.width * [activityArray count];
        myScrollView.contentSize = CGSizeMake(width, myScrollView.frame.size.height);
        [myScrollView setContentOffset:CGPointMake(startingX, self.view.frame.size.height)];
        [self pageLayout:currentPage];
    } else {
        [self buildActivityDictionary];
    }
    
//    [self setupView];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

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

- (BOOL)prefersStatusBarHidden {
    return YES;
}

-(void)viewDidLayoutSubviews {
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        [self setNeedsStatusBarAppearanceUpdate];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)aScrollView {
    [aScrollView setContentOffset:CGPointMake(aScrollView.contentOffset.x, 0.0)];
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    scrollView.userInteractionEnabled = NO;
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
        currentPage = (myScrollView.contentOffset.x + (0.5f * myScrollView.frame.size.width))/myScrollView.frame.size.width;
        if (currentPage != previousPage) {
            if (currentPage > previousPage) {
                [self swipePhoto:(currentPage - 2) andAdd:(currentPage + 1)];
            }
            if (currentPage < previousPage) {
                [self swipePhoto:(currentPage + 2) andAdd:(currentPage - 1)];
            }
            previousPage = currentPage;
        }
        scrollView.userInteractionEnabled = YES;
}

-(void)resetScrollView
{
    for (UIView *myView in myScrollView.subviews) {
        [myView removeFromSuperview];
    }

    [self pageLayout:currentPage];
}

-(void)pageLayout:(int)page
{
    
    if (activityArray[page]) {
        [self drawPages:page];
    }
    
    if (((page + 1) < [activityArray count])) {
        [self drawPages:(page + 1)];
    }
}

-(void)drawPages:(int)sub
{
    NSDictionary *activity = [NSDictionary new];
    
    activity = activityArray[sub];
    
    if (sub == 0) {
        // Code for User Ball
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"user_ball_thrown"]) {
            // Code for when User Ball has been thrown
            NSDictionary *tempUserDictionary = activityArray[sub];
            if ([tempUserDictionary[@"arrived"]  isEqual: @YES]) {
                //Code for when User Ball has been thrown and has been returned
            } else {
                // Code for when User Ball has been thrown and has not been returned
            }
        } else {
            // Code for when User Ball has not been thrown
            if ([toFBdetailsArray count] > 0) {
                // Code for when User Ball has not been thrown and Friend has been selected
            } else {
                // Code for when User Ball has not been thrown and Friend has not been selected
            }
        }
    } else {
        // Code for Friend Ball
    }
    
    UIView *myView = [[UIView alloc] init];
    myView.contentMode = UIViewContentModeScaleToFill;
    myView.backgroundColor = [UIColor redColor];
    myView.frame = CGRectMake((self.view.frame.size.width * sub), 0, self.view.frame.size.width, myScrollView.frame.size.height);
    myView.tag = sub + 1;
    
    UILabel *myLabel = [[UILabel alloc] init];
    myLabel.font = [UIFont systemFontOfSize:18];
    myLabel.textColor = [UIColor whiteColor];
    myLabel.text = [NSString stringWithFormat:@"%i", (sub +1)];
    myLabel.frame = CGRectMake(180, 284, 100, 100);
    [myLabel sizeToFit];

    [myView addSubview:myLabel];
    [myScrollView addSubview:myView];
}

-(void)swipePhoto:(int)subViewToDelete andAdd:(int)subViewToAdd
{
    for (UIView *myView in myScrollView.subviews) {
        if ((myView.tag == subViewToDelete + 1) && (myView.tag != 0)) {
            [myView removeFromSuperview];
        }
    }
    
    if (subViewToAdd < [activityArray count]) {
        [self drawPages:subViewToAdd];
    }
}

-(void) buildActivityDictionaryMethod {
    if (!isBuildActivityStarted) {
        [self buildActivityDictionary];
    }
}

- (void) buildActivityDictionary {
    NSLog(@"buildActivityDictionary method started");
    isBuildActivityStarted = YES;
    
    __block PFObject *myFriend = [PFObject objectWithClassName:@"User"];
    __block PFObject *userActivity = [PFObject objectWithClassName:@"Activity"];
    __block PFObject *friendActivity = [PFObject objectWithClassName:@"Activity"];
    __block NSMutableDictionary *userDictionary = [NSMutableDictionary new];
    __block NSMutableArray *friendsActivityArray = [NSMutableArray new];
    __block NSArray *sortedFriendsActivityArray = [NSMutableArray new];
    __block NSMutableSet *remainingActivities = [NSMutableSet new];
    __block BOOL isError = NO;
    
    [tempActivityArray removeAllObjects];
    
    dispatch_group_t taskGroup = dispatch_group_create();
    
    dispatch_group_enter(taskGroup);
    
    PFQuery *userActivityQuery = [PFQuery queryWithClassName:@"Activity"];
    [userActivityQuery whereKey:@"FromFBID" matchesRegex:fBID];
    [userActivityQuery findObjectsInBackgroundWithBlock:^(NSArray *activityObjects, NSError *error1) {
        if (!error1) {
            userActivity = [activityObjects firstObject];
            NSLog(@"1. userActivity = %@", userActivity);
            
            if ((userActivity[@"FromFBID"] != NULL) && (userActivity[@"BeingReturned"] == [NSNumber numberWithBool:TRUE])) {
                PFQuery *FriendQuery = [PFQuery queryWithClassName:@"User"];
                [FriendQuery findObjectsInBackgroundWithBlock:^(NSArray *friendObjects, NSError *error2) {
                    if (!error2) {
                        for (PFObject *friend in friendObjects) {
                            if ([friend[@"facebookID"] isEqualToString:userActivity[@"ToFBID"]]) {
                                myFriend = friend;
                            }
                        }
                        
                        NSLog(@"2. myFriend = %@", myFriend);
                        
                        PFGeoPoint *myUserGeoPoint = myUser[@"location"];
                        PFGeoPoint *myFriendGeoPoint = myFriend[@"location"];
                        
                        CLLocation *userLocation = [[CLLocation alloc] initWithLatitude:myUserGeoPoint.latitude longitude:myUserGeoPoint.longitude];
                        CLLocation *friendsLocation = [[CLLocation alloc] initWithLatitude:myFriendGeoPoint.latitude longitude:myFriendGeoPoint.longitude];
                        
                        CLLocationDistance distance = [userLocation distanceFromLocation:friendsLocation];
                        
                        double secondsForBallToTravel = distance/(3600/500);
                        NSNumber *timeTillArrival = [NSNumber numberWithDouble:(secondsForBallToTravel - [[NSDate date] timeIntervalSinceDate:userActivity.updatedAt])];
                        
                        // If users ball has arrived, ???
                        if (secondsForBallToTravel < [[NSDate date] timeIntervalSinceDate:userActivity.updatedAt]) {
                            [userDictionary setObject:userActivity forKey:@"activity"];
                            [userDictionary setObject:@YES forKey:@"arrived"];
                            [userDictionary setObject:timeTillArrival forKey:@"timeTillArrival"];
                            
                            NSLog(@"useractivity = %@", userActivity);
                            NSLog(@"secondsForBallToTravel = %f", secondsForBallToTravel);
                            NSLog(@"Uncomment code to delete returned ball object");
                            //                    [userActivity deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                            //                        if (succeeded && !error) {
                            //                            NSLog(@"Object deleted from Parse");
                            //                        } else {
                            //                            NSLog(@"error: %@", error);
                            //                        }
                            //                    }];
                        } else {
                            [userDictionary setObject:userActivity forKey:@"activity"];
                            [userDictionary setObject:@NO forKey:@"arrived"];
                            [userDictionary setObject:timeTillArrival forKey:@"timeTillArrival"];
                        }
                    } else {
                        NSLog(@"error2");
                        isError = YES;
                        dispatch_group_leave(taskGroup);
                    }
                }];
            } else {
                [userDictionary setObject:userActivity forKey:@"activity"];
                [userDictionary setObject:@NO forKey:@"arrived"];
                [userDictionary setObject:@10 forKey:@"timeTillArrival"];
            }
            
            PFQuery *friendActivityQuery = [PFQuery queryWithClassName:@"Activity"];
            NSLog(@"3. fbID = %@", fBID);
            NSLog(@"3. myUser[facebookID] = %@", myUser[@"@facebookID"]);
            [friendActivityQuery whereKey:@"ToFBID" matchesRegex:fBID];
            [friendActivityQuery findObjectsInBackgroundWithBlock:^(NSArray *activityObjects, NSError *error3) {
                if (!error3) {
                    remainingActivities = [NSMutableSet setWithArray:activityObjects];
                    NSLog(@"3. activityObjects = %@", activityObjects);
                    
                    PFQuery *friendQuery = [PFQuery queryWithClassName:@"User"];
                    [friendQuery findObjectsInBackgroundWithBlock:^(NSArray *friendObjects, NSError *error4) {
                        if (!error4) {
                            NSLog(@"4. friendObjects = %@", friendObjects);
                            for (PFObject *activity in activityObjects) {
                                NSMutableDictionary *friendDictionary = [NSMutableDictionary new];
                                
                                friendActivity = activity;
                                for (PFObject *friend in friendObjects) {
                                    if ([friend[@"facebookID"] isEqualToString:friendActivity[@"FromFBID"]]) {
                                        myFriend = friend;
                                    }
                                }
                                
                                PFGeoPoint *myUserGeoPoint = myUser[@"location"];
                                PFGeoPoint *myFriendGeoPoint = myFriend[@"location"];
                                
                                CLLocation *userLocation = [[CLLocation alloc] initWithLatitude:myUserGeoPoint.latitude longitude:myUserGeoPoint.longitude];
                                CLLocation *friendsLocation = [[CLLocation alloc] initWithLatitude:myFriendGeoPoint.latitude longitude:myFriendGeoPoint.longitude];
                                
                                CLLocationDistance distance = [userLocation distanceFromLocation:friendsLocation];
                                double secondsForBallToTravel = distance/(3600/500);
                                NSNumber *timeTillArrival = [NSNumber numberWithDouble:(secondsForBallToTravel - [[NSDate date] timeIntervalSinceDate:friendActivity.createdAt])];
                                
                                // If friends ball has arrived, ???
                                if (secondsForBallToTravel < [[NSDate date] timeIntervalSinceDate:friendActivity.createdAt]) {
                                    [friendDictionary setObject:friendActivity forKey:@"activity"];
                                    [friendDictionary setObject:@YES forKey:@"arrived"];
                                    [friendDictionary setObject:timeTillArrival forKey:@"timeTillArrival"];
                                    [friendsActivityArray addObject:friendDictionary];
                                } else {
                                    [friendDictionary setObject:friendActivity forKey:@"activity"];
                                    [friendDictionary setObject:@NO forKey:@"arrived"];
                                    [friendDictionary setObject:timeTillArrival forKey:@"timeTillArrival"];
                                    [friendsActivityArray addObject:friendDictionary];
                                }
                                [remainingActivities removeObject:friendActivity];
                                if ([remainingActivities count] == 0) {
                                    
                                    sortedFriendsActivityArray = [friendsActivityArray sortedArrayUsingComparator:^NSComparisonResult(NSMutableDictionary *a, NSMutableDictionary *b) {
                                        NSNumber *first = a[@"timeTillArrival"];
                                        NSNumber *second = b[@"timeTillArrival"];
                                        
                                        return [second compare:first];
                                    }];
                                    
                                    NSLog(@"buildActivityDictionary method finished");
                                    dispatch_group_leave(taskGroup);
                                }
                            }
                        } else {
                            NSLog(@"error4");
                            isError = YES;
                            dispatch_group_leave(taskGroup);
                        }
                    }];
                } else {
                    NSLog(@"error3");
                    isError = YES;
                    dispatch_group_leave(taskGroup);
                }
            }];
        } else {
            NSLog(@"error1");
            isError = YES;
            dispatch_group_leave(taskGroup);
        }
    }];

    dispatch_group_notify(taskGroup, dispatch_get_main_queue(), ^ {
        NSLog(@"END userDictionary = %@", userDictionary);
        [tempActivityArray addObject:userDictionary];
        
        for (int i = 0; i < [sortedFriendsActivityArray count]; i++) {
            NSDictionary *tempFriendsActivity = [NSDictionary new];
            tempFriendsActivity = sortedFriendsActivityArray[i];
            if ([tempFriendsActivity[@"arrived"] isEqual: @YES]) {
                [tempActivityArray addObject:sortedFriendsActivityArray[i]];
            }
        }
        
        BOOL isTheSame = YES;
        
        if ([tempActivityArray count] == [activityArray count]) {
            for (int i = 0; i < [activityArray count]; i++) {
                NSDictionary *tempActivityArrayDictionary = tempActivityArray[i];
                NSDictionary *activityArrayDictionary = activityArray[i];
                
                PFObject *tempActivityArrayDictionaryActivity = tempActivityArrayDictionary[@"activity"];
                PFObject *activityArrayDictionaryActivity = activityArrayDictionary[@"activity"];
                
                if (![tempActivityArrayDictionaryActivity.objectId isEqualToString:activityArrayDictionaryActivity.objectId] ) {
                    isTheSame = NO;
                }
            }
        } else {
            isTheSame = NO;
        }
        
        if (isTheSame == NO) {
            activityArray = [NSMutableArray arrayWithArray:tempActivityArray];
            
            for (int i = 0; i < [activityArray count]; i++) {
                NSDictionary *tempDictionary = activityArray[i];
                NSLog(@"activityArray index #%d = %@", i, tempDictionary[@"timeTillArrival"]);
            }
            
            CGFloat width = self.view.frame.size.width * [activityArray count];
            myScrollView.contentSize = CGSizeMake(width, myScrollView.frame.size.height);
            isViewBuilt = NO;
            [self buildView];
        } else {
            NSLog(@"THE SAME!!");
        }
        isBuildActivityStarted = NO;
    });
}

- (void) buildView {
    
    if (isViewBuilt == NO) {
        [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(buildActivityDictionaryMethod) userInfo:nil repeats:YES];
        
        isViewBuilt = YES;
    }
    
    currentPage = 0;
    previousPage = 0;
    startingX = (int)currentPage * (int)self.view.frame.size.width;
    CGFloat width = self.view.frame.size.width * [activityArray count];
    myScrollView.contentSize = CGSizeMake(width, myScrollView.frame.size.height);
    [myScrollView setContentOffset:CGPointMake(startingX, self.view.frame.size.height)];
    [self resetScrollView];
}

- (void) setupView {
    [self.ball removeFromSuperview];
    
    [self initBall];
    
    [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(updateDeviceMotion) userInfo:nil repeats:YES];
    
    // TODO: 2.1
    
    // 2.1 Create a CMMotionManager instance and store it in the property "motionManager"
    self.motionManager = [[CMMotionManager alloc] init];
    
    // 2.1 Set the motion update interval to 1/60
    self.motionManager.deviceMotionUpdateInterval = 1.0 / 60.0;
    
    // 2.1 Start updating the motion using the reference frame CMAttitudeReferenceFrameXArbitraryCorrectedZVertical
    [self.motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryCorrectedZVertical];
}

- (void)initBall {
    self.ball = [[UIView alloc] initWithFrame:CGRectMake(160, 134, R, R)];
    self.ball.layer.cornerRadius = 150;
    if (is35) {
        self.ball = [[UIView alloc] initWithFrame:CGRectMake(160, 113, R, R)];
        self.ball.layer.cornerRadius = 127;
    }
    self.ball.backgroundColor = [UIColor redColor];
    [self.view addSubview:self.ball];
}

- (void)updateBallWithRoll:(float)roll Pitch:(float)pitch Yaw:(float)yaw accX:(float)accX accY:(float)accY accZ:(float)accZ {
    // 0, 20, 114, 154
    float maxYValue = 268;
    float maxXValue = 20;
    float minYValue = 0;
    float minXValue = 0;
    if (is35) {
        maxYValue = 226;
        maxXValue = 68;
        minYValue = 0;
        minXValue = 0;
    }
    
    X += 2 * roll;
    Y += 2 * pitch;
    
    // 0.8
    X *= 0.8;
    Y *= 0.8;
    
    CGFloat newX = self.ball.frame.origin.x + X;
    CGFloat newY = self.ball.frame.origin.y + Y;
    
    newX = fmin(maxXValue, fmax(minXValue, newX));
    newY = fmin(maxYValue, fmax(minYValue, newY));
    
    self.ball.frame = CGRectMake(newX, newY, R, R);
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
    
//    NSLog(@"accX:%.2f, accY:%.2f, accZ:%.2f", accX, accY, accZ);
}

-(void) throwBall {
    PFObject *throwBallActivity = [PFObject objectWithClassName:@"Activity"];
    throwBallActivity[@"FromFBID"] = fBID;
    throwBallActivity[@"ToFBID"] = [toFBdetailsArray objectAtIndex:1];
    throwBallActivity[@"BeingReturned"] = [NSNumber numberWithBool:NO];
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"user_ball_thrown"];
    
    [throwBallActivity saveInBackground];
    [self.ball removeFromSuperview];
    [toFBdetailsArray removeObjectAtIndex:0];
    [toFBdetailsArray removeObjectAtIndex:0];
    [self performSegueWithIdentifier:@"AfterThrowingSegue" sender:self];
}

-(void) findFriends {
    [self performSegueWithIdentifier:@"FriendsScreenSegue" sender:self];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"FriendsScreenSegue"]) {
        FindFriendsViewController *myFindFriendsViewController = (FindFriendsViewController *) segue.destinationViewController;
        myFindFriendsViewController.delegate = self;
    }
    if ([segue.identifier isEqualToString:@"AfterThrowingSegue"]) {
        AfterThrowingViewController *myAfterThrowingViewController = (AfterThrowingViewController *) segue.destinationViewController;
        myAfterThrowingViewController.fBID = fBID;
    }
}

-(void)sendFriendDetailsToMainScreen:(NSMutableArray *) detailsArray {
    if ([detailsArray count] > 0) {
        NSLog(@"Selected Name = %@", detailsArray[0]);
        NSLog(@"Selected ID = %@", detailsArray[1]);
    }
    
    toFBdetailsArray = detailsArray;
}

@end
