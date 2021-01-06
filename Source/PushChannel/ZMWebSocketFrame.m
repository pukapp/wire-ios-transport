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


#import "ZMWebSocketFrame.h"
#import "ZMTLogging.h"
#import <WireTransport/WireTransport-Swift.h>


static NSString* ZMLogTag ZM_UNUSED = ZMT_LOG_TAG_PUSHCHANNEL_LOW_LEVEL;

NSString * const ZMWebSocketFrameErrorDomain = @"ZMWebSocketFrame";

enum Opcode : uint8_t {
    NOT_SET = 0x0,
    CONTINUATION = 0x0,
    TEXT_FRAME   = 0x1,
    BINARY_FRAME = 0x2,
    CLOSE        = 0x8,
    PING         = 0x9,
    PONG         = 0xa,
};


struct Header {
    size_t headerSize;
    bool fin;
    bool mask;
    enum Opcode opcode;
    int N0;
    uint64_t N;
    uint8_t maskingKey[4];
};

typedef union websocket_header_t {
    struct bits {
        unsigned int opcode : 4;
        unsigned int rsv1 : 1;
        unsigned int rsv2 : 1;
        unsigned int rsv3 : 1;
        unsigned int fin : 1;
        unsigned int payload : 7;
        unsigned int mask : 1;
        
    } __attribute__ ((packed)) bits;
    
    uint16_t shortHeader;
    struct s {
        uint8_t bits;
        uint8_t length;
    } __attribute__ ((packed)) s;
} websocket_header_t;




@interface ZMWebSocketFrame ()

@property (nonatomic) ZMWebSocketFrameType frameType;
@property (nonatomic) NSData *payload;
@property (nonatomic) BOOL isWholeFrame;
@end



@implementation ZMWebSocketFrame

- (instancetype)init
{
    @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"You should not use -init" userInfo:nil];
    return [self initWithBinaryFrameWithPayload:nil];
}

- (instancetype)initWithDataBuffer:(DataBuffer *)dataBuffer error:(NSError **)error
{
    self = [super init];
    if (self) {
        if (! [self parseDataBuffer:dataBuffer error:error]) {
            return nil;
        }
    }
    return self;
}

- (instancetype)initWithPreviousFrameType:(ZMWebSocketFrameType)frameType previousPayload: (NSData*)payload dataBuffer:(DataBuffer *)dataBuffer  error:(NSError **)error
{
    self = [super init];
    if (self) {
        self.frameType = frameType;
        self.payload = [[NSMutableData alloc] initWithData:payload];
        if (! [self parseDataBuffer:dataBuffer error:error]) {
            return nil;
        }
    }
    return self;
}

/// Creates a binary frame with the given payload.
- (instancetype)initWithBinaryFrameWithPayload:(NSData *)payload;
{
    VerifyReturnNil(payload != nil);
    self = [super init];
    if (self) {
        self.frameType = ZMWebSocketFrameTypeBinary;
        self.payload = payload ?: [NSData data];
    }
    return self;
}

- (instancetype)initWithTextFrameWithPayload:(NSString *)payload;
{
    VerifyReturnNil(payload != nil);
    self = [super init];
    if (self) {
        self.frameType = ZMWebSocketFrameTypeText;
        NSString *s = payload ?: [NSString string];
        self.payload = [s dataUsingEncoding:NSUTF8StringEncoding];
    }
    return self;
}

- (instancetype)initWithPongFrame;
{
    self = [super init];
    if (self) {
        self.frameType = ZMWebSocketFrameTypePong;
    }
    return self;
}

- (instancetype)initWithPingFrame;
{
    self = [super init];
    if (self) {
        self.frameType = ZMWebSocketFrameTypePing;
    }
    return self;
}

+ (NSError *)parseError;
{
    return [NSError errorWithDomain:ZMWebSocketFrameErrorDomain code:ZMWebSocketFrameErrorCodeParseError userInfo:nil];
}

+ (NSError *)dataTooShortError;
{
    return [NSError errorWithDomain:ZMWebSocketFrameErrorDomain code:ZMWebSocketFrameErrorCodeDataTooShort userInfo:nil];
}

- (dispatch_data_t)pongFrameData;
{
    websocket_header_t wshead = {
        .bits = {
            .opcode  = PONG,
            .rsv1    = 0,
            .rsv2    = 0,
            .rsv3    = 0,
            .fin     = 1, // single frame
            .payload = 0,
            .mask    = 0,
        }
    };
    return dispatch_data_create(&wshead, sizeof(wshead), NULL, DISPATCH_DATA_DESTRUCTOR_DEFAULT);
}

