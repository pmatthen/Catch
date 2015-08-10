//
//  ViewController.m
//  Catch
//
//  Created by Poulose Matthen on 04/06/15.
//  Copyright (c) 2015 Zettanode. All rights reserved.
//

#import "WelcomeScreenViewController.h"
#import "MainScreenViewController.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

@interface WelcomeScreenViewController () <UIGestureRecognizerDelegate, CLLocationManagerDelegate>

@property CLLocation *userLocation;
@property __block NSString *fBUsername;
@property __block NSNumber *fBID;

@end

@implementation WelcomeScreenViewController
@synthesize locationManager, userLocation, fBUsername, fBID;

- (void)viewDidLoad {
    [super viewDidLoad];
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
        [locationManager requestWhenInUseAuthorization];
    
    [locationManager startUpdatingLocation];
    
    FBSDKLoginButton *loginButton = [[FBSDKLoginButton alloc] init];
    loginButton.readPermissions = @[@"public_profile", @"email", @"user_friends"];
    loginButton.center = CGPointMake(160, 500);
    [self.view addSubview:loginButton];
    
    __block NSString *username;
    __block NSNumber *facebookID;
    
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                  initWithGraphPath:@"me"
                                  parameters:nil
                                  HTTPMethod:@"GET"];
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                          id result,
                                          NSError *error) {
        if (!error) {
            username = [result objectForKey:@"name"];
            facebookID = [NSNumber numberWithLongLong:[[result objectForKey:@"id"] longLongValue]];
            
            fBID = facebookID;
            fBUsername = username;
        } else {
            NSString *errorString = [error userInfo][@"error"];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:errorString delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            [alert show];
        }
        
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapFrom:)];
        
        [self.view addGestureRecognizer:tapGestureRecognizer];
    }];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

-(void)viewDidLayoutSubviews {
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        [self setNeedsStatusBarAppearanceUpdate];
    }
}

- (void) handleTapFrom: (UITapGestureRecognizer *)recognizer {
    __block BOOL userSignedUp = NO;
    __block PFObject *myUser = [PFObject objectWithClassName:@"User"];
    
    PFQuery *query = [PFQuery queryWithClassName:@"User"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            for (PFObject *user in objects) {
                if (user[@"facebookID"] == fBID) {
                    myUser = user;
                    NSLog(@"User Signed Up Already");
                    userSignedUp = YES;
                }
            }
            
            [PFGeoPoint geoPointForCurrentLocationInBackground:^(PFGeoPoint *geoPoint, NSError *error) {
                if (!error) {
                    if (userSignedUp) {
                        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"friend_selected_to_throw_ball_to"];
                        
                        // REMOVE THIS WHEN RECIEVING BALL CODE IS WRITTEN
                        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"user_ball_thrown"];
                        // XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
                        
                        [myUser setObject:geoPoint forKey:@"location"];
                        [myUser saveInBackground];
                        [locationManager stopUpdatingLocation];
                        
                        [self performSegueWithIdentifier:@"MainScreenSegue" sender:self];
                    } else {
                        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"friend_selected_to_throw_ball_to"];
                        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"user_ball_thrown"];
                        
                        [myUser setObject:geoPoint forKey:@"location"];
                        [myUser setObject:fBID forKey:@"facebookID"];
                        [myUser setObject:fBUsername forKey:@"username"];
                        [myUser saveInBackground];
                        [locationManager stopUpdatingLocation];
                        
                        [self performSegueWithIdentifier:@"MainScreenSegue" sender:self];
                    }
                } else {
                    NSLog(@"error = %@", error);
                }
            }];
        } else {
            NSLog(@"error = %@", error);
        }
    }];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"MainScreenSegue"]) {
        MainScreenViewController *myMainScreenViewController = (MainScreenViewController *) segue.destinationViewController;
        
        myMainScreenViewController.fBID = fBID;
        myMainScreenViewController.fBUsername = fBUsername;
    }
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    UIAlertView *errorAlert = [[UIAlertView alloc]initWithTitle:@"Error" message:@"There was an error retrieving your location" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [errorAlert show];
    NSLog(@"Error: %@",error.description);
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    userLocation = [locations lastObject];
}

@end
