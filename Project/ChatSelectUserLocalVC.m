//
//  ChatSelectUserLocalVC.m
//  bppmobile
//
//  Created by Andrea Sponziello on 13/09/2017.
//  Copyright © 2017 Frontiere21. All rights reserved.
//

#import "ChatSelectUserLocalVC.h"

//#import "SHPSearchUsersLoader.h"
#import "SHPApplicationContext.h"
//#import "SHPUserDC.h"
//#import "SHPUser.h"
#import "SHPImageDownloader.h"
#import "SHPModalCallerDelegate.h"
#import "SHPImageUtil.h"
#import "SHPCaching.h"
#import "ChatImageCache.h"
#import "ChatImageWrapper.h"
#import "ChatGroup.h"
//#import "AlfrescoUsersDC.h"
//#import "AlfrescoRequest.h"
#import "ChatDB.h"
#import "ChatUser.h"
#import "ContactsDB.h"
#import "ChatManager.h"
#import "ChatContactsSynchronizer.h"

@interface ChatSelectUserLocalVC () {
    ChatContactsSynchronizer *contacts;
}

@end

@implementation ChatSelectUserLocalVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.users = nil;
    if (self.group) {
        self.navigationItem.title = NSLocalizedString(@"Add member", nil);
    } else {
        self.navigationItem.title = NSLocalizedString(@"NewMessage", nil);
    }
    
    //    self.imageCache = self.applicationContext.smallImagesCache;
    
    self.imageDownloadsInProgress = [NSMutableDictionary dictionary];
    
    NSLog(@"tableView %@", self.tableView);
    
    self.searchBar.delegate = self;
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    //    [self restoreRecents];
    //    [self restoreAllUsers];
    //    [self loadAllUsers];
    
    //    NSLog(@"Current RECENTS...");
    //    for (SHPUser *u in self.recentUsers) {
    //        NSLog(@"recent-user %@", u.username);
    //    }
    
    [self initImageCache];
//    ChatManager *chat = [ChatManager getSharedInstance];
//    ChatContactsSynchronizer *contacts = chat.contactsSynchronizer;
//    self.synchronizing = contacts.synchronizing;
//    if (!self.synchronizing) {
//        [self.searchBar becomeFirstResponder];
//        [self search];
//    } else {
//        self.searchBar.userInteractionEnabled = NO;
//    }
    ChatManager *chatm = [ChatManager getInstance];
    contacts = chatm.contactsSynchronizer;
    [self setupSynchronizing];
    [contacts addSynchSubcriber:self];
//    [self activityIndicatorOnNavigationBar];
}

//-(void)activityIndicatorOnNavigationBar {
//    self.activityIndicator = [[UIActivityIndicatorView alloc]
//                              initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhite];
//    self.activityIndicator.hidden = NO;
//    UIBarButtonItem* spinner = [[UIBarButtonItem alloc] initWithCustomView: self.activityIndicator];
//    self.navigationItem.rightBarButtonItem = spinner;
//}

// SYNCH PROTOCOL

-(void)synchStart {
    NSLog(@"SYNCH-START");
    [self setupSynchronizing];
    [self.tableView reloadData];
}

-(void)synchEnd {
    NSLog(@"SYNCH-END");
    [self setupSynchronizing];
    [self.tableView reloadData];
}

-(void)setupSynchronizing {
    self.synchronizing = contacts.synchronizing;
    if (!self.synchronizing) {
        [self.searchBar becomeFirstResponder];
        [self search];
    } else {
        self.searchBar.userInteractionEnabled = NO;
    }
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

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
//    [self search];
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    //    NSLog(@"AAA viewDidDisappear...isMoving: %d, isBeingDismissed: %d", self.isMovingFromParentViewController, self.isBeingDismissed);
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    //    NSLog(@"SEARCH USERS VIEW WILL DISAPPEAR...isMoving: %d, isBeingDismissed: %d", self.isMovingFromParentViewController, self.isBeingDismissed);
    //    if (self.isMovingFromParentViewController || self.isBeingDismissed) {
    //        NSLog(@"SEARCH USERS VIEW WILL DISAPPEAR...DISMISSING..");
    //        [self disposeResources];
    //    }
}

