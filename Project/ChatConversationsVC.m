//
//  ChatConversationsVC.m
//  Soleto
//
//  Created by Andrea Sponziello on 07/11/14.
//
//

#import "ChatConversationsVC.h"
//#import "SHPAppDelegate.h"
//#import "SHPApplicationContext.h"
//#import "SHPUser.h"
#import "ChatConversation.h"
//#import "MessagesViewController.h"
#import "ChatUtil.h"
#import "ChatConversationsHandler.h"
#import "ChatManager.h"
#import "ChatDB.h"
#import "ChatGroupsDB.h"
//#import "SHPImageDownloader.h"
//#import "SHPImageUtil.h"
#import "ChatConversationHandler.h"
#import "ChatGroupsHandler.h"
//#import "SHPSelectUserVC.h"
//#import "SHPChatCreateGroupVC.h"
//#import "SHPChatSelectGroupMembers.h"
#import "ChatGroup.h"
//#import <Parse/Parse.h>
#import "ChatImageCache.h"
//#import "ParseChatNotification.h"
//#import "ChatParsePushService.h"
#import "ChatPresenceHandler.h"
#import "ChatImageWrapper.h"
#import "ChatTitleVC.h"
#import "ChatMessagesVC.h"
#import "CellConfigurator.h"
#import "ChatStatusTitle.h"
//#import <DropboxSDK/DropboxSDK.h>
//#import "MRCategoryStepTVC.h"
//#import "MRPreviewStepTVC.h"
//#import "MRJobSkillStepTVC.h"
//#import "MRJobSkillPreviewStepTVC.h"
//#import "MRJobCategory.h"
//#import "MRService.h"
//#import "ChatContactsSynchronizer.h"
#import "ChatSelectUserLocalVC.h"
#import "ChatSelectGroupMembersLocal.h"
#import "ChatSelectGroupLocalTVC.h"
#import "HelpFacade.h"

@interface ChatConversationsVC ()
- (IBAction)writeToAction:(id)sender;

@end

@implementation ChatConversationsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //autodim
    self.tableView.estimatedRowHeight = 70;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    NSLog(@"Conversations viewDidLoad start");
//    if(!self.applicationContext) {
//        SHPAppDelegate *appDelegate = (SHPAppDelegate *)[[UIApplication sharedApplication] delegate];
//        self.applicationContext = appDelegate.applicationContext;
//    }
    
    self.settings = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"settings" ofType:@"plist"]];
    
    [self initImageCache];
    
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    
    self.groupsMode =  [ChatManager getInstance].groupsMode;

    [self backButtonSetup];
    [self customizeTitleView];
    [self setupTitle:@"Chat"];
    [self setUIStatusDisconnected];
    [[HelpFacade sharedInstance] activateSupportBarButton:self];
}

//-(void)customizeRightBarButton {
//    UIImage* image = [UIImage imageNamed:@"chat_mrlupo.png"];
//    CGRect frameimg = CGRectMake(0, 0, image.size.width, image.size.height);
//    UIButton *imageButton = [[UIButton alloc] initWithFrame:frameimg];
//    [imageButton setBackgroundImage:image forState:UIControlStateNormal];
//    [imageButton addTarget:self action:@selector(writeToSupport)
//         forControlEvents:UIControlEventTouchUpInside];
//    //[imageButton setShowsTouchWhenHighlighted:YES];
//
//    UIBarButtonItem *rightbutton =[[UIBarButtonItem alloc] initWithCustomView:imageButton];
//    self.navigationItem.rightBarButtonItem=rightbutton;
//}

//-(void)writeToSupport {
//    NSLog(@"New message to Support.");
//    NSString *botuser = [self.settings objectForKey:@"botuser"];
//    NSString *fakeuser = [self.settings objectForKey:@"fakeuser"];
//
//    if ([self.applicationContext.loggedUser.username isEqualToString:botuser] ||
//        [self.applicationContext.loggedUser.username isEqualToString:fakeuser]) {
//        [self performSegueWithIdentifier:@"SelectUser" sender:self];
//    } else {
//        [self openConversationWithRecipient:botuser];
//    }
//}

// ------------------------------
// --------- USER INFO ----------
// ------------------------------
//-(void)getAllUserInfo {
//    [self.userLoader findByUsername:self.me.username];
//}

////DELEGATE
////--------------------------------------------------------------------//
//-(void)usersDidLoad:(NSArray *)__users error:(NSError *)error
//{
//    NSLog(@"usersDidLoad: %@ - %@",__users, error);
//    SHPUser *tmp_user;
//    if(__users.count > 0) {
//        tmp_user = [__users objectAtIndex:0];
//        self.applicationContext.loggedUser.fullName = tmp_user.fullName;
//        self.applicationContext.loggedUser.email = tmp_user.fullName;
//        // get company
//        NSArray *parts = [tmp_user.email componentsSeparatedByString: @"@"];
//        NSString *domain;
//        if (parts.count > 0) {
//            domain = [parts lastObject];
//            // SOLO IN QUESTA VISTA VENGONO RINFRESCATI E SALVATI
//            // I DATI DELL'UTENTE CONNESSO
//            NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
//            NSMutableDictionary *userData = [[NSMutableDictionary  alloc] init];
//            [userData setObject:tmp_user.email forKey:@"email"];
//            [userData setObject:tmp_user.fullName forKey:@"fullName"];
//            // save chat domain.
//            [defaults setObject:domain forKey:@"userChatDomain"];
//            NSString *userKey = [[NSString alloc] initWithFormat:@"usrKey-%@", self.applicationContext.loggedUser.username];
//            [defaults setObject:userData forKey:userKey];
////            // get
////            NSString *fullName = [[NSUserDefaults standardUserDefaults] objectForKey:@"userFullName"];
//            [defaults synchronize];
//        }
//        // save user in NSUserDefaults
//        NSLog(@"User full name: %@", tmp_user.fullName);
//        // updateTitle
//        [self changeTitle];
//    } else {
//    }
//}
// ------------------------------------
// --------- USER INFO END ------------
// ------------------------------------

