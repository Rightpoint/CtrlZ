//
//  CRZViewController.m
//  CtrlZ
//
//  Created by spencer poff on 02/20/2015.
//  Copyright (c) 2014 spencer poff. All rights reserved.
//

#import "CRZViewController.h"

@interface CRZViewController ()

@property (weak, nonatomic) IBOutlet UITextView *postTextView;
@property (weak, nonatomic) IBOutlet UIButton *postButton;

@end

@implementation CRZViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.automaticallyAdjustsScrollViewInsets = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.title = CRZLocalizedString(@"Welcome!");
    self.postTextView.text = CRZLocalizedString(@"Add a message here to post for all the world to see.");
    [self.postButton setTitle:CRZLocalizedString(@"Post") forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
