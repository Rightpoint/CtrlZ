//
//  CRZMessagePostedVC.m
//  CtrlZ-Example
//
//  Created by Spencer Poff on 3/6/15.
//  Copyright (c) 2015 spencer poff. All rights reserved.
//

#import "CRZMessagePostedVC.h"

@interface CRZMessagePostedVC ()

@property (weak, nonatomic) IBOutlet UILabel *congratulationsLabel;

@end

@implementation CRZMessagePostedVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.congratulationsLabel.text = CRZLocalizedString(@"Message Posted.");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