-(void)isStatusConnected {
    NSString *url = @"/.info/connected";
    FIRDatabaseReference *rootRef = [[FIRDatabase database] reference];
    FIRDatabaseReference *connectedRef = [rootRef child:url];
    
    // once
    [connectedRef observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        // Get user value
        NSLog(@"SNAPSHOT ONCE %@ - %d", snapshot, [snapshot.value boolValue]);
        if([snapshot.value boolValue]) {
            NSLog(@"..connected once..");
            // come giu, rifattorizzare
            [self setUIStatusConnected];
        }
        else {
            NSLog(@"..not connected once..");
            [self setUIStatusDisconnected];
        }
    } withCancelBlock:^(NSError * _Nonnull error) {
        NSLog(@"%@", error.localizedDescription);
    }];
}

//-(void)setupConnectionStatus {
//    NSLog(@"Connection status.");
//    NSString *url = @"/.info/connected";
//    FIRDatabaseReference *rootRef = [[FIRDatabase database] reference];
//    FIRDatabaseReference *connectedRef = [rootRef child:url];
//
//    // event
//    if (!self.connectedRefHandle) {
//        self.connectedRefHandle = [connectedRef observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot) {
//            NSLog(@"snapshot %@ - %d", snapshot, [snapshot.value boolValue]);
//            if([snapshot.value boolValue]) {
//                NSLog(@".connected.");
//                [self setUIStatusConnected];
//            } else {
//                NSLog(@".not connected.");
//                [self setUIStatusDisconnected];
//            }
//        }];
//    }
//}

-(void)setUIStatusConnected {
    self.usernameButton.hidden = NO;
    self.activityIndicator.hidden = YES;
    [self.activityIndicator stopAnimating];
    self.statusLabel.text = NSLocalizedString(@"ChatConnected", nil);
}

-(void)setUIStatusDisconnected {
    self.usernameButton.hidden = YES;
    self.activityIndicator.hidden = NO;
    [self.activityIndicator startAnimating];
    self.statusLabel.text = NSLocalizedString(@"ChatDisconnected", nil);
}

-(void)customizeTitleView {
    NSLog(@"CUSTOMIZING TITLE VIEW");
    
    NSArray *subviewArray = [[NSBundle mainBundle] loadNibNamed:@"status_title_ios11" owner:self options:nil];
    ChatStatusTitle *view = [subviewArray objectAtIndex:0];
//    view.frame = CGRectMake(0, 0, 200, 40);
    self.usernameButton = view.usernameButton;
    self.statusLabel = view.statusLabel;
    self.activityIndicator = view.activityIndicator;
    self.navigationItem.titleView = view;
}

-(void)setupTitle:(NSString *)title {
    [self.usernameButton setTitle:title forState:UIControlStateNormal];
}

-(void)changeTitle {
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    NSString *title = (NSString *)[defaults objectForKey:@"userChatDomain"];
    if (!title) {
        title = @"Chat";
    }
    [self setupTitle:title];
}

-(void)initImageCache {
//    // cache setup
//    self.imageCache = (ChatImageCache *) [self.applicationContext getVariable:@"chatUserIcons"];
//    if (!self.imageCache) {
//        self.imageCache = [[ChatImageCache alloc] init];
//        self.imageCache.cacheName = @"chatUserIcons";
//        // test
//        // [self.imageCache listAllImagesFromDisk];
//        // [self.imageCache empty];
//        [self.applicationContext setVariable:@"chatUserIcons" withValue:self.imageCache];
//    }
}

-(void)backButtonSetup {
    if (!self.backButton) {
        self.backButton = [[UIBarButtonItem alloc]
                           initWithTitle:@"Chat"
                           style:UIBarButtonItemStylePlain
                           target:self
                           action:@selector(backButtonClicked:)];
    }
    self.navigationItem.backBarButtonItem = self.backButton;
}

-(void)backButtonClicked:(UIBarButtonItem*)sender
{
    NSLog(@"Back");
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
//    if (self.authStateDidChangeListenerHandle) {
//        [[FIRAuth auth] removeAuthStateDidChangeListener:self.authStateDidChangeListenerHandle];
//    }
}
     
-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"Conversations viewDidAppear");
    
    //[self isStatusConnected];
    ChatManager *chat = [ChatManager getInstance];
    [chat isStatusConnectedWithCompletionBlock:^(BOOL connected, NSError *error) {
        if (connected) {
            [self setUIStatusConnected];
        }
        else {
            [self setUIStatusDisconnected];
        }
    }];
    
//    if (!self.authStateDidChangeListenerHandle) {
//        self.authStateDidChangeListenerHandle =
//            [[FIRAuth auth]
//                 addAuthStateDidChangeListener:^(FIRAuth *_Nonnull auth, FIRUser *_Nullable user) {
//                     NSLog(@"Firebase stato autenticazione cambiato! Auth: %@ user: %@", auth.currentUser, user);
//                     if (user) {
//                         NSLog(@"Signed in.");
//                         [self setupConnectionStatus];
////                         [self initPresenceHandler];
//                     }
//                     else {
//                         NSLog(@"Signed out.");
//                     }
//                 }];
//    }
    
    // è necessario impostare queste variabili da ChatRootNC.openConversationWithRecipient
    // per preservare la sequenza delle animazioni: popToRootVC > animate to recipient.MessagesVC
//    if (self.selectedRecipient) {
//        NSLog(@"self.selectedRecipient TRUE. [self openConversationWithRecipient:%@]", self.selectedRecipient);
//        [self openConversationWithRecipient:self.selectedRecipient];
//    }
}

