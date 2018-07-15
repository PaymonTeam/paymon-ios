//
// Created by Vladislav on 09/09/2017.
// Copyright (c) 2017 Paymon. All rights reserved.
//

#import "MoneyViewController.h"
#import "BRReceiveViewController.h"
#import "BRSendViewController.h"
#import "BRSettingsViewController.h"
#import "BRTxHistoryViewController.h"
#import "BRTransaction.h"
#import "BRAppDelegate.h"
#import "BRBubbleView.h"
#import "BRBouncyBurgerButton.h"

#import "BRPeerManager.h"
#import "BRWalletManager.h"
#import "BRPaymentRequest.h"
#import "UIImage+Utils.h"
#import "BREventManager.h"
#import "BREventConfirmView.h"
#import "Reachability.h"

#import "paymon-Swift.h"
#import "BRAppGroupConstants.h"
#import "BRPaymentProtocol.h"
#import <WebKit/WebKit.h>
#import <LocalAuthentication/LocalAuthentication.h>
#import <sys/stat.h>
#import <mach-o/dyld.h>
#import "paymon-Swift.h"

#define BRURLNotification            @"BRURLNotification"
#define BRFileNotification           @"BRFileNotification"
//#define NSLocalizedString(key, comment)
#define BALANCE_TIP NSLocalizedString(@"This is your bitcoin balance. Bitcoin is a currency. "\
                                       "The exchange rate changes with the market.", nil)
#define BITS_TIP    NSLocalizedString(@"%@ is for 'bits'. %@ = 1 bitcoin.", nil)

#define BACKUP_DIALOG_TIME_KEY @"BACKUP_DIALOG_TIME"
#define BALANCE_KEY            @"BALANCE"
#define SETTINGS_MAX_DIGITS_KEY @"SETTINGS_MAX_DIGITS"
#define SCAN_TIP      NSLocalizedString(@"Scan someone else's QR code to get their bitcoin address. "\
                                         "You can send a payment to anyone with an address.", nil)
#define CLIPBOARD_TIP NSLocalizedString(@"Bitcoin addresses can also be copied to the clipboard. "\
                                         "A bitcoin address always starts with '1' or '3'.", nil)

#define LOCK @"\xF0\x9F\x94\x92" // unicode lock symbol U+1F512 (utf-8)
#define REDX @"\xE2\x9D\x8C"     // unicode cross mark U+274C, red x emoji (utf-8)
#define NBSP @"\xC2\xA0"         // no-break space (utf-8)

static NSString *sanitizeString(NSString *s) {
    NSMutableString *sane = [NSMutableString stringWithString:(s) ? s : @""];

    CFStringTransform((CFMutableStringRef) sane, NULL, kCFStringTransformToUnicodeName, NO);
    return sane;
}

@interface MoneyWalletTableCell ()
@property(weak, nonatomic) IBOutlet UILabel *balanceLabel;
//@property(weak, nonatomic) IBOutlet UILabel *currencyLabel;
@property(weak, nonatomic) IBOutlet UILabel *localBalanceLabel;
@property(weak, nonatomic) IBOutlet UIImageView *image;
//@property(weak, nonatomic) IBOutlet UIButton *withdrawButton;
//@property(weak, nonatomic) IBOutlet UIButton *addButton;
@end

@implementation MoneyWalletTableCell

@end


@interface MoneyViewController ()

