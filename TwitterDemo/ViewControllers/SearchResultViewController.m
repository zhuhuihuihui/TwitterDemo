//
//  SearchResultViewController.m
//  TwitterDemo
//
//  Created by Scott Zhu on 3/12/16.
//  Copyright © 2016 Scott Zhu. All rights reserved.
//

#import "SearchResultViewController.h"

static NSString * const TweetTableReuseIdentifier = @"TweetCell";

@interface SearchResultViewController ()
@property (nonatomic, strong) NSArray *tweets; // Hold all the loaded tweets
@end

@implementation SearchResultViewController
@synthesize tableView = _tableView;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSArray *tweetIDs = @[@"20", // @jack's first Tweet
                          @"510908133917487104" // our favorite Bike tweet
                          ];
    
    // Setup tableview
    self.tableView.estimatedRowHeight = 150;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.allowsSelection = NO;
    [self.tableView registerClass:[TWTRTweetTableViewCell class] forCellReuseIdentifier:TweetTableReuseIdentifier];
    
    // Load tweets
    TWTRAPIClient *client = [[TWTRAPIClient alloc] init];
    [client loadTweetsWithIDs:tweetIDs completion:^(NSArray *tweets, NSError *error) {
        if (tweets) {
            self.tweets = tweets;
            [self.tableView reloadData];
        } else {
            NSLog(@"Failed to load tweet: %@", [error localizedDescription]);
        }
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma -mark- UITableViewDataSource
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TWTRTweet *tweet = self.tweets[indexPath.row];
    
    TWTRTweetTableViewCell *cell = (TWTRTweetTableViewCell *)[tableView dequeueReusableCellWithIdentifier:TweetTableReuseIdentifier forIndexPath:indexPath];
    [cell configureWithTweet:tweet];
    cell.tweetView.delegate = self;
    
    return cell;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.tweets count];
}

// Calculate the height of each row
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    TWTRTweet *tweet = self.tweets[indexPath.row];
    
    return [TWTRTweetTableViewCell heightForTweet:tweet width:CGRectGetWidth(self.view.bounds)];
}


#pragma -mark- UITableViewDelegate

@end
