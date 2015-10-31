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

@interface MainScreenViewController () <UIScrollViewDelegate>

@property (nonatomic, strong) CMMotionManager * motionManager;
@property (nonatomic, strong) NSMutableArray *toFBdetailsArray;
@property BOOL is35;

@property (nonatomic, strong) NSMutableArray *tempActivityArray;
@property BOOL isBuildActivityStarted;
@property BOOL isViewBuilt;
@property int currentPage;
@property int previousPage;
@property float startingX;
@property BOOL userBallStateChanged;
@property __block NSNumber *ballETAInSeconds;
@property __block NSString *cityName;
@property __block NSString *friendName;
@property int calculateMessageLabelCurrentPage;
@property BOOL canMakeParseQueries;
@property BOOL isMessageDisplayed;
@property (nonatomic, strong) PFObject *myFriendsImThrowingTo;
@property (nonatomic, strong) UIButton *selectFriendButton;

@end

@implementation MainScreenViewController
@synthesize fBID, toFBdetailsArray, myUser, is35, tempActivityArray, activityArray, isBuildActivityStarted, isViewBuilt, myScrollView, currentPage, previousPage, startingX, userBallStateChanged, ballETAInSeconds, cityName, friendName, myViewBack, myViewMiddle, myViewFront, rightArrowButton, rightArrowLabel, rightArrowLabel35, canMakeParseQueries, isMessageDisplayed, myFriendsImThrowingTo, player, refreshTime, shouldAnimateIncomingBall, selectFriendButton;