@property(weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property(nonatomic) IBOutlet UITableView *tableView;
//@property (weak, nonatomic) IBOutlet UILabel *balanceLabel;
@property(weak, nonatomic) IBOutlet UIBarButtonItem *infoBarItem;
@property(weak, nonatomic) IBOutlet UIButton *sendButton;
@property(weak, nonatomic) IBOutlet UITextField *sendAddress;
//@property (weak, nonatomic) IBOutlet UIButton *balanceButton;
@property(nonatomic, strong) IBOutlet UIProgressView *progress;
@property(nonatomic, strong) IBOutlet UIProgressView *pulse;
@property(nonatomic, strong) IBOutlet UILabel *percent;
@property(nonatomic, strong) IBOutlet UIView *errorBar, *splash, *logo, *blur;
@property(nonatomic, strong) IBOutlet UIGestureRecognizer *navBarTap;
@property(nonatomic, strong) IBOutlet UIBarButtonItem *lock;
//@property (nonatomic, strong) IBOutlet BRBouncyBurgerButton *burger;
@property(nonatomic, strong) IBOutlet NSLayoutConstraint *wallpaperXLeft;

@property(nonatomic, strong) UIScrollView *scrollView;
//@property (nonatomic, strong) BRBubbleView *tipView;
@property(nonatomic, assign) BOOL showTips, inNextTip, didAppear;
@property(nonatomic, assign) uint64_t balance;
@property(nonatomic, assign) uint64_t amount;
@property(nonatomic, strong) BRPaymentProtocolRequest *request;
@property(nonatomic, strong) NSString *okAddress, *okIdentity;
@property(nonatomic, strong) NSURL *url;
@property(nonatomic, strong) NSData *file;
@property(nonatomic, strong) Reachability *reachability;
@property(nonatomic, strong) id urlObserver, fileObserver, protectedObserver, balanceObserver, seedObserver;
@property(nonatomic, strong) id reachabilityObserver, syncStartedObserver, syncFinishedObserver, syncFailedObserver;
@property(nonatomic, strong) id activeObserver, resignActiveObserver, foregroundObserver, backgroundObserver;
@property(nonatomic, assign) NSTimeInterval timeout, start;
//@property (nonatomic, assign) SystemSoundID pingsound;

@end


@implementation MoneyViewController


- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationBar.topItem.title = [[NSBundle mainBundle] localizedStringForKey:(@"Money") value:@"" table:nil];

//    self.navigationController.navigationItem.rightBarButtonItem =
    // Do any additional setup after loading the view.

    // detect jailbreak so we can throw up an idiot warning, in viewDidLoad so it can't easily be swizzled out
    struct stat s;
    BOOL jailbroken = (stat("/bin/sh", &s) == 0) ? YES : NO; // if we can see /bin/sh, the app isn't sandboxed

    // some anti-jailbreak detection tools re-sandbox apps, so do a secondary check for any MobileSubstrate dyld images
    for (uint32_t count = _dyld_image_count(), i = 0; i < count && !jailbroken; i++) {
        if (strstr(_dyld_get_image_name(i), "MobileSubstrate")) jailbroken = YES;
    }

#if TARGET_IPHONE_SIMULATOR
    jailbroken = NO;
#endif

    _balance = UINT64_MAX;

//    self.receiveViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ReceiveViewController"];
//    self.sendViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"SendViewController"];
//    self.pageViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PageViewController"];
//
//    self.pageViewController.dataSource = self;
//    [self.pageViewController setViewControllers:@[self.sendViewController]
//                                      direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
//    self.pageViewController.view.frame = self.view.bounds;
//    [self addChildViewController:self.pageViewController];
//    [self.view insertSubview:self.pageViewController.view belowSubview:self.splash];
//    [self.pageViewController didMoveToParentViewController:self];
//
//    for (UIView *view in self.pageViewController.view.subviews) {
//        if (! [view isKindOfClass:[UIScrollView class]]) continue;
//        self.scrollView = (id)view;
//        self.scrollView.delegate = self;
//        break;
//    }

    BRWalletManager *manager = [BRWalletManager sharedInstance];
    self.urlObserver =
            [[NSNotificationCenter defaultCenter] addObserverForName:BRURLNotification object:nil queue:nil
                                                          usingBlock:^(NSNotification *note) {
                                                              if (!manager.noWallet) {
                                                                  if (self.navigationController.topViewController != self) {
                                                                      [self.navigationController popToRootViewControllerAnimated:YES];
                                                                  }

                                                                  if (self.navigationController.presentedViewController) {
                                                                      [self.navigationController dismissViewControllerAnimated:YES completion:nil];
                                                                  }

//                                                                  BRSendViewController *c = self.sendViewController;
//
//                                                                  [self.pageViewController setViewControllers:(c ? @[c] : @[])
//                                                                                                    direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:^(BOOL finished) {
//                                                                              _url = note.userInfo[@"url"];
//
//                                                                              if (self.didAppear && [UIApplication sharedApplication].protectedDataAvailable) {
//                                                                                  _url = nil;
//                                                                                  [c performSelector:@selector(handleURL:) withObject:note.userInfo[@"url"] afterDelay:0.0];
//                                                                              }
//                                                                          }];
                                                              }
                                                          }];
//
//    self.fileObserver =
//            [[NSNotificationCenter defaultCenter] addObserverForName:BRFileNotification object:nil queue:nil
//                                                          usingBlock:^(NSNotification *note) {
//                                                              if (! manager.noWallet) {
//                                                                  if (self.navigationController.topViewController != self) {
//                                                                      [self.navigationController popToRootViewControllerAnimated:YES];
//                                                                  }
//
//                                                                  if (self.navigationController.presentedViewController) {
//                                                                      [self.navigationController dismissViewControllerAnimated:YES completion:nil];
//                                                                  }
//
////                                                                  BRSendViewController *sendController = self.sendViewController;
////
////                                                                  [self.pageViewController setViewControllers:(sendController ? @[sendController] : @[])
////                                                                                                    direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:^(BOOL finished) {
////                                                                              _file = note.userInfo[@"file"];
////
////                                                                              if (self.didAppear && [UIApplication sharedApplication].protectedDataAvailable) {
////                                                                                  _file = nil;
////                                                                                  [sendController handleFile:note.userInfo[@"file"]];
////                                                                              }
////                                                                          }];
//                                                              }
//                                                          }];
//
    self.foregroundObserver =
            [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification object:nil
                                                               queue:nil usingBlock:^(NSNotification *note) {
                        if (!manager.noWallet) {
                            BREventManager *eventMan = [BREventManager sharedEventManager];

                            [[BRPeerManager sharedInstance] connect];
//                            [self.sendViewController updateClipboardText];

                            if (eventMan.isInSampleGroup && !eventMan.hasAskedForPermission) {
                                [eventMan acquireUserPermissionInViewController:self.navigationController withCallback:nil];
                            } else {
                                NSString *userDefaultsKey = @"has_asked_for_push";
                                [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:userDefaultsKey];
//                                ([(id)[UIApplication sharedApplication].delegate registerForPushNotifications]);
                            }
                        }

                        if (jailbroken && manager.wallet.totalReceived > 0) {
                            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"WARNING", nil)
                                                        message:NSLocalizedString(@"DEVICE SECURITY COMPROMISED\n"
                                                                "Any 'jailbreak' app can access any other app's keychain data "
                                                                "(and steal your bitcoins). "
                                                                "Wipe this wallet immediately and restore on a secure device.", nil)
                                                       delegate:self cancelButtonTitle:NSLocalizedString(@"ignore", nil)
                                              otherButtonTitles:NSLocalizedString(@"wipe", nil), nil] show];
                        } else if (jailbroken) {
                            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"WARNING", nil)
                                                        message:NSLocalizedString(@"DEVICE SECURITY COMPROMISED\n"
                                                                "Any 'jailbreak' app can access any other app's keychain data "
                                                                "(and steal your bitcoins).", nil)
                                                       delegate:self cancelButtonTitle:NSLocalizedString(@"ignore", nil)
                                              otherButtonTitles:NSLocalizedString(@"close app", nil), nil] show];
                        }
                    }];

    self.backgroundObserver =
            [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil
                                                               queue:nil usingBlock:^(NSNotification *note) {
                        if (!manager.noWallet) { // lockdown the app
                            manager.didAuthenticate = NO;
                            self.navigationItem.titleView = self.logo;
                            self.navigationItem.leftBarButtonItem.image = [UIImage imageNamed:@"burger"];
                            self.navigationItem.rightBarButtonItem = self.lock;
//                            self.pageViewController.view.alpha = 1.0;
                            [UIApplication sharedApplication].applicationIconBadgeNumber = 0; // reset app badge number
                        }
                    }];

    self.activeObserver =
            [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil
                                                               queue:nil usingBlock:^(NSNotification *note) {
                        [self.blur removeFromSuperview];
                        self.blur = nil;
                    }];

    self.resignActiveObserver =
            [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillResignActiveNotification object:nil
                                                               queue:nil usingBlock:^(NSNotification *note) {
                        UIView *keyWindow = [UIApplication sharedApplication].keyWindow;
                        UIImage *img;

                        if (![keyWindow viewWithTag:-411]) { // only take a screenshot if no views are marked highly sensitive
                            UIGraphicsBeginImageContext([UIScreen mainScreen].bounds.size);
                            [keyWindow drawViewHierarchyInRect:[UIScreen mainScreen].bounds afterScreenUpdates:NO];
                            img = UIGraphicsGetImageFromCurrentImageContext();
                            UIGraphicsEndImageContext();
                        } else img = [UIImage imageNamed:@"wallpaper-default"];

                        [self.blur removeFromSuperview];
                        self.blur = [[UIImageView alloc] initWithImage:[img blurWithRadius:3]];
                        [keyWindow.subviews.lastObject addSubview:self.blur];
                    }];

    self.reachabilityObserver =
            [[NSNotificationCenter defaultCenter] addObserverForName:kReachabilityChangedNotification object:nil queue:nil
                                                          usingBlock:^(NSNotification *note) {
                                                              if (!manager.noWallet && self.reachability.currentReachabilityStatus != NotReachable &&
                                                                      [UIApplication sharedApplication].applicationState != UIApplicationStateBackground) {
                                                                  [[BRPeerManager sharedInstance] connect];
                                                              } else if (!manager.noWallet && self.reachability.currentReachabilityStatus == NotReachable) {
                                                                  [self showErrorBar];
                                                              }
                                                          }];

    self.balanceObserver =
            [[NSNotificationCenter defaultCenter] addObserverForName:BRWalletBalanceChangedNotification object:nil queue:nil
                                                          usingBlock:^(NSNotification *note) {
                                                              NSLog(@"BRWalletBalanceChangedNotification");
                                                              double progress = [BRPeerManager sharedInstance].syncProgress;

                                                              if (_balance != UINT64_MAX && progress > DBL_EPSILON && progress + DBL_EPSILON < 1.0) { // wait for sync
                                                                  self.balance = _balance; // this updates the local currency value with the latest exchange rate
                                                                  return;
                                                              }

                                                              [self showBackupDialogIfNeeded];
//                                                              [self.receiveViewController updateAddress];
                                                              self.balance = manager.wallet.balance;
                                                          }];

    self.seedObserver =
            [[NSNotificationCenter defaultCenter] addObserverForName:BRWalletManagerSeedChangedNotification object:nil
                                                               queue:nil usingBlock:^(NSNotification *note) {
                        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"BCHTxHashKey"];
//                        [self.receiveViewController updateAddress];
                        self.balance = manager.wallet.balance;
                    }];

    self.syncStartedObserver =
            [[NSNotificationCenter defaultCenter] addObserverForName:BRPeerManagerSyncStartedNotification object:nil
                                                               queue:nil usingBlock:^(NSNotification *note) {
                        if (self.reachability.currentReachabilityStatus == NotReachable) return;
                        NSLog(@"Sync started");
                        [self hideErrorBar];
                        [self startActivityWithTimeout:0];
                    }];

    self.syncFinishedObserver =
            [[NSNotificationCenter defaultCenter] addObserverForName:BRPeerManagerSyncFinishedNotification object:nil
                                                               queue:nil usingBlock:^(NSNotification *note) {
                        if (self.timeout < 1.0) [self stopActivityWithSuccess:YES];
                        [self showBackupDialogIfNeeded];
                        if (!self.percent.hidden) [self hideTips];
                        self.percent.hidden = YES;
                        if (!manager.didAuthenticate) self.navigationItem.titleView = self.logo;
//                        [self.receiveViewController updateAddress];
                        self.balance = manager.wallet.balance;
                        NSLog(@"Sync finished %@", manager.wallet.receiveAddress);
//                        _balanceButton.titleLabel.text = manager.wallet.receiveAddress;
                    }];

    self.syncFailedObserver =
            [[NSNotificationCenter defaultCenter] addObserverForName:BRPeerManagerSyncFailedNotification object:nil
                                                               queue:nil usingBlock:^(NSNotification *note) {
                        if (self.timeout < 1.0) [self stopActivityWithSuccess:YES];
                        [self showBackupDialogIfNeeded];
//                        [self.receiveViewController updateAddress];
                        [self showErrorBar];
                        NSLog(@"Sync failed");
                    }];

    self.reachability = [Reachability reachabilityForInternetConnection];
    [self.reachability startNotifier];

    self.navigationController.delegate = self;

#if BITCOIN_TESTNET
    UILabel *label = [UILabel new];

    label.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:13.0];
    label.textColor = [UIColor redColor];
    label.textAlignment = NSTextAlignmentRight;
    label.text = @"testnet";
    label.tag = 0xbeef;
    [label sizeToFit];
    label.center = CGPointMake(self.view.frame.size.width - label.frame.size.width,
                               self.view.frame.size.height - (label.frame.size.height + 5));
    [self.view addSubview:label];
#endif

#if SNAPSHOT
    [self.view viewWithTag:0xbeef].hidden = YES;
    [self.navigationController
     presentViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"NewWalletNav"] animated:NO
     completion:^{
        [self.navigationController.presentedViewController.view
         addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(nextScreen:)]];
     }];
#endif

    if (manager.watchOnly) { // watch only wallet
        UILabel *label = [UILabel new];

        label.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:13.0];
        label.textColor = [UIColor redColor];
        label.textAlignment = NSTextAlignmentRight;
        label.text = @"watch only";
        [label sizeToFit];
        label.center = CGPointMake(self.view.frame.size.width - label.frame.size.width,
                self.view.frame.size.height - (label.frame.size.height + 5) * 2);
        [self.view addSubview:label];
    }

//    AudioServicesCreateSystemSoundID((__bridge CFURLRef)[[NSBundle mainBundle] URLForResource:@"coinflip"
//                                                                                withExtension:@"aiff"], &_pingsound);

    if (!manager.noWallet) {
        //TODO: do some kickass quick logo animation, fast circle spin that slows
        self.splash.hidden = YES;
        self.navigationController.navigationBar.hidden = NO;
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
    }

    if (jailbroken && manager.wallet.totalReceived + manager.wallet.totalSent > 0) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"WARNING", nil)
                                    message:NSLocalizedString(@"DEVICE SECURITY COMPROMISED\n"
                                            "Any 'jailbreak' app can access any other app's keychain data "
                                            "(and steal your bitcoins). "
                                            "Wipe this wallet immediately and restore on a secure device.", nil)
                                   delegate:self cancelButtonTitle:NSLocalizedString(@"ignore", nil)
                          otherButtonTitles:NSLocalizedString(@"wipe", nil), nil] show];
    } else if (jailbroken) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"WARNING", nil)
                                    message:NSLocalizedString(@"DEVICE SECURITY COMPROMISED\n"
                                            "Any 'jailbreak' app can access any other app's keychain data "
                                            "(and steal your bitcoins).", nil)
                                   delegate:self cancelButtonTitle:NSLocalizedString(@"ignore", nil)
                          otherButtonTitles:NSLocalizedString(@"close app", nil), nil] show];
    }

    [_sendButton addTarget:self action:@selector(onSendClicked) forControlEvents:UIControlEventTouchUpInside];
    _tableView.delegate = self;
    _tableView.dataSource = self;
}

