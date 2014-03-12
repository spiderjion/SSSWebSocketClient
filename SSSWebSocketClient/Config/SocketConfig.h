//
//  SocketConfig.h
//  SSSWebSocketClient
//
//  Created by sagles on 14-3-7.
//  Copyright (c) 2014年 sagles. All rights reserved.
//

#ifndef SSSWebSocketClient_SocketConfig_h
#define SSSWebSocketClient_SocketConfig_h

#ifdef IsEnableDyci
#undef IsEnableDyci
#endif
#define IsEnableDyci 1

#define SocketServerHost @"114.246.154.100"
//#define SocketServerHost @"localhost"
#define SocketServerPort @"4000"
#define SOcketEndPoint   @"chat"

#ifdef __cplusplus
#define SSS_EXTERN		extern "C" __attribute__((visibility ("default")))
#else
#define SSS_EXTERN	        extern __attribute__((visibility ("default")))
#endif

#endif
