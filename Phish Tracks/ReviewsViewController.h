//
//  ReviewsViewController.h
//  Phish Tracks
//
//  Created by Alec Gorge on 6/5/13.
//  Copyright (c) 2013 Alec Gorge. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ReviewsViewController : UITableViewController
- (id)initWithSetlist:(PhishNetSetlist *)setlist;

@property PhishNetSetlist *setlist;

@end
