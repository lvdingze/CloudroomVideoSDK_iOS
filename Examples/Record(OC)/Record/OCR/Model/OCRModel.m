//
//  OCRModel.m
//  BKNetwork
//
//  Created by king on 2018/6/8.
//  Copyright © 2018年 king. All rights reserved.
//

#import "OCRModel.h"

@implementation OCRModel
#pragma mark - life cycle
- (void)dealloc {
    NSLog(@"OCRModel dealloc");
}

- (NSString *)description {
    return [NSString stringWithFormat:@"address:%@ agency:%@ birthday:%@ citizenId:%@ gender:%@ name:%@ nation:%@ validDateBegin:%@ validDateEnd:%@", _address, _agency, _birthday, _citizenId, _gender, _name, _nation, _validDateBegin, _validDateEnd];
}
@end