//-(void)testFirebase {
//
//    // TEST SCRITTURA FIREBASE
//    FIRDatabaseReference *_ref1 = [[FIRDatabase database] reference];
//    [[_ref1 child:@"TEST"] setValue:@{@"PLATFORM": @"1.8"} withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
//        if (error) {
//            NSLog(@"Error saving RAILS2: %@", error);
//        }
//        else {
//            NSLog(@"RAILS2 SAVED!");
//        }
//    }];
//
//    [[FIRAuth auth] createUserWithEmail:@"andrea.sponziello@frontiere21.it"
//                               password:@"123456"
//                             completion:^(FIRUser *_Nullable user, NSError *_Nullable error) {
//                                 NSLog(@"Utente creato: andrea.sponziello@gmail.com/pallino");
//                             }];
//
//    [[FIRAuth auth] signInWithEmail:@"andrea.sponziello@frontiere21.it"
//                           password:@"123456"
//                         completion:^(FIRUser *user, NSError *error) {
//                             NSLog(@"Autenticato: %@ - %@/emailverified: %d", error, user.email, user.emailVerified);
//                             if (!user.emailVerified) {
//                                 NSLog(@"Email non verificata. Invio email verifica...");
//                                 [user sendEmailVerificationWithCompletion:^(NSError * _Nullable error) {
//                                     NSLog(@"Email verifica inviata.");
//                                 }];
//                             }
//                             // TEST CONNECTION
//                             FIRDatabaseReference *_ref = [[FIRDatabase database] reference];
//                             //                             FIRUser *currentUser = [FIRAuth auth].currentUser;
//                             [[_ref child:@"yesmister3"] setValue:@"andrea" withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
//
//                                 NSLog(@"completato! %@", ref);
//                                 
//                             }];
//                             
//                             [[_ref child:@"test"] setValue:@{@"username": @"Lampatu"}];
//                             [[_ref child:@"test2"] setValue:@{@"valore": @"Andrea"}];
//                             [[_ref child:@"NADAL"] setValue:@{@"Vince": @"Wimbledon"}];
//                             
//                             [[_ref child:@"test"] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
//                                 NSLog(@"snapshot: %@", snapshot);
//                             } withCancelBlock:^(NSError * _Nonnull error) {
//                                 NSLog(@"error: %@", error.localizedDescription);
//                             }];
//                             
//                             [[_ref child:@"test10"] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
//                                 NSLog(@"snapshot: %@", snapshot);
//                             } withCancelBlock:^(NSError * _Nonnull error) {
//                                 NSLog(@"error: %@", error.localizedDescription);
//                             }];
//                             
//                             [[_ref child:@"yesmister"] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
//                                 NSLog(@"snapshot: %@", snapshot);
//                             } withCancelBlock:^(NSError * _Nonnull error) {
//                                 NSLog(@"error: %@", error.localizedDescription);
//                             }];
//                             
//                         }];
//
//    [[FIRAuth auth]
//     addAuthStateDidChangeListener:^(FIRAuth *_Nonnull auth, FIRUser *_Nullable user) {
//         NSLog(@"Firebase autenticatooooo! auth: %@ user: %@", auth, user);
//     }];
//}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSLog(@"Conversations viewWillAppear");
    
    [self initializeWithSignedUser];
    
    [self resetCurrentConversation];
}

-(void)logout {
    self.me = nil;
}

-(void)initializeWithSignedUser {
//    NSLog(@"Initializing user. Signed in as %@", self.applicationContext.loggedUser.username);
    ChatManager *chat = [ChatManager getInstance];
    NSLog(@"Current ChatManager.presenceHandler: %@", chat.presenceHandler);
    ChatUser *loggedUser = chat.loggedUser; //[self userBy:self.applicationContext.loggedUser];
    NSString *loggedUserId = loggedUser.userId;
    if (loggedUser && !self.me) { // > just signed in / first load after startup
        self.me = loggedUser;
        
        chat.conversationsVC = self;
        [self initChat];
        NSLog(@"reloadData loggedUser && !self.me");
        [self.tableView reloadData];
    }
    else if (!loggedUser && self.me) {
        NSLog(@"**** You just logged out! Disposing current chat handlers...");
        // DEPRECATED
        self.me = nil;
        self.conversationsHandler = nil;
        ChatManager *chat = [ChatManager getInstance];
        [chat dispose];
        NSLog(@"reloadData !loggedUser && self.me");
        [self.tableView reloadData];
    }
    else if (loggedUser && ![self.me.userId isEqualToString:loggedUserId]) { // user changed
        NSAssert(false, @"user changed? this code must be unreacheable!");
        // DEPRECATED
        // user changed
        // reset handlers
        NSLog(@"**** User changed! Disposing current chat handlers and creating new one...");
        self.me = nil;
        self.conversationsHandler = nil;
        ChatManager *chat = [ChatManager getInstance];
//        [chat dispose];
        NSLog(@"Creating new handlers...");
        [chat startWithUser:loggedUser];
        chat.conversationsVC = self;
        [self initChat];
        NSLog(@"reloadData !loggedUser && self.me");
        [self.tableView reloadData];
    }
    else if (!loggedUser) { // logged out
        NSLog(@"**** User still not logged in.");
        // DEPRECATED
        // not signed in
        // do nothing
    }
    else if (loggedUser && [loggedUserId isEqualToString:self.me.userId]) {
        NSLog(@"**** You are logged in with the same user. Do nothing.");
    }
}

-(void)initChat {
    [self initConversationsHandler];
//    [self initContactsSynchronizer];
//    if (self.groupsMode) {
//        [self initGroupsHandler];
//    }
////    [self setupConnectionStatus];
////    [self initPresenceHandler];
}