- (void)addMoney:(UIButton *)button {
    __kindof UIViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"MoneyDepositView"];
    NSLog(@"%d %d %d", controller != nil, self.navigationController != nil, self != nil);
//    [controller dismissViewControllerAnimated:false completion:nil];
    [self presentViewController:controller animated:false completion:nil];
//    [self.navigationController dismissViewControllerAnimated:false completion:nil];
//    [self.navigationController pushViewController:controller animated:true];
}

- (void)showWallet {
    __kindof UIViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"WalletView"];
//    NSLog(@"%d %d %d", controller!=nil, self.navigationController != nil, self != nil);
//    [controller dismissViewControllerAnimated:false completion:nil];
    [self presentViewController:controller animated:true completion:nil];
//    [self.navigationController dismissViewControllerAnimated:false completion:nil];
//    [self.navigationController pushViewController:controller animated:true];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    if (indexPath.row == 0) {
        UIStoryboard *ethur = [UIStoryboard storyboardWithName:@"Ethur" bundle:[NSBundle mainBundle]];
        CoinDetailsViewController *coinDetail = [ethur instantiateViewControllerWithIdentifier:@"CoinDetailsViewController"];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:coinDetail];
        [self presentViewController:nav animated:true completion:nil];

    } else {
        [tableView deselectRowAtIndexPath:indexPath animated:true];
        [self showWallet];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
//    f data is CellDialogData {
//            let cell = tableView.dequeueReusableCell(withIdentifier: "ChatsTableViewCell") as! ChatsTableViewCell
//            cell.title.text = data.name
//            cell.lastMessageText.text = data.lastMessageText
//            cell.lastMessageTime.text = data.timeString
//            cell.photo.setPhoto(ownerID: data.chatID, photoID: data.photoID)
//            return cell
//    } else if data is CellGroupData {
//            let groupData = data as! CellGroupData
//            let cell = tableView.dequeueReusableCell(withIdentifier: "ChatsTableGroupViewCell") as! ChatsTableGroupViewCell
//            cell.title.text = groupData.name
//            cell.lastMessageText.text = groupData.lastMessageText
//            cell.lastMessageTime.text = groupData.timeString
//            if groupData.lastMsgPhoto != nil {
//                cell.lastMessagePhoto.setPhoto(photo: groupData.lastMsgPhoto!)
//            }
//            cell.photo.setPhoto(ownerID: -groupData.chatID, photoID: groupData.photoID)
//            return cell
//    }

    if (indexPath.row == 0) {
        auto cell = (MoneyWalletTableCell *) [tableView dequeueReusableCellWithIdentifier:@"EtherWalletTableCell"];
        return cell;

    }
    auto manager = [BRWalletManager sharedInstance];
    if (!manager.noWallet) {
        auto cell = (MoneyWalletTableCell *) [tableView dequeueReusableCellWithIdentifier:@"MoneyWalletTableCell"];

        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]
                initWithTarget:self action:@selector(handleLongPress:)];
        longPress.minimumPressDuration = 0.5; //seconds
        longPress.delegate = self;
        [cell addGestureRecognizer:longPress];

        cell.balanceLabel.text = [NSString stringWithFormat:@"%@", [manager stringForAmount:manager.wallet.balance]];
        cell.localBalanceLabel.text = [NSString stringWithFormat:@"%@", [manager localCurrencyStringForAmount:manager.wallet.balance]];
// [NSString stringWithFormat:@"%lld", manager.wallet.balance];
//        cell.currencyLabel.text = @"BTC";
//        cell.addButton.tag = indexPath.row;
//        [cell.addButton addTarget:self action:@selector(addMoney:) forControlEvents:UIControlEventTouchUpInside];
        return cell;
    } else {
        auto cell = [tableView dequeueReusableCellWithIdentifier:@"MoneyAddWalletTableCell"];
        return cell;
    }
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)longPress {
    if (longPress.state == UIGestureRecognizerStateBegan) {
        __kindof UIViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"BitcoinAddressInfoViewController"];
        [self presentViewController:controller animated:false completion:nil];
    }
}

- (IBAction)infoBarItemClicked:(id)sender {
    UIAlertController *alertInfo = [UIAlertController
            alertControllerWithTitle:[[NSBundle mainBundle] localizedStringForKey:(@"What to do next?")
                                                                            value:@""
                                                                            table:nil]
                             message:[[NSBundle mainBundle] localizedStringForKey:(@"To find out the address of your wallet and the QR-code, hold the cell of wallet. \n\n To transfer, deposit or withdraw funds, click on the dell of wallet.")
                                                                            value:@""
                                                                            table:nil]
                      preferredStyle:UIAlertControllerStyleAlert];


    UIAlertAction *okButton = [UIAlertAction
            actionWithTitle:@"OK"
                      style:UIAlertActionStyleDefault
                    handler:^(UIAlertAction *action) {
                        //Handle your yes please button action here
                    }];

    [alertInfo addAction:okButton];

    [self presentViewController:alertInfo animated:YES completion:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.infoBarItem.action = @selector(infoBarItemClicked:);

    self.navigationItem.leftBarButtonItem.image = [UIImage imageNamed:@"burger"];
//    self.pageViewController.view.alpha = 1.0;
    NSLog(@"UNLOCK %d", [BRWalletManager sharedInstance].didAuthenticate);
    if ([BRWalletManager sharedInstance].didAuthenticate) [self unlock:nil];


}

- (void)viewDidAppear:(BOOL)animated {
    self.didAppear = YES;

    if (!self.navBarTap) {
        self.navBarTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(navBarTap:)];
        [self.navigationController.navigationBar addGestureRecognizer:self.navBarTap];
    }

    if (!self.protectedObserver) {
        self.protectedObserver =
                [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationProtectedDataDidBecomeAvailable
                                                                  object:nil queue:nil usingBlock:^(NSNotification *note) {
                            [self performSelector:@selector(protectedViewDidAppear) withObject:nil afterDelay:0.0];
                        }];
    }

    if ([UIApplication sharedApplication].protectedDataAvailable) {
        [self performSelector:@selector(protectedViewDidAppear) withObject:nil afterDelay:0.0];
    }

    [super viewDidAppear:animated];
}

- (void)onSendClicked {
    self.amount = 600;
    self.okAddress = _sendAddress.text;
    NSString *str = _sendAddress.text;

    BRWalletManager *manager = [BRWalletManager sharedInstance];
    NSUInteger i = 0;

    BRPaymentRequest *req = [BRPaymentRequest requestWithString:str];
    NSData *data = str.hexToData.reverse;

    i++;

    // if the clipboard contains a known txHash, we know it's not a hex encoded private key
    if (data.length == sizeof(UInt256) && [manager.wallet transactionForHash:*(UInt256 *) data.bytes]) {
        NSLog(@"clipboard contains a known txHash error");
    }

    if ([req.paymentAddress isValidBitcoinAddress] || [str isValidBitcoinPrivateKey] ||
            [str isValidBitcoinBIP38Key] || (req.r.length > 0 && [req.scheme isEqual:@"bitcoin"])) {
        NSLog(@"Send 1");
        [self performSelector:@selector(confirmRequest:) withObject:req afterDelay:0.1];// delayed to show highlight
        return;
    } else if (req.r.length > 0) { // may be BIP73 url: https://github.com/bitcoin/bips/blob/master/bip-0073.mediawiki
        NSLog(@"Send 2");
//        [BRPaymentRequest fetch:req.r timeout:5.0 completion:^(BRPaymentProtocolRequest *req, NSError *error) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                if (error) { // don't try any more BIP73 urls
//                    [self payFirstFromArray:[array objectsAtIndexes:[array
//                            indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
//                                return (idx >= i && ([obj hasPrefix:@"bitcoin:"] || ! [NSURL URLWithString:obj]));
//                            }]]];
//                }
//                else [self confirmProtocolRequest:req];
//            });
//        }];

        return;
    }
//    [self performSelector:@selector(cancel:) withObject:self afterDelay:0.1];
}

- (void)confirmRequest:(BRPaymentRequest *)request {
    if (!request.isValid) {
        if ([request.paymentAddress isValidBitcoinPrivateKey] || [request.paymentAddress isValidBitcoinBIP38Key]) {
            NSLog(@"Send sweep");
//            [self confirmSweep:request.paymentAddress];
        } else {
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"not a valid bitcoin address", nil)
                                        message:request.paymentAddress delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil)
                              otherButtonTitles:nil] show];
//            [self cancel:nil];
        }
    } else if (request.r.length > 0) { // payment protocol over HTTP
        [(id) self.parentViewController.parentViewController startActivityWithTimeout:20.0];

        [BRPaymentRequest fetch:request.r timeout:20.0 completion:^(BRPaymentProtocolRequest *req, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [(id) self.parentViewController.parentViewController stopActivityWithSuccess:(!error)];

                if (error && ![request.paymentAddress isValidBitcoinAddress]) {
                    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"couldn't make payment", nil)
                                                message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil)
                                      otherButtonTitles:nil] show];
//                    [self cancel:nil];
                } else [self confirmProtocolRequest:(error) ? request.protocolRequest : req];
            });
        }];
    } else [self confirmProtocolRequest:request.protocolRequest];
}

