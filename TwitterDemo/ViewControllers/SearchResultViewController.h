//
//  SearchResultViewController.h
//  TwitterDemo
//
//  Created by Scott Zhu on 3/12/16.
//  Copyright © 2016 Scott Zhu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TwitterKit/TwitterKit.h>
@interface SearchResultViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, TWTRTweetViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@end