-(void)disposeResources {
//    if (self.currentRequest) {
//        [self.currentRequest cancel];
//    }
    NSLog(@"Disposing pending image connections...");
    [self terminatePendingImageConnections];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.users) { // users found matching search criteria
        return 1;
    }
    return 2; // recentUsers, allUsers
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (section == 0 && self.synchronizing) {
        return 1; // message cell
    }
    else if (section == 0 && self.users) {
        return self.users.count;
    }
    else if (section == 0) {
        return self.recentUsers.count;
    }
    else if (section == 1) {
        return self.allUsers.count;
    }
    else {
        return 0;
    }
    
    //    if(self.users && self.users.count > 0) {
    //        NSInteger num = self.users.count;
    //        return num;
    //    } else if (self.recentUsers && self.recentUsers > 0) {
    //        NSInteger num = self.recentUsers.count;
    //        return num;
    //    }
    //    else {
    //        NSLog(@"0 rows.");
    //        return 0;
    //    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 1 && self.allUsers.count > 0) {
        return NSLocalizedString(@"all contacts", nil);
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    if (indexPath.section == 0 && self.synchronizing) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"WaitCell"];
        UIActivityIndicatorView *indicator = (UIActivityIndicatorView *)[cell viewWithTag:1];
        [indicator startAnimating];
        UILabel *messageLabel = (UILabel *)[cell viewWithTag:2];
        messageLabel.text = NSLocalizedString(@"Synchronizing contacts", nil);
    }
    else if (indexPath.section == 0 && self.users) {
        long userIndex = indexPath.row;
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"UserCell"];
        //        cell.contentView.backgroundColor = [UIColor whiteColor];
        ChatUser *user = [self.users objectAtIndex:userIndex];
        
        [self setupUserLabel:user cell:cell];
        
        UIImage *circled = [SHPImageUtil circleImage:[UIImage imageNamed:@"avatar"]];
        UIImageView *image_view = (UIImageView *)[cell viewWithTag:1];
        image_view.image = circled;
    }
    else if (indexPath.section == 0 && self.recentUsers.count > 0) {
        // show recents
        long userIndex = indexPath.row;
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"UserCell"];
        ChatUser *user = [self.recentUsers objectAtIndex:userIndex];
        
        [self setupUserLabel:user cell:cell];
        
        // USER IMAGE
        UIImageView *image_view = (UIImageView *)[cell viewWithTag:1];
        NSString *imageURL = @""; //[SHPUser photoUrlByUsername:user.userId];
        ChatImageWrapper *cached_image_wrap = (ChatImageWrapper *)[self.imageCache getImage:imageURL];
        UIImage *user_image = cached_image_wrap.image;
        if(!cached_image_wrap) { // user_image == nil if image saving gone wrong!
            //NSLog(@"USER %@ IMAGE NOT CACHED. DOWNLOADING...", conversation.conversWith);
            [self startIconDownload:user.userId forIndexPath:indexPath];
            // if a download is deferred or in progress, return a placeholder image
            UIImage *circled = [SHPImageUtil circleImage:[UIImage imageNamed:@"avatar"]];
            image_view.image = circled;
        } else {
            //NSLog(@"USER IMAGE CACHED. %@", conversation.conversWith);
            image_view.image = [SHPImageUtil circleImage:user_image];
            // update too old images
            double now = [[NSDate alloc] init].timeIntervalSince1970;
            double reload_timer_secs = 86400; // one day
            if (now - cached_image_wrap.createdTime.timeIntervalSince1970 > reload_timer_secs) {
                //NSLog(@"EXPIRED image for user %@. Created: %@ - Now: %@. Reloading...", conversation.conversWith, cached_image_wrap.createdTime, [[NSDate alloc] init]);
                [self startIconDownload:user.userId forIndexPath:indexPath];
            } else {
                //NSLog(@"VALID image for user %@. Created %@ - Now %@", conversation.conversWith, cached_image_wrap.createdTime, [[NSDate alloc] init]);
            }
        }
    }
    //    else {
    //        cell = [self.tableView dequeueReusableCellWithIdentifier:@"UserCell"];
    //    }
    else if (indexPath.section == 1 && self.allUsers.count > 0) {
        // show recents
        long userIndex = indexPath.row;
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"UserCell"];
        ChatUser *user = [self.allUsers objectAtIndex:userIndex];
        
        [self setupUserLabel:user cell:cell];
        
        // USER IMAGE
        UIImageView *image_view = (UIImageView *)[cell viewWithTag:1];
        NSString *imageURL = @""; //[SHPUser photoUrlByUsername:user.userId];
        ChatImageWrapper *cached_image_wrap = (ChatImageWrapper *)[self.imageCache getImage:imageURL];
        UIImage *user_image = cached_image_wrap.image;
        if(!cached_image_wrap) { // user_image == nil if image saving gone wrong!
            //NSLog(@"USER %@ IMAGE NOT CACHED. DOWNLOADING...", conversation.conversWith);
            [self startIconDownload:user.userId forIndexPath:indexPath];
            // if a download is deferred or in progress, return a placeholder image
            UIImage *circled = [SHPImageUtil circleImage:[UIImage imageNamed:@"avatar"]];
            image_view.image = circled;
        } else {
            //NSLog(@"USER IMAGE CACHED. %@", conversation.conversWith);
            image_view.image = [SHPImageUtil circleImage:user_image];
            // update too old images
            double now = [[NSDate alloc] init].timeIntervalSince1970;
            double reload_timer_secs = 86400; // one day
            if (now - cached_image_wrap.createdTime.timeIntervalSince1970 > reload_timer_secs) {
                //NSLog(@"EXPIRED image for user %@. Created: %@ - Now: %@. Reloading...", conversation.conversWith, cached_image_wrap.createdTime, [[NSDate alloc] init]);
                [self startIconDownload:user.userId forIndexPath:indexPath];
            } else {
                //NSLog(@"VALID image for user %@. Created %@ - Now %@", conversation.conversWith, cached_image_wrap.createdTime, [[NSDate alloc] init]);
            }
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSInteger userIndex = indexPath.row;
    ChatUser *selectedUser = nil;
    if (self.synchronizing) {
        return;
    }
    else if (self.users) {
        selectedUser = [self.users objectAtIndex:userIndex];
    }
    else if (indexPath.section == 0){
        selectedUser = [self.recentUsers objectAtIndex:userIndex];
    }
    else if (indexPath.section == 1) {
        selectedUser = [self.allUsers objectAtIndex:userIndex];
    }
    
    if (self.group) {
        if (![self.group isMember:selectedUser.userId]) {
            NSLog(@"Just in this group!");
            [self addUserToGroup:selectedUser];
        }
    } else {
        [self selectUser:selectedUser];
    }
}

