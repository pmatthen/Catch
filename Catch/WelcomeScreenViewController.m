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
@property __block NSString *fBUsername;
@property __block NSString *fBID;
@property BOOL is35;
@property (nonatomic, strong) PFObject *myUser;
@property UITapGestureRecognizer *tapGestureRecognizer;

@end

@implementation WelcomeScreenViewController
@synthesize locationManager, userLocation, fBUsername, fBID, is35, initializingView, activityIndicatorView, myUser, tapGestureRecognizer;

int counter = 0;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    is35 = NO;
    
    CGRect bounds = self.view.bounds;
    CGFloat height = bounds.size.height;
    
    if (height == 480) {
        is35 = YES;
    }
    
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
    if (is35) {
        loginButton.center = CGPointMake(160, 423);
    }
    [loginButton setDelegate:self];
    [self.view addSubview:loginButton];
    
    if ([FBSDKAccessToken currentAccessToken]) {
        __block NSString *username;
        __block NSString *facebookID;
        
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
                facebookID = [result objectForKey:@"id"];
                
                username = [result objectForKey:@"name"];
                
                fBID = facebookID;
                fBUsername = username;
            } else {
                NSString *errorString = [error userInfo][@"error"];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:errorString delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                [alert show];
            }
            
            tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapFrom:)];
            
            [self.view addGestureRecognizer:tapGestureRecognizer];
            
            [activityIndicatorView stopAnimating];
            [initializingView setHidden:TRUE];
        }];
    }
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
    
    __block NSString *username;
    __block NSString *facebookID;
    
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                  initWithGraphPath:@"me"
                                  parameters:nil
                                  HTTPMethod:@"GET"];
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                          id result,
                                          NSError *error) {
        if (!error) {
            facebookID = [result objectForKey:@"id"];
            
            username = [result objectForKey:@"name"];
            
            fBID = facebookID;
            fBUsername = username;
        } else {
            NSString *errorString = [error userInfo][@"error"];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:errorString delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            [alert show];
        }
        
        tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapFrom:)];
        
        [self.view addGestureRecognizer:tapGestureRecognizer];
        
        [activityIndicatorView stopAnimating];
        [initializingView setHidden:TRUE];
    }];
}

-(void)loginButtonDidLogOut:(FBSDKLoginButton *)loginButton {
    NSLog(@"Logged Out");
}

- (void) handleTapFrom: (UITapGestureRecognizer *)recognizer {
    recognizer.enabled = NO;
    PFQuery *query = [PFQuery queryWithClassName:@"User"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
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
                        
                        [self performSegueWithIdentifier:@"MainScreenSegue" sender:self];
                    } else {
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
        myMainScreenViewController.myUser = myUser;
    }
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    UIAlertView *errorAlert = [[UIAlertView alloc]initWithTitle:@"Error" message:@"There was an error retrieving your location" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [errorAlert show];
    NSLog(@"Error: %@",error.description);
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    userLocation = [locations lastObject];
    
    NSLog(@"userlocation #%i = %@", counter, userLocation);
    counter++;
}

@end