- (dispatch_data_t)pingFrameData;
{
    websocket_header_t wshead = {
        .bits = {
            .opcode  = PING,
            .rsv1    = 0,
            .rsv2    = 0,
            .rsv3    = 0,
            .fin     = 1, // single frame
            .payload = 0,
            .mask    = 0,
        }
    };
    return dispatch_data_create(&wshead, sizeof(wshead), NULL, DISPATCH_DATA_DESTRUCTOR_DEFAULT);
}

- (dispatch_data_t)frameData;
{
    if (self.frameType == ZMWebSocketFrameTypePong) {
        return self.pongFrameData;
    } else if (self.frameType == ZMWebSocketFrameTypePing) {
        return self.pingFrameData;
    }
    
    websocket_header_t wshead = {
        .bits = {
            .opcode  = TEXT_FRAME,
            .rsv1    = 0,
            .rsv2    = 0,
            .rsv3    = 0,
            .fin     = 1, // single frame
            .payload = 0,
            .mask    = 1,//由于是从客户端发送给服务端的数据，所以mask必须置为1，防止服务端无法解析数据
        }
    };
    
    size_t const length = self.payload.length;
    //生成随机的掩码
    uint8_t *mask_key = (uint8_t*)malloc(sizeof(uint32_t));
    int reslut = SecRandomCopyBytes(kSecRandomDefault, sizeof(uint32_t), (uint8_t *)mask_key);
    if (reslut != 0) {
        NSLog(@"websocket get maskKey failure");
    }
    dispatch_data_t maskKey = dispatch_data_create(mask_key, sizeof(uint32_t), NULL, DISPATCH_DATA_DESTRUCTOR_DEFAULT);
    
    uint8_t *needMasked_payload = (uint8_t *)[self.payload bytes];
    for (size_t i = 0; i < length; i++) {
        needMasked_payload[i] = needMasked_payload[i] ^ mask_key[i % sizeof(uint32_t)];
    }
    
    CFDataRef cfdata = CFBridgingRetain(self.payload);
    dispatch_data_t payload = dispatch_data_create(needMasked_payload, length, dispatch_get_global_queue(0, 0), ^{
        CFRelease(cfdata);
    });
    
    if (length < 126) {
        wshead.bits.payload = (unsigned int)length;
        dispatch_data_t header = dispatch_data_create(&wshead, sizeof(wshead), NULL, DISPATCH_DATA_DESTRUCTOR_DEFAULT);
        dispatch_data_t headerAndMask = dispatch_data_create_concat(header, maskKey);
        
        return dispatch_data_create_concat(headerAndMask, payload);
    } else if (length <= UINT16_MAX) {
        wshead.bits.payload = (unsigned int)126;
        
        uint16_t const l = (uint16_t) length;
        uint16_t bigL =  CFSwapInt16BigToHost(l);
        dispatch_data_t h1 = dispatch_data_create(&wshead, sizeof(wshead), NULL, DISPATCH_DATA_DESTRUCTOR_DEFAULT);
        dispatch_data_t h2 = dispatch_data_create(&bigL, sizeof(bigL), NULL, DISPATCH_DATA_DESTRUCTOR_DEFAULT);
        dispatch_data_t header = dispatch_data_create_concat(h1, h2);
        dispatch_data_t headerAndMask = dispatch_data_create_concat(header, maskKey);
        
        return dispatch_data_create_concat(headerAndMask, payload);
    } else {
        return nil;
    }
}

