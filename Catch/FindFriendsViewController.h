//
//  FindFriendsViewController.h
//  Catch
//
//  Created by Poulose Matthen on 17/06/15.
//  Copyright (c) 2015 Zettanode. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol sendDataProtocol <NSObject>

-(void)sendFriendDetailsToMainScreen:(NSMutableArray *) detailsArray;

@end

@interface FindFriendsViewController : UIViewController

@property(nonatomic,assign)id delegate;
@property (strong, nonatomic) IBOutlet UITableView *currentFriendsTableView;
@property (strong, nonatomic) IBOutlet UILabel *lookingForFriendsLabel;

- (IBAction)backButtonPressed:(id)sender;

@end
