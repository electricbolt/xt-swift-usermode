// Bin.m
// XT Copyright © 2026; Electric Bolt Limited.

#import "Foundation/Foundation.h"
#import "Types.h"
#import "Bin.h"

static const BYTE _bin[] = {
    #embed "EmbeddedBinary.bin"
};

const BYTE* const bin = _bin;
const NSUInteger binSize = sizeof(_bin);
