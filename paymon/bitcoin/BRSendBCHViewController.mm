//
//  BRSendBCHViewController.m
//  BreadWallet
//
//  Created by Adrian Corscadden on 2017-08-07.
//  Copyright © 2017 Aaron Voisine. All rights reserved.
//

#import "BRSendBCHViewController.h"
#import "BRScanViewController.h"
#import "BRWalletManager.h"
#import "BRWallet.h"
#import "paymon-Swift.h"
#import "BRPaymentRequest.h"
#import "BRBubbleView.h"

#if BITCOIN_TESTNET
#define BCASH_FORKHEIGHT 1155744
#else // mainnet
#define BCASH_FORKHEIGHT 478559
#endif

NSString * const BCHTxHashKey = @"BCHTxHashKey";

@interface BRSendBCHViewController ()

@property (nonatomic, strong) UILabel *body;
@property (nonatomic, strong) UIButton *scan;
@property (nonatomic, strong) UIButton *paste;
@property (nonatomic, strong) BRScanViewController *scanController;
@property (nonatomic, strong) UILabel *txHashHeader;
@property (nonatomic, strong) UIButton *txHashButton;
@property (nonatomic, strong) NSString *address;

@end

@implementation BRSendBCHViewController

- (void)viewDidLoad
{
    [self addSubviews];
    [self addConstraints];
    [self setInitialData];
}

- (void)addSubviews
{
    self.body = [[UILabel alloc] init];
    self.scan = [self buttonWithTitle:NSLocalizedString(@"scan QR code", nil) imageNamed:@"cameraguide-blue-small"];
    self.paste = [self buttonWithTitle:NSLocalizedString(@"pay address from clipboard", nil) imageNamed:nil];
    self.txHashHeader = [[UILabel alloc] init];
    self.txHashButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.view addSubview:self.body];
    [self.view addSubview:self.scan];
    [self.view addSubview:self.paste];
    [self.view addSubview:self.body];
    [self.view addSubview:self.txHashHeader];
    [self.view addSubview:self.txHashButton];
}

- (void)addConstraints
{
    [self constrain:@[
                      [self constraintFrom:self.body toView:self.view attribute:NSLayoutAttributeLeading constant:16.0],
                      [NSLayoutConstraint constraintWithItem:self.body attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.topLayoutGuide attribute:NSLayoutAttributeBottom multiplier:1.0 constant:16.0],
                      [self constraintFrom:self.body toView:self.view attribute:NSLayoutAttributeTrailing constant:-16.0], ]];

    [self constrain:@[
                      [self constraintFrom:self.scan toView:self.view attribute:NSLayoutAttributeCenterX constant:0.0],
                      [self constraintFrom:self.scan toView:self.view attribute:NSLayoutAttributeCenterY constant:-35.0],
                      [self constrain:self.scan toWidth:290.0],
                      [self constrain:self.scan toHeight:44.0] ]];

    [self constrain:@[
                      [self constraintFrom:self.paste toView:self.view attribute:NSLayoutAttributeCenterX constant:0.0],
                      [self constraintFrom:self.paste toView:self.view attribute:NSLayoutAttributeCenterY constant:35.0],
                      [self constrain:self.paste toWidth:290.0],
                      [self constrain:self.paste toHeight:44.0] ]];

    [self constrain:@[
                      [self constraintFrom:self.txHashHeader toView:self.view attribute:NSLayoutAttributeLeading constant:16.0],
                      [NSLayoutConstraint constraintWithItem:self.txHashHeader attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.paste attribute:NSLayoutAttributeBottom multiplier:1.0 constant:40.0]
                      ]];

    [self constrain:@[
                      [self constraintFrom:self.txHashButton toView:self.view attribute:NSLayoutAttributeLeading constant:16.0],
                      [self constraintFrom:self.txHashButton toView:self.view attribute:NSLayoutAttributeTrailing constant:-16.0],
                      [NSLayoutConstraint constraintWithItem:self.txHashButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.txHashHeader attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0]
                      ]];
}

- (void)setInitialData
{
    self.view.backgroundColor = [UIColor clearColor];
    self.navigationItem.title = NSLocalizedString(@"Withdraw BCH", nil);

    self.body.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:17.0];
    self.body.numberOfLines = 0;
    self.body.lineBreakMode = NSLineBreakByWordWrapping;
    self.body.text = NSLocalizedString(@"Use one of the options below to enter your destination address. All BCH in your wallet at the time of the fork will be sent.", nil);
    self.body.translatesAutoresizingMaskIntoConstraints = NO;

    [self.scan setImageEdgeInsets:UIEdgeInsetsMake(0, -10.0, 0.0, 10.0)];
    [self.scan addTarget:self action:@selector(didTapScan) forControlEvents:UIControlEventTouchUpInside];
    [self.paste addTarget:self action:@selector(didTapPaste) forControlEvents:UIControlEventTouchUpInside];

    self.txHashHeader.translatesAutoresizingMaskIntoConstraints = NO;
    self.txHashHeader.text = NSLocalizedString(@"BCH Transaction ID", nil);
    [self.txHashHeader setHidden:YES];
    self.txHashButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.txHashButton addTarget:self action:@selector(didTapTxHash) forControlEvents:UIControlEventTouchUpInside];
    [self setTxHashData];

    if ([BRPeerManager sharedInstance].lastBlockHeight < BCASH_FORKHEIGHT) {
        self.body.text = NSLocalizedString(@"Please wait for syncing to complete before using this feature.", nil);
        self.scan.enabled = NO;
        self.paste.enabled = NO;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (! self.scanController) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
        self.scanController = [storyboard instantiateViewControllerWithIdentifier:@"ScanViewController"];
        self.scanController.delegate = self;
    }
}