-(void)setupUserLabel:(ChatUser *)user cell:(UITableViewCell *)cell {
    UILabel *fullnameLabel = (UILabel *) [cell viewWithTag:2];
    UILabel *usernameLabel = (UILabel *) [cell viewWithTag:3];
    if (self.group && [self.group isMember:user.userId]) {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        fullnameLabel.textColor = [UIColor grayColor];
        usernameLabel.textColor = [UIColor grayColor];
        fullnameLabel.text = [user fullname];
        usernameLabel.text = NSLocalizedString(@"Just in group", nil);
    } else {
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        fullnameLabel.textColor = [UIColor blackColor];
        usernameLabel.textColor = [UIColor blackColor];
        fullnameLabel.text = user.fullname;
        usernameLabel.text = user.userId;
    }
}

-(void)addUserToGroup:(ChatUser *)selectedUser {
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Add user to group", nil), selectedUser.fullname, self.group.name];
    
    UIAlertController *view = [UIAlertController
                               alertControllerWithTitle:message
                               message:nil
                               preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *confirm = [UIAlertAction
                              actionWithTitle:NSLocalizedString(@"Add", nil)
                              style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction * action)
                              {
                                  [self selectUser:selectedUser];
                              }];
    
    UIAlertAction *cancel = [UIAlertAction
                             actionWithTitle:NSLocalizedString(@"CancelLKey", nil)
                             style:UIAlertActionStyleDefault
                             handler:nil];
    
    [view addAction:confirm];
    [view addAction:cancel];
    
    [self presentViewController:view animated:YES completion:nil];
}

