//
//  HelloAppDelegate.m
//
//  Created by andrea sponziello on 24/05/17.
//

#import "HelloAppDelegate.h"
#import "HelloApplicationContext.h"
//#import "SHPCaching.h"
#import "HelloUser.h"
#import "HelloAuth.h"
#import "ChatManager.h"
#import "ChatUtil.h"
#import "ChatConversationsVC.h"
#import "ChatUtil.h"
#import "HelloAuthTVC.h"
#import "ChatContactsSynchronizer.h"
#import "ChatUser.h"
#import "HelloChatUtil.h"
#import "ChatUIManager.h"
#import "ChatGroup.h"
#import "ChatMessage.h"
#import "ChatAuth.h"
#import <DBChooser/DBChooser.h>

#import <sys/utsname.h>
@import Firebase;

@implementation HelloAppDelegate

static NSString *NOTIFICATION_KEY_TYPE = @"t"; //type
static NSString *NOTIFICATION_KEY_TYPE_CHAT = @"chat";


static NSString *NOTIFICATION_KEY_ALERT = @"alert";
static NSString *NOTIFICATION_KEY_CATEGORY = @"category";
static NSString *NOTIFICATION_KEY_APS = @"aps";
static NSString *NOTIFICATION_KEY_BADGE = @"badge";
static NSString *NOTIFICATION_VALUE_NEW_MESSAGE = @"NEW_MESSAGE";

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSLog(@"didFinishLaunchingWithOptions...");
    
    HelloApplicationContext *context = [HelloApplicationContext getSharedInstance];
    self.applicationContext = context;
    NSString *settingsPath = [[NSBundle mainBundle] pathForResource:@"settings" ofType:@"plist"];
    NSDictionary *settings = [[NSDictionary alloc] initWithContentsOfFile:settingsPath];
    self.applicationContext.settings = settings;
    
    [self initUser];
    // chat config
    [FIRApp configure];
    [ChatManager configure];
    // initial chat signin
    if ((context.loggedUser)) {
        // initialize signed-in user so I can get chat-history from DB, using offline mode, regardless of a real remote (Firebase) successfull authentication&connection
        [HelloChatUtil initChat];
        // now I can try to authenticate. Always authenticate on on app's startup
        [ChatAuth authWithEmail:context.loggedUser.email password:context.loggedUser.password completion:^(ChatUser *user, NSError *error) {
            if (error) {
                NSLog(@"Authentication error. %@", error);
            }
            else {
                NSLog(@"Authentication success.");
            }
        }];
    }
    
    // adding chat controller
    NSInteger chat_tab_index = [ChatUIManager getInstance].tabBarIndex;
    if (chat_tab_index >= 0) {
        UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
        UITabBarController *tabController = (UITabBarController *)window.rootViewController;
        NSMutableArray *controllers = [[tabController viewControllers] mutableCopy];
        UINavigationController *conversationsNC = [[ChatUIManager getInstance] getConversationsViewController];
        conversationsNC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Chat" image:[UIImage imageNamed:@"ic_linear_chat"] selectedImage:[UIImage imageNamed:@"ic_linear_chat"]];
        controllers[1] = conversationsNC;
        [tabController setViewControllers:controllers];
        ChatConversationsVC *conversationsVC = conversationsNC.viewControllers[0];
        [conversationsVC loadViewIfNeeded];
    } else {
        NSLog(@"ChatController doesn't exist.");
    }
    
    // #notificationworkflow
    
    // Get remote push notifications on application startup
    NSDictionary* userInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (userInfo) {
        NSLog(@"REMOTE NOTIFICATION STARTED THE APPLICATION!");
        [self processRemoteNotification:userInfo];
    }
    
    // the chat app only asks notification permission when user is logged in
    if (self.applicationContext.loggedUser) {
        [self startPushNotifications];
    }
    
    return YES;
}

-(ChatUser *)chatUserBy:(HelloUser *)hello_user {
    if (!hello_user) {
        return nil;
    }
    ChatUser *user = [[ChatUser alloc] init];
    user.userId = hello_user.username;
    user.fullname = hello_user.fullName;
    user.email = hello_user.email;
    return user;
}