-(void)initConversationsHandler {
    ChatManager *chat = [ChatManager getInstance];
    ChatConversationsHandler *handler = chat.conversationsHandler;
    if (!handler) {
        NSLog(@"Conversations Handler not found. Creating & initializing a new one.");
        handler = [chat createConversationsHandlerForUser:self.me];
        handler.delegateView = self;
        
        NSLog(@"DISABLED *** Restoring DB archived conversations *** DISABLED: using Firebase keepSynced:YES");
        NSLog(@"Restoring DB archived conversations.");
        [handler restoreConversationsFromDB];
        NSLog(@"Archived conversations count %lu", (unsigned long)self.conversationsHandler.conversations.count);
        
        [self update_unread];
//        [self update_unread_ui];
        NSLog(@"Connecting handler to firebase.");
        [handler connect];
        self.conversationsHandler = handler;
    } else {
        NSLog(@"Conversations Handler instance already set. Assigning delegate.");
        handler.delegateView = self;
        self.conversationsHandler = handler;
    }
}

//-(void)initContactsSynchronizer {
//    ChatManager *chat = [ChatManager getSharedInstance];
//    ChatContactsSynchronizer *synchronizer = chat.contactsSynchronizer;
//    if (!synchronizer) {
//        NSLog(@"Contacts Synchronizer not found. Creating & initializing a new one.");
//        synchronizer = [chat createContactsSynchronizerForUser:self.me];
//        [synchronizer startSynchro];
//    } else {
//        [synchronizer startSynchro];
//    }
//}

//-(void)initPresenceHandler {
//    ChatManager *chat = [ChatManager getSharedInstance];
//    ChatPresenceHandler *handler = chat.presenceHandler;
//    if (!handler) {
//        NSLog(@"Presence Handler not found. Creating & initializing a new one.");
//        handler = [chat createPresenceHandlerForUser:self.me];
//        handler.delegate = self;
//        self.presenceHandler = handler;
//        NSLog(@"Connecting handler to firebase.");
//        [self.presenceHandler setupMyPresence];
//    }
//}

//-(void)initGroupsHandler {
//    ChatManager *chat = [ChatManager getSharedInstance];
//    ChatGroupsHandler *handler = chat.groupsHandler;
//    if (!handler) {
//        NSLog(@"Groups Handler not found. Creating & initializing a new one.");
//        handler = [chat createGroupsHandlerForUser:self.me];
//        [handler restoreGroupsFromDB]; // not thread-safe, call this method before firebase synchronization start
//        [handler connect]; // firebase synchronization starts
//    }
//}

//#protocol SHPConversationsViewDelegate

-(void)didFinishConnect:(ChatConversationsHandler *)handler error:(NSError *)error {
    if (!error) {
        NSLog(@"ChatConversationsHandler Initialization finished with success.");
    } else {
        NSLog(@"ChatConversationsHandler Initialization finished with error: %@", error);
    }
}

//protocol SHPConversationsViewDelegate

-(void)finishedReceivingConversation:(ChatConversation *)conversation {
    // STUDIARE: since iOS 5, you can do the move like so:
    // [tableView moveRowAtIndexPath:indexPathOfRowToMove toIndexPath:indexPathOfTopRow];
    
    NSLog(@"New conversation received %@ by %@ (sender: %@)", conversation.last_message_text, conversation.conversWith_fullname, conversation.sender);
    [self showNotificationWindow:conversation];
    [self.tableView reloadData];
//    [self printAllConversations];
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self update_unread];
//        [self update_unread_ui];
    });
}

-(void)finishedRemovingConversation:(ChatConversation *)conversation {
    NSLog(@"Deleting conversation...");
    NSLog(@"Conversation removed %@ by %@ (sender: %@)", conversation.last_message_text, conversation.conversWith_fullname, conversation.sender);
    [self.tableView reloadData];
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self update_unread];
//        [self update_unread_ui];
    });
}

//-(void)printAllConversations {
//    NSLog(@"====== CONVERSATIONS DUMP ======");
//    NSMutableArray *conversations = [[[ChatDB getSharedInstance] getAllConversations] mutableCopy];
//    for (ChatConversation *c in conversations) {
//        NSLog(@"user: %@ id:%@ converswith:%@ sender:%@ recipient:%@",c.user, c.conversationId, c.conversWith, c.sender, c.recipient);
//    }
//    NSLog(@"====== END.");
//    
//    NSLog(@"-------- CONVERSATIONS DUMP 2 --------");
//    NSMutableArray *_conversations = self.conversationsHandler.conversations;
//    for (ChatConversation *c in _conversations) {
//        NSLog(@"user: %@ id:%@ converswith:%@ sender:%@ recipient:%@",c.user, c.conversationId, c.conversWith, c.sender, c.recipient);
//    }
//    NSLog(@"-------- END.");
//    
//    NSLog(@"########## CONVERSATIONS DUMP 2 ##########");
//    
//    NSMutableArray *__conversations = [[[ChatDB getSharedInstance] getAllConversationsForUser:self.me] mutableCopy];
//    for (ChatConversation *c in __conversations) {
//        NSLog(@"user: %@ id:%@ converswith:%@ sender:%@ recipient:%@",c.user, c.conversationId, c.conversWith, c.sender, c.recipient);
//    }
//    NSLog(@"########## END.");
//    
//}

-(void)showNotificationWindow:(ChatConversation *)conversation {
    NSString *currentConversationId = self.conversationsHandler.currentOpenConversationId;
    NSLog(@"conversation.is_new: %d", conversation.is_new);
    NSLog(@"!self.view.window: %d", !self.view.window);
    NSLog(@"conversation.conversationId: %@", conversation.conversationId);
    NSLog(@"currentConversationId: %@", currentConversationId);
    NSLog(@"conversation.is_new && !self.view.window && conversation.conversationId != currentConversationId");
    if ( conversation.is_new
         && !self.view.window // conversationsview hidden
         && conversation.conversationId != currentConversationId ) {
        
//        UIImage *userImage = [SHPImageUtil circleImage:[UIImage imageNamed:@"avatar"]];
//        NSString *imageURL = @""; //[SHPUser photoUrlByUsername:conversation.sender];
//        ChatImageWrapper *cached_image_wrap = [self.imageCache getImage:imageURL];
//        UIImage *cached_image = cached_image_wrap.image;
//        UIImage *_circled_cached_image = [SHPImageUtil circleImage:cached_image];
//        if(_circled_cached_image) {
//            userImage = _circled_cached_image;
//        }
        [ChatUtil showNotificationWithMessage:conversation.last_message_text image:nil sender:conversation.conversWith senderFullname:conversation.conversWith_fullname];
    }
}