- (void)confirmProtocolRequest:(BRPaymentProtocolRequest *)protoReq {
    BRWalletManager *manager = [BRWalletManager sharedInstance];
    BRTransaction *tx = nil;
    uint64_t amount = 0, fee = 0;
    NSString *address = [NSString addressWithScriptPubKey:protoReq.details.outputScripts.firstObject];
    BOOL valid = protoReq.isValid, outputTooSmall = NO;

    if (!valid && [protoReq.errorMessage isEqual:NSLocalizedString(@"request expired", nil)]) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"bad payment request", nil) message:protoReq.errorMessage
                                   delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil] show];
//        [self cancel:nil];
        return;
    }

    //TODO: check for duplicates of already paid requests

    if (self.amount == 0) {
        for (NSNumber *outputAmount in protoReq.details.outputAmounts) {
            if (outputAmount.unsignedLongLongValue > 0 && outputAmount.unsignedLongLongValue < TX_MIN_OUTPUT_AMOUNT) {
                outputTooSmall = YES;
            }
            amount += outputAmount.unsignedLongLongValue;
        }
    } else amount = self.amount;

    if ([manager.wallet containsAddress:address]) {
        [[[UIAlertView alloc] initWithTitle:@""
                                    message:NSLocalizedString(@"this payment address is already in your wallet", nil)
                                   delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil] show];
//        [self cancel:nil];
        return;
    } else if (![self.okAddress isEqual:address] && [manager.wallet addressIsUsed:address] &&
            [[UIPasteboard generalPasteboard].string isEqual:address]) {
        self.request = protoReq;
        self.okAddress = address;
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"WARNING", nil)
                                    message:NSLocalizedString(@"\nADDRESS ALREADY USED\n\nbitcoin addresses are intended for single use only\n\n"
                                            "re-use reduces privacy for both you and the recipient and can result in loss if "
                                            "the recipient doesn't directly control the address", nil)
                                   delegate:self cancelButtonTitle:nil
                          otherButtonTitles:NSLocalizedString(@"ignore", nil), NSLocalizedString(@"cancel", nil), nil] show];
        return;
    } else if (protoReq.errorMessage.length > 0 && protoReq.commonName.length > 0 &&
            ![self.okIdentity isEqual:protoReq.commonName]) {
        self.request = protoReq;
        self.okIdentity = protoReq.commonName;
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"payee identity isn't certified", nil)
                                    message:protoReq.errorMessage delegate:self cancelButtonTitle:nil
                          otherButtonTitles:NSLocalizedString(@"ignore", nil), NSLocalizedString(@"cancel", nil), nil] show];
        return;
    } else if (amount == 0 || amount == UINT64_MAX) {
        BRAmountViewController *amountController = [self.storyboard
                instantiateViewControllerWithIdentifier:@"AmountViewController"];

//        amountController.delegate = self;
        self.request = protoReq;

        if (protoReq.commonName.length > 0) {
            if (valid && ![protoReq.pkiType isEqual:@"none"]) {
                amountController.to = [LOCK @" " stringByAppendingString:sanitizeString(protoReq.commonName)];
            } else if (protoReq.errorMessage.length > 0) {
                amountController.to = [REDX @" " stringByAppendingString:sanitizeString(protoReq.commonName)];
            } else amountController.to = sanitizeString(protoReq.commonName);
        } else amountController.to = address;

        amountController.navigationItem.title = [NSString stringWithFormat:@"%@ (%@)",
                                                                           [manager stringForAmount:manager.wallet.balance],
                                                                           [manager localCurrencyStringForAmount:manager.wallet.balance]];
        [self.navigationController pushViewController:amountController animated:YES];
        return;
    } else if (amount < TX_MIN_OUTPUT_AMOUNT) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"couldn't make payment", nil)
                                    message:[NSString stringWithFormat:NSLocalizedString(@"bitcoin payments can't be less than %@", nil),
                                                                       [manager stringForAmount:TX_MIN_OUTPUT_AMOUNT]] delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil] show];
//        [self cancel:nil];
        return;
    } else if (outputTooSmall) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"couldn't make payment", nil)
                                    message:[NSString stringWithFormat:NSLocalizedString(@"bitcoin transaction outputs can't be less than %@",
                                                                               nil), [manager stringForAmount:TX_MIN_OUTPUT_AMOUNT]]
                                   delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil] show];
//        [self cancel:nil];
        return;
    }

    self.request = protoReq;

    if (self.amount == 0) {
        tx = [manager.wallet transactionForAmounts:protoReq.details.outputAmounts
                                   toOutputScripts:protoReq.details.outputScripts withFee:YES];
    } else {
        tx = [manager.wallet transactionForAmounts:@[@(self.amount)]
                                   toOutputScripts:@[protoReq.details.outputScripts.firstObject] withFee:YES];
    }

    if (tx) {
        amount = [manager.wallet amountSentByTransaction:tx] - [manager.wallet amountReceivedFromTransaction:tx];
        fee = [manager.wallet feeForTransaction:tx];
    } else {
        fee = [manager.wallet feeForTxSize:[manager.wallet transactionFor:manager.wallet.balance
                                                                       to:address withFee:NO].size];
        fee += (manager.wallet.balance - amount) % 100;
        amount += fee;
    }

    for (NSData *script in protoReq.details.outputScripts) {
        NSString *addr = [NSString addressWithScriptPubKey:script];

        if (!addr) addr = NSLocalizedString(@"unrecognized address", nil);
        if ([address rangeOfString:addr].location != NSNotFound) continue;
        address = [address stringByAppendingFormat:@"%@%@", (address.length > 0) ? @", " : @"", addr];
    }

    NSString *prompt = [self promptForAmount:amount fee:fee address:address name:protoReq.commonName
                                        memo:protoReq.details.memo isSecure:(valid && ![protoReq.pkiType isEqual:@"none"])];

    // to avoid the frozen pincode keyboard bug, we need to make sure we're scheduled normally on the main runloop
    // rather than a dispatch_async queue
    CFRunLoopPerformBlock([[NSRunLoop mainRunLoop] getCFRunLoop], kCFRunLoopCommonModes, ^{
        [self confirmTransaction:tx withPrompt:prompt forAmount:amount];
    });
}

- (void)confirmTransaction:(BRTransaction *)tx withPrompt:(NSString *)prompt forAmount:(uint64_t)amount {
    BRWalletManager *manager = [BRWalletManager sharedInstance];
    BOOL didAuth = manager.didAuthenticate;

    if (!tx) { // tx is nil if there were insufficient wallet funds
        if (!manager.didAuthenticate) [manager seedWithPrompt:prompt forAmount:amount];

        if (manager.didAuthenticate) {
            uint64_t fuzz = [manager amountForLocalCurrencyString:[manager localCurrencyStringForAmount:1]] * 2;

            // if user selected an amount equal to or below wallet balance, but the fee will bring the total above the
            // balance, offer to reduce the amount to available funds minus fee
            if (self.amount <= manager.wallet.balance + fuzz && self.amount > 0) {
                int64_t amount = manager.wallet.maxOutputAmount;

                if (amount > 0 && amount < self.amount) {
                    [[[UIAlertView alloc]
                            initWithTitle:NSLocalizedString(@"insufficient funds for bitcoin network fee", nil)
                                  message:[NSString stringWithFormat:NSLocalizedString(@"reduce payment amount by\n%@ (%@)?", nil),
                                                                     [manager stringForAmount:self.amount - amount],
                                                                     [manager localCurrencyStringForAmount:self.amount - amount]] delegate:self
                        cancelButtonTitle:NSLocalizedString(@"cancel", nil)
                        otherButtonTitles:[NSString stringWithFormat:@"%@ (%@)",
                                                                     [manager stringForAmount:amount - self.amount],
                                                                     [manager localCurrencyStringForAmount:amount - self.amount]], nil] show];
                    self.amount = amount;
                } else {
                    [[[UIAlertView alloc]
                            initWithTitle:NSLocalizedString(@"insufficient funds for bitcoin network fee", nil) message:nil
                                 delegate:self cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil] show];
                }
            } else {
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"insufficient funds", nil) message:nil
                                           delegate:self cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil] show];
            }
        } else {
            NSLog(@"Send error 3");
//            [self cancelOrChangeAmount];
        }

        if (!didAuth) manager.didAuthenticate = NO;
        return;
    }

    if (![manager.wallet signTransaction:tx withPrompt:prompt]) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"couldn't make payment", nil)
                                    message:NSLocalizedString(@"error signing bitcoin transaction", nil) delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil] show];
    }

    if (!didAuth) manager.didAuthenticate = NO;

    if (!tx.isSigned) { // user canceled authentication
//        [self cancelOrChangeAmount];
        NSLog(@"Send error 2");
        return;
    }

    if (self.navigationController.topViewController != self.parentViewController.parentViewController) {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }

    __block BOOL waiting = YES, sent = NO;

    [(id) self.parentViewController.parentViewController startActivityWithTimeout:30.0];

    [[BRPeerManager sharedInstance] publishTransaction:tx completion:^(NSError *error) {
        if (error) {
            if (!waiting && !sent) {
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"couldn't make payment", nil)
                                            message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil)
                                  otherButtonTitles:nil] show];
                [(id) self.parentViewController.parentViewController stopActivityWithSuccess:NO];