float X = 0;
float Y = 0;
float R = 300;
float speedInMetersPerSecond = 20;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSLog(@"refreshTime = %@", refreshTime);
    
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(onResume)
                                                name:UIApplicationDidBecomeActiveNotification
                                              object:nil];
    
    is35 = NO;
    isViewBuilt = NO;
    isBuildActivityStarted = NO;
    userBallStateChanged = NO;
    canMakeParseQueries = YES;
    isMessageDisplayed = NO;
    shouldAnimateIncomingBall = YES;
    selectFriendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
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
    myFriendsImThrowingTo = [PFObject objectWithClassName:@"User"];
    
    currentPage = 0;
    previousPage = 0;
    
    [self buildView];
    
    NSLog(@"myUser[facebookID] = %@", myUser[@"facebookID"]);
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSLog(@"ViewWillAppear");
    
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
    
    if ([toFBdetailsArray count] > 0) {
        UILabel *throwBallLabel = [[UILabel alloc] init];
        
        float heightValue = 85;
        if (is35) {
            heightValue = 73;
        }
        throwBallLabel.frame = CGRectMake(0, -5, 320, heightValue);
        throwBallLabel.text = @"Ok, throw your ball!";
        throwBallLabel.font = [UIFont systemFontOfSize:20];
        throwBallLabel.textAlignment = NSTextAlignmentCenter;
        throwBallLabel.textColor = [UIColor redColor];
        throwBallLabel.tag = 70000;
        
        [myScrollView addSubview:throwBallLabel];
        
        [self performSelector:@selector(removeThrowBallLabelFromView) withObject:nil afterDelay:3];
    }
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    shouldAnimateIncomingBall = NO;
    [self performSelector:@selector(findAFriendButtonDelayedShow) withObject:nil afterDelay:2.0f];
    
    [self buildView];

}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
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
    
    if (currentPage != ([activityArray count] - 1)) {
        [rightArrowButton setHidden:NO];
        [rightArrowLabel setHidden:NO];
        [rightArrowLabel35 setHidden:NO];
    } else {
        [rightArrowButton setHidden:YES];
        [rightArrowLabel setHidden:YES];
        [rightArrowLabel35 setHidden:YES];
    }
    
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
        if (myView.tag == 80000) {
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"user_ball_thrown"] == NO) {
                [myView removeFromSuperview];
            }
        } else {
            [myView removeFromSuperview];
        }
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
        // Code for User Ball
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"user_ball_thrown"]) {
            // Code for when User Ball has been thrown
            if (isMessageDisplayed == NO) {
                UILabel *noBallLabel = [[UILabel alloc] init];
                noBallLabel.text = @"No Ball";
                noBallLabel.font = [UIFont systemFontOfSize:20];
                noBallLabel.textColor = [UIColor blackColor];
                [noBallLabel sizeToFit];
                
                noBallLabel.frame = CGRectMake(((self.view.frame.size.width - noBallLabel.frame.size.width)/2), ((self.view.frame.size.height - noBallLabel.frame.size.height)/2), noBallLabel.frame.size.width, noBallLabel.frame.size.height);
                noBallLabel.tag = 50000;
                
                [myScrollView addSubview:noBallLabel];
                [myScrollView sendSubviewToBack:noBallLabel];
            }
        } else {
            // Code for when User Ball has not been thrown
            if ([toFBdetailsArray count] > 0) {
                // Code for when User Ball has not been thrown and Friend has been selected
                [self initBall:sub];
            } else {
                // Code for when User Ball has not been thrown and Friend has not been selected
                [selectFriendButton addTarget:self
                           action:@selector(findFriends)
                 forControlEvents:UIControlEventTouchUpInside];
                [selectFriendButton setTitle:@"Find a friend to throw your ball to." forState:UIControlStateNormal];
                selectFriendButton.backgroundColor = [UIColor clearColor];
                selectFriendButton.titleLabel.font = [UIFont systemFontOfSize:20];
                [selectFriendButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
                selectFriendButton.titleLabel.textAlignment = NSTextAlignmentLeft;
                selectFriendButton.titleLabel.numberOfLines = 0;
                selectFriendButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
                [selectFriendButton setHidden:YES];
                float heightValue = 95;
                if (is35) {
                    heightValue = 80;
                }
                selectFriendButton.frame = CGRectMake(30, -5, 250, heightValue);
                selectFriendButton.tag = 60000;

                [myScrollView insertSubview:selectFriendButton atIndex:1];
                
                [self initBall:sub];
            }
        }
    } else {
        // Code for Friend Ball
        
        PFObject *fromUser = activity[@"from"];
        UILabel *myLabel = [[UILabel alloc] init];
        myLabel.font = [UIFont systemFontOfSize:20];
        myLabel.textColor = [UIColor blackColor];
        
        NSString *str = fromUser[@"username"];
        NSRange range= [str rangeOfString: @" " options: NSBackwardsSearch];
        NSString* str1= [str substringToIndex: range.location]; // @"this is a"
        myLabel.text = [NSString stringWithFormat:@"You have %@'s ball", str1];
        myLabel.tag = 40000;
        
        [myLabel sizeToFit];
        float yValue = 490;
        if (is35) {
            yValue = 414;
        }
        myLabel.frame = CGRectMake((((self.view.frame.size.width - myLabel.frame.size.width)/2) + (sub * self.view.frame.size.width)), yValue, myLabel.frame.size.width, myLabel.frame.size.height);
        
        [myScrollView addSubview:myLabel];
        [myScrollView bringSubviewToFront:myLabel];
        
        [self initBall:sub];
    }
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
        if (subViewToAdd == 0) {
            [self performSelector:@selector(findAFriendButtonDelayedShow) withObject:nil afterDelay:2.0f];
        }
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
    [userActivityQuery findObjectsInBackgroundWithBlock:^(NSArray *activityObjects, NSError *error1) {
        if (!error1 || (canMakeParseQueries == NO)) {
            if ([activityObjects count] > 0) {
                for (PFObject *myUserActivity in activityObjects) {
                    if ([myUserActivity[@"FromFBID"] isEqualToString:fBID]) {
                        userActivity = myUserActivity;
                    }
                }
            }
            NSLog(@"1. userActivity = %@", userActivity);
            
            if ((userActivity[@"FromFBID"] != NULL) && (userActivity[@"BeingReturned"] == [NSNumber numberWithBool:TRUE])) {
                PFQuery *FriendQuery = [PFQuery queryWithClassName:@"User"];
                [FriendQuery findObjectsInBackgroundWithBlock:^(NSArray *friendObjects, NSError *error2) {
                    if (!error2 || (canMakeParseQueries == NO)) {
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
                        
                        double secondsForBallToTravel = distance/speedInMetersPerSecond;
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
                                    shouldAnimateIncomingBall = YES;
                                    NSLog(@"Object deleted from Parse");
                                    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"user_ball_thrown"];
                                    userBallStateChanged = YES;
                                    isMessageDisplayed = NO;
                                } else {
                                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:@"Network request limit has been exceeded. Waiting for 30 seconds before trying again." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                                    [alert show];
                                    NSLog(@"Error = %@", error);
                                    canMakeParseQueries = NO;
                                    [self performSelector:@selector(canMakeParseQueriesMethod) withObject:nil afterDelay:30.0f];
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
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:@"Network request limit has been exceeded. Waiting for 30 seconds before trying again." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                        [alert show];
                        NSLog(@"Error = %@", error2);
                        canMakeParseQueries = NO;
                        [self performSelector:@selector(canMakeParseQueriesMethod) withObject:nil afterDelay:30.0f];
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
            [friendActivityQuery findObjectsInBackgroundWithBlock:^(NSArray *activityObjects, NSError *error3) {
                if (!error3 || (canMakeParseQueries == NO)) {
                    NSMutableArray *tempActivityObjects = [NSMutableArray new];
                    
                    for (PFObject *myFriendActivity in activityObjects) {
                        if ([myFriendActivity[@"ToFBID"] isEqualToString:fBID]) {
                            [tempActivityObjects addObject:myFriendActivity];
                        }
                    }
                    
                    remainingActivities = [NSMutableSet setWithArray:tempActivityObjects];
                    
                    NSLog(@"3. remainingActivities = %@", remainingActivities);
                    
                    if ([remainingActivities count] > 0) {
                        PFQuery *friendQuery = [PFQuery queryWithClassName:@"User"];
                        [friendQuery findObjectsInBackgroundWithBlock:^(NSArray *friendObjects, NSError *error4) {
                            if (!error4 || (canMakeParseQueries == NO)) {
                                NSLog(@"4. friendObjects = %@", friendObjects);
                                for (PFObject *activity in tempActivityObjects) {
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
                                    double secondsForBallToTravel = distance/speedInMetersPerSecond;
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
                                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:@"Network request limit has been exceeded. Waiting for 30 seconds before trying again." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                                [alert show];
                                NSLog(@"Error = %@", error4);
                                canMakeParseQueries = NO;
                                [self performSelector:@selector(canMakeParseQueriesMethod) withObject:nil afterDelay:30.0f];
                                isError = YES;
                                dispatch_group_leave(taskGroup);
                            }
                        }];
                    } else {
                        dispatch_group_leave(taskGroup);
                    }
                } else {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:@"Network request limit has been exceeded. Waiting for 30 seconds before trying again." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                    [alert show];
                    NSLog(@"Error = %@", error3);
                    canMakeParseQueries = NO;
                    [self performSelector:@selector(canMakeParseQueriesMethod) withObject:nil afterDelay:30.0f];
                    isError = YES;
                    dispatch_group_leave(taskGroup);
                }
            }];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:@"Network request limit has been exceeded. Waiting for 30 seconds before trying again." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            [alert show];
            NSLog(@"Error = %@", error1);
            canMakeParseQueries = NO;
            [self performSelector:@selector(canMakeParseQueriesMethod) withObject:nil afterDelay:30.0f];
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
            shouldAnimateIncomingBall = YES;
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
        [NSTimer scheduledTimerWithTimeInterval:[refreshTime intValue] target:self selector:@selector(buildActivityDictionaryMethod) userInfo:nil repeats:YES];
        
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
    
    if (currentPage != ([activityArray count] - 1)) {
        [rightArrowButton setHidden:NO];
        [rightArrowLabel setHidden:NO];
        [rightArrowLabel35 setHidden:NO];
    } else {
        [rightArrowButton setHidden:YES];
        [rightArrowLabel setHidden:YES];
        [rightArrowLabel35 setHidden:YES];
    }
    
    [self pulsateArrow];
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
        [ball setFrame:CGRectMake((10 + (sub * self.view.frame.size.width)), (268 - 568), R, R)];
        ball.layer.cornerRadius = 150;
        if (is35) {
            [ball setFrame:CGRectMake((10 + (sub * self.view.frame.size.width)), (226 - 568), R, R)];
            ball.layer.cornerRadius = 127;
        }
        
        if (is35) {
            [ball setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"redballSmaller.png"]]];
        } else {
            [ball setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"redball1.png"]]];
        }
        
        CGRect frame = CGRectMake(ball.frame.origin.x, (ball.frame.origin.y + 568), ball.frame.size.width, ball.frame.size.height);
        if (shouldAnimateIncomingBall) {
            NSLog(@"Animation Start");
            [self playAudioFiles:0];
            [UIView animateWithDuration:0.9 animations:^{
                ball.frame = frame;
            } completion:^(BOOL finished) {
                NSLog(@"Animation Finish");
                [self performSelector:@selector(findAFriendButtonDelayedShow) withObject:nil afterDelay:2.0f];
                ball.frame = frame;
                shouldAnimateIncomingBall = NO;
            }];
        } else {
            [ball setFrame:CGRectMake((10 + (sub * self.view.frame.size.width)), 134, R, R)];
            ball.layer.cornerRadius = 150;
            if (is35) {
                [ball setFrame:CGRectMake((10 + (sub * self.view.frame.size.width)), 113, R, R)];
                ball.layer.cornerRadius = 127;
            }
        }
    } else {
        if (is35) {
            [ball setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"blueballSmaller.png"]]];
        } else {
            [ball setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"blueball1.png"]]];
        }
        
    }
    ball.tag = sub + 1;
    
    [myScrollView addSubview:ball];
    
    for (UIView *tempView in myScrollView.subviews) {
        // messageLabel
        if (tempView.tag == 80000) {
            [myScrollView sendSubviewToBack:tempView];
        }
        // selectFriendButton
        if (tempView.tag == 60000) {
            [myScrollView sendSubviewToBack:tempView];
        }
        // noBallLabel
        if (tempView.tag == 50000) {
            [myScrollView sendSubviewToBack:tempView];
        }
        // mylabel
        if (tempView.tag == 40000) {
            [myScrollView bringSubviewToFront:tempView];
        }
    }
}