-(void)selectUser:(ChatUser *)selectedUser {
    [self updateRecentUsersWith:selectedUser];
    [self saveRecents];
    NSMutableDictionary *options = [[NSMutableDictionary alloc] init];
    [options setObject:selectedUser forKey:@"user"];
    [self.view endEditing:YES];
    [self.modalCallerDelegate setupViewController:self didFinishSetupWithInfo:options];
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

// UISEARCHBAR DELEGATE

- (void)searchBarTextDidBeginEditing:(UISearchBar *)_searchBar {
    NSLog(@"start editing.");
}

//- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
//    NSLog(@"SEARCH BUTTON PRESSED!");
//}

//-(void)searchBar:(UISearchBar *)_searchBar textDidChange:(NSString *)text {
-(void)searchBar:(UISearchBar*)_searchBar textDidChange:(NSString*)text {
    NSLog(@"_searchBar textDidChange");
//    [self.currentRequest cancel];
    if (self.searchTimer) {
        if ([self.searchTimer isValid]) {
            [self.searchTimer invalidate];
        }
        self.searchTimer = nil;
    }
//    NSString *preparedText = [text stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    self.searchTimer = [NSTimer scheduledTimerWithTimeInterval:0.0 target:self selector:@selector(userPaused:) userInfo:nil repeats:NO];
//    if (![preparedText isEqualToString:@""]) {
//        self.searchTimer = [NSTimer scheduledTimerWithTimeInterval:0.0 target:self selector:@selector(userPaused:) userInfo:nil repeats:NO];
//    } else {
//        // test reset. show "recents" (when supported) or nothing
//        NSLog(@"show recents...");
//        self.users = nil;
//        [self.tableView reloadData];
//    }
}

-(void)userPaused:(NSTimer *)timer {
    if (self.searchTimer) {
        if ([self.searchTimer isValid]) {
            [self.searchTimer invalidate];
        }
        self.searchTimer = nil;
    }
    [self search];
    //    dispatch_queue_t serialDatabaseQueue;
    //    serialDatabaseQueue = dispatch_queue_create("db.sqllite", DISPATCH_QUEUE_SERIAL);
    //    NSLog(@"search queue %@", serialDatabaseQueue);
    //    dispatch_async(serialDatabaseQueue, ^{
    //    });
    
//    AlfrescoUsersDC *service = [[AlfrescoUsersDC alloc] init];
//    self.currentRequest = [service usersByText:self.textToSearch completion:^(NSArray<SHPUser *> *users) {
//        NSLog(@"USERS LOADED OK!");
//        self.users = users;
//        [self.tableView reloadData];
//    }];
}

-(void)search {
    NSLog(@"(SHPSearchViewController) userPaused:");
    NSString *text = self.searchBar.text;
    self.textToSearch = [self prepareTextToSearch:text];
    NSLog(@"timer on userPaused: searching for %@", self.textToSearch);
    ContactsDB *db = [ContactsDB getSharedInstance];
    [db searchContactsByFullnameSynchronized:self.textToSearch completion:^(NSArray<ChatUser *> *users) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"USERS LOADED! %lu", (unsigned long)users.count);
            self.users = users;
            [self.tableView reloadData];
        });
    }];
}