- (void)setTxHashData
{
    NSString *txHash = [[NSUserDefaults standardUserDefaults] stringForKey:BCHTxHashKey];
    if (txHash) {
        [self.txHashButton setTitle:txHash forState:UIControlStateNormal];
        [self.txHashHeader setHidden:NO];
    }
}


- (void)didTapScan
{
    [self.navigationController presentViewController:self.scanController animated:YES completion:nil];
}

- (void)didTapPaste
{
    NSString *str = [[UIPasteboard generalPasteboard].string
                     stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (str) {
        self.address = str;
        [self confirmSend];
    } else {
        [self showErrorMessage:NSLocalizedString(@"No Address on Pasteboard", nil)];
    }
}

- (void)didTapTxHash
{
    NSString *txHash = [[NSUserDefaults standardUserDefaults] stringForKey:BCHTxHashKey];
    if (txHash) {
        [[UIPasteboard generalPasteboard] setString:txHash];
        [self.view addSubview:[[[BRBubbleView viewWithText:NSLocalizedString(@"copied", nil)
                                                    center:CGPointMake(self.view.bounds.size.width/2.0, self.view.bounds.size.height/2.0 - 130.0)] popIn]
                               popOutAfterDelay:2.0]];
    }
}

- (void)confirmSend
{
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Would you like to send your entire BCH balance to %@", nil), self.address];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Send BCH?", nil) message:message delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
    [alert show];
}

- (void)showErrorMessage:(NSString *)message
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:message delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
    [alert show];
}

- (void)showSuccess
{
    [self setTxHashData];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Success", nil) message:NSLocalizedString(@"Successfully sent BCH", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
    [alert show];
}

- (void)send
{
    BCHSender *sender = [[BCHSender alloc] init];
    [sender sendBCHTransactionWithWalletManager:[BRWalletManager sharedInstance]
                                          address:self.address
                                         feePerKb:MIN_FEE_PER_KB
                                         callback:^(NSString * _Nullable errorMessage) {
        if (errorMessage) {
            [self showErrorMessage:errorMessage];
        } else {
            [self showSuccess];
        }
    }];
}

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        [self send];
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects
       fromConnection:(AVCaptureConnection *)connection
{
    for (AVMetadataMachineReadableCodeObject *codeObject in metadataObjects) {
        if (! [codeObject.type isEqual:AVMetadataObjectTypeQRCode]) continue;
        NSString *addr = [codeObject.stringValue stringByTrimmingCharactersInSet:
                          [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        BRPaymentRequest *request = [BRPaymentRequest requestWithString:addr];
        if ((request.isValid && [request.scheme isEqual:@"bitcoin"]) || [addr isValidBitcoinPrivateKey] ||
                   [addr isValidBitcoinBIP38Key]) {
            if (request.r.length == 0) {
                self.scanController.cameraGuide.image = [UIImage imageNamed:@"cameraguide-green"];
                [self.scanController stop];
                [self.scanController dismissViewControllerAnimated:YES completion:^{
                    [self resetQRGuide];
                    self.address = request.paymentAddress;
                    [self confirmSend];
                }];
            }
        }
        
        break;
    }
}

- (void)resetQRGuide
{
    self.scanController.message.text = nil;
    self.scanController.cameraGuide.image = [UIImage imageNamed:@"cameraguide"];
}

#pragma mark AutoLayout Helpers
- (void)constrain:(NSArray<NSLayoutConstraint *>*)constraints
{
    [NSLayoutConstraint activateConstraints:constraints];
}

- (NSLayoutConstraint* )constrain:(UIView*)view toWidth:(CGFloat)width
{
    return [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:width];
}

- (NSLayoutConstraint* )constrain:(UIView*)view toHeight:(CGFloat)width
{
    return [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:width];
}

- (NSLayoutConstraint *)constraintFrom:(UIView *)fromView toView:(UIView*)toView attribute:(NSLayoutAttribute)attribute constant:(CGFloat)constant
{
    return [NSLayoutConstraint constraintWithItem:fromView attribute:attribute relatedBy:NSLayoutRelationEqual toItem:toView attribute:attribute multiplier:1.0 constant:constant];
}

- (UIButton *)buttonWithTitle:(NSString *)title imageNamed:(NSString *)imageName
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:title forState:UIControlStateNormal];
    [button setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    [button setBackgroundImage:[UIImage imageNamed:@"button-bg-blue"] forState:UIControlStateNormal];
    [button setBackgroundImage:[UIImage imageNamed:@"button-bg-blue-pressed"] forState:UIControlStateHighlighted];
    [button setTitleColor:[UIColor colorWithRed:0.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button setTitleColor:[UIColor colorWithRed:0.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    return button;
}

@end
