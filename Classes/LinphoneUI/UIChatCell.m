/* UIChatCell.m
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

#import "UIChatCell.h"
#import "PhoneMainView.h"
#import "LinphoneManager.h"
#import "Utils.h"

@implementation UIChatCell

@synthesize avatarImage;
@synthesize addressLabel;
@synthesize chatContentLabel;
@synthesize deleteButton;
@synthesize unreadMessageLabel;
@synthesize unreadMessageView;

#pragma mark - Lifecycle Functions

- (id)initWithIdentifier:(NSString *)identifier {
	if ((self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier]) != nil) {
		NSArray *arrayOfViews = [[NSBundle mainBundle] loadNibNamed:@"UIChatCell" owner:self options:nil];

		if ([arrayOfViews count] >= 1) {

			[self.contentView addSubview:[arrayOfViews objectAtIndex:0]];
		}
		[chatContentLabel setAdjustsFontSizeToFitWidth:TRUE]; // Auto shrink: IB lack!
	}
	return self;
}

#pragma mark - Property Funcitons

- (void)setChatRoom:(LinphoneChatRoom *)achat {
	self->chatRoom = achat;
	[self update];
}

#pragma mark -

- (NSString *)accessibilityValue {
	if (chatContentLabel.text) {
		return [NSString stringWithFormat:@"%@ - %@ (%li)", addressLabel.text, chatContentLabel.text,
										  (long)[unreadMessageLabel.text integerValue]];
	} else {
		return [NSString stringWithFormat:@"%@ (%li)", addressLabel.text, (long)[unreadMessageLabel.text integerValue]];
	}
}

- (void)update {
	NSString *displayName = nil;
	UIImage *image = nil;
	if (chatRoom == nil) {
		LOGW(@"Cannot update chat cell: null chat");
		return;
	}
	const LinphoneAddress *linphoneAddress = linphone_chat_room_get_peer_address(chatRoom);

	if (linphoneAddress == NULL)
		return;
	char *tmp = linphone_address_as_string_uri_only(linphoneAddress);
	NSString *normalizedSipAddress = [NSString stringWithUTF8String:tmp];
	ms_free(tmp);

	ABRecordRef contact = [[[LinphoneManager instance] fastAddressBook] getContact:normalizedSipAddress];
	if (contact != nil) {
		displayName = [FastAddressBook getContactDisplayName:contact];
		image = [FastAddressBook getContactImage:contact thumbnail:true];
	}

	// Display name
	if (displayName == nil) {
		const char *username = linphone_address_get_username(linphoneAddress);
		char *address = linphone_address_as_string(linphoneAddress);
		displayName = [NSString stringWithUTF8String:username ?: address];
		ms_free(address);
	}
	[addressLabel setText:displayName];

	// Avatar
	if (image == nil) {
		image = [UIImage imageNamed:@"avatar_unknown_small.png"];
	}
	[avatarImage setImage:image];

	LinphoneChatMessage *last_message = linphone_chat_room_get_user_data(chatRoom);

	if (last_message) {

		const char *text = linphone_chat_message_get_text(last_message);
		const char *url = linphone_chat_message_get_external_body_url(last_message);
		const LinphoneContent *last_content = linphone_chat_message_get_file_transfer_information(last_message);
		// Message
		if (url || last_content) {
			[chatContentLabel setText:@"🗻"];
		} else if (text) {
			NSString *message = [NSString stringWithUTF8String:text];
			// shorten long messages
			if ([message length] > 50)
				message = [[message substringToIndex:50] stringByAppendingString:@"[...]"];

			chatContentLabel.text = message;
		}

		int count = linphone_chat_room_get_unread_messages_count(chatRoom);
		unreadMessageLabel.text = [NSString stringWithFormat:@"%i", count];
		[unreadMessageView setHidden:(count <= 0)];
	} else {
		chatContentLabel.text = nil;
		unreadMessageLabel.text = [NSString stringWithFormat:@"0"];
		[unreadMessageView setHidden:TRUE];
	}
}

- (void)setEditing:(BOOL)editing {
	[self setEditing:editing animated:FALSE];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
	if (animated) {
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.3];
	}
	if (editing) {
		[deleteButton setAlpha:1.0f];
	} else {
		[deleteButton setAlpha:0.0f];
	}
	if (animated) {
		[UIView commitAnimations];
	}
}

#pragma mark - Action Functions

- (IBAction)onDeleteClick:(id)event {
	if (chatRoom != NULL) {
		UIView *view = [self superview];
		// Find TableViewCell
		while (view != nil && ![view isKindOfClass:[UITableView class]])
			view = [view superview];
		if (view != nil) {
			UITableView *tableView = (UITableView *)view;
			NSIndexPath *indexPath = [tableView indexPathForCell:self];
			[[tableView dataSource] tableView:tableView
						   commitEditingStyle:UITableViewCellEditingStyleDelete
							forRowAtIndexPath:indexPath];
		}
	}
}

@end
