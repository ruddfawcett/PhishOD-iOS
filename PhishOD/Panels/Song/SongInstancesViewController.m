//
//  SongInstancesViewController.m
//  Phish Tracks
//
//  Created by Alec Gorge on 6/6/13.
//  Copyright (c) 2013 Alec Gorge. All rights reserved.
//

#import "SongInstancesViewController.h"
#import <TDBadgedCell/TDBadgedCell.h>
#import "ShowViewController.h"
#import <SVWebViewController/SVWebViewController.h>

@interface SongInstancesViewController ()

@end

@implementation SongInstancesViewController

- (id)initWithSong:(PhishinSong*) s {
    self = [super initWithStyle: UITableViewStylePlain];
    if (self) {
        self.title = s.title;
		self.song = s;
		self.indicies = @[];
    }
    return self;
}

- (void)refresh:(id)sender {
	[[PhishinAPI sharedAPI] fullSong:self.song
							 success:^(PhishinSong *ss) {
								 self.song = ss;
								 [[PhishNetAPI sharedAPI] jamsForSong:self.song
															  success:^(NSArray *dates) {
																  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
																	  for (PhishinTrack *track in self.song.tracks) {
																		  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
																		  formatter.dateFormat = @"yyyy-MM-dd";
																		  if([dates containsObject:[formatter dateFromString: track.show_date]]) {
																			  track.isBold = YES;
																		  }
																	  }
																	  dispatch_async(dispatch_get_main_queue(), ^{
																		  [self.tableView reloadData];
																	  });
																  });
																  
															  }];
								 
								 dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
									 [self makeIndicies];
									 
									 dispatch_async(dispatch_get_main_queue(), ^{
										 [self.tableView reloadData];
										 
										 [super refresh:sender];
									 });
								 });
							 }
							 failure:REQUEST_FAILED(self.tableView)];
}

- (void)makeIndicies {
    //---create the index---
    NSMutableArray *stateIndex = [[NSMutableArray alloc] init];
    
	for(PhishinTrack *s in self.song.tracks) {
        NSString *uniChar = s.index;
		
		if(![stateIndex containsObject: uniChar])
			[stateIndex addObject: uniChar];
	}
	
	self.indicies = stateIndex;
}

- (NSArray *)filteredForSection:(NSUInteger) section {
	if(self.indicies.count == 0) {
		return @[];
	}
    NSString *alphabet = self.indicies[section-1];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.index == %@", alphabet];
    return [self.song.tracks filteredArrayUsingPredicate:predicate];
}

#pragma mark - Table view data source

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
	if(self.indicies.count <= 5) return nil;
	return self.indicies;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return self.indicies.count + 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	if(section == self.indicies.count && self.song.tracks.count > 15) {
		return [NSString stringWithFormat:@"%lu times", (unsigned long)self.song.tracks.count];
	}
	return nil;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
	if(section == 0) {
		return 3;
	}
	return [self filteredForSection: section].count;
}

- (NSString *)tableView:(UITableView *)tableView
titleForHeaderInSection:(NSInteger)section {
	if(section == 0) {
		return @"Song Info";
	}
	else {
		if(self.song.tracks.count) {
			return self.indicies[section - 1];
		}
		return @"Times Played";
	}
}

- (NSString*)formattedStringForDuration:(NSTimeInterval)duration {
    NSInteger minutes = floor(duration/60);
    NSInteger seconds = round(duration - minutes * 60);
    return [NSString stringWithFormat:@"%ld:%02ld", (long)minutes, (long)seconds];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
		 cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if(indexPath.section == 0) {
		static NSString *CellIdentifier = @"Cell";
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		
		if(cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
										  reuseIdentifier:CellIdentifier];
		}

		if(indexPath.row == 0) {
			cell.textLabel.text = @"Song History";
		}
		else if(indexPath.row == 1) {
			cell.textLabel.text = @"Song Lyrics";
		}
		else if(indexPath.row == 2) {
			cell.textLabel.text = @"Jamming Charts";
		}
		
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		return cell;
	}
    
    static NSString *CellIdentifier = @"BadgedCell";
    TDBadgedCell *cell = (TDBadgedCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
	if(cell == nil) {
		cell = [[TDBadgedCell alloc] initWithStyle:UITableViewCellStyleValue1
								   reuseIdentifier:CellIdentifier];
	}
	
	PhishinTrack *song = [self filteredForSection:indexPath.section][indexPath.row];
    cell.textLabel.text = song.show_date;
//	cell.detailTextLabel.text = song.showLocation;
//	cell.detailTextLabel.numberOfLines = 2;
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	cell.detailTextLabel.font = [UIFont systemFontOfSize:12.0];
	cell.detailTextLabel.textColor = [UIColor grayColor];
	
	if(song.isBold)
		cell.detailTextLabel.text = [NSString stringWithFormat: @"Jam Chart, %@", [self formattedStringForDuration: song.duration], nil];
	else
		cell.detailTextLabel.text = [self formattedStringForDuration:song.duration];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return UITableViewAutomaticDimension;

	if(indexPath.section == 0) {
		return UITableViewAutomaticDimension;
	}
	return tableView.rowHeight * 1.5;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if(indexPath.section == 0) {
		if(indexPath.row == 0) {
			NSString *addr = [NSString stringWithFormat:@"http://phish.net/song/%@/history", self.song.netSlug];
			[self.navigationController pushViewController:[[SVWebViewController alloc] initWithAddress:addr]
												 animated:YES];
			
		}
		else if(indexPath.row == 1) {
			NSString *addr = [NSString stringWithFormat:@"http://phish.net/song/%@/lyrics", self.song.netSlug];
			[self.navigationController pushViewController:[[SVWebViewController alloc] initWithAddress:addr]
												 animated:YES];
		}
		else if(indexPath.row == 2) {
			NSString *addr = [NSString stringWithFormat:@"http://phish.net/song/%@/jamming-chart", self.song.netSlug];
			[self.navigationController pushViewController:[[SVWebViewController alloc] initWithAddress:addr]
												 animated:YES];
		}
		return;
	}
	
	PhishinTrack *song = [self filteredForSection:indexPath.section][indexPath.row];
	
	PhishinShow *show = [[PhishinShow alloc] init];
	show.id = (int)song.show_id;
	show.date = song.show_date;
	
	[tableView deselectRowAtIndexPath:indexPath
							 animated:YES];
	
	ShowViewController *showvc = [[ShowViewController alloc] initWithShow:show];
	showvc.autoplay = YES;
	showvc.autoplayTrackId = song.id;
	
	[self.navigationController pushViewController:showvc
										 animated:YES];
}

@end
