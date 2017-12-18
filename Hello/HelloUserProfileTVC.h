//
//  HelloUserProfileTVC.h
//  tilechat
//
//  Created by Andrea Sponziello on 18/12/2017.
//  Copyright © 2017 Frontiere21. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HelloUser;

@interface HelloUserProfileTVC : UITableViewController

@property (strong, nonatomic) HelloUser *user;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *fullNameLabel;


@end