- (BOOL)parseDataBuffer:(DataBuffer *)dataBuffer error:(NSError **)error
{
    NSData *data = (id) dataBuffer.objcData;
    struct Header ws = {};
    
    {
        // Check that we have at least 2 bytes of the header
        if (data.length < 2) {
            if (error) {
                *error = [[self class] dataTooShortError];
            }
            return NO;
        }
        uint8_t frameData[2];
        [data getBytes:frameData length:2];
        
        ws.fin = !! (frameData[0] & 0x80);
        ws.opcode = (enum Opcode) (frameData[0] & 0x0f);
        ws.mask = !! (frameData[1] & 0x80);
        ws.N0 = (frameData[1] & 0x7f);
        ws.headerSize = 2 + (ws.N0 == 126 ? 2 : 0) + (ws.N0 == 127 ? 6 : 0) + (ws.mask ? 4 : 0);
    }
    
    switch (ws.opcode) {
        case TEXT_FRAME: {
            self.frameType = ZMWebSocketFrameTypeText;
            break;
        }
        case BINARY_FRAME: {
            self.frameType = ZMWebSocketFrameTypeBinary;
            break;
        }
        case PING: {
            self.frameType = ZMWebSocketFrameTypePing;
            break;
        }
        case PONG: {
            self.frameType = ZMWebSocketFrameTypePong;
            break;
        }
        case CLOSE: {
            self.frameType = ZMWebSocketFrameTypeClose;
            break;
        }
        case CONTINUATION: {
            //这里已经在初始化的时候已经对frameType赋值了
            break;
        }
        default: {
            if (error) {
                *error = [[self class] parseError];
            }
            return NO;
        }
    }
    
    {
        // Have we received the complete header at least?
        if (data.length < ws.headerSize) {
            if (error) {
                *error = [[self class] dataTooShortError];
            }
            return NO;
        }
        uint8_t frameData[ws.headerSize];
        [data getBytes:frameData length:ws.headerSize];
        
        
        int i;
        if ((0 <= ws.N0) && (ws.N0 < 126)) {
            ws.N = (uint64_t) ws.N0;
            i = 2;
        } else if (ws.N0 == 126) {
            ws.N = 0;
            ws.N |= ((uint64_t) frameData[2]) << 8;
            ws.N |= ((uint64_t) frameData[3]) << 0;
            i = 4;
        } else if (ws.N0 == 127) {
            ws.N = 0;
            ws.N |= ((uint64_t) frameData[2]) << 56;
            ws.N |= ((uint64_t) frameData[3]) << 48;
            ws.N |= ((uint64_t) frameData[4]) << 40;
            ws.N |= ((uint64_t) frameData[5]) << 32;
            ws.N |= ((uint64_t) frameData[6]) << 24;
            ws.N |= ((uint64_t) frameData[7]) << 16;
            ws.N |= ((uint64_t) frameData[8]) << 8;
            ws.N |= ((uint64_t) frameData[9]) << 0;
            i = 10;
        } else {
            if (error) {
                *error = [[self class] parseError];
            }
            return NO;
        }
        if (ws.mask) {
            ws.maskingKey[0] = ((uint8_t) frameData[i + 0]);
            ws.maskingKey[1] = ((uint8_t) frameData[i + 1]);
            ws.maskingKey[2] = ((uint8_t) frameData[i + 2]);
            ws.maskingKey[3] = ((uint8_t) frameData[i + 3]);
        }
    }
    
    {
        size_t const messageLength = (size_t) (ws.headerSize + ws.N);
        if (data.length < messageLength) {
            if (error) {
                *error = [[self class] dataTooShortError];
            }
            return NO;
        }
        
        // We got a whole message:
        NSData *frameData = [data subdataWithRange:NSMakeRange(0, messageLength)];
        [dataBuffer clearUntil:(int)messageLength];
        
        ZMLogInfo(@"opcode=%d(FIN:%d) NO=%d headerSize=%zu len=%lld inbuffer=%zu", ws.opcode, (int)ws.fin, ws.N0, ws.headerSize, ws.N, messageLength);
        
        // We got a whole message, now do something with it:
        if ((self.frameType == ZMWebSocketFrameTypeText) ||
            (self.frameType == ZMWebSocketFrameTypeBinary))
        {
            //先获取当前帧的数据
            NSData *currentPayload;
            if (ws.mask) {
                size_t const l = self.payload.length;
                uint8_t maskedBytes[l];
                [self.payload getBytes:maskedBytes length:l];
                for (size_t i = 0; i < l; ++i) {
                    maskedBytes[i] ^= ws.maskingKey[i & 0x3];
                }
                currentPayload = [NSData dataWithBytes:maskedBytes length:l];
            } else {
                currentPayload = [frameData subdataWithRange:NSMakeRange(ws.headerSize, messageLength - ws.headerSize)];
            }
            //需要拼接data，即上一帧是延续帧
            if (self.payload && self.payload.length > 0) {
                [(NSMutableData* )self.payload appendData:currentPayload];
            } else {
                self.payload = currentPayload;
            }
        }
        self.isWholeFrame = ws.fin;
    }
    return YES;
}

@end