- (void)updateBallWithRoll:(float)roll Pitch:(float)pitch Yaw:(float)yaw accX:(float)accX accY:(float)accY accZ:(float)accZ sub:(int)sub {
    
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
    
    if ((accY > 1.5) && (accZ > 1.5)) {
        if (sub == 0) {
            if ([toFBdetailsArray count] > 0) {
                if(self.motionManager != nil){
                    [self.motionManager stopDeviceMotionUpdates];
                    self.motionManager = nil;
                }
                [self throwBall:sub];
                return;
            }
        } else {
            if(self.motionManager != nil){
                [self.motionManager stopDeviceMotionUpdates];
                self.motionManager = nil;
            }
            [self throwBall:sub];
            return;
        }
    } else {
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
    UIView *ball = [[UIView alloc] init];
    
    for (UIView *myBall in myScrollView.subviews) {
        if (myBall.tag == (sub + 1)) {
            ball = myBall;
        }
    }
    
    CGRect frame = CGRectMake(ball.frame.origin.x, (ball.frame.origin.y - 568), ball.frame.size.width, ball.frame.size.height);
    
    NSLog(@"Animation Start");
    [UIView animateWithDuration:0.3 animations:^{
                         ball.frame = frame;
                     } completion:^(BOOL finished) {
                         NSLog(@"Animation Finish");
                         ball.frame = frame;
                         [ball removeFromSuperview];
                         isMessageDisplayed = YES;
                         [self performSelector:@selector(buildView) withObject:nil afterDelay:1.5f];
                         
                         self.motionManager = [[CMMotionManager alloc] init];
                         
                         self.motionManager.deviceMotionUpdateInterval = 1.0 / 60.0;
                         
                         [self.motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryCorrectedZVertical];
                     }];
    [self playAudioFiles:1];
    
    if (sub == 0) {
        for (UIView *myVire in myScrollView.subviews) {
            if (myVire.tag == 50000) {
                [myVire removeFromSuperview];
            }
        }
        
        PFObject *throwBallActivity = [PFObject objectWithClassName:@"Activity"];
        throwBallActivity[@"FromFBID"] = fBID;
        throwBallActivity[@"ToFBID"] = [toFBdetailsArray objectAtIndex:1];
        throwBallActivity[@"BeingReturned"] = [NSNumber numberWithBool:NO];
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"user_ball_thrown"];
        userBallStateChanged = YES;
        [throwBallActivity saveInBackground];
        
        PFQuery *FriendQuery = [PFQuery queryWithClassName:@"User"];
        [FriendQuery findObjectsInBackgroundWithBlock:^(NSArray *friendObjects, NSError *error) {
            if (!error) {
                for (PFObject *friend in friendObjects) {
                    if ([friend[@"facebookID"] isEqualToString:[toFBdetailsArray objectAtIndex:1]]) {
                        myFriendsImThrowingTo = friend;
                        [self performSelector:@selector(calculateMessageLabelVariables) withObject:nil afterDelay:1.0f];
                        [toFBdetailsArray removeObjectAtIndex:0];
                        [toFBdetailsArray removeObjectAtIndex:0];
                    }
                }
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:[NSString stringWithFormat:@"Please ensure a stable internet connection, and restart the app"] delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                [alert show];
            }
        }];
    } else {
        shouldAnimateIncomingBall = YES;
        NSDictionary *tempDictionary = activityArray[sub];
        PFObject *myActivity = tempDictionary[@"activity"];
        
        PFQuery *query = [PFQuery queryWithClassName:@"Activity"];
        [query whereKey:@"objectId" equalTo:myActivity.objectId];
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error || (canMakeParseQueries == NO)) {
                PFObject *obj = [objects firstObject];
                [obj setObject:[NSNumber numberWithBool:true] forKey:@"BeingReturned"];
                [obj saveInBackground];
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:@"Network request limit has been exceeded. Waiting for 30 seconds before trying again." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                [alert show];
                NSLog(@"Error = %@", error);
                canMakeParseQueries = NO;
                [self performSelector:@selector(canMakeParseQueriesMethod) withObject:nil afterDelay:30.0f];
            }
        }];
    }
    
    if ([activityArray count] > 1) {
        [activityArray removeObjectAtIndex:sub];
    }
}

