/* WizardViewController.h
 *
 * Copyright (C) 2012  Belledonne Comunications, Grenoble, France
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Library General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#import <UIKit/UIKit.h>
#import <XMLRPCConnectionDelegate.h>
#import "UICompositeViewController.h"
#import "UILinphoneTextField.h"
#import "LinphoneUI/UILinphoneButton.h"
#import "TPKeyboardAvoidingScrollView.h"

@interface WizardViewController : TPMultiLayoutViewController
<UITextFieldDelegate,
    UICompositeViewDelegate,
    XMLRPCConnectionDelegate,
    UIGestureRecognizerDelegate,
    UIAlertViewDelegate>
{
    @private
    UITextField *activeTextField;
    UIView *currentView;
    UIView *nextView;
    NSMutableArray *historyViews;
}

@property(nonatomic, strong) IBOutlet TPKeyboardAvoidingScrollView *contentView;

@property (nonatomic, strong) IBOutlet UIView *welcomeView;
@property (nonatomic, strong) IBOutlet UIView *choiceView;
@property (nonatomic, strong) IBOutlet UIView *createAccountView;
@property (nonatomic, strong) IBOutlet UIView *connectAccountView;
@property (nonatomic, strong) IBOutlet UIView *externalAccountView;
@property (nonatomic, strong) IBOutlet UIView *validateAccountView;
@property (strong, nonatomic) IBOutlet UIView *provisionedAccountView;

@property (nonatomic, strong) IBOutlet UIView *waitView;

@property (nonatomic, strong) IBOutlet UIButton *backButton;
@property (nonatomic, strong) IBOutlet UIButton *startButton;
@property (nonatomic, strong) IBOutlet UIButton *createAccountButton;
@property (nonatomic, strong) IBOutlet UIButton *connectAccountButton;
@property (nonatomic, strong) IBOutlet UIButton *externalAccountButton;
@property (strong, nonatomic) IBOutlet UIButton *remoteProvisioningButton;
@property (strong, nonatomic) IBOutlet UILinphoneButton *registerButton;

@property (strong, nonatomic) IBOutlet UILinphoneTextField *createAccountUsername;
@property (strong, nonatomic) IBOutlet UILinphoneTextField *connectAccountUsername;
@property (strong, nonatomic) IBOutlet UILinphoneTextField *externalAccountUsername;

@property (strong, nonatomic) IBOutlet UITextField *provisionedUsername;
@property (strong, nonatomic) IBOutlet UITextField *provisionedPassword;
@property (strong, nonatomic) IBOutlet UITextField *provisionedDomain;

@property (nonatomic, strong) IBOutlet UIImageView *choiceViewLogoImageView;
@property (strong, nonatomic) IBOutlet UISegmentedControl *transportChooser;

@property (nonatomic, strong) IBOutlet UITapGestureRecognizer *viewTapGestureRecognizer;

- (void)reset;
- (void)fillDefaultValues;

- (IBAction)onStartClick:(id)sender;
- (IBAction)onBackClick:(id)sender;
- (IBAction)onCancelClick:(id)sender;

- (IBAction)onCreateAccountClick:(id)sender;
- (IBAction)onConnectLinphoneAccountClick:(id)sender;
- (IBAction)onExternalAccountClick:(id)sender;
- (IBAction)onCheckValidationClick:(id)sender;
- (IBAction)onRemoteProvisioningClick:(id)sender;

- (IBAction)onSignInClick:(id)sender;
- (IBAction)onSignInExternalClick:(id)sender;
- (IBAction)onRegisterClick:(id)sender;
- (IBAction)onProvisionedLoginClick:(id)sender;

@end
