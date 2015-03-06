//
//  CRZViewController.m
//  CtrlZ
//
//  Created by spencer poff on 02/20/2015.
//  Copyright (c) 2014 spencer poff. All rights reserved.
//

#import "CRZViewController.h"

@interface CRZViewController ()

@property (weak, nonatomic) IBOutlet UILabel *welcomeLabel;
@property (weak, nonatomic) IBOutlet UITextView *postTextView;

@end

@implementation CRZViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.welcomeLabel.text = CRZLocalizedString(@"Welcome!");
    self.postTextView.text = CRZLocalizedString(@"Add a message here to post for all the world to see.");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
