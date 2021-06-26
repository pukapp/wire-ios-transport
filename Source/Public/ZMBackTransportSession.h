//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//


#import <Foundation/Foundation.h>
#import <WireTransport/ZMTransportResponse.h>
#import <WireTransport/ZMTransportRequest.h>
#import <WireTransport/ZMReachability.h>
#import <WireTransport/ZMBackgroundable.h>
#import <WireTransport/ZMRequestCancellation.h>
#import <WireTransport/ZMURLSession.h>

NS_ASSUME_NONNULL_BEGIN

@class UIApplication;
@class ZMAccessToken;
@class ZMTransportRequest;
@class ZMPersistentCookieStorage;
@class ZMTransportRequestScheduler;
@protocol ZMPushChannelConsumer;
@protocol ZMSGroupQueue;
@protocol ZMKeyValueStore;
@protocol ZMPushChannel;
@protocol ReachabilityProvider;
@protocol BackendEnvironmentProvider;
@protocol URLSessionsDirectory;
@class ZMTransportRequest;

typedef ZMTransportRequest* _Nullable (^ZMTransportRequestGenerator)(void);

extern NSString * const ZMTransportSessionNewRequestAvailableNotification;

@interface ZMBackTransportSession : NSObject

@property (nonatomic, nullable) ZMAccessToken *accessToken;
@property (nonatomic) NSURL *baseURL;
@property (nonatomic) NSURL *websocketURL;
@property (nonatomic, readonly) NSOperationQueue *workQueue;
@property (nonatomic, assign) NSInteger maximumConcurrentRequests;
@property (nonatomic, readonly) ZMPersistentCookieStorage *cookieStorage;
@property (nonatomic, copy) void (^requestLoopDetectionCallback)(NSString*);
@property (nonatomic, readonly) id<ReachabilityProvider, TearDownCapable> reachability;

- (instancetype)initWithEnvironment:(id<BackendEnvironmentProvider>)environment
                      cookieStorage:(ZMPersistentCookieStorage *)cookieStorage
                       reachability:(id<ReachabilityProvider, TearDownCapable>)reachability
                 initialAccessToken:(nullable ZMAccessToken *)initialAccessToken
         applicationGroupIdentifier:(nullable NSString *)applicationGroupIdentifier;

- (void)tearDown;

/// Sets the access token failure callback. This can be called only before the first request is fired
- (void)setAccessTokenRenewalFailureHandler:(ZMCompletionHandlerBlock)handler NS_SWIFT_NAME(setAccessTokenRenewalFailureHandler(handler:)); //TODO accesstoken // move this out of here?

/// Sets the access token success callback
- (void)setAccessTokenRenewalSuccessHandler:(ZMAccessTokenHandlerBlock)handler;

- (void)enqueueOneTimeRequest:(ZMTransportRequest *)searchRequest NS_SWIFT_NAME(enqueueOneTime(_:));

- (ZMTransportEnqueueResult *)attemptToEnqueueSyncRequestWithGenerator:(NS_NOESCAPE ZMTransportRequestGenerator)requestGenerator NS_SWIFT_NAME(attemptToEnqueueSyncRequest(generator:));

/**
 *   This method should be called from inside @c application(application:handleEventsForBackgroundURLSession identifier:completionHandler:)
 *   and passed the identifier and completionHandler to store after recreating the background session with the given identifier.
 *   We need to store the handler to call it as soon as the background download completed (in @c URLSessionDidFinishEventsForBackgroundURLSession(session:))
 */
- (void)addCompletionHandlerForBackgroundSessionWithIdentifier:(NSString *)identifier handler:(dispatch_block_t)handler NS_SWIFT_NAME(addCompletionHandlerForBackgroundSession(identifier:handler:));

/**
 *   Asynchronically gets all current @c NSURLSessionTasks for the background session and calls the completionHandler
 *   with them as parameter, can be used to check if a request that is expected to be registered with the
 *   background session indeed is, e.g. after the app has been terminated
 */
- (void)getBackgroundTasksWithCompletionHandler:(void (^)(NSArray <NSURLSessionTask *>*))completionHandler;

@end

@interface ZMBackTransportSession (RequestScheduler) <ZMTransportRequestSchedulerSession>
@end



@interface ZMBackTransportSession (URLSessionDelegate) <ZMURLSessionDelegate>
@end


NS_ASSUME_NONNULL_END
