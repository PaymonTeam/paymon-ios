//
// Created by Vladislav on 09/09/2017.
// Copyright (c) 2017 Paymon. All rights reserved.
//

#import <UIKit/UIKit.h>

#define PARALAX_RATIO    0.25

@class MoneyViewController, BRSendViewController;
@class MoneyWalletTableCell;

@interface MoneyWalletTableCell : UITableViewCell

@end

@interface MoneyViewController : UIViewController <UIAlertViewDelegate, UIPageViewControllerDataSource,
        UIScrollViewDelegate, UINavigationControllerDelegate, UIViewControllerTransitioningDelegate,
        UIViewControllerAnimatedTransitioning, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate>

//@property (nonatomic, strong) IBOutlet BRReceiveViewController *receiveViewController;
//@property (nonatomic, strong) IBOutlet BRSendViewController *sendViewController;
//@property (nonatomic, strong) IBOutlet UIPageViewController *pageViewController;

- (IBAction)tip:(id)sender;

- (void)startActivityWithTimeout:(NSTimeInterval)timeout;
- (void)stopActivityWithSuccess:(BOOL)success;
- (void)ping;



@end
