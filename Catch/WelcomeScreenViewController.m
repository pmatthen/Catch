//
//  ViewController.m
//  Catch
//
//  Created by Poulose Matthen on 04/06/15.
//  Copyright (c) 2015 Zettanode. All rights reserved.
//  Username: manmohansingh26932
//  Password: qpwoei123
//
//  Username: pranabmukherjee111235
//  Password: qpwoei123
//

#import "WelcomeScreenViewController.h"
#import "MainScreenViewController.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

@interface WelcomeScreenViewController () <UIGestureRecognizerDelegate, CLLocationManagerDelegate, FBSDKLoginButtonDelegate>

@property CLLocation *userLocation;
@property __block NSString *fBID;
@property BOOL is35;
@property (nonatomic, strong) PFObject *myUser;
@property UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, strong) NSMutableArray *tempActivityArray;
@property (nonatomic, strong) NSMutableArray *activityArray;
@property (nonatomic, strong) NSNumber *refreshTime;

@end

@implementation WelcomeScreenViewController
@synthesize locationManager, userLocation, fBID, is35, initializingView, activityIndicatorView, myUser, tapGestureRecognizer, tempActivityArray, activityArray, refreshTime;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    is35 = NO;
    
    CGRect bounds = self.view.bounds;
    CGFloat height = bounds.size.height;
    
    if (height == 480) {
        is35 = YES;
    }
    
    tempActivityArray = [NSMutableArray new];
    activityArray = [NSMutableArray new];
    
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
        [locationManager requestWhenInUseAuthorization];
    
    [locationManager startUpdatingLocation];
    
    FBSDKLoginButton *loginButton = [[FBSDKLoginButton alloc] init];
    loginButton.readPermissions = @[@"public_profile", @"email", @"user_friends"];
    loginButton.center = CGPointMake(160, 485);
    if (is35) {
        loginButton.center = CGPointMake(160, 420);
    }
    [loginButton setDelegate:self];
    [self.view addSubview:loginButton];
}

-(void)viewDidAppear:(BOOL)animated {
    tapGestureRecognizer.enabled = YES;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

-(void)viewDidLayoutSubviews {
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        [self setNeedsStatusBarAppearanceUpdate];
    }
}

- (void)  loginButton:  (FBSDKLoginButton *)loginButton
didCompleteWithResult:  (FBSDKLoginManagerLoginResult *)result
                error:  (NSError *)error{
    
    [activityIndicatorView startAnimating];
    [initializingView setHidden:FALSE];
    
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                  initWithGraphPath:@"me"
                                  parameters:nil
                                  HTTPMethod:@"GET"];
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                          id result,
                                          NSError *error) {
        if (!error) {
            fBID = [result objectForKey:@"id"];
        } else {
            NSString *errorString = [error userInfo][@"error"];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:errorString delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            [alert show];
        }
        
        PFQuery *query = [PFQuery queryWithClassName:@"User"];
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            PFQuery *refreshTimeQuery = [PFQuery queryWithClassName:@"Settings"];
            [refreshTimeQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                PFObject *tempRefreshTime = [PFObject objectWithClassName:@"Settings"];
                tempRefreshTime = [objects firstObject];
                refreshTime = tempRefreshTime[@"refreshTime"];
            }];
            
            BOOL userSignedUp = NO;
            myUser = [PFObject objectWithClassName:@"User"];
            
            if (!error) {
                for (PFObject *user in objects) {
                    if ([fBID isEqualToString:user[@"facebookID"]]) {
                        myUser = user;
                        NSLog(@"User Signed Up Already");
                        userSignedUp = YES;
                    }
                }
                
                [PFGeoPoint geoPointForCurrentLocationInBackground:^(PFGeoPoint *geoPoint, NSError *error) {
                    if (!error) {
                        if (userSignedUp) {
                            [myUser setObject:geoPoint forKey:@"location"];
                            [myUser saveInBackground];
                            [locationManager stopUpdatingLocation];
                            
                            [self buildActivityDictionary];
                        } else {
                            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"user_ball_thrown"];
                            
                            [myUser setObject:geoPoint forKey:@"location"];
                            [myUser setObject:fBID forKey:@"facebookID"];
                            [myUser saveInBackground];
                            [locationManager stopUpdatingLocation];
                            
                            [self buildActivityDictionary];
                        }
                    } else {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:@"Please ensure a stable internet connection, and restart the app" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                        [alert show];
                        NSLog(@"Error = %@", error);
                    }
                }];
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:@"Please ensure a stable internet connection, and restart the app" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                [alert show];
                NSLog(@"Error = %@", error);
            }
        }];
    }];
}

