#ifndef _KFLog_h
#define _KFLog_h

#ifndef LOG_LEVEL_DEF
#define LOG_LEVEL_DEF ddKickflipLogLevel
#endif

#import "DDLog.h"

#ifdef DEBUG
static const int ddKickflipLogLevel = LOG_LEVEL_INFO;
#else
static const int ddKickflipLogLevel = LOG_LEVEL_OFF;
#endif

#endif