- (void) displayMessage {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setMaximumFractionDigits:0];
    [formatter setMinimumFractionDigits:0];
    
    NSString *messageLabelStringPortion = [[NSString alloc] init];
    
    if (ballETAInSeconds < [NSNumber numberWithInt:60]) {
        messageLabelStringPortion = [NSString stringWithFormat:@"It is moving at 20 meters per second and will reach in less than a minute."];
        
    } else if (ballETAInSeconds < [NSNumber numberWithInt:(60*60)]) {
        // Show Minutes
        messageLabelStringPortion = [NSString stringWithFormat:@" It is moving at 20 meters per second and will reach in about %d minutes.", (int)([ballETAInSeconds floatValue]/60)];
        
    } else if (ballETAInSeconds < [NSNumber numberWithInt:(60*60*24)]) {
        // Show Hours
        messageLabelStringPortion = [NSString stringWithFormat:@" It is moving at 20 meters per second and will reach in about %d hours.", (int)([ballETAInSeconds floatValue]/(60 * 60))];
        
    } else {
        // Show Days
        messageLabelStringPortion = [NSString stringWithFormat:@" It is moving at 20 meters per second and will reach in about %d days.", (int)([ballETAInSeconds floatValue]/(60 * 60 * 24))];
    }
    
    for (UIView *myView in myScrollView.subviews) {
        if (myView.tag == 50000) {
            [myView removeFromSuperview];
        }
    }
    
    UILabel *messageLabel = [[UILabel alloc] init];
    messageLabel.text = [NSString stringWithFormat:@"Your ball is on it's way to %@ in %@. %@", friendName, cityName, messageLabelStringPortion];
    messageLabel.font = [UIFont systemFontOfSize:20];
    messageLabel.textColor = [UIColor redColor];
    messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
    messageLabel.tag = 80000;
    messageLabel.numberOfLines = 0;
    
