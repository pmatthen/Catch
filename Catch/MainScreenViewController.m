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
@property (nonatomic, strong) NSMutableArray *toFBdetailsArray;
@property BOOL is35;

@property (nonatomic, strong) NSMutableArray *tempActivityArray;
@property (nonatomic, strong) NSMutableArray *activityArray;
@property BOOL isBuildActivityStarted;
@property BOOL isViewBuilt;
@property int currentPage;
@property int previousPage;
@property float startingX;
@property BOOL userBallStateChanged;

@end

@implementation MainScreenViewController
@synthesize fBUsername, fBID, toFBdetailsArray, myUser, is35, tempActivityArray, activityArray, isBuildActivityStarted, isViewBuilt, myScrollView, currentPage, previousPage, startingX, userBallStateChanged;

float X = 0;
float Y = 0;
float R = 300;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    is35 = NO;
    isViewBuilt = NO;
    isBuildActivityStarted = NO;
    userBallStateChanged = NO;
    
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
        [self resetScrollView];
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
    
//    if(self.motionManager != nil){
//        
//        // TODO: 2.3
//        
//        // 2.3 Stop updating the motionManager
//        [self.motionManager stopDeviceMotionUpdates];
//        
//        // 2.3 Set the ivar "motionManager" to nil
//        self.motionManager = nil;
//        
//    }
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
    if (isViewBuilt) {
        if (activityArray[page]) {
            [self drawPages:page];
        }
        
        if (((page + 1) < [activityArray count])) {
            [self drawPages:(page + 1)];
        }
    }
}