//                [self cancel:nil];
            }
        } else if (!sent) { //TODO: show full screen sent dialog with tx info, "you sent b10,000 to bob"
            sent = YES;
            tx.timestamp = [NSDate timeIntervalSinceReferenceDate];
            [manager.wallet registerTransaction:tx];
            [self.view addSubview:[[[BRBubbleView viewWithText:NSLocalizedString(@"sent!", nil)
                                                        center:CGPointMake(self.view.bounds.size.width / 2, self.view.bounds.size.height / 2)] popIn]
                    popOutAfterDelay:2.0]];
            [(id) self.parentViewController.parentViewController stopActivityWithSuccess:YES];
            [(id) self.parentViewController.parentViewController ping];

//            if (self.callback) {
//                self.callback = [NSURL URLWithString:[self.callback.absoluteString stringByAppendingFormat:@"%@txid=%@",
//                                                                                                           (self.callback.query.length > 0) ? @"&" : @"?",
//                                                                                                           [NSString hexWithData:[NSData dataWithBytes:tx.txHash.u8
//                                                                                                                                                length:sizeof(UInt256)].reverse]]];
//                [[UIApplication sharedApplication] openURL:self.callback];
//            }

//            [self reset:nil];
        }

        waiting = NO;
    }];

    if (self.request.details.paymentURL.length > 0) {
        uint64_t refundAmount = 0;
        NSMutableData *refundScript = [NSMutableData data];

        [refundScript appendScriptPubKeyForAddress:manager.wallet.receiveAddress];

        for (NSNumber *amt in self.request.details.outputAmounts) {
            refundAmount += amt.unsignedLongLongValue;
        }

        // TODO: keep track of commonName/memo to associate them with outputScripts
        BRPaymentProtocolPayment *payment =
                [[BRPaymentProtocolPayment alloc] initWithMerchantData:self.request.details.merchantData
                                                          transactions:@[tx] refundToAmounts:@[@(refundAmount)] refundToScripts:@[refundScript] memo:nil];

        NSLog(@"posting payment to: %@", self.request.details.paymentURL);

        [BRPaymentRequest postPayment:payment to:self.request.details.paymentURL timeout:20.0
                           completion:^(BRPaymentProtocolACK *ack, NSError *error) {
                               dispatch_async(dispatch_get_main_queue(), ^{
                                   [(id) self.parentViewController.parentViewController stopActivityWithSuccess:(!error)];

                                   if (error) {
                                       if (!waiting && !sent) {
                                           [[[UIAlertView alloc] initWithTitle:@"" message:error.localizedDescription delegate:nil
                                                             cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil] show];
                                           [(id) self.parentViewController.parentViewController stopActivityWithSuccess:NO];
//                                           [self cancel:nil];
                                       }
                                   } else if (!sent) {
                                       sent = YES;
                                       tx.timestamp = [NSDate timeIntervalSinceReferenceDate];
                                       [manager.wallet registerTransaction:tx];
                                       [self.view addSubview:[[[BRBubbleView
                                               viewWithText:(ack.memo.length > 0 ? ack.memo : NSLocalizedString(@"sent!", nil))
                                                     center:CGPointMake(self.view.bounds.size.width / 2, self.view.bounds.size.height / 2)] popIn]
                                               popOutAfterDelay:(ack.memo.length > 0 ? 3.0 : 2.0)]];
                                       [(id) self.parentViewController.parentViewController stopActivityWithSuccess:YES];
                                       [(id) self.parentViewController.parentViewController ping];

//                                       if (self.callback) {
//                                           self.callback = [NSURL URLWithString:[self.callback.absoluteString
//                                                   stringByAppendingFormat:@"%@txid=%@",
//                                                                           (self.callback.query.length > 0) ? @"&" : @"?",
//                                                                           [NSString hexWithData:[NSData dataWithBytes:tx.txHash.u8
//                                                                                                                length:sizeof(UInt256)].reverse]]];
//                                           [[UIApplication sharedApplication] openURL:self.callback];
//                                       }

//                                       [self reset:nil];
                                   }

                                   waiting = NO;
                               });
                           }];
    } else waiting = NO;
}

- (NSString *)promptForAmount:(uint64_t)amount fee:(uint64_t)fee address:(NSString *)address name:(NSString *)name
                         memo:(NSString *)memo isSecure:(BOOL)isSecure {
    BRWalletManager *manager = [BRWalletManager sharedInstance];
    NSString *prompt = (isSecure && name.length > 0) ? LOCK @" " : @"";

    //BUG: XXX limit the length of name and memo to avoid having the amount clipped
    if (!isSecure && self.request.errorMessage.length > 0) prompt = [prompt stringByAppendingString:REDX @" "];
    if (name.length > 0) prompt = [prompt stringByAppendingString:sanitizeString(name)];
    if (!isSecure && prompt.length > 0) prompt = [prompt stringByAppendingString:@"\n"];
    if (!isSecure || prompt.length == 0) prompt = [prompt stringByAppendingString:address];
    if (memo.length > 0) prompt = [prompt stringByAppendingFormat:@"\n\n%@", sanitizeString(memo)];
    prompt = [prompt stringByAppendingFormat:NSLocalizedString(@"\n\n     amount %@ (%@)", nil),
                                             [manager stringForAmount:amount - fee], [manager localCurrencyStringForAmount:amount - fee]];
    if (fee > 0) {
        prompt = [prompt stringByAppendingFormat:NSLocalizedString(@"\nnetwork fee +%@ (%@)", nil),
                                                 [manager stringForAmount:fee], [manager localCurrencyStringForAmount:fee]];
        prompt = [prompt stringByAppendingFormat:NSLocalizedString(@"\n         total %@ (%@)", nil),
                                                 [manager stringForAmount:amount], [manager localCurrencyStringForAmount:amount]];
    }

    return prompt;
}

- (void)protectedViewDidAppear {
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    BRWalletManager *manager = [BRWalletManager sharedInstance];

    if (self.protectedObserver) [[NSNotificationCenter defaultCenter] removeObserver:self.protectedObserver];
    self.protectedObserver = nil;

    if ([defs integerForKey:SETTINGS_MAX_DIGITS_KEY] == 5) {
        manager.format.currencySymbol = @"m" BTC NARROW_NBSP;
        manager.format.maximumFractionDigits = 5;
        manager.format.maximum = @((MAX_MONEY / SATOSHIS) * 1000);
    } else if ([defs integerForKey:SETTINGS_MAX_DIGITS_KEY] == 8) {
        manager.format.currencySymbol = BTC NARROW_NBSP;
        manager.format.maximumFractionDigits = 8;
        manager.format.maximum = @(MAX_MONEY / SATOSHIS);
    }

    if (manager.noWallet) {
        if (!manager.passcodeEnabled) {
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"turn device passcode on", nil)
                                        message:NSLocalizedString(@"\nA device passcode is needed to safeguard your wallet. Go to settings and "
                                                "turn passcode on to continue.", nil)
                                       delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"close app", nil), nil] show];
        } else {
//            [self.navigationController
//                    presentViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"NewWalletNav"] animated:NO
//                               completion:^{
//                                   self.splash.hidden = YES;
//                                   self.navigationController.navigationBar.hidden = NO;
////                                   [self.pageViewController setViewControllers:@[self.receiveViewController]
////                                                                     direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
//                               }];
            [BREventManager saveEvent:@"welcome:generate"];
//            manager.didAuthenticate = YES;
//            self.showTips = YES;
            NSLog(@"UNLOCK 2 %d", [BRWalletManager sharedInstance].didAuthenticate);
            if (manager.didAuthenticate) [self unlock:nil];
            manager.didAuthenticate = NO;
            [BREventManager saveEvent:@"welcome:show"];
            [manager generateRandomSeed];
            NSLog(@"New Seed = %@", manager.seedPhrase);

            __kindof UIViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"SeedViewController"];
            [self presentViewController:controller animated:true completion:nil];
        }
    } else {
        NSLog(@"Seed = %@", manager.seedPhrase);
        if (_balance == UINT64_MAX && [defs objectForKey:BALANCE_KEY]) self.balance = [defs doubleForKey:BALANCE_KEY];
        self.splash.hidden = YES;

        self.navigationController.navigationBar.hidden = NO;
//        self.pageViewController.view.alpha = 1.0;
//        [self.receiveViewController updateAddress];
        if (self.reachability.currentReachabilityStatus == NotReachable) [self showErrorBar];

        if (self.navigationController.visibleViewController == self) {
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
            [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        }

#if SNAPSHOT
        return;
#endif
        if ([defs doubleForKey:PIN_UNLOCK_TIME_KEY] + 7 * 24 * 60 * 60 < [NSDate timeIntervalSinceReferenceDate]) {
            NSLog(@"UNLOCK 2 %d", [BRWalletManager sharedInstance].didAuthenticate);
//            while (![manager authenticateWithPrompt:nil andTouchId:NO]) {}
//            [self unlock:nil];
            if ([manager authenticateWithPrompt:nil andTouchId:NO]) {
                [self unlock:nil];
            } else {
                return;
            }
        }

        if (self.navigationController.visibleViewController == self) {
            if (self.showTips) [self performSelector:@selector(tip:) withObject:nil afterDelay:0.3];
        }

        if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground) {
            [[BRPeerManager sharedInstance] connect];
            [UIApplication sharedApplication].applicationIconBadgeNumber = 0; // reset app badge number

            if (self.url) {
//                [self.sendViewController handleURL:self.url];
                self.url = nil;
            } else if (self.file) {
//                [self.sendViewController handleFile:self.file];
                self.file = nil;
            }

            BRAppDelegate *del = (BRAppDelegate *) [UIApplication sharedApplication].delegate;
            [del updatePlatformOnComplete:^{
                NSLog(@"[BRRootViewController] updatePlatform completed!");
                NSLog(@"CL 8");

                if (!self.showTips &&
                        [[NSUserDefaults standardUserDefaults] boolForKey:@"has_alerted_buy_bitcoin"] == NO
                                && [WKWebView class] && [[BRAPIClient sharedClient] featureEnabled:BRFeatureFlagsBuyBitcoin]) {
                    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"has_alerted_buy_bitcoin"];
                    [self showBuyAlert];
                }
            }];
        }
    }

    [_tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    if (self.navBarTap) [self.navigationController.navigationBar removeGestureRecognizer:self.navBarTap];
    self.navBarTap = nil;
    [self hideTips];

    [super viewWillDisappear:animated];
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if ([self nextTip]) return NO;

    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];

    (segue.destinationViewController).transitioningDelegate = self;
    (segue.destinationViewController).modalPresentationStyle = UIModalPresentationCustom;
    [self hideErrorBar];

    if ([sender isEqual:NSLocalizedString(@"show phrase", nil)]) { // show recovery phrase
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"WARNING", nil)
                                    message:[NSString stringWithFormat:@"\n%@\n\n%@\n\n%@\n",
                                                                       [NSLocalizedString(@"\nDO NOT let anyone see your recovery\n"
                                                                               "phrase or they can spend your bitcoins.\n", nil)
                                                                               stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]],
                                                                       [NSLocalizedString(@"\nNEVER type your recovery phrase into\n"
                                                                               "password managers or elsewhere.\n"
                                                                               "Other devices may be infected.\n", nil)
                                                                               stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]],
                                                                       [NSLocalizedString(@"\nDO NOT take a screenshot.\n"
                                                                               "Screenshots are visible to other apps\n"
                                                                               "and devices.\n", nil)
                                                                               stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]]]
                                   delegate:[(id) segue.destinationViewController viewControllers].firstObject
                          cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:NSLocalizedString(@"show", nil), nil]
                show];
    } else if ([sender isEqual:@"buy alert"]) {
        UINavigationController *nav = segue.destinationViewController;

        [nav.topViewController performSelector:@selector(showBuy) withObject:nil afterDelay:1.0];
    }
}