//    noBallLabel.frame = CGRectMake(((self.view.frame.size.width - noBallLabel.frame.size.width)/2), ((self.view.frame.size.height - noBallLabel.frame.size.height)/2), noBallLabel.frame.size.width, noBallLabel.frame.size.height);
    
    [messageLabel setFrame:CGRectMake(40, 250, 240, 400)];
    NSLog(@"1. messageLabel.frame = X:%.2f Y:%.2f W:%.2f H:%.2f", messageLabel.frame.origin.x, messageLabel.frame.origin.y, messageLabel.frame.size.width, messageLabel.frame.size.height);
    [messageLabel sizeToFit];
    NSLog(@"2. messageLabel.frame = X:%.2f Y:%.2f W:%.2f H:%.2f", messageLabel.frame.origin.x, messageLabel.frame.origin.y, messageLabel.frame.size.width, messageLabel.frame.size.height);
    [messageLabel setFrame:CGRectMake(40, ((self.view.frame.size.height - messageLabel.frame.size.height)/2), 240, messageLabel.frame.size.height)];
    NSLog(@"3. messageLabel.frame = X:%.2f Y:%.2f W:%.2f H:%.2f", messageLabel.frame.origin.x, messageLabel.frame.origin.y, messageLabel.frame.size.width, messageLabel.frame.size.height);
    
    [myScrollView addSubview:messageLabel];
    [myScrollView sendSubviewToBack:messageLabel];
    isMessageDisplayed = YES;
}

