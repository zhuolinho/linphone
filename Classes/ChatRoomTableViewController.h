/* ChatRoomTableViewController.h
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
 *  GNU General Public License for more details.                
 *                                                                      
 *  You should have received a copy of the GNU General Public License   
 *  along with this program; if not, write to the Free Software         
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */ 


#import <UIKit/UIKit.h>
#include "linphone/linphonecore.h"

@protocol ChatRoomDelegate <NSObject>

- (BOOL)chatRoomStartImageUpload:(UIImage*)image url:(NSURL*)url;
- (void)resendChat:(NSString*)message withExternalUrl:(NSString*)url;

@end

@interface ChatRoomTableViewController : UITableViewController {
@private
    LinphoneChatRoom* chatRoom;
    MSList *messageList;
}

@property (nonatomic, strong) id<ChatRoomDelegate> chatRoomDelegate;

- (void)addChatEntry:(LinphoneChatMessage*)chat;
- (void)scrollToBottom:(BOOL)animated;
- (void)scrollToLastUnread:(BOOL)animated;
- (void)updateChatEntry:(LinphoneChatMessage*)chat;
- (void)setChatRoom:(LinphoneChatRoom*)room;

@end