- (void)viewDidLayoutSubviews {
    [self scrollViewDidScroll:self.scrollView];
}

- (void)dealloc {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self.reachability stopNotifier];
    if (self.navigationController.delegate == self) self.navigationController.delegate = nil;
    if (self.urlObserver) [[NSNotificationCenter defaultCenter] removeObserver:self.urlObserver];
    if (self.fileObserver) [[NSNotificationCenter defaultCenter] removeObserver:self.fileObserver];
    if (self.protectedObserver) [[NSNotificationCenter defaultCenter] removeObserver:self.protectedObserver];
    if (self.foregroundObserver) [[NSNotificationCenter defaultCenter] removeObserver:self.foregroundObserver];
    if (self.backgroundObserver) [[NSNotificationCenter defaultCenter] removeObserver:self.backgroundObserver];
    if (self.activeObserver) [[NSNotificationCenter defaultCenter] removeObserver:self.activeObserver];
    if (self.resignActiveObserver) [[NSNotificationCenter defaultCenter] removeObserver:self.resignActiveObserver];
    if (self.reachabilityObserver) [[NSNotificationCenter defaultCenter] removeObserver:self.reachabilityObserver];
    if (self.balanceObserver) [[NSNotificationCenter defaultCenter] removeObserver:self.balanceObserver];
    if (self.seedObserver) [[NSNotificationCenter defaultCenter] removeObserver:self.seedObserver];
    if (self.syncStartedObserver) [[NSNotificationCenter defaultCenter] removeObserver:self.syncStartedObserver];
    if (self.syncFinishedObserver) [[NSNotificationCenter defaultCenter] removeObserver:self.syncFinishedObserver];
    if (self.syncFailedObserver) [[NSNotificationCenter defaultCenter] removeObserver:self.syncFailedObserver];
//    AudioServicesDisposeSystemSoundID(self.pingsound);
}

- (void)setBalance:(uint64_t)balance {
//    NSLog(@"set balance %llu", balance);
    BRWalletManager *manager = [BRWalletManager sharedInstance];

    if (balance > _balance && [UIApplication sharedApplication].applicationState != UIApplicationStateBackground) {
//        [self.view addSubview:[[[BRBubbleView viewWithText:[NSString
//                        stringWithFormat:NSLocalizedString(@"received %@ (%@)", nil), [manager stringForAmount:balance - _balance],
//                                         [manager localCurrencyStringForAmount:balance - _balance]]
//                                                    center:CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2)] popIn]
//                popOutAfterDelay:3.0]];
        [self ping];
    }

    _balance = balance;
//    _balanceLabel.text = [NSString stringWithFormat:@"%@ (%@)", [manager stringForAmount:balance],
//                                                    [manager localCurrencyStringForAmount:balance]];
    // use setDouble since setInteger won't hold a uint64_t
    [[NSUserDefaults standardUserDefaults] setDouble:balance forKey:BALANCE_KEY];

    if (self.percent.hidden) {
        self.navigationItem.title = [NSString stringWithFormat:@"%@ (%@)", [manager stringForAmount:balance],
                                                               [manager localCurrencyStringForAmount:balance]];
    }
    [_tableView reloadData];
}

- (void)showSyncing {
//    double progress = [BRPeerManager sharedInstance].syncProgress;
//
//    if (progress > DBL_EPSILON && progress + DBL_EPSILON < 1.0 &&
//            [BRWalletManager sharedInstance].seedCreationTime + 60*60*24 < [NSDate timeIntervalSinceReferenceDate]) {
//        self.percent.hidden = NO;
//        self.navigationItem.titleView = nil;
//        self.navigationItem.title = NSLocalizedString(@"syncing...", nil);
//    }
}

- (void)startActivityWithTimeout:(NSTimeInterval)timeout {
//    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
//
//    if (timeout > 1 && start + timeout > self.start + self.timeout) {
//        self.timeout = timeout;
//        self.start = start;
//    }
//
//    if (timeout <= DBL_EPSILON) {
//        if ([[BRPeerManager sharedInstance] timestampForBlockHeight:[BRPeerManager sharedInstance].lastBlockHeight] +
//                60*60*24*7 < [NSDate timeIntervalSinceReferenceDate]) {
//            if ([BRWalletManager sharedInstance].seedCreationTime + 60*60*24 < start) {
//                self.percent.hidden = NO;
//                self.navigationItem.titleView = nil;
//                self.navigationItem.title = NSLocalizedString(@"syncing...", nil);
//            }
//        }
//        else [self performSelector:@selector(showSyncing) withObject:nil afterDelay:5.0];
//    }
//
//    [UIApplication sharedApplication].idleTimerDisabled = YES;
//    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    self.progress.hidden = self.pulse.hidden = NO;
    [UIView animateWithDuration:0.2 animations:^{
        self.progress.alpha = 1.0;
    }];
    [self updateProgress];
}

- (void)stopActivityWithSuccess:(BOOL)success {
    NSLog(@"stopActivityWithSuccess");
    double progress = [BRPeerManager sharedInstance].syncProgress;

    self.start = self.timeout = 0.0;
    if (progress > DBL_EPSILON && progress + DBL_EPSILON < 1.0) return; // not done syncing
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    if (self.progress.alpha < 0.5) return;

    if (success) {
        [self.progress setProgress:1.0 animated:YES];
        [self.pulse setProgress:1.0 animated:YES];

        [UIView animateWithDuration:0.2 animations:^{
            self.progress.alpha = self.pulse.alpha = 0.0;
        }                completion:^(BOOL finished) {
            self.progress.hidden = self.pulse.hidden = YES;
            self.progress.progress = self.pulse.progress = 0.0;
        }];
    } else {
        self.progress.hidden = self.pulse.hidden = YES;
        self.progress.progress = self.pulse.progress = 0.0;
    }
}

- (void)setProgressTo:(NSNumber *)n {
    self.progress.progress = n.floatValue;
}

- (void)updateProgress {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateProgress) object:nil];

    static int counter = 0;
    NSTimeInterval elapsed = [NSDate timeIntervalSinceReferenceDate] - self.start;
    double progress = [BRPeerManager sharedInstance].syncProgress;

//    if (progress > DBL_EPSILON && ! self.percent.hidden && self.tipView.alpha > 0.5) {
//        self.tipView.text = [NSString stringWithFormat:NSLocalizedString(@"block #%d of %d", nil),
//                                                       [BRPeerManager sharedInstance].lastBlockHeight,
//                                                       [BRPeerManager sharedInstance].estimatedBlockHeight];
//    }

    if (self.timeout > 1.0 && 0.1 + 0.9 * elapsed / self.timeout < progress) progress = 0.1 + 0.9 * elapsed / self.timeout;

    if ((counter % 13) == 0) {
        self.pulse.alpha = 1.0;
        [self.pulse setProgress:progress animated:progress > self.pulse.progress];
        [self.progress setProgress:progress animated:progress > self.progress.progress];

        if (progress > self.progress.progress) {
            [self performSelector:@selector(setProgressTo:) withObject:@(progress) afterDelay:1.0];
        } else self.progress.progress = progress;

        [UIView animateWithDuration:1.59 delay:1.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.pulse.alpha = 0.0;
        }                completion:nil];

        [self.pulse performSelector:@selector(setProgress:) withObject:nil afterDelay:2.59];
    } else if ((counter % 13) >= 5) {
        [self.progress setProgress:progress animated:progress > self.progress.progress];
        [self.pulse setProgress:progress animated:progress > self.pulse.progress];
    }

    counter++;
    self.percent.text = [NSString stringWithFormat:@"%0.1f%%", (progress > 0.1 ? progress - 0.1 : 0.0) * 111.0];

    if (progress + DBL_EPSILON >= 1.0) {
        if (self.timeout < 1.0) [self stopActivityWithSuccess:YES];
//        if (! self.percent.hidden) [self hideTips];
        self.percent.hidden = YES;
//        if (! [BRWalletManager sharedInstance].didAuthenticate) self.navigationItem.titleView = self.logo;
    } else [self performSelector:@selector(updateProgress) withObject:nil afterDelay:0.2];
}