- (void) calculateMessageLabelVariables {
    PFObject *myFriend = [PFObject objectWithClassName:@"User"];
    ballETAInSeconds = [[NSNumber alloc] init];
    cityName = [[NSString alloc] init];
    friendName = [[NSString alloc] init];
    
    NSDictionary *tempDictionary = [NSDictionary new];
    tempDictionary = activityArray[0];
    myUser = tempDictionary[@"from"];
    myFriend = myFriendsImThrowingTo;
    
    
    NSString *myFriendFullNameString = myFriend[@"username"];
    NSRange range = [myFriendFullNameString rangeOfString: @" " options: NSBackwardsSearch];
    NSString *myFriendFirstNameString = [myFriendFullNameString substringToIndex: range.location];
    
    friendName = myFriendFirstNameString;
    
    PFGeoPoint *myUserGeoPoint = myUser[@"location"];
    PFGeoPoint *myFriendGeoPoint = myFriend[@"location"];
    
    CLLocation *userLocation = [[CLLocation alloc] initWithLatitude:myUserGeoPoint.latitude longitude:myUserGeoPoint.longitude];
    CLLocation *friendsLocation = [[CLLocation alloc] initWithLatitude:myFriendGeoPoint.latitude longitude:myFriendGeoPoint.longitude];
    
    CLLocationDistance distance = [userLocation distanceFromLocation:friendsLocation];
    
    CLGeocoder *reverseGeocoder = [[CLGeocoder alloc] init];
    
    [reverseGeocoder reverseGeocodeLocation:friendsLocation completionHandler:^(NSArray *placemarks, NSError *error) {
        if (!error) {
            CLPlacemark *myPlacemark = [placemarks objectAtIndex:0];
            cityName = myPlacemark.locality;
            ballETAInSeconds = [NSNumber numberWithDouble:(distance/speedInMetersPerSecond)];
            
            [self displayMessage];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:@"Please restart the app" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            [alert show];
            NSLog(@"Error = %@", error);
        }
    }];
}