// TODO: MOVE THIS ELSEWHERE
//-(void)update_unread_ui {
//    [self update_unread_badge];
//}
//-(void)update_unread_badge {
//    NSString *_count;
//    if (self.unread_count > 0) {
//        _count = [NSString stringWithFormat:@"%d", self.unread_count];
//    } else {
//        _count = nil;
//    }
//    int messages_tab_index = [SHPApplicationContext tabIndexByName:@"ChatController"];
//    [[self.tabBarController.tabBar.items objectAtIndex:messages_tab_index] setBadgeValue:_count];
//}

-(void)update_unread {
    int count = 0;
    for (ChatConversation *c in self.conversationsHandler.conversations) {
        if (c.is_new) {
            count++;
        }
    }
    self.unread_count = count;
    
//    // back button
//    if (count == 0) {
//        self.backButton.title = @"Chat";
//    } else {
//        self.backButton.title = [[NSString alloc] initWithFormat:@"Chat (%d)", count];
//        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
//        [label setBackgroundColor:[UIColor redColor]];
//        label.text = _count;
//    }
    
    // notify next VC
    if (self.navigationController.viewControllers.count > 1) {
        ChatMessagesVC *nextVC = [self.navigationController.viewControllers objectAtIndex:1];
        if ([nextVC respondsToSelector:@selector(updateUnreadMessagesCount)]) {
            nextVC.unread_count = count;
            [nextVC performSelector:@selector(updateUnreadMessagesCount) withObject:nil];
        }
        
    }
}

#pragma mark - Table view data source

// Override to support conditional editing of the table view.
// This only needs to be implemented if you are going to be returning NO
// for some items. By default, all items are editable.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return YES if you want the specified item to be editable.
    if (indexPath.section == 0) {
        return NO;
    }
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"commitEditingStyle");
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //add code here for when you hit delete
        NSString *title = NSLocalizedString(@"DeleteConversationTitle", nil);
        NSString *msg = NSLocalizedString(@"DeleteConversationMessage", nil);
        NSString *cancel = NSLocalizedString(@"CancelLKey", nil);
        
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title message:msg delegate:self cancelButtonTitle:cancel otherButtonTitles:@"OK", nil];
        self.removingConversationAtIndexPath = indexPath;
        [alertView show];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (section == 0) {
        return 1;
    } else {
        NSArray *conversations = self.conversationsHandler.conversations;
        if (conversations && conversations.count > 0) {
            return conversations.count;
        } else {
            return 1; // message cell
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        if (self.groupsMode) {
            return 44;
        } else {
            return 0;
        }
    }
    return UITableViewAutomaticDimension;// else 70;//
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *menuCellName = @"menuCell";
    static NSString *messageCellName = @"MessageCell";
    
    UITableViewCell *cell;
    NSArray *conversations = self.conversationsHandler.conversations;
    if (indexPath.section == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:menuCellName forIndexPath:indexPath];
        // Chat
        UIButton *new_group_button = [cell viewWithTag:10];
        [new_group_button setTitle:NSLocalizedString(@"NewGroup", nil) forState:UIControlStateNormal];
        UIButton *groups_button = [cell viewWithTag:20];
        [groups_button setTitle:NSLocalizedString(@"Groups", nil) forState:UIControlStateNormal];
        
        // Labot
        UIButton *new_quote_button = [cell viewWithTag:3];
        [new_quote_button setTitle:NSLocalizedString(@"new quote", nil) forState:UIControlStateNormal];
        UIButton *want_work_button = [cell viewWithTag:4];
        [want_work_button setTitle:NSLocalizedString(@"I want to work", nil) forState:UIControlStateNormal];
        //    UIButton *groupsButton;
        //    [self.groupsButton setTitle:NSLocalizedString(@"Groups", nil) forState:UIControlStateNormal];
    }
    else if (indexPath.section == 1) {
        if (conversations && conversations.count > 0) {
            ChatConversation *conversation = (ChatConversation *)[conversations objectAtIndex:indexPath.row];
//            NSLog(@"Conversation.sender %@", conversation.sender);
            cell = [CellConfigurator configureConversationCell:conversation tableView:tableView indexPath:indexPath conversationsVC:self];
        } else {
            NSLog(@"*conversations.count = 0");
            NSLog(@"Rendering NO CONVERSATIONS CELL...");
            cell = [tableView dequeueReusableCellWithIdentifier:messageCellName forIndexPath:indexPath];
            UILabel *message1 = (UILabel *)[cell viewWithTag:50];
            message1.text = NSLocalizedString(@"NoConversationsYet", nil);
            cell.userInteractionEnabled = NO;
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)_tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"selected s:%d i:%d", (int)indexPath.section, (int)indexPath.row);
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) { // toolbar
        return;
    }
    NSArray *conversations = self.conversationsHandler.conversations;
    ChatConversation *selectedConversation = (ChatConversation *)[conversations objectAtIndex:indexPath.row];
    self.selectedConversationId = selectedConversation.conversationId;
    NSLog(@"selected conv: %@ and conversWith: %@", selectedConversation, selectedConversation.conversWith);
    if (selectedConversation.groupId) {
        self.selectedGroupId = selectedConversation.groupId;
    }
    else {
        self.selectedRecipient = selectedConversation.conversWith;
        self.selectedRecipientFullname = selectedConversation.conversWith_fullname;
    }
    
    NSLog(@"Opening conversation with id: %@, recipient: %@, groupId: %@", self.selectedConversationId, self.selectedRecipient, self.selectedGroupId);
    
    if (selectedConversation.status == CONV_STATUS_FAILED) {
        // TODO
        NSLog(@"CONV_STATUS_FAILED. Not implemented. Re-start group creation workflow");
        return;
    }
    
    ChatManager *chat = [ChatManager getInstance];
    selectedConversation.is_new = NO;
    [chat updateConversationIsNew:selectedConversation.ref is_new:selectedConversation.is_new];
    
    
    [self performSegueWithIdentifier:@"CHAT_SEGUE" sender:self];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"CHAT_SEGUE"]) {
        NSLog(@"Preparing chat_segue...");
        
//        MessagesViewController *vc = (MessagesViewController *)[segue destinationViewController];
        ChatMessagesVC *vc = (ChatMessagesVC *)[segue destinationViewController];
        
        NSLog(@"vc %@", vc);
        // conversationsHandler will update status of new conversations (they come with is_new = true) with is_new = false (because the conversation is open and so new messages are all read)
        self.conversationsHandler.currentOpenConversationId = self.selectedConversationId;
        NSLog(@"self.selectedConversationId = %@", self.selectedConversationId);
        NSLog(@"self.conversationsHandler.currentOpenConversationId = %@", self.selectedConversationId);
//        vc.conversationsVC = self;
        
        vc.conversationId = self.selectedConversationId;
        NSLog(@"self.selectedRecipient: %@", self.selectedRecipient);
        if (self.selectedRecipient) {
            ChatUser *recipient = [[ChatUser alloc] init:self.selectedRecipient fullname:self.selectedRecipientFullname];
            vc.recipient = recipient;
        }
        else {
            vc.recipient = nil;
        }
        if (self.selectedGroupId) {
            vc.group = [[ChatManager getInstance] groupById:self.selectedGroupId];
            NSLog(@"INFO GROUP OK: %@", vc.group.name);
            if (!vc.group) {
                NSLog(@"INFO X GRUPPO %@ NON TROVATE. PROBABILMENTE GRUPPI NON ANCORA SINCRONIZZATI. CARICO INFO GRUPPO DIRETTAMENTE DA VISTA MESSAGGI (CON ID GRUPPO)", self.selectedGroupId);
                ChatGroup *emptyGroup = [[ChatGroup alloc] init];
                emptyGroup.name = nil; // signals no group metadata
                emptyGroup.groupId = self.selectedGroupId;
                vc.group = emptyGroup;
            }
        }
        vc.unread_count = self.unread_count;
        vc.textToSendAsChatOpens = self.selectedRecipientTextToSend;
        vc.attributesToSendAsChatOpens = self.selectedRecipientAttributesToSend;
        [self resetSelectedConversationStatus];
    }
    // TODO: DOPO, DIVENTA UN EXTENSION POINT.
    else if ([[segue identifier] isEqualToString:@"SelectUser"]) {
        UINavigationController *navigationController = [segue destinationViewController];
        ChatSelectUserLocalVC *vc = (ChatSelectUserLocalVC *)[[navigationController viewControllers] objectAtIndex:0];
        vc.modalCallerDelegate = self;
    }