-(void)loginButtonDidLogOut:(FBSDKLoginButton *)loginButton {
    NSLog(@"Logged Out");
}

- (void) buildActivityDictionary {
    NSLog(@"buildActivityDictionary method started");
    
    __block PFObject *myFriend = [PFObject objectWithClassName:@"User"];
    __block PFObject *userActivity = [PFObject objectWithClassName:@"Activity"];
    __block PFObject *friendActivity = [PFObject objectWithClassName:@"Activity"];
    __block NSMutableDictionary *userDictionary = [NSMutableDictionary new];
    __block NSMutableArray *friendsActivityArray = [NSMutableArray new];
    __block NSArray *sortedFriendsActivityArray = [NSMutableArray new];
    __block NSMutableSet *remainingActivities = [NSMutableSet new];
    __block BOOL isError = NO;
    
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
                        
                        CLLocation *usersLocation = [[CLLocation alloc] initWithLatitude:myUserGeoPoint.latitude longitude:myUserGeoPoint.longitude];
                        CLLocation *friendsLocation = [[CLLocation alloc] initWithLatitude:myFriendGeoPoint.latitude longitude:myFriendGeoPoint.longitude];
                        
                        CLLocationDistance distance = [usersLocation distanceFromLocation:friendsLocation];
                        
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
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:@"Please ensure a stable internet connection, and restart the app" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                        [alert show];
                        NSLog(@"Error = %@", error2);
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
                                    
                                    CLLocation *usersLocation = [[CLLocation alloc] initWithLatitude:myUserGeoPoint.latitude longitude:myUserGeoPoint.longitude];
                                    CLLocation *friendsLocation = [[CLLocation alloc] initWithLatitude:myFriendGeoPoint.latitude longitude:myFriendGeoPoint.longitude];
                                    
                                    CLLocationDistance distance = [usersLocation distanceFromLocation:friendsLocation];
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
                                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:@"Please ensure a stable internet connection, and restart the app" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                                [alert show];
                                NSLog(@"Error = %@", error4);
                                isError = YES;
                                dispatch_group_leave(taskGroup);
                            }
                        }];
                    } else {
                        dispatch_group_leave(taskGroup);
                    }
                } else {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:@"Please ensure a stable internet connection, and restart the app" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                    [alert show];
                    NSLog(@"Error = %@", error3);
                    isError = YES;
                    dispatch_group_leave(taskGroup);
                }
            }];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:@"Please ensure a stable internet connection, and restart the app" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            [alert show];
            NSLog(@"Error = %@", error1);
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
        
        if (isTheSame == NO) {
            activityArray = [NSMutableArray arrayWithArray:tempActivityArray];
            
            for (int i = 0; i < [activityArray count]; i++) {
                NSDictionary *tempDictionary = activityArray[i];
                NSLog(@"activityArray index #%d = %@", i, tempDictionary[@"timeTillArrival"]);
            }
            
            [self performSegueWithIdentifier:@"MainScreenSegue" sender:self];
        } else {
            NSLog(@"THE SAME!!");
        }
    });
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"MainScreenSegue"]) {
        MainScreenViewController *myMainScreenViewController = (MainScreenViewController *) segue.destinationViewController;
        
        myMainScreenViewController.fBID = fBID;
        myMainScreenViewController.myUser = myUser;
        myMainScreenViewController.activityArray = activityArray;
        myMainScreenViewController.refreshTime = refreshTime;
    }
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    UIAlertView *errorAlert = [[UIAlertView alloc]initWithTitle:@"Location Error" message:@"There was an error retrieving your location, please restart the app" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [errorAlert show];
    NSLog(@"Error: %@",error.description);
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    userLocation = [locations lastObject];
}

@end