- (void)ping {
//    AudioServicesPlaySystemSound(self.pingsound);
}

- (void)showErrorBar {
    if (self.navigationItem.prompt != nil || self.navigationController.presentedViewController != nil) return;
    self.navigationItem.prompt = @"";
    self.errorBar.hidden = NO;
    self.errorBar.alpha = 0.0;

    [UIView animateWithDuration:UINavigationControllerHideShowBarDuration delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
//                self.burger.center = CGPointMake(self.burger.center.x, 70.0);
                self.errorBar.alpha = 1.0;
            }        completion:nil];

//    BRWalletManager *manager = [BRWalletManager sharedInstance];
//
//    if (! self.percent.hidden) [self hideTips];
//    self.percent.hidden = YES;
//    if (! manager.didAuthenticate) self.navigationItem.titleView = self.logo;
//    self.balance = _balance; // reset navbar title
//    self.progress.hidden = self.pulse.hidden = YES;
}

- (void)hideErrorBar {
    if (self.navigationItem.prompt == nil) return;
    self.navigationItem.prompt = nil;

    [UIView animateWithDuration:UINavigationControllerHideShowBarDuration delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut animations:^{
//                self.burger.center = CGPointMake(self.burger.center.x, 40.0);
                self.errorBar.alpha = 0.0;
            }        completion:^(BOOL finished) {
                if (self.navigationItem.prompt == nil) self.errorBar.hidden = YES;
            }];
}

- (void)showBackupDialogIfNeeded {
//    BRWalletManager *manager = [BRWalletManager sharedInstance];
//    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
//    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
//
//    if (self.navigationController.visibleViewController != self || ! [defs boolForKey:WALLET_NEEDS_BACKUP_KEY] ||
//            manager.wallet.balance == 0 || [defs doubleForKey:BACKUP_DIALOG_TIME_KEY] > now - 36*60*60) return;
//
//    BOOL first = ([defs doubleForKey:BACKUP_DIALOG_TIME_KEY] < 1.0) ? YES : NO;
//
//    [defs setDouble:now forKey:BACKUP_DIALOG_TIME_KEY];
//
//    [[[UIAlertView alloc]
//            initWithTitle:(first) ? NSLocalizedString(@"you received bitcoin!", nil) : NSLocalizedString(@"IMPORTANT", nil)
//                  message:[NSString stringWithFormat:NSLocalizedString(@"\n%@\n\nif you ever lose your phone, you will need it to "
//                          "recover your wallet", nil),
//                                                     (first) ? NSLocalizedString(@"next, write down your recovery phrase", nil) :
//                                                             NSLocalizedString(@"WRITE DOWN YOUR RECOVERY PHRASE", nil)] delegate:self
//        cancelButtonTitle:NSLocalizedString(@"do it later", nil)
//        otherButtonTitles:NSLocalizedString(@"show phrase", nil), nil] show];
}

- (void)hideTips {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(tip:) object:nil];
//    if (self.tipView.alpha > 0.5) [self.tipView popOut];
}

- (BOOL)nextTip {
//    if (self.tipView.alpha < 0.5) { // if the tip view is dismissed, cycle through child view controller tips
//        BOOL ret;
//
//        if (self.inNextTip) return NO; // break out of recursive loop
//        self.inNextTip = YES;
//        ret = [self.pageViewController.viewControllers.lastObject nextTip];
//        self.inNextTip = NO;
//        return ret;
//    }
//
//    BRBubbleView *tipView = self.tipView;
//
//    self.tipView = nil;
//    [tipView popOut];
//
//    if ([tipView.text hasPrefix:BALANCE_TIP]) {
//        BRWalletManager *manager = [BRWalletManager sharedInstance];
//        UINavigationBar *navBar = self.navigationController.navigationBar;
//        NSString *text = [NSString stringWithFormat:BITS_TIP,
//                                                    manager.format.currencySymbol, [manager stringForAmount:SATOSHIS]];
//        CGRect r = [self.navigationItem.title boundingRectWithSize:navBar.bounds.size options:0
//                                                        attributes:navBar.titleTextAttributes context:nil];
//
//        self.tipView = [BRBubbleView viewWithText:text
//                                         tipPoint:CGPointMake(navBar.center.x + 5.0 - r.size.width/2.0,
//                                                 navBar.frame.origin.y + navBar.frame.size.height - 10)
//                                     tipDirection:BRBubbleTipDirectionUp];
//        self.tipView.backgroundColor = tipView.backgroundColor;
//        self.tipView.font = tipView.font;
//        self.tipView.userInteractionEnabled = NO;
//        [self.view addSubview:[self.tipView popIn]];
//    }
//    else if (self.showTips) {
//        self.showTips = NO;
//        [self.pageViewController.viewControllers.lastObject tip:self];
//    }
    return NO;
//    return YES;
}

// MARK: - IBAction

- (IBAction)tip:(id)sender {
//    BRWalletManager *manager = [BRWalletManager sharedInstance];
//
//    if (sender == self.receiveViewController) {
//        BRSendViewController *sendController = self.sendViewController;
//
//        [(id)self.pageViewController setViewControllers:@[sendController]
//                                              direction:UIPageViewControllerNavigationDirectionReverse animated:YES
//                                             completion:^(BOOL finished) { [sendController tip:sender]; }];
//    }
//    else if (sender == self.sendViewController) {
//        self.scrollView.scrollEnabled = YES;
//        [(id)self.pageViewController setViewControllers:@[self.receiveViewController]
//                                              direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
//    }
//    else if (self.showTips && manager.seedCreationTime + 60*60*24 < [NSDate timeIntervalSinceReferenceDate]) {
//        self.showTips = NO;
//    }
//    else {
//        UINavigationBar *bar = self.navigationController.navigationBar;
//        NSString *tip = (self.percent.hidden) ? BALANCE_TIP :
//                [NSString stringWithFormat:NSLocalizedString(@"block #%d of %d", nil),
//                                           [BRPeerManager sharedInstance].lastBlockHeight,
//                                           [BRPeerManager sharedInstance].estimatedBlockHeight];
//
//        self.tipView = [BRBubbleView viewWithText:tip
//                                         tipPoint:CGPointMake(bar.center.x, bar.frame.origin.y + bar.frame.size.height - 10)
//                                     tipDirection:BRBubbleTipDirectionUp];
//        self.tipView.backgroundColor = [UIColor orangeColor];
//        self.tipView.font = [UIFont fontWithName:@"HelveticaNeue" size:15.0];
//        self.tipView.userInteractionEnabled = NO;
//        [self.view addSubview:[self.tipView popIn]];
//        if (self.showTips) self.scrollView.scrollEnabled = NO;
//    }
}

- (IBAction)unlock:(id)sender {
    [BREventManager saveEvent:@"root:unlock"];
    BRWalletManager *manager = [BRWalletManager sharedInstance];

    NSLog(@"UNLOCK! 7");
    if (sender && !manager.didAuthenticate && ![manager authenticateWithPrompt:nil andTouchId:YES]) return;
    [BREventManager saveEvent:@"root:unlock_success"];

    self.navigationItem.titleView = nil;
    [self.navigationItem setRightBarButtonItem:nil animated:(sender) ? YES : NO];
}

- (IBAction)connect:(id)sender {
    [BREventManager saveEvent:@"root:connect"];
    if (!sender && [self.reachability currentReachabilityStatus] == NotReachable) return;

    [[BRPeerManager sharedInstance] connect];
    [BREventManager saveEvent:@"root:connect_success"];
    if (self.reachability.currentReachabilityStatus == NotReachable) [self showErrorBar];
}

- (IBAction)navBarTap:(id)sender {
//    if ([self nextTip]) return;
//
//    if (! self.errorBar.hidden) {
//        [self hideErrorBar];
//        [self performSelector:@selector(connect:) withObject:sender afterDelay:0.1];
//    }
//    else if (! [BRWalletManager sharedInstance].didAuthenticate && self.percent.hidden) {
//        [self unlock:sender];
//    }
//    else [self tip:sender];
}

- (void)showBuyAlert {
//    // grab a blurred image for the background
//    UIGraphicsBeginImageContext(self.navigationController.view.bounds.size);
//    [self.navigationController.view drawViewHierarchyInRect:self.navigationController.view.bounds
//                                         afterScreenUpdates:NO];
//    UIImage *bgImg = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//    UIImage *blurredBgImg = [bgImg blurWithRadius:3];
//
//    // display the popup
//    __weak BREventConfirmView *view =
//            [[NSBundle mainBundle] loadNibNamed:@"BREventConfirmView" owner:nil options:nil][0];
//    view.titleLabel.text = NSLocalizedString(@"Buy bitcoin in breadwallet!", nil);
//    view.descriptionLabel.text =
//            NSLocalizedString(@"You can now buy bitcoin in\nbreadwallet with cash or\nbank transfer.", nil);
//    [view.okBtn setTitle:NSLocalizedString(@"Try It!", nil) forState:UIControlStateNormal];
//
//    view.image = blurredBgImg;
//    view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
//    view.frame = self.navigationController.view.bounds;
//    view.alpha = 0;
//    [self.navigationController.view addSubview:view];
//
//    [UIView animateWithDuration:.5 animations:^{
//        view.alpha = 1;
//    }];
//
//    view.completionHandler = ^(BOOL didApprove) {
//        if (didApprove) [self performSegueWithIdentifier:@"SettingsSegue" sender:@"buy alert"];
//
//        [UIView animateWithDuration:.5 animations:^{
//            view.alpha = 0;
//        } completion:^(BOOL finished) {
//            [view removeFromSuperview];
//        }];
//    };
}