//    else if ([[segue identifier] isEqualToString:@"CreateGroup"]) {
//        NSLog(@"CreateGroup");
//        NSString *newGroupId = [[ChatManager getInstance] newGroupId];
//        [self.applicationContext setVariable:@"newGroupId" withValue:newGroupId];
//        NSLog(@"Creating group with ID: %@", newGroupId);
//        UINavigationController *navigationController = [segue destinationViewController];
//        SHPChatCreateGroupVC *vc = (SHPChatCreateGroupVC *)[[navigationController viewControllers] objectAtIndex:0];
//        vc.modalCallerDelegate = self;
//    }
//    else if ([[segue identifier] isEqualToString:@"ChooseGroup"]) {
//        UINavigationController *navigationController = [segue destinationViewController];
//        ChatSelectGroupLocalTVC *vc = (ChatSelectGroupLocalTVC *)[[navigationController viewControllers] objectAtIndex:0];
//        vc.applicationContext = self.applicationContext;
//        vc.modalCallerDelegate = self;
//    }
}

-(void)openConversationWithUser:(ChatUser *)user {
    [self openConversationWithUser:user orGroup:nil sendMessage:nil attributes:nil];
}

-(void)openConversationWithUser:(ChatUser *)user orGroup:(NSString *)groupid sendMessage:(NSString *)text attributes:(NSDictionary *)attributes {
    NSLog(@"Opening conversation with recipient: %@ or group: %@", user.userId, groupid);
    [self loadViewIfNeeded];
    [self.navigationController popToRootViewControllerAnimated:NO];
    self.selectedRecipientTextToSend = text;
    if (user) {
        self.selectedRecipient = user.userId;
        self.selectedRecipientFullname = user.fullname;
//        ChatUser *loggedUser = [ChatManager getInstance].loggedUser;
        self.selectedConversationId = user.userId; //[ChatUtil conversationIdWithSender:loggedUser.userId receiver:user.userId];
        NSLog(@"Auto Generated Conversation ID: %@", self.selectedConversationId);
        self.selectedRecipientAttributesToSend = attributes;
    }
    else {
        self.selectedGroupId = groupid;
        self.selectedConversationId = groupid; //[ChatUtil conversationIdForGroup:groupid];
    }
    [self performSegueWithIdentifier:@"CHAT_SEGUE" sender:self];
}

-(void)resetCurrentConversation {
    NSLog(@"resetting current conversationId");
    self.conversationsHandler.currentOpenConversationId = nil;
}

-(void)resetSelectedConversationStatus {
    self.selectedRecipientTextToSend = nil;
    self.selectedRecipientAttributesToSend = nil;
    self.selectedRecipient = nil;
    self.selectedRecipientFullname = nil;
    self.selectedGroupId = nil;
}

//- (IBAction)testConnectionAction:(id)sender {
//    NSLog(@"test connection status.");
//    [self isStatusConnected];
//}

- (IBAction)newGroupAction:(id)sender {
    NSLog(@"Nuovo gruppo");
//    [self performSegueWithIdentifier:@"CreateGroup" sender:self];
}