-(void) findFriends {
    [self performSegueWithIdentifier:@"FriendsScreenSegue" sender:self];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"FriendsScreenSegue"]) {
        FindFriendsViewController *myFindFriendsViewController = (FindFriendsViewController *) segue.destinationViewController;
        myFindFriendsViewController.delegate = self;
    }
}

-(void)sendFriendDetailsToMainScreen:(NSMutableArray *) detailsArray {
    if ([detailsArray count] > 0) {
        NSLog(@"Selected Name = %@", detailsArray[0]);
        NSLog(@"Selected ID = %@", detailsArray[1]);
    }
    
    toFBdetailsArray = detailsArray;
    shouldAnimateIncomingBall = NO;
}

-(void) removeThrowBallLabelFromView {
    for (UIView *myView in myScrollView.subviews) {
        if (myView.tag == 70000) {
            [myView removeFromSuperview];
        }
    }
}

-(void) pulsateArrow {
    [UIView animateWithDuration:0.5 animations:^{
        
        rightArrowButton.alpha = 0;
        rightArrowLabel.alpha = 0;
        rightArrowLabel35.alpha = 0;
    } completion:^(BOOL finished){
        
        [UIView animateWithDuration:0.5 animations:^{
            
            rightArrowButton.alpha = 1;
            rightArrowLabel.alpha = 1;
            rightArrowLabel35.alpha = 1;
        } completion:^(BOOL finished){
            
        }];
    }];
}

-(void) canMakeParseQueriesMethod {
    canMakeParseQueries = YES;
}

-(void) onResume {
    shouldAnimateIncomingBall = NO;
    isMessageDisplayed = NO;
    [self performSelector:@selector(findAFriendButtonDelayedShow) withObject:nil afterDelay:2.0f];
    for (UIView *myView in myScrollView.subviews) {
        if (myView.tag == 80000) {
            [myView removeFromSuperview];
        }
    }
    
    [self buildView];
}

-(void) playAudioFiles:(int)soundNumber {
    NSString *soundFilePath = [[NSString alloc] init];
    switch (soundNumber) {
        case 0:
            soundFilePath = [NSString stringWithFormat:@"%@/pop!.wav",
                             [[NSBundle mainBundle] resourcePath]];
            break;
        case 1:
            soundFilePath = [NSString stringWithFormat:@"%@/swooshOct.wav",
                             [[NSBundle mainBundle] resourcePath]];
            break;
        default:
            break;
    }
    
    NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
    
    AVAudioPlayer *newPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL
                                                                   error:nil];
    player = newPlayer;
    [player play];
}

- (IBAction)rightArrowButtonPressed:(id)sender {
    [myScrollView setContentOffset:CGPointMake((myScrollView.contentOffset.x + 320), myScrollView.contentOffset.y) animated:YES];
    
    currentPage++;
    
    if (currentPage != ([activityArray count] - 1)) {
        [rightArrowButton setHidden:NO];
        [rightArrowLabel setHidden:NO];
        [rightArrowLabel35 setHidden:NO];
    } else {
        [rightArrowButton setHidden:YES];
        [rightArrowLabel setHidden:YES];
        [rightArrowLabel35 setHidden:YES];
    }
    
    if (currentPage != previousPage) {
        if (currentPage > previousPage) {
            [self swipePhoto:(currentPage - 2) andAdd:(currentPage + 1)];
        }
        if (currentPage < previousPage) {
            [self swipePhoto:(currentPage + 2) andAdd:(currentPage - 1)];
        }
        previousPage = currentPage;
    }
}

- (void) findAFriendButtonDelayedShow {
    [selectFriendButton setHidden:NO];
}

@end
