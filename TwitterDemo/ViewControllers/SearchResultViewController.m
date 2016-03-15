//
//  SearchResultViewController.m
//  TwitterDemo
//
//  Created by Scott Zhu on 3/12/16.
//  Copyright © 2016 Scott Zhu. All rights reserved.
//

#import "SearchResultViewController.h"
#import "UIScrollView+INSPullToRefresh.h"
#import "INSTwitterPullToRefresh.h"
#import "INSDefaultInfiniteIndicator.h"

#define TweetTableReuseIdentifier @"TweetCell"
#define SearchKeyword @"@peek"
#define TwitterSearchEndPoint @"https://api.twitter.com/1.1/search/tweets.json"

@interface SearchResultViewController ()
@property (nonatomic, strong) NSMutableArray *tweets; // Hold all the loaded tweets
@end

@implementation SearchResultViewController
@synthesize tableView = _tableView;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //1. Setup tableview
    self.tableView.estimatedRowHeight = 150;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.allowsSelection = NO;
    [self.tableView registerClass:[TWTRTweetTableViewCell class] forCellReuseIdentifier:TweetTableReuseIdentifier];
    self.tableView.tableFooterView = [[UIView alloc] init];
    
    //2. Setup pull to refresh component
    [self.tableView ins_addPullToRefreshWithHeight:60.0 handler:^(UIScrollView *scrollView) {
        int64_t delayInSeconds = 1;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self refreshTweetsWithMaxTweetID:nil completion:^(NSArray *tweets, NSError *error) {
                if (nil == error) {
                    self.tweets = [tweets mutableCopy];
                    [self.tableView reloadData];
                } else {
                    NSLog(@"Error: %@", error);
                }
                [scrollView ins_endPullToRefresh];
            }];
        });
    }];
    CGRect pullFrame = CGRectMake(0, 0, 24, 24);
    UIView <INSPullToRefreshBackgroundViewDelegate> *pullToRefresh = [[INSTwitterPullToRefresh alloc] initWithFrame:pullFrame];
    self.tableView.ins_pullToRefreshBackgroundView.delegate = pullToRefresh;
    [self.tableView.ins_pullToRefreshBackgroundView addSubview:pullToRefresh];
    
    //3. Setup infinity scrolling componet
    [self.tableView ins_addInfinityScrollWithHeight:60.0 handler:^(UIScrollView *scrollView) {
        int64_t delayInSeconds = 1;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self refreshTweetsWithMaxTweetID:  ((TWTRTweet *)self.tweets.lastObject).tweetID completion:^(NSArray *tweets, NSError *error) {
                if (nil == error) {
                    NSLog(@"loaded Tweets count = %lu", (unsigned long)tweets.count);
                    [self.tweets addObjectsFromArray:[tweets subarrayWithRange:NSMakeRange(1, tweets.count - 1)]];
                    [self.tableView reloadData];
                } else {
                    NSLog(@"Error: %@", error);
                }
                [scrollView ins_endInfinityScrollWithStoppingContentOffset:NO];
            }];
        });
    }];
    CGRect infinityFrame = CGRectMake(0, 0, 24, 24);
    UIView <INSAnimatable> *infinityRefresh = [[INSDefaultInfiniteIndicator alloc] initWithFrame:infinityFrame];
    [self.tableView.ins_infiniteScrollBackgroundView addSubview:infinityRefresh];
    [infinityRefresh startAnimating];
    
    //4. Refresh tweets for the first time.
    [self refreshTweetsWithMaxTweetID:nil completion:^(NSArray *tweets, NSError *error) {
        if (nil == error) {
            self.tweets = [tweets mutableCopy];
            [self.tableView reloadData];
        } else {
            NSLog(@"Error: %@", error);
        }
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma -mark- Custom Methods
- (void) refreshTweetsWithMaxTweetID: (NSString *) maxTweetID
                          completion: (void (^)(NSArray *tweets, NSError *error)) completion {
    TWTRAPIClient *client = [[TWTRAPIClient alloc] init];
    NSDictionary *params = @{@"q": SearchKeyword, @"result_type": @"recent", @"max_id": maxTweetID? maxTweetID: @""};
    NSError *clientError;
    
    NSURLRequest *request = [[[Twitter sharedInstance] APIClient] URLRequestWithMethod:@"GET" URL:TwitterSearchEndPoint parameters:params error:&clientError];
    
    if (request) {
        [client sendTwitterRequest:request completion:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            if (data) {
                // handle the response data e.g.
                NSError *jsonError;
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
                if (json && jsonError == nil) {
                    NSArray *resultTweets = [json objectForKey:@"statuses"];
                    if (resultTweets && [resultTweets count] > 0) {
                        completion([TWTRTweet tweetsWithJSONArray:resultTweets], nil);
                    } else {
                        completion([[NSArray alloc] init], nil);
                    }
                } else {
                    completion(nil, jsonError);
                }
            }
            else {
                completion(nil, connectionError);
            }
        }];
    }
    else {
        NSLog(@"Error: %@", clientError);
    }
}

#pragma -mark- UITableViewDataSource
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TWTRTweet *tweet = self.tweets[indexPath.row];
    
    TWTRTweetTableViewCell *cell = (TWTRTweetTableViewCell *)[tableView dequeueReusableCellWithIdentifier:TweetTableReuseIdentifier forIndexPath:indexPath];
    cell.tweetView.showActionButtons = YES;
    [cell configureWithTweet:tweet];
    if (indexPath.row % 2 == 0) {
        cell.tweetView.theme = TWTRTweetViewThemeLight;
    } else {
        cell.tweetView.theme = TWTRTweetViewThemeDark;
    }
    
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
    
//    return [TWTRTweetTableViewCell heightForTweet:tweet width:CGRectGetWidth(self.view.bounds)];
    return [TWTRTweetTableViewCell heightForTweet:tweet width:CGRectGetWidth(self.view.bounds) showingActions:YES];
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.tweets removeObjectAtIndex:indexPath.row];
        [self.tableView reloadData];
    }
}
#pragma -mark- UITableViewDelegate

@end
