//
//  ShowErrorView.m
//  test
//
//  Created by 张磊 on 16/6/15.
//  Copyright © 2016年 lei. All rights reserved.
//

#import "ShowErrorView.h"

@interface ShowErrorView()
@property (weak, nonatomic) IBOutlet UIView *hubView;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@end

@implementation ShowErrorView

static ShowErrorView *_instance;

+ (ShowErrorView *)showerrorView {
    ShowErrorView *view = [[NSBundle mainBundle] loadNibNamed:@"ShowErrorView" owner:nil options:nil].firstObject;

    view.hubView.layer.cornerRadius = 10;
    return view;
}

- (void)setInfoStr:(NSString *)infoStr {
    _infoLabel.text = infoStr;
}

@end
