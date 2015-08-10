//
//  FindFriendsViewController.m
//  Catch
//
//  Created by Poulose Matthen on 17/06/15.
//  Copyright (c) 2015 Zettanode. All rights reserved.
//

#import "FindFriendsViewController.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>

@interface FindFriendsViewController () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSMutableArray *facebookFriendsNameArray;
@property (strong, nonatomic) NSMutableArray *facebookFriendsIDArray;
@property (strong, nonatomic) NSMutableArray *detailsArray;

@end

@implementation FindFriendsViewController
@synthesize currentFriendsTableView, facebookFriendsNameArray, facebookFriendsIDArray, detailsArray, delegate;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    facebookFriendsNameArray = [NSMutableArray new];
    facebookFriendsIDArray = [NSMutableArray new];
    detailsArray = [NSMutableArray new];
    
    [self findUserFriends];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

-(void)viewDidLayoutSubviews {
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        [self setNeedsStatusBarAppearanceUpdate];
    }
}

- (void)findUserFriends {

    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                  initWithGraphPath:@"me/friends"
                                  parameters:nil
                                  HTTPMethod:@"GET"];
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                          id result,
                                          NSError *error) {
        if (!error) {
            NSArray *data = [result objectForKey:@"data"];
            NSDictionary *dataIndex = [data firstObject];

            [facebookFriendsNameArray addObject:[dataIndex objectForKey:@"name"]];
            [facebookFriendsIDArray addObject:[dataIndex objectForKey:@"id"]];
        } else {
            NSLog(@"error = %@", error);
        }
        [currentFriendsTableView reloadData];
    }];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [facebookFriendsNameArray count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [currentFriendsTableView dequeueReusableCellWithIdentifier:@"CellID"];
    
    cell.textLabel.text = [facebookFriendsNameArray objectAtIndex:indexPath.row];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [detailsArray addObject:[facebookFriendsNameArray objectAtIndex:indexPath.row]];
    [detailsArray addObject:[facebookFriendsIDArray objectAtIndex:indexPath.row]];
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"friend_selected_to_throw_ball_to"];
    
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)viewWillDisappear:(BOOL)animated {
    [delegate sendFriendDetailsToMainScreen:detailsArray];
    
}

- (IBAction)backButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
