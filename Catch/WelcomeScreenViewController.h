//
//  ViewController.h
//  Catch
//
//  Created by Poulose Matthen on 04/06/15.
//  Copyright (c) 2015 Zettanode. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Parse/Parse.h"
#import <CoreLocation/CoreLocation.h>

@interface WelcomeScreenViewController : UIViewController <CLLocationManagerDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) IBOutlet UIView *initializingView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorView;

@property (strong, nonatomic) IBOutlet UIButton *logInButton;

@end