-(void)drawPages:(int)sub
{
    NSDictionary *activity = [NSDictionary new];
    
    activity = activityArray[sub];
    
    if (sub == 0) {
        for (UIView *myView in myScrollView.subviews) {
            if (myView.tag == 50000) {
                [myView removeFromSuperview];
            }
        }
        
        // Code for User Ball
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"user_ball_thrown"]) {
            // Code for when User Ball has been thrown
            UILabel *noBallLabel = [[UILabel alloc] init];
            noBallLabel.text = @"No Ball";
            noBallLabel.font = [UIFont systemFontOfSize:20];
            noBallLabel.textColor = [UIColor redColor];
            [noBallLabel sizeToFit];
            float yValue = 250;
            if (is35) {
                yValue = 211;
            }
            noBallLabel.frame = CGRectMake(((self.view.frame.size.width - noBallLabel.frame.size.width)/2), yValue, noBallLabel.frame.size.width, noBallLabel.frame.size.height);
            noBallLabel.tag = 50000;
            [myScrollView addSubview:noBallLabel];
        } else {
            // Code for when User Ball has not been thrown
            if ([toFBdetailsArray count] > 0) {
                // Code for when User Ball has not been thrown and Friend has been selected
                [self initBall:sub];
            } else {
                // Code for when User Ball has not been thrown and Friend has not been selected
                UIButton *selectFriendButton = [UIButton buttonWithType:UIButtonTypeCustom];
                [selectFriendButton addTarget:self
                           action:@selector(findFriends)
                 forControlEvents:UIControlEventTouchUpInside];
                [selectFriendButton setTitle:@"Find a friend to throw your ball to." forState:UIControlStateNormal];
                selectFriendButton.backgroundColor = [UIColor purpleColor];
                selectFriendButton.titleLabel.font = [UIFont systemFontOfSize:20];
                [selectFriendButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
                selectFriendButton.titleLabel.textAlignment = NSTextAlignmentCenter;
                selectFriendButton.titleLabel.numberOfLines = 0;
                selectFriendButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
                float yValue = 488;
                if (is35) {
                    yValue = 412;
                }
                selectFriendButton.frame = CGRectMake(0, yValue, 320, (self.view.frame.size.height - yValue));
                selectFriendButton.tag = 50000;
                [myScrollView bringSubviewToFront:selectFriendButton];
                [myScrollView addSubview:selectFriendButton];
                
                [self initBall:sub];
            }
        }
    } else {
        // Code for Friend Ball
        [self initBall:sub];
    }
    
    PFObject *fromUser = activity[@"from"];
    
    
    UILabel *myLabel = [[UILabel alloc] init];
    myLabel.font = [UIFont systemFontOfSize:20];
    myLabel.textColor = [UIColor blackColor];
    myLabel.text = fromUser[@"username"];
    [myLabel sizeToFit];
    float yValue = 450;
    if (is35) {
        yValue = 380;
    }
    myLabel.frame = CGRectMake((((self.view.frame.size.width - myLabel.frame.size.width)/2) + (sub * self.view.frame.size.width)), yValue, myLabel.frame.size.width, myLabel.frame.size.height);

    [myScrollView addSubview:myLabel];
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
            if ([activityObjects count] > 0) {
                userActivity = [activityObjects firstObject];
            }
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
                            [userDictionary setObject:myUser forKey:@"from"];
                            [userDictionary setObject:myFriend forKey:@"to"];
                            
                            NSLog(@"useractivity = %@", userActivity);
                            NSLog(@"secondsForBallToTravel = %f", secondsForBallToTravel);
                            [userActivity deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                if (succeeded && !error) {
                                    NSLog(@"Object deleted from Parse");
                                    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"user_ball_thrown"];
                                    userBallStateChanged = YES;
                                } else {
                                    NSLog(@"error: %@", error);
                                }
                            }];
                        } else {
                            [userDictionary setObject:userActivity forKey:@"activity"];
                            [userDictionary setObject:@NO forKey:@"arrived"];
                            [userDictionary setObject:timeTillArrival forKey:@"timeTillArrival"];
                            [userDictionary setObject:myUser forKey:@"from"];
                            [userDictionary setObject:myFriend forKey:@"to"];
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
                [userDictionary setObject:myUser forKey:@"from"];
                [userDictionary setObject:myUser forKey:@"to"];
            }
            
            PFQuery *friendActivityQuery = [PFQuery queryWithClassName:@"Activity"];
            NSLog(@"3. fbID = %@", fBID);
            NSLog(@"3. myUser[facebookID] = %@", myUser[@"@facebookID"]);
            [friendActivityQuery whereKey:@"ToFBID" matchesRegex:fBID];
            [friendActivityQuery findObjectsInBackgroundWithBlock:^(NSArray *activityObjects, NSError *error3) {
                if (!error3) {
                    remainingActivities = [NSMutableSet setWithArray:activityObjects];
                    NSLog(@"3. activityObjects = %@", activityObjects);
                    
                    if ([activityObjects count] > 0) {
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
                                        [friendDictionary setObject:myFriend forKey:@"from"];
                                        [friendDictionary setObject:myUser forKey:@"to"];
                                        [friendsActivityArray addObject:friendDictionary];
                                    } else {
                                        [friendDictionary setObject:friendActivity forKey:@"activity"];
                                        [friendDictionary setObject:@NO forKey:@"arrived"];
                                        [friendDictionary setObject:timeTillArrival forKey:@"timeTillArrival"];
                                        [friendDictionary setObject:myFriend forKey:@"from"];
                                        [friendDictionary setObject:myUser forKey:@"to"];
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
                        dispatch_group_leave(taskGroup);
                    }
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
            PFObject *tempFriendActivityObject = tempFriendsActivity[@"activity"];
            
            if (([tempFriendsActivity[@"arrived"] isEqual: @YES]) && ([tempFriendActivityObject[@"BeingReturned"] isEqualToNumber:[NSNumber numberWithBool:false]])) {
                [tempActivityArray addObject:sortedFriendsActivityArray[i]];
            }
        }
        
        BOOL isTheSame = YES;
        
        if ([tempActivityArray count] == [activityArray count]) {
            for (int i = 1; i < [activityArray count]; i++) {
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
        
        if ((isTheSame == NO) || userBallStateChanged) {
            activityArray = [NSMutableArray arrayWithArray:tempActivityArray];
            
            for (int i = 0; i < [activityArray count]; i++) {
                NSDictionary *tempDictionary = activityArray[i];
                NSLog(@"activityArray index #%d = %@", i, tempDictionary[@"timeTillArrival"]);
            }
            
            CGFloat width = self.view.frame.size.width * [activityArray count];
            myScrollView.contentSize = CGSizeMake(width, myScrollView.frame.size.height);
            userBallStateChanged = NO;
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
        
        [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(updateDeviceMotion) userInfo:nil repeats:YES];
        
        // TODO: 2.1
        
        // 2.1 Create a CMMotionManager instance and store it in the property "motionManager"
        self.motionManager = [[CMMotionManager alloc] init];
        
        // 2.1 Set the motion update interval to 1/60
        self.motionManager.deviceMotionUpdateInterval = 1.0 / 60.0;
        
        // 2.1 Start updating the motion using the reference frame CMAttitudeReferenceFrameXArbitraryCorrectedZVertical
        [self.motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryCorrectedZVertical];
        
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

- (void) setupBall:(int)sub {
    for (UIView *myBall in myScrollView.subviews) {
        if (myBall.tag > 0) {
            [myBall removeFromSuperview];
        }
    }
    
    [self initBall:currentPage];
}

- (void)initBall:(int)sub {
    UIView *ball = [[UIView alloc] init];
    ball = [[UIView alloc] initWithFrame:CGRectMake((10 + (sub * self.view.frame.size.width)), 134, R, R)];
    ball.layer.cornerRadius = 150;
    if (is35) {
        ball = [[UIView alloc] initWithFrame:CGRectMake((10 + (sub * self.view.frame.size.width)), 113, R, R)];
        ball.layer.cornerRadius = 127;
    }
    if (sub == 0) {
        ball.backgroundColor = [UIColor blueColor];
    } else {
        ball.backgroundColor = [UIColor redColor];
    }
    ball.tag = sub + 1;
    [myScrollView addSubview:ball];
}

- (void)updateBallWithRoll:(float)roll Pitch:(float)pitch Yaw:(float)yaw accX:(float)accX accY:(float)accY accZ:(float)accZ sub:(int)sub {
    
    if ((accY > 3) && (accZ > 3)) {
        if (sub == 0) {
            if ([toFBdetailsArray count] > 0) {
                [self throwBall:sub];
                return;
            }
        } else {
            [self throwBall:sub];
            return;
        }
    }
    
    float maxYValue = 268;
    float maxXValue = 20 + (sub * self.view.frame.size.width);
    float minYValue = 0;
    float minXValue = 0 + (sub * self.view.frame.size.width);
    if (is35) {
        maxYValue = 226;
        maxXValue = 68 + (sub * self.view.frame.size.width);
        minYValue = 0;
        minXValue = 0 + (sub * self.view.frame.size.width);
    }
    
    X += 2 * roll;
    Y += 2 * pitch;
    
    // 0.8
    X *= 0.8;
    Y *= 0.8;
    
    UIView *ball = [[UIView alloc] init];
    
    for (UIView *myBall in myScrollView.subviews) {
        if (myBall.tag == (sub + 1)) {
            ball = myBall;
        }
    }
    
    CGFloat newX = ball.frame.origin.x + X;
    CGFloat newY = ball.frame.origin.y + Y;
    
    newX = fmin(maxXValue, fmax(minXValue, newX));
    newY = fmin(maxYValue, fmax(minYValue, newY));
    
    ball.frame = CGRectMake(newX, newY, R, R);
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
    
    [self updateBallWithRoll:roll Pitch:pitch Yaw:yaw accX:accX accY:accY accZ:accZ sub:currentPage];
    
//    NSLog(@"accX:%.2f, accY:%.2f, accZ:%.2f", accX, accY, accZ);
}

-(void) throwBall:(int)sub {
    if (sub == 0) {
        PFObject *throwBallActivity = [PFObject objectWithClassName:@"Activity"];
        throwBallActivity[@"FromFBID"] = fBID;
        throwBallActivity[@"ToFBID"] = [toFBdetailsArray objectAtIndex:1];
        throwBallActivity[@"BeingReturned"] = [NSNumber numberWithBool:NO];
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"user_ball_thrown"];
        userBallStateChanged = YES;
        
        [toFBdetailsArray removeObjectAtIndex:0];
        [toFBdetailsArray removeObjectAtIndex:0];
        
        [throwBallActivity saveInBackground];
        
        [self performSegueWithIdentifier:@"AfterThrowingSegue" sender:self];
    } else {
        NSDictionary *tempDictionary = activityArray[sub];
        PFObject *myActivity = tempDictionary[@"activity"];
        
        PFQuery *query = [PFQuery queryWithClassName:@"Activity"];
        [query whereKey:@"objectId" equalTo:myActivity.objectId];
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
        {
            PFObject *obj = [objects firstObject];
            [obj setObject:[NSNumber numberWithBool:true] forKey:@"BeingReturned"];
            [obj saveInBackground];
        }];
    }
    
    UIView *ball = [[UIView alloc] init];
    
    for (UIView *myBall in myScrollView.subviews) {
        if (myBall.tag == (sub + 1)) {
            ball = myBall;
        }
    }
    
    [ball removeFromSuperview];
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
