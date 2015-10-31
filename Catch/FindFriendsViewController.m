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
@synthesize currentFriendsTableView, facebookFriendsNameArray, facebookFriendsIDArray, detailsArray, delegate, lookingForFriendsLabel;

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
            NSDictionary *dataIndex = [[NSDictionary alloc] init];
            
            for (int i = 0; i < [data count]; i++) {
                dataIndex = [data objectAtIndex:i];
                [facebookFriendsNameArray addObject:[dataIndex objectForKey:@"name"]];
                [facebookFriendsIDArray addObject:[dataIndex objectForKey:@"id"]];
            }

        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:[NSString stringWithFormat:@"Please ensure a stable internet connection, and restart the app (%@)", error] delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            [alert show];
            NSLog(@"Error = %@", error);
        }
        
        [currentFriendsTableView setHidden:NO];
        [currentFriendsTableView reloadData];
        
        if ([facebookFriendsNameArray count] == 0) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Uh oh... Looks like none of your friends have our app yet. Tell them about it or try again later!" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            [alert show];
        }
    }];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [facebookFriendsNameArray count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [currentFriendsTableView dequeueReusableCellWithIdentifier:@"CellID"];
    
    cell.textLabel.textColor = [UIColor redColor];
    cell.textLabel.text = [facebookFriendsNameArray objectAtIndex:indexPath.row];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [detailsArray addObject:[facebookFriendsNameArray objectAtIndex:indexPath.row]];
    [detailsArray addObject:[facebookFriendsIDArray objectAtIndex:indexPath.row]];
    
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)viewWillDisappear:(BOOL)animated {
    [delegate sendFriendDetailsToMainScreen:detailsArray];
    
}

- (IBAction)backButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