-(void)startPushNotifications {
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_9_x_Max) {
        UIUserNotificationType allNotificationTypes =
        (UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge);
        UIUserNotificationSettings *settings =
        [UIUserNotificationSettings settingsForTypes:allNotificationTypes categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    }
    else {
        // iOS 10 or later
#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
        // For iOS 10 display notification (sent via APNS)
        [UNUserNotificationCenter currentNotificationCenter].delegate = self;
        UNAuthorizationOptions authOptions =
        UNAuthorizationOptionAlert
        | UNAuthorizationOptionSound
        | UNAuthorizationOptionBadge;
        [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:authOptions completionHandler:^(BOOL granted, NSError * _Nullable error) {
        }];
#endif
    }
    
    [[UIApplication sharedApplication] registerForRemoteNotifications];
    
    // Add observer for InstanceID token refresh callback.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tokenRefreshNotification:)
                                                 name:kFIRInstanceIDTokenRefreshNotification object:nil];
}

// #notificationsworkflow
- (void)application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary*)userInfo {
    NSLog(@"REMOTE NOTIFICATION. didReceiveRemoteNotification: %@", userInfo);
    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
    NSLog(@"APPLICATION DID RECEIVE REMOTE NOTIFICATION IN STATE: %ld", (long)state);
    if (state == UIApplicationStateBackground || state == UIApplicationStateInactive)
    {
        NSLog(@"APPLICATION WAS RUNNING IN BACKGROUND!");
        [self processRemoteNotification:userInfo];
    }
    else {
        NSLog(@"APPLICATION IS RUNNING IN FOREGROUND! NOTIFICATION IGNORED.");
    }
}

-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(nonnull void (^)(UIBackgroundFetchResult))completionHandler {
    NSLog(@"call -> application:didReceiveRemoteNotification:fetchCompletionHandler:");
    
    // DECODE NOTIFICATION...
    
    // THEN...
    
    ChatManager *chatm = [ChatManager getInstance];
    // initialize and connect ChatConversationsHandler
    [chatm getAndStartConversationsHandler];
    
    // for any unread-conversation?
    //   initialize and connect ChatConversationHandler
    //
    //    ChatConversationHandler *handler;
    //    if (self.recipient) {
    //        handler = [chatm getConversationHandlerForRecipient:self.recipient];
    //    } else {
    //        ChatGroup *group = [[ChatGroup alloc] init];
    //        group.name = recipient_fullname;
    //        group.groupId = recipientid;
    //        handler = [chatm getConversationHandlerForGroup:group];
    //    }
    // Start a 5 seconds timer. Call completionHandler on timer-end
}

