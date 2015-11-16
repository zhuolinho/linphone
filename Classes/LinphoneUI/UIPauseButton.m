/* UIPauseButton.m
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

#import "UIPauseButton.h"
#import "LinphoneManager.h"

#include "linphone/linphonecore.h"

@implementation UIPauseButton

#pragma mark - Lifecycle Functions

- (void)initUIPauseButton {
	type = UIPauseButtonType_CurrentCall;
}

- (id)init {
	self = [super init];
	if (self) {
		[self initUIPauseButton];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
	self = [super initWithCoder:decoder];
	if (self) {
		[self initUIPauseButton];
	}
	return self;
}

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		[self initUIPauseButton];
	}
	return self;
}

#pragma mark - Static Functions

+ (bool)isInConference:(LinphoneCall *)call {
	if (!call)
		return false;
	return linphone_call_is_in_conference(call);
}

+ (int)notInConferenceCallCount:(LinphoneCore *)lc {
	int count = 0;
	const MSList *calls = linphone_core_get_calls(lc);

	while (calls != 0) {
		if (![UIPauseButton isInConference:(LinphoneCall *)calls->data]) {
			count++;
		}
		calls = calls->next;
	}
	return count;
}

+ (LinphoneCall *)getCall {
	LinphoneCore *lc = [LinphoneManager getLc];
	LinphoneCall *currentCall = linphone_core_get_current_call(lc);
	if (currentCall == nil && linphone_core_get_calls_nb(lc) == 1) {
		currentCall = (LinphoneCall *)linphone_core_get_calls(lc)->data;
	}
	return currentCall;
}

#pragma mark -

- (void)setType:(UIPauseButtonType)atype call:(LinphoneCall *)acall {
	type = atype;
	call = acall;
}

#pragma mark - UIToggleButtonDelegate Functions

- (void)onOn {
	switch (type) {
	case UIPauseButtonType_Call: {
		if (call != nil) {
			linphone_core_pause_call([LinphoneManager getLc], call);
		} else {
			LOGW(@"Cannot toggle pause buttton, because no current call");
		}
		break;
	}
	case UIPauseButtonType_Conference: {
		linphone_core_leave_conference([LinphoneManager getLc]);

		// Fake event
		[[NSNotificationCenter defaultCenter] postNotificationName:kLinphoneCallUpdate object:self];
		break;
	}
	case UIPauseButtonType_CurrentCall: {
		LinphoneCall *currentCall = [UIPauseButton getCall];
		if (currentCall != nil) {
			linphone_core_pause_call([LinphoneManager getLc], currentCall);
		} else {
			LOGW(@"Cannot toggle pause buttton, because no current call");
		}
		break;
	}
	}
}

- (void)onOff {
	switch (type) {
	case UIPauseButtonType_Call: {
		if (call != nil) {
			linphone_core_resume_call([LinphoneManager getLc], call);
		} else {
			LOGW(@"Cannot toggle pause buttton, because no current call");
		}
		break;
	}
	case UIPauseButtonType_Conference: {
		linphone_core_enter_conference([LinphoneManager getLc]);
		// Fake event
		[[NSNotificationCenter defaultCenter] postNotificationName:kLinphoneCallUpdate object:self];
		break;
	}
	case UIPauseButtonType_CurrentCall: {
		LinphoneCall *currentCall = [UIPauseButton getCall];
		if (currentCall != nil) {
			linphone_core_resume_call([LinphoneManager getLc], currentCall);
		} else {
			LOGW(@"Cannot toggle pause buttton, because no current call");
		}
		break;
	}
	}
}

- (bool)onUpdate {
	bool ret = false;
	LinphoneCore *lc = [LinphoneManager getLc];
	LinphoneCall *c = call;
	switch (type) {
		case UIPauseButtonType_Conference: {
			self.enabled = (linphone_core_get_conference_size(lc) > 0);
			if (self.enabled) {
				ret = (!linphone_core_is_in_conference(lc));
			}
			break;
		}
		case UIPauseButtonType_CurrentCall:
			c = [UIPauseButton getCall];
		case UIPauseButtonType_Call: {
			if (c != nil) {
				LinphoneCallState state = linphone_call_get_state(c);
				ret = (state == LinphoneCallPaused || state == LinphoneCallPausing);
				self.enabled = (state == LinphoneCallPaused || state == LinphoneCallPausing ||
								state == LinphoneCallStreamsRunning);
			} else {
				self.enabled = FALSE;
			}
			break;
		}
	}
	return ret;
}

@end
