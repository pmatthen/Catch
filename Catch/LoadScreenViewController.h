//
//  LoadScreenViewController.h
//  Catch
//
//  Created by Poulose Matthen on 16/10/15.
//  Copyright © 2015 Zettanode. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Parse/Parse.h"
#import <CoreLocation/CoreLocation.h>

@interface LoadScreenViewController : UIViewController <CLLocationManagerDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;

@property (strong, nonatomic) IBOutlet UILabel *loadingLabel;
@property (strong, nonatomic) IBOutlet UILabel *loadingLabel35;

@end