// #notificationsworkflow
-(void)processRemoteNotification:(NSDictionary*)userInfo {
    NSDictionary *aps = [userInfo objectForKey:NOTIFICATION_KEY_APS];
//    NSString *alert = [aps objectForKey:NOTIFICATION_KEY_ALERT];
    NSString *category = [aps objectForKey:NOTIFICATION_KEY_CATEGORY];
    
    if ([category isEqualToString:NOTIFICATION_VALUE_NEW_MESSAGE]) {
        NSString *senderid = [userInfo objectForKey:@"sender"];
        NSString *sender_fullname = [userInfo objectForKey:@"sender_fullname"];
        NSString *recipientid = [userInfo objectForKey:@"recipient"];
        NSString *recipient_fullname = [userInfo objectForKey:@"recipient_fullname"];
        NSString *channel_type = [userInfo objectForKey:@"channel_type"];
//        NSString *badge = [[userInfo objectForKey:NOTIFICATION_KEY_APS] objectForKey:NOTIFICATION_KEY_BADGE];
        
        if ([channel_type isEqualToString:MSG_CHANNEL_TYPE_GROUP]) {
            // GROUP MESSAGE
            ChatGroup *group = [[ChatGroup alloc] init];
            group.name = recipient_fullname;
            group.groupId = recipientid;
            [ChatUIManager moveToConversationViewWithGroup:group];
        }
        else {
            // DIRECT MESSAGE
            NSString *trimmedSender = [senderid stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
            if (trimmedSender.length > 0) {
                ChatUser *user = [[ChatUser alloc] init];
                user.userId = senderid;
                user.fullname = sender_fullname;
                [ChatUIManager moveToConversationViewWithUser:user];
            }
            else {
                NSLog(@"Error: invalid sender (0 length). Message notification discarded.");
            }
        }
    }
}

// #notificationsworkflow
// Delegation methods
- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)devToken {
    
    NSLog(@"Application successfully registered to APN with devToken %@", devToken);
    [[ChatManager getInstance] registerForNotifications:devToken];
//    NSString *FCMToken = [FIRMessaging messaging].FCMToken;
//    NSLog(@"FCMToken: %@", FCMToken);
//    [FIRMessaging messaging].APNSToken = devToken;
//    NSLog(@"[FIRMessaging messaging].APNSToken: %@", [FIRMessaging messaging].APNSToken);
//    ChatUser *loggedUser = [ChatManager getInstance].loggedUser;
//    if (loggedUser) {
//        NSString *user_path = [ChatUtil userPath:loggedUser.userId];
//        NSLog(@"Writing instanceId (FCMToken) %@ on path: %@", FCMToken, user_path);
//        [[[[[FIRDatabase database] reference] child:user_path] child:@"instanceId"] setValue:FCMToken withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
//            if (error) {
//                NSLog(@"Error saving instanceId (FCMToken) on user_path %@: %@", error, user_path);
//            }
//            else {
//                NSLog(@"instanceId (FCMToken) %@ saved", FCMToken);
//            }
//        }];
//    }
//    else {
//        NSLog(@"No user is signed in for push notifications token.");
//    }
}

// #notificationsworkflow
- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
    NSLog(@">>>>>>> Error in APN registration: %@", err);
}

// [START refresh_token]
- (void)tokenRefreshNotification:(NSNotification *)notification {
    // Note that this callback will be fired everytime a new token is generated, including the first
    // time. So if you need to retrieve the token as soon as it is available this is where that
    // should be done.
    NSString *refreshedToken = [[FIRInstanceID instanceID] token];
    NSLog(@"InstanceID token: %@", refreshedToken);
    
    // Connect to FCM since connection may have failed when attempted before having a token.
    //    [self connectToFcm];
    
    // TODO: If necessary send token to appliation server.
}
// [END refresh_token]

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    NSLog(@"Tab selected.");
}

-(void)initUser {
    HelloUser *user = [HelloAuth restoreSavedUser];
    if (user) {
        self.applicationContext.loggedUser = user;
    } else {
        self.applicationContext.loggedUser = nil;
    }
}

// **** APP DELEGATES ****

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    NSLog(@"App >> applicationWillResignActive...");
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    NSLog(@"App >> applicationDidEnterBackground...");
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    NSLog(@"App >> applicationWillEnterForeground...");
    //    NSLog(@"notifications are active? %d", [self checkPushNotificationsActive]);
    //    [Appirater appEnteredForeground:YES];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    NSLog(@"App >> applicationDidBecomeActive...");
    application.applicationIconBadgeNumber = 0;
    
    if (self.applicationContext.loggedUser) {
        NSLog(@"Registering for remote notifications...");
        [application registerForRemoteNotifications];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    NSLog(@"App >> applicationWillTerminate...");
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    NSLog(@"App >> applicationDidReceiveMemoryWarning. Caches empting...");
}

-(BOOL)application:(UIApplication *)application
           openURL:(NSURL *)url
 sourceApplication:(NSString *)sourceApplication
        annotation:(id)annotation{
    NSLog(@"AppDelegate openURL");
    //    if ([[DBSession sharedSession] handleOpenURL:url]) {
    //        if ([[DBSession sharedSession] isLinked]) {
    //            NSLog(@"App linked successfully!");
    //            // At this point you can start making API calls
    //        }
    //        return YES;
    //    }
    if ([[DBChooser defaultChooser] handleOpenURL:url]) {
        // This was a Chooser response and handleOpenURL automatically ran the
        // completion block
        NSLog(@"DBChooser openURL");
        return YES;
    }
    return NO;
}

@end