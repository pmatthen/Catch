//
//  AfterThrowingViewController.m
//  Catch
//
//  Created by Poulose Matthen on 17/09/15.
//  Copyright (c) 2015 Zettanode. All rights reserved.
//

#import "AfterThrowingViewController.h"

@interface AfterThrowingViewController ()

@property __block NSNumber *ballETA;
@property __block NSString *cityName;
@property __block NSString *friendName;

@end

@implementation AfterThrowingViewController
@synthesize fBID, ballETA, cityName, friendName;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapFrom:)];
    
    [self.view addGestureRecognizer:tapGestureRecognizer];

    [self calculateMessageLabelVariables];
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
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) displayMessage {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setMaximumFractionDigits:0];
    [formatter setMinimumFractionDigits:0];
    
    NSString *messageLabelStringPortion = [[NSString alloc] init];
    
    if (ballETA < [NSNumber numberWithInt:1]) {
        messageLabelStringPortion = [NSString stringWithFormat:@"less than 1 hour"];
    } else if (ballETA < [NSNumber numberWithInt:2]) {
        messageLabelStringPortion = [NSString stringWithFormat:@"approximately 1 hour"];
    } else {
        messageLabelStringPortion = [NSString stringWithFormat:@"approximately %@ hours", [formatter stringFromNumber:ballETA]];
    }
    
    UILabel *messageLabel = [[UILabel alloc] init];
    messageLabel.text = [NSString stringWithFormat:@"Your ball is on it's way to %@. It is moving at .5 kilometers per hour, and it will reach %@ in %@", cityName, friendName, messageLabelStringPortion];
    messageLabel.font = [UIFont fontWithName:@"AvenirNextCondensed-Bold" size:28];
    messageLabel.textColor = [UIColor redColor];
    messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
    messageLabel.numberOfLines = 0;

    [messageLabel setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    
    [self.view addSubview:messageLabel];
}

- (void) calculateMessageLabelVariables {
    __block PFObject *myUser = [PFObject objectWithClassName:@"User"];
    __block PFObject *myFriend = [PFObject objectWithClassName:@"User"];
    __block PFObject *myActivity = [PFObject objectWithClassName:@"Activity"];
    ballETA = [[NSNumber alloc] init];
    cityName = [[NSString alloc] init];
    friendName = [[NSString alloc] init];
    
    PFQuery *UserQuery = [PFQuery queryWithClassName:@"User"];
    [UserQuery findObjectsInBackgroundWithBlock:^(NSArray *userObjects, NSError *error) {
        for (PFObject *user in userObjects) {
            if ([fBID isEqualToString:user[@"facebookID"]]) {
                myUser = user;
            }
        }
        
        NSLog(@"User Name = %@", myUser[@"username"]);
        
        PFQuery *ActivityQuery = [PFQuery queryWithClassName:@"Activity"];
        [ActivityQuery findObjectsInBackgroundWithBlock:^(NSArray *activityObjects, NSError *error) {
            for (PFObject *activity in activityObjects) {
                if ([activity[@"FromFBID"] isEqualToString:myUser[@"facebookID"]]) {
                    myActivity = activity;
                }
            }
            
            PFQuery *FriendQuery = [PFQuery queryWithClassName:@"User"];
            [FriendQuery findObjectsInBackgroundWithBlock:^(NSArray *friendObjects, NSError *error) {
                for (PFObject *friend in friendObjects) {
                    if ([friend[@"facebookID"] isEqualToString:myActivity[@"ToFBID"]]) {
                        myFriend = friend;
                    }
                }
                
                friendName = [[myFriend[@"username"] componentsSeparatedByString:@" "] objectAtIndex:0];
                
                PFGeoPoint *myUserGeoPoint = myUser[@"location"];
                PFGeoPoint *myFriendGeoPoint = myFriend[@"location"];
                
                CLLocation *userLocation = [[CLLocation alloc] initWithLatitude:myUserGeoPoint.latitude longitude:myUserGeoPoint.longitude];
                CLLocation *friendsLocation = [[CLLocation alloc] initWithLatitude:myFriendGeoPoint.latitude longitude:myFriendGeoPoint.longitude];
                
                CLLocationDistance distance = [userLocation distanceFromLocation:friendsLocation];
                
                NSLog(@"The distance from user location to friends location is %f meters", distance);
                
                CLGeocoder *reverseGeocoder = [[CLGeocoder alloc] init];
                
                [reverseGeocoder reverseGeocodeLocation:friendsLocation completionHandler:^(NSArray *placemarks, NSError *error) {
                    
                    CLPlacemark *myPlacemark = [placemarks objectAtIndex:0];
                    cityName = myPlacemark.subAdministrativeArea;
                    ballETA = [NSNumber numberWithDouble:(distance/500)];
                    
                    [self displayMessage];
                }];
            }];
        }];
    }];
}

@end