#if SNAPSHOT
- (IBAction)nextScreen:(id)sender
{
    BRWalletManager *manager = [BRWalletManager sharedInstance];

    if (self.navigationController.presentedViewController) {
        if (manager.noWallet) [manager generateRandomSeed];
        self.showTips = NO;
        [self.navigationController dismissViewControllerAnimated:NO completion:^{
            manager.didAuthenticate = NO;
            self.navigationItem.titleView = self.logo;
            self.navigationItem.rightBarButtonItem = self.lock;
            self.pageViewController.view.alpha = 1.0;
            self.navigationController.navigationBar.hidden = YES;
            [[UIApplication sharedApplication] setStatusBarHidden:YES];
            self.splash.hidden = NO;
            [self.splash
             addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(nextScreen:)]];
        }];
    }
    else if (! self.splash.hidden) {
        self.navigationController.navigationBar.hidden = NO;
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
        self.splash.hidden = YES;
        [self stopActivityWithSuccess:YES];
        [self.pageViewController setViewControllers:@[self.receiveViewController]
         direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
        self.receiveViewController.paymentRequest =
            [BRPaymentRequest requestWithString:@"n2eMqTT929pb1RDNuqEnxdaLau1rxy3efi"];
        [self.receiveViewController updateAddress];
        [self.progress removeFromSuperview];
        [self.pulse removeFromSuperview];
    }
}
#endif

// MARK: - UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
      viewControllerBeforeViewController:(UIViewController *)viewController {
    return nil;
//    return (viewController == self.receiveViewController) ? self.sendViewController : nil;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
       viewControllerAfterViewController:(UIViewController *)viewController {
    return nil;
//    return (viewController == self.sendViewController) ? self.receiveViewController : nil;
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController {
    return 2;
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController {
    return 0;
//    return (pageViewController.viewControllers.lastObject == self.receiveViewController) ? 1 : 0;
}

// MARK: - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat off = scrollView.contentOffset.x + (scrollView.contentInset.left < 0 ? scrollView.contentInset.left : 0);

//    self.wallpaperXLeft.constant = -PARALAX_RATIO*off;
}

// MARK: - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.cancelButtonIndex) return;

    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqual:NSLocalizedString(@"close app", nil)]) exit(0);

    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqual:NSLocalizedString(@"wipe", nil)]) {
//        BRRestoreViewController *restoreController =
//                [self.storyboard instantiateViewControllerWithIdentifier:@"WipeViewController"];

//        [self.navigationController pushViewController:restoreController animated:NO];
        return;
    }

    [self performSegueWithIdentifier:@"SettingsSegue" sender:[alertView buttonTitleAtIndex:buttonIndex]];
}

// MARK: - UIViewControllerAnimatedTransitioning

// This is used for percent driven interactive transitions, as well as for container controllers that have companion
// animations that might need to synchronize with the main animation.
- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return (transitionContext.isAnimated) ? 0.35 : 0.0;
}

// This method can only be a nop if the transition is interactive and not a percentDriven interactive transition.
- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    BRWalletManager *manager = [BRWalletManager sharedInstance];
//    UIView *containerView = transitionContext.containerView;
//    UIViewController *to = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey],
//            *from = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
//
//    if (to == self || from == self) { // nav stack push/pop
//        self.progress.hidden = self.pulse.hidden = YES;
//        [containerView addSubview:to.view];
//        to.view.center = CGPointMake(containerView.frame.size.width*(to == self ? -1 : 3)/2, to.view.center.y);
//
//        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0.0 usingSpringWithDamping:0.8
//              initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
//                    to.view.center = from.view.center;
//                    from.view.center = CGPointMake(containerView.frame.size.width*(to == self ? 3 : -1)/2, from.view.center.y);
//                    self.wallpaperXLeft.constant = containerView.frame.size.width*(to == self ? 0 : -1)*PARALAX_RATIO;
//                } completion:^(BOOL finished) {
//                    if (to == self) {
//                        [from.view removeFromSuperview];
//                        self.navigationController.navigationBarHidden = YES; // hack to fix topLayoutGuide bug
//                        [self.navigationController performSelector:@selector(setNavigationBarHidden:) withObject:nil
//                                                        afterDelay:0];
//                    }
//
//                    if (self.progress.progress > 0) self.progress.hidden = self.pulse.hidden = NO;
//                    [transitionContext completeTransition:YES];
//                }];
//    }
//    else if ([to isKindOfClass:[UINavigationController class]] && from == self.navigationController) { // modal display
//        // to.view must be added to superview prior to positioning it off screen for its navbar to underlap statusbar
//        [self.navigationController.navigationBar.superview insertSubview:to.view
//                                                            belowSubview:self.navigationController.navigationBar];
//        [containerView layoutIfNeeded];
//        to.view.center = CGPointMake(to.view.center.x, containerView.frame.size.height*3/2);
//
//        UINavigationItem *item = [(id)to topViewController].navigationItem;
//        UIView *titleView = item.titleView;
//        UIBarButtonItem *rightButton = item.rightBarButtonItem;
//
//        item.title = nil;
//        item.leftBarButtonItem.image = [UIImage imageNamed:@"none"];
//        item.titleView = nil;
//        item.rightBarButtonItem = nil;
//        self.navigationItem.leftBarButtonItem.image = [UIImage imageNamed:@"none"];
////        [containerView addSubview:self.burger];
//        [containerView layoutIfNeeded];
////        self.burger.center = CGPointMake(26.0, 40.0);
////        self.burger.hidden = NO;
////        [self.burger setX:YES completion:nil];
//
//        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0.0 usingSpringWithDamping:0.8
//              initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
//                    to.view.center = CGPointMake(to.view.center.x, containerView.frame.size.height/2);
////                    self.pageViewController.view.alpha = 0.0;
////                    self.pageViewController.view.center = CGPointMake(self.pageViewController.view.center.x,
////                            containerView.frame.size.height/4.0);
//                } completion:^(BOOL finished) {
////                    self.pageViewController.view.center = CGPointMake(self.pageViewController.view.center.x,
////                            containerView.frame.size.height/2.0);
//
//                    if (! manager.didAuthenticate) {
//                        item.rightBarButtonItem = rightButton;
//                        if (self.percent.hidden) item.titleView = titleView;
//                    }
//
//                    item.title = self.navigationItem.title;
//                    item.leftBarButtonItem.image = [UIImage imageNamed:@"x"];
//                    [containerView addSubview:to.view];
//                    [transitionContext completeTransition:YES];
//                }];
//    }
//    else if ([from isKindOfClass:[UINavigationController class]] && to == self.navigationController) { // modal dismiss
//        if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground) {
//            [[BRPeerManager sharedInstance] connect];
////            [self.sendViewController updateClipboardText];
//        }
//
//        if (manager.didAuthenticate) [self unlock:nil];
//        [self.navigationController.navigationBar.superview insertSubview:from.view
//                                                            belowSubview:self.navigationController.navigationBar];
//
//        UINavigationItem *item = [(id)from topViewController].navigationItem;
//        UIView *titleView = item.titleView;
//        UIBarButtonItem *rightButton = item.rightBarButtonItem;
//
//        item.title = nil;
//        item.leftBarButtonItem.image = [UIImage imageNamed:@"none"];
//        item.titleView = nil;
//        item.rightBarButtonItem = nil;
//        self.navigationItem.leftBarButtonItem.image = [UIImage imageNamed:@"none"];
////        self.burger.hidden = NO;
//        [containerView layoutIfNeeded];
////        self.burger.center = CGPointMake(26.0, 40.0);
////        [self.burger setX:NO completion:nil];
////        self.pageViewController.view.alpha = 0.0;
////        self.pageViewController.view.center = CGPointMake(self.pageViewController.view.center.x,
////                containerView.frame.size.height/4.0);
//
//        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0.0 usingSpringWithDamping:0.8
//              initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
//                    from.view.center = CGPointMake(from.view.center.x, containerView.frame.size.height*3/2);
////                    self.pageViewController.view.alpha = 1.0;
////                    self.pageViewController.view.center = CGPointMake(self.pageViewController.view.center.x,
////                            containerView.frame.size.height/2);
//                } completion:^(BOOL finished) {
//                    item.rightBarButtonItem = rightButton;
//                    item.titleView = titleView;
//                    item.title = self.navigationItem.title;
//                    item.leftBarButtonItem.image = [UIImage imageNamed:@"x"];
//                    [from.view removeFromSuperview];
////                    self.burger.hidden = YES;
//                    self.navigationItem.leftBarButtonItem.image = [UIImage imageNamed:@"burger"];
//                    [transitionContext completeTransition:YES];
//                    if (self.reachability.currentReachabilityStatus == NotReachable) [self showErrorBar];
//                }];
//    }
}

// MARK: - UINavigationControllerDelegate

- (id <UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                   animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC
                                                  toViewController:(UIViewController *)toVC {
    return self;
}

// MARK: - UIViewControllerTransitioningDelegate

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                   presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    return self;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    return self;
}


@end
