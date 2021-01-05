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


@import Foundation;
@import WireSystem;

@class DataBuffer;


typedef NS_ENUM(uint8_t, ZMWebSocketFrameType) {
    ZMWebSocketFrameTypeInvalid = 0,
    ZMWebSocketFrameTypeText,
    ZMWebSocketFrameTypeBinary,
    ZMWebSocketFrameTypePing,
    ZMWebSocketFrameTypePong,
    ZMWebSocketFrameTypeClose,
};

extern NSString * const ZMWebSocketFrameErrorDomain;
typedef NS_ENUM(NSInteger, ZMWebSocketFrameErrorCode) {
    ZMWebSocketFrameErrorCodeInvalid = 0,
    ZMWebSocketFrameErrorCodeDataTooShort,
    ZMWebSocketFrameErrorCodeParseError,
};





/// Web Socket Frame according to RFC 6455
/// http://tools.ietf.org/html/rfc6455
@interface ZMWebSocketFrame : NSObject

/// The passed in error will be set to @c ZMWebSocketFrameErrorDomain and one of
/// @c ZMWebSocketFrameErrorCodeDataTooShort or @c ZMWebSocketFrameErrorCodeParseError
- (instancetype)initWithDataBuffer:(DataBuffer *)dataBuffer error:(NSError **)error NS_DESIGNATED_INITIALIZER ZM_NON_NULL(1, 2);

/// The passed in error will be set to @c ZMWebSocketFrameErrorDomain and one of
/// 新增frameType,记录延续帧之前的数据类型
/// 新增previousPayload，来实现websocket延续帧的功能
/// @c ZMWebSocketFrameErrorCodeDataTooShort or @c ZMWebSocketFrameErrorCodeParseError
- (instancetype)initWithPreviousFrameType:(ZMWebSocketFrameType)frameType previousPayload: (NSData*)payload dataBuffer:(DataBuffer *)dataBuffer  error:(NSError **)error NS_DESIGNATED_INITIALIZER;

/// Creates a binary frame with the given payload.
- (instancetype)initWithBinaryFrameWithPayload:(NSData *)payload NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithTextFrameWithPayload:(NSString *)payload NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithPongFrame NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithPingFrame NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly) ZMWebSocketFrameType frameType;
@property (nonatomic, readonly) NSData *payload;
@property (nonatomic, readonly) BOOL isWholeFrame;//是否是完整的一帧数据
@property (nonatomic, readonly) dispatch_data_t frameData;

@end