-(NSString *)prepareTextToSearch:(NSString *)text {
    return [text stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
}
// DC delegate

//- (void)usersDidLoad:(NSArray *)__users usersDC:usersDC error:(NSError *)error {
//    NSLog(@"USERS LOADED OK!");
//    if (error) {
//        NSLog(@"Error loading users!");
//    }
//    if (usersDC == self.userDC) {
//        self.users = __users;
//        [self.tableView reloadData];
//    } else {
//        self.allUsers = [__users mutableCopy];
//        [self saveAllUsers];
//        [self.tableView reloadData];
//    }
//
//}

-(void)networkError {
    NSString *title = NSLocalizedString(@"NetworkErrorTitle", nil);
    NSString *msg = NSLocalizedString(@"NetworkError", nil);
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
}


// dismiss modal

- (IBAction)CancelAction:(id)sender {
    NSLog(@"dismissing %@", self.modalCallerDelegate);
    [contacts removeSynchSubcriber:self];
    [self disposeResources];
    [self.view endEditing:YES];
    [self.modalCallerDelegate setupViewController:self didCancelSetupWithInfo:nil];
}

// IMAGE HANDLING

-(void)terminatePendingImageConnections {
    NSLog(@"''''''''''''''''''''''   Terminate all pending IMAGE connections...");
    NSArray *allDownloads = [self.imageDownloadsInProgress allValues];
    NSLog(@"total downloads: %ld", (long)allDownloads.count);
    for(SHPImageDownloader *obj in allDownloads) {
        obj.delegate = nil;
    }
    [allDownloads makeObjectsPerformSelector:@selector(cancelDownload)];
}

- (void)startIconDownload:(NSString *)username forIndexPath:(NSIndexPath *)indexPath
{
    NSString *imageURL = @""; //[SHPUser photoUrlByUsername:username];
    //    NSLog(@"START DOWNLOADING IMAGE: %@ imageURL: %@", username, imageURL);
    SHPImageDownloader *iconDownloader = [self.imageDownloadsInProgress objectForKey:imageURL];
    //    NSLog(@"IconDownloader..%@", iconDownloader);
    if (iconDownloader == nil)
    {
        iconDownloader = [[SHPImageDownloader alloc] init];
        NSMutableDictionary *options = [[NSMutableDictionary alloc] init];
        [options setObject:indexPath forKey:@"indexPath"];
        iconDownloader.options = options;
        iconDownloader.imageURL = imageURL;
        iconDownloader.delegate = self;
        [self.imageDownloadsInProgress setObject:iconDownloader forKey:imageURL];
        [iconDownloader startDownload];
    }
}

//- (void)startIconDownload:(SHPUser *)user forIndexPath:(NSIndexPath *)indexPath
//{
//    NSString *imageURL = [SHPUser photoUrlByUsername:user.username];
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

// called by our ImageDownloader when an icon is ready to be displayed
- (void)appImageDidLoad:(UIImage *)image withURL:(NSString *)imageURL downloader:(SHPImageDownloader *)downloader
{
    image = [SHPImageUtil circleImage:image];
    [self.imageCache addImage:image withKey:imageURL];
    NSDictionary *options = downloader.options;
    NSIndexPath *indexPath = [options objectForKey:@"indexPath"];
    // if the cell for the image is visible updates the cell
    NSArray *indexes = [self.tableView indexPathsForVisibleRows];
    for (NSIndexPath *index in indexes) {
        if (index.row == indexPath.row && index.section == indexPath.section) {
            UITableViewCell *cell = [(UITableView *)self.tableView cellForRowAtIndexPath:index];
            UIImageView *iv = (UIImageView *)[cell viewWithTag:1];
            iv.image = image;
        }
    }
    [self.imageDownloadsInProgress removeObjectForKey:imageURL];
}

// all users

static NSString* const chatAllUsers = @"chatAllUsers";

-(void)saveAllUsers {
    [SHPCaching saveArray:self.allUsers inFile:chatAllUsers];
}

-(void)deleteAllUsers {
    [SHPCaching deleteFile:chatAllUsers];
}

-(void)restoreAllUsers {
    self.allUsers = [SHPCaching restoreArrayFromFile:chatAllUsers];
    if (!self.allUsers) {
        self.allUsers = [[NSMutableArray alloc] init];
    }
}

// recent users

static NSString* const chatRecentUsers = @"chatRecentUsers";

-(void)saveRecents {
    [SHPCaching saveArray:self.recentUsers inFile:chatRecentUsers];
}

-(void)deleteRecents {
    [SHPCaching deleteFile:chatRecentUsers];
}

-(void)restoreRecents {
    self.recentUsers = [SHPCaching restoreArrayFromFile:chatRecentUsers];
    if (!self.recentUsers) {
        self.recentUsers = [[NSMutableArray alloc] init];
    }
}

-(void)updateRecentUsersWith:(ChatUser *)user {
    NSLog(@"............ADDING.... user %@", user.userId);
    //    for (SHPUser *u in self.recentUsers) {
    //        NSLog(@"recent-user %@", u.username);
    //    }
    //    BOOL found = NO;
    int index = 0;
    for (ChatUser *u in self.recentUsers) {
        if([u.userId isEqualToString: user.userId]) {
            //            found = YES;
            NSLog(@"Found this user AT INDEX %d. Removing.", index);
            [self.recentUsers removeObjectAtIndex:index];
            break;
        }
        index++;
    }
    //    if (!found) {
    NSLog(@"user NOT FOUND, adding on top");
    [self.recentUsers insertObject:user atIndex:0];
    //    }
    //    NSLog(@"AFTER");
    //    for (SHPUser *u in self.recentUsers) {
    //        NSLog(@"recent-user %@", u.username);
    //    }
}

//-(void)loadAllUsers {
//    NSLog(@"Loading all users base...");
//    NSString *text = @"*";
//
//    self.firstUsersDC = [[ChatUsersDC alloc] init];
//    self.firstUsersDC.delegate = self;
//    [self.firstUsersDC findByText:text page:0 pageSize:40 withUser:self.applicationContext.loggedUser];
//}

// scroll delegate

// Somewhere in your implementation file:
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.view endEditing:YES];
    //    NSLog(@"Will begin dragging");
}

//- (void)scrollViewDidScroll:(UIScrollView *)scrollView
//{
//    NSLog(@"Did Scroll");
//}

// end

-(void)dealloc {
    NSLog(@"SEARCH USERS VIEW DEALLOCATING...");
}

@end