//- (IBAction)testAction:(id)sender {
//    NSLog(@"Test action.");
//    ChatManager *chat = [ChatManager getSharedInstance];
//    [chat firebaseScout];
//}

//- (IBAction)printAction:(id)sender {
//    [self printDBConvs];
//}

//- (IBAction)printGroupsAction:(id)sender {
//    [self printDBGroups];
//}

- (IBAction)groupsAction:(id)sender {
//    [self printDBGroups];
//    [self performSegueWithIdentifier:@"ChooseGroup" sender:self];
}

// images

//- (void)startIconDownload:(NSString *)imageURL forIndexPath:(NSIndexPath *)indexPath
//{
////    NSString *imageURL = [SHPUser photoUrlByUsername:username];
//    NSLog(@"START DOWNLOADING IMAGE: %@", imageURL);
//    SHPImageDownloader *iconDownloader = [self.imageDownloadsInProgress objectForKey:imageURL];
//    //    NSLog(@"IconDownloader..%@", iconDownloader);
//    if (iconDownloader == nil)
//    {
//        iconDownloader = [[SHPImageDownloader alloc] init];
//        NSMutableDictionary *options = [[NSMutableDictionary alloc] init];
//        [options setObject:indexPath forKey:@"indexPath"];
//        iconDownloader.options = options;
//        iconDownloader.imageURL = imageURL;
//        iconDownloader.delegate = self;
//        [self.imageDownloadsInProgress setObject:iconDownloader forKey:imageURL];
//        [iconDownloader startDownload];
//    }
//}

//- (void)startIconDownload:(NSString *)username forIndexPath:(NSIndexPath *)indexPath
//{
//    NSString *imageURL = [SHPUser photoUrlByUsername:username];
//    NSLog(@"START DOWNLOADING IMAGE: %@ imageURL: %@", username, imageURL);
//    SHPImageDownloader *iconDownloader = [self.imageDownloadsInProgress objectForKey:imageURL];
//    //    NSLog(@"IconDownloader..%@", iconDownloader);
//    if (iconDownloader == nil)
//    {
//        iconDownloader = [[SHPImageDownloader alloc] init];
//        NSMutableDictionary *options = [[NSMutableDictionary alloc] init];
//        [options setObject:indexPath forKey:@"indexPath"];
//        iconDownloader.options = options;
//        iconDownloader.imageURL = imageURL;
//        iconDownloader.delegate = self;
//        [self.imageDownloadsInProgress setObject:iconDownloader forKey:imageURL];
//        [iconDownloader startDownload];
//    }
//}

//// callback for the icon loaded
//- (void)appImageDidLoad:(UIImage *)image withURL:(NSString *)imageURL downloader:(SHPImageDownloader *)downloader {
//    NSLog(@"+******** IMAGE AT URL: %@ DID LOAD: %@", imageURL, image);
//    if (!image) {
//        return;
//    }
//    //UIImage *circled = [SHPImageUtil circleImage:image];
//    [self.imageCache addImage:image withKey:imageURL];
//    NSDictionary *options = downloader.options;
//    NSIndexPath *indexPath = [options objectForKey:@"indexPath"];
////    NSLog(@"+******** appImageDidLoad row: %ld", indexPath.row);
//
//    // if the cell for the image is visible updates the cell
//    NSArray *indexes = [self.tableView indexPathsForVisibleRows];
//    for (NSIndexPath *index in indexes) {
//        if (index.row == indexPath.row && index.section == indexPath.section) {
//            UITableViewCell *cell = [(UITableView *)self.tableView cellForRowAtIndexPath:index];
//            UIImageView *iv = (UIImageView *)[cell viewWithTag:1];
//            iv.image = [SHPImageUtil circleImage:image];
//        }
//    }
//    [self.imageDownloadsInProgress removeObjectForKey:imageURL];
//}

//-(void)terminatePendingImageConnections {
//    NSLog(@"''''''''''''''''''''''   Terminate all pending IMAGE connections...");
//    NSArray *allDownloads = [self.imageDownloadsInProgress allValues];
////    NSLog(@"total downloads: %d", allDownloads.count);
//    for(SHPImageDownloader *obj in allDownloads) {
//        obj.delegate = nil;
//    }
//    [allDownloads makeObjectsPerformSelector:@selector(cancelDownload)];
//}

// end user images

- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
        {
            // cancel
            NSLog(@"Delete canceled");
            break;
        }
        case 1:
        {
            // ok
            NSLog(@"Deleting conversation...");
            NSInteger conversationIndex = self.removingConversationAtIndexPath.row;
            [self removeConversationAtIndex:conversationIndex];
        }
    }
}

