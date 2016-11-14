//
//  ViewController.m
//  routersafe
//
//  Created by 李胜营 on 16/11/1.
//  Copyright © 2016年 dasheng. All rights reserved.
//

#import "ViewController.h"
#import <NMSSH/NMSSH.h>

@interface ViewController ()<NMSSHSessionDelegate, NMSSHChannelDelegate>
@property (weak, nonatomic) IBOutlet UITextField *ipTextField;
@property (weak, nonatomic) IBOutlet UITextField *sshPasswordTextField;
/* ssh session */
@property (strong, nonatomic) NMSSHSession * session;
/* dispatch */
@property (assign, nonatomic) dispatch_once_t  onceToken;
/* ssh que */
@property (strong, nonatomic) dispatch_queue_t  sshQueue;
/* ssh host */
@property (strong, nonatomic) NSString * host;
/* ssh username */
@property (strong, nonatomic) NSString * username;
/* ssh password */
@property (strong, nonatomic) NSString * password;

/* command */
@property (strong, nonatomic) NSString * command;
@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation ViewController
- (IBAction)SSHLogin:(id)sender {
    
    NSString *command = self.ipTextField.text;
    self.command = command;
    
    
    [self performCommand];
}
- (IBAction)disconnect:(id)sender {
    
    dispatch_async(self.sshQueue, ^{
        [self.session disconnect];
    });
    [self.navigationController popToRootViewControllerAnimated:YES];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.host = @"119.136.24.59";
    self.username = @"root";
    self.password = @"admin";
    
    self.sshQueue = dispatch_queue_create("NMSSH.queue", DISPATCH_QUEUE_SERIAL);
    

}

- (void)viewWillAppear:(BOOL)animated
{
    
    dispatch_once(&_onceToken, ^{
        dispatch_async(self.sshQueue, ^{
            //            self.session = [NMSSHSession connectToHost:self.host withUsername:self.username];
            self.session = [NMSSHSession connectToHost:self.host port:1122 withUsername:self.username];
            self.session.delegate = self;
            
            [self.session connect];
            
            if (self.session.isConnected) {
                [self.session authenticateByPassword:@"admin"];
                
                if (self.session.isAuthorized) {
                    NSLog(@"Authentication succeeded");
                }
            }
            
            if (!self.session.connected) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self appendToTextView:@"Connection error"];
                });
            }
            self.session.channel.delegate = self;
            self.session.channel.requestPty = YES;
            self.session.channel.ptyTerminalType = NMSSHChannelPtyTerminalVT100;
            
            NSError *error;
            [self.session.channel startShell:&error];
        });
    });
    
    

}
- (void)performCommand {
    
        dispatch_async(self.sshQueue, ^{
            
            [self.session.channel execute:self.command error:nil timeout:@10];
            
            [[self.session channel] write:self.command error:nil timeout:@10];
        });
    
}

- (void)channel:(NMSSHChannel *)channel didReadData:(NSString *)message {
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self appendToTextView:message];
        
        NSLog(@"=====%@=====",message);
    });
}

- (void)channel:(NMSSHChannel *)channel didReadError:(NSString *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self appendToTextView:error];
    });
}

- (void)channelShellDidClose:(NMSSHChannel *)channel {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self appendToTextView:@"\nShell closed\n"];
        self.textView.editable = NO;
    });
}
- (void)appendToTextView:(NSString *)text {
    
    self.textView.text = [NSString stringWithFormat:@"%@%@", self.textView.text, text];
    [self.textView scrollRangeToVisible:NSMakeRange([self.textView.text length] - 1, 1)];
}
@end
