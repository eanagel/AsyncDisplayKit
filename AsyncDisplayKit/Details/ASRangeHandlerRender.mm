/* Copyright (c) 2014-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "ASRangeHandlerRender.h"

#import "ASDisplayNode.h"
#import "ASDisplayNode+Subclasses.h"
#import "ASDisplayNodeInternal.h"
#import "_ASDisplayView.h"

@interface ASRangeHandlerRender ()
@property (nonatomic,readonly) UIWindow *workingWindow;
@end

@implementation ASRangeHandlerRender

@synthesize workingWindow = _workingWindow;

- (UIWindow *)workingWindow
{
  ASDisplayNodeAssertMainThread();

  // we add nodes' views to this invisible window to start async rendering
  // TODO: Replace this with directly triggering display https://github.com/facebook/AsyncDisplayKit/issues/315

  if (!_workingWindow) {
    _workingWindow = [[UIWindow alloc] initWithFrame:CGRectZero];
    _workingWindow.windowLevel = UIWindowLevelNormal - 1000;
    _workingWindow.userInteractionEnabled = NO;
    _workingWindow.hidden = YES;
    _workingWindow.alpha = 0.0;
  }

  return _workingWindow;
}

- (void)dealloc
{
  NSArray *views = [self.workingWindow.subviews copy];
  for(_ASDisplayView *view in views) {
    if (![view isKindOfClass:[_ASDisplayView class]]) {
      continue;
    }
    ASDisplayNode *node = view.asyncdisplaykit_node;
    [self node:node exitedRangeOfType:ASLayoutRangeTypeRender];
  }
}

- (void)node:(ASDisplayNode *)node enteredRangeOfType:(ASLayoutRangeType)rangeType
{
  ASDisplayNodeAssertMainThread();
  ASDisplayNodeAssert(rangeType == ASLayoutRangeTypeRender, @"Render delegate should not handle other ranges");

  [node recursivelySetDisplaySuspended:NO];

  // add the node to an off-screen window to force display and preserve its contents
  [[self workingWindow] addSubnode:node];
}

- (void)node:(ASDisplayNode *)node exitedRangeOfType:(ASLayoutRangeType)rangeType
{
  ASDisplayNodeAssertMainThread();
  ASDisplayNodeAssert(rangeType == ASLayoutRangeTypeRender, @"Render delegate should not handle other ranges");

  [node recursivelySetDisplaySuspended:YES];
  [node.view removeFromSuperview];

  [node recursivelyClearContents];
}

@end