-(void)removeConversationAtIndex:(NSInteger)conversationIndex {
    ChatConversation *removingConversation = (ChatConversation *)[self.conversationsHandler.conversations objectAtIndex:conversationIndex];
    NSLog(@"Removing conversation id %@ / ref %@",removingConversation.conversationId, removingConversation.ref);
    
    [self.tableView beginUpdates];
    ChatManager *chat = [ChatManager getInstance];
    [chat removeConversation:removingConversation];
    [self.conversationsHandler.conversations removeObjectAtIndex:conversationIndex];
    [self.tableView deleteRowsAtIndexPaths:@[self.removingConversationAtIndexPath] withRowAnimation:UITableViewRowAnimationFade];
    /* http://stackoverflow.com/questions/5454708/nsinternalinconsistencyexception-invalid-number-of-rows
     If you delete the last row in your table, the UITableView code expects there to be 0 rows remaining. It
     calls your UITableViewDataSource methods to determine how many are left. Since you have a "No data"
     cell, it returns 1, not 0. So when you delete the last row in your table, try calling
     insertRowsAtIndexPaths:withRowAnimation: to insert your "No data" row.
     */
    if (self.conversationsHandler.conversations.count <= 0) {
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:self.removingConversationAtIndexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
    [self.tableView endUpdates];
    
    [self update_unread];
//    [self update_unread_ui];
    
    // verify
    ChatConversation *conv = [[ChatDB getSharedInstance] getConversationById:removingConversation.conversationId];
    NSLog(@"Verifying conv %@", conv);
    NSArray *messages = [[ChatDB getSharedInstance] getAllMessagesForConversation:removingConversation.conversationId];
    NSLog(@"resting messages count %lu", (unsigned long)messages.count);
}

-(void)disposeResources {
//    [self terminatePendingImageConnections];
}

//-(void)printDBConvs {
//    NSString *current_user = self.me.userId;
//    NSLog(@"Conversations for user %@...", current_user);
//    NSArray *convs = [[ChatDB getSharedInstance] getAllConversations];//ForUser:current_user];
//    for (ChatConversation *conv in convs) {
//        NSLog(@"[%@] new?%d sender:%@ recip: %@ groupId: %@ \"%@\"", conv.conversationId, conv.is_new, conv.sender, conv.recipient, conv.groupId, conv.last_message_text);
//    }
//}

//-(void)printDBGroups {
//    NSString *current_user = [ChatManager getSharedInstance].loggedUser.userId;
//    NSLog(@"Groups for user %@...", current_user);
//    NSArray *groups = [[ChatGroupsDB getSharedInstance] getAllGroupsForUser:current_user];
//    NSLog(@"GROUPS >>");
//    for (ChatGroup *g in groups) {
//        NSLog(@"ID:%@ NAME:%@ OWN:%@ MBRS:%@", g.groupId, g.name, g.owner, [ChatGroup membersDictionary2String:g.members]);
//    }
//}

- (void)setupViewController:(UIViewController *)controller didFinishSetupWithInfo:(NSDictionary *)setupInfo {
    NSLog(@"setupViewController...");
    if([controller isKindOfClass:[ChatSelectUserLocalVC class]])
    {
        ChatUser *user = nil;
        if ([setupInfo objectForKey:@"user"]) {
            user = [setupInfo objectForKey:@"user"];
            NSLog(@">>>>>> SELECTED: user %@", user.userId);
        }
        [self dismissViewControllerAnimated:YES completion:^{
            if (user) {
//                self.selectedRecipientFullname = user.fullname;
                [self openConversationWithUser:user];
            }
        }];
    }
    if([controller isKindOfClass:[ChatSelectGroupLocalTVC class]])
    {
        ChatGroup *group = nil;
        if ([setupInfo objectForKey:@"group"]) {
            group = [setupInfo objectForKey:@"group"];
            NSLog(@">>>>>> SELECTED: group %@", group.groupId);
        }
        [self dismissViewControllerAnimated:YES completion:^{
            if (group) {
                self.selectedGroupId = group.groupId;
                [self openConversationWithUser:nil orGroup:group.groupId sendMessage:nil attributes:nil];
            }
        }];
    }
    else if([controller isKindOfClass:[ChatSelectGroupMembersLocal class]])
    {
        [self dismissViewControllerAnimated:YES completion:nil];
        NSMutableArray<ChatUser *> *groupMembers = (NSMutableArray<ChatUser *> *)[setupInfo objectForKey:@"groupMembers"];
        NSMutableArray *membersIDs = [[NSMutableArray alloc] init];
        for (ChatUser *u in groupMembers) {
            [membersIDs addObject:u.userId];
        }
        // adding group's owner to members
        [membersIDs addObject:self.me.userId];
        NSString *groupId = (NSString *)[setupInfo objectForKey:@"newGroupId"];
        NSLog(@"New Group ID: %@", groupId);
        NSString *groupName = (NSString *)[setupInfo objectForKey:@"groupName"];
        NSLog(@"New Group Name: %@", groupName);
        ChatManager *chat = [ChatManager getInstance];
        [chat createGroup:groupId name:groupName owner:self.me.userId members:membersIDs];
    }
}

- (void)setupViewController:(UIViewController *)controller didCancelSetupWithInfo:(NSDictionary *)setupInfo {
    if([controller isKindOfClass:[ChatSelectUserLocalVC class]])
    {
        NSLog(@"User selection Canceled.");
        [self dismissViewControllerAnimated:YES completion:nil];
    }
//    else if([controller isKindOfClass:[SHPChatCreateGroupVC class]])
//    {
//        NSLog(@"Group creation canceled.");
//        [self dismissViewControllerAnimated:YES completion:nil];
//    }
    else if([controller isKindOfClass:[ChatSelectGroupLocalTVC class]])
    {
        NSLog(@"Group selection canceled.");
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (IBAction)actionNewMessage:(id)sender {
    [self performSegueWithIdentifier:@"SelectUser" sender:self];
}

-(IBAction)unwindToConversationsView:(UIStoryboardSegue *)sender {
    
//    UIViewController *sourceViewController = sender.sourceViewController;
//    if ([sourceViewController isKindOfClass:[MRCategoryStepTVC class]]) {
//        NSLog(@"Job wizard canceled.");
//        [self dismissViewControllerAnimated:YES completion:nil];
//    } else if ([sourceViewController isKindOfClass:[MRPreviewStepTVC class]]) {
//        NSLog(@"job context: %@", self.jobWizardContext);
//    }
//    
    NSLog(@"unwindToConversationsView. no impl.");
    
}



- (IBAction)writeToAction:(id)sender {
    [self performSegueWithIdentifier:@"SelectUser" sender:self];
}

- (IBAction)helpAction:(id)sender {
    NSLog(@"Help in Documents' navigator view");
    [[HelpFacade sharedInstance] openSupportView:self];
}

-(void)helpWizardEnd:(NSDictionary *)context {
    NSLog(@"helpWizardEnd");
    [context setValue:NSStringFromClass([self class]) forKey:@"section"];
    [[HelpFacade sharedInstance] handleWizardSupportFromViewController:self helpContext:context];
}

@end