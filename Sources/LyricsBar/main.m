#import <AppKit/AppKit.h>

@interface LyricLine : NSObject
@property double time;
@property(copy) NSString *text;
@end
@implementation LyricLine @end

@interface Overlay : NSObject
@property NSWindow *window;
@property NSTextField *current;
@property NSTextField *next;
- (void)show:(NSString *)text next:(NSString *)next;
- (void)reposition;
@end

@implementation Overlay
- (instancetype)init {
    if ((self = [super init])) {
        NSRect rect = NSMakeRect(0, 0, 260, 26);
        _window = [[NSWindow alloc] initWithContentRect:rect styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:NO];
        _window.level = NSStatusWindowLevel + 1;
        _window.backgroundColor = NSColor.clearColor;
        _window.opaque = NO; _window.hasShadow = NO; _window.ignoresMouseEvents = YES;
        _window.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorStationary | NSWindowCollectionBehaviorFullScreenAuxiliary;
        NSVisualEffectView *view = [[NSVisualEffectView alloc] initWithFrame:NSMakeRect(0, 0, 260, 26)];
        view.material = NSVisualEffectMaterialHUDWindow; view.blendingMode = NSVisualEffectBlendingModeBehindWindow; view.state = NSVisualEffectStateActive;
        view.wantsLayer = YES; view.layer.cornerRadius = 8;
        _current = [NSTextField labelWithString:@"打开 Apple Music 并播放歌曲"];
        _next = [NSTextField labelWithString:@""];
        for (NSTextField *label in @[_current, _next]) {
            label.alignment = NSTextAlignmentCenter; label.lineBreakMode = NSLineBreakByTruncatingTail;
            label.textColor = NSColor.whiteColor; label.translatesAutoresizingMaskIntoConstraints = NO; [view addSubview:label];
        }
        _current.font = [NSFont systemFontOfSize:12 weight:NSFontWeightMedium];
        _next.hidden = YES;
        [NSLayoutConstraint activateConstraints:@[
            [_current.leadingAnchor constraintEqualToAnchor:view.leadingAnchor constant:8],
            [_current.trailingAnchor constraintEqualToAnchor:view.trailingAnchor constant:-8],
            [_current.centerYAnchor constraintEqualToAnchor:view.centerYAnchor]
        ]];
        _window.contentView = view; [self reposition]; [_window orderFrontRegardless];
    }
    return self;
}
- (void)reposition {
    NSScreen *s = NSScreen.mainScreen;
    if (!s) return;
    // Use macOS's actual notch-safe rectangle instead of guessing the notch width.
    // This keeps the entire lyric window inside the unobstructed area to its left.
    NSRect leftSafeArea = s.auxiliaryTopLeftArea;
    CGFloat x;
    if (!NSIsEmptyRect(leftSafeArea) && NSWidth(leftSafeArea) >= NSWidth(_window.frame) + 12) {
        x = NSMaxX(leftSafeArea) - NSWidth(_window.frame) - 12;
    } else {
        x = NSMidX(s.frame) - NSWidth(_window.frame) - 96;
    }
    // visibleFrame also excludes the Dock, so using its height pushed the window
    // below the menu bar. safeAreaInsets.top is the actual notch/menu-bar band.
    CGFloat menuHeight = s.safeAreaInsets.top;
    if (menuHeight < 26) menuHeight = NSStatusBar.systemStatusBar.thickness;
    menuHeight = MAX(26, menuHeight);
    CGFloat y = NSMaxY(s.frame) - menuHeight + (menuHeight - NSHeight(_window.frame)) / 2;
    if (!NSIsEmptyRect(leftSafeArea)) y = NSMidY(leftSafeArea) - NSHeight(_window.frame) / 2;
    [_window setFrameOrigin:NSMakePoint(x, y)];
}
- (void)show:(NSString *)text next:(NSString *)next { _current.stringValue = text ?: @""; _next.stringValue = next ?: @""; }
@end

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property NSStatusItem *statusItem;
@property NSTimer *timer;
@property NSString *trackID;
@property NSArray<LyricLine *> *lines;
@property BOOL loading;
@property NSPanel *settingsPanel;
@property NSPopUpButton *fontPopup;
@property NSSlider *sizeSlider;
@property NSButton *boldCheck;
@property NSColorWell *colorWell;
@end

@implementation AppDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)n {
    _trackID = @""; _lines = @[];
    // A real status item is laid out by macOS, so it stays to the right of the
    // notch and participates in spacing with every other menu-bar item.
    _statusItem = [NSStatusBar.systemStatusBar statusItemWithLength:NSVariableStatusItemLength];
    _statusItem.button.lineBreakMode = NSLineBreakByTruncatingTail;
    NSMenu *menu = [NSMenu new];
    NSMenuItem *hint = [[NSMenuItem alloc] initWithTitle:@"歌词宽度会随内容和菜单栏空间自动调整" action:nil keyEquivalent:@""];
    hint.enabled = NO; [menu addItem:hint]; [menu addItem:NSMenuItem.separatorItem];
    NSMenuItem *settings = [[NSMenuItem alloc] initWithTitle:@"字体设置…" action:@selector(openSettings:) keyEquivalent:@","];
    settings.target = self; [menu addItem:settings]; [menu addItem:NSMenuItem.separatorItem];
    NSMenuItem *quit = [[NSMenuItem alloc] initWithTitle:@"退出 LyricsBar" action:@selector(quit:) keyEquivalent:@"q"];
    quit.target = self; [menu addItem:quit]; _statusItem.menu = menu;
    [self tick:nil];
    _timer = [NSTimer scheduledTimerWithTimeInterval:.5 target:self selector:@selector(tick:) userInfo:nil repeats:YES];
}
- (NSArray<NSString *> *)nowPlaying {
    NSString *src = @"tell application \"Music\"\nif player state is stopped then return \"\"\nset s to ASCII character 30\nset t to name of current track\nset ar to artist of current track\nset al to album of current track\nset d to duration of current track\nset p to player position\nreturn t & s & ar & s & al & s & (d as text) & s & (p as text)\nend tell";
    NSDictionary *error = nil; NSAppleEventDescriptor *result = [[[NSAppleScript alloc] initWithSource:src] executeAndReturnError:&error];
    if (!result.stringValue.length) return nil;
    NSArray *parts = [result.stringValue componentsSeparatedByString:@"\x1e"];
    return parts.count == 5 ? parts : nil;
}
- (void)tick:(NSTimer *)timer {
    NSArray<NSString *> *t = [self nowPlaying];
    if (!t) { _trackID=@""; _lines=@[]; [self show:@"等待 Apple Music…"]; return; }
    double duration=t[3].doubleValue, position=t[4].doubleValue;
    NSString *identity=[NSString stringWithFormat:@"%@\x1f%@\x1f%.0f",t[0],t[1],duration];
    if (![identity isEqual:_trackID]) {
        _trackID=identity; _lines=@[]; [self show:[NSString stringWithFormat:@"%@ — %@",t[0],t[1]]];
        [self fetchTitle:t[0] artist:t[1] album:t[2] duration:duration identity:identity];
    }
    if (!_lines.count) { if (!_loading) [self show:[NSString stringWithFormat:@"%@ — %@",t[0],t[1]]]; return; }
    NSInteger idx=0; for (NSInteger i=0;i<_lines.count;i++) { if (_lines[i].time<=position+.15) idx=i; else break; }
    [self show:_lines[idx].text];
}
- (void)show:(NSString *)text {
    NSString *value = text.length ? text : @"♪";
    NSUserDefaults *d=NSUserDefaults.standardUserDefaults;
    CGFloat size=[d doubleForKey:@"fontSize"]; if (size<9) size=12;
    NSInteger style=[d integerForKey:@"fontStyle"];
    BOOL bold=[d objectForKey:@"fontBold"] ? [d boolForKey:@"fontBold"] : YES;
    NSFontWeight weight=bold ? NSFontWeightSemibold : NSFontWeightRegular;
    NSFont *font;
    if (style==1) font=[NSFont monospacedSystemFontOfSize:size weight:weight];
    else if (style==2) {
        NSFont *base=[NSFont systemFontOfSize:size weight:weight];
        NSFontDescriptor *rounded=[base.fontDescriptor fontDescriptorWithDesign:NSFontDescriptorSystemDesignRounded];
        font=rounded ? [NSFont fontWithDescriptor:rounded size:size] : base;
    }
    else if (style==3) font=[NSFont fontWithName:@"Songti SC" size:size] ?: [NSFont systemFontOfSize:size weight:weight];
    else font=[NSFont systemFontOfSize:size weight:weight];
    CGFloat r=[d objectForKey:@"colorR"] ? [d doubleForKey:@"colorR"] : 1;
    CGFloat g=[d objectForKey:@"colorG"] ? [d doubleForKey:@"colorG"] : 1;
    CGFloat b=[d objectForKey:@"colorB"] ? [d doubleForKey:@"colorB"] : 1;
    NSColor *color=[NSColor colorWithSRGBRed:r green:g blue:b alpha:1];
    NSDictionary *attrs=@{NSFontAttributeName:font, NSForegroundColorAttributeName:color};
    _statusItem.button.attributedTitle=[[NSAttributedString alloc] initWithString:value attributes:attrs];
    CGFloat natural = ceil([value sizeWithAttributes:attrs].width) + 18;
    NSScreen *screen = NSScreen.mainScreen;
    CGFloat safeRightWidth = NSIsEmptyRect(screen.auxiliaryTopRightArea) ? 280 : NSWidth(screen.auxiliaryTopRightArea);
    // The item grows with short/long lyrics, but never claims more than about
    // half of the notch-safe right side. macOS handles the remaining items.
    CGFloat maximum = MIN(280, MAX(120, safeRightWidth * 0.48));
    _statusItem.length = MAX(72, MIN(natural, maximum));
    _statusItem.button.toolTip = value;
}
- (void)openSettings:(id)sender {
    if (!_settingsPanel) {
        _settingsPanel=[[NSPanel alloc] initWithContentRect:NSMakeRect(0,0,360,240) styleMask:NSWindowStyleMaskTitled|NSWindowStyleMaskClosable backing:NSBackingStoreBuffered defer:NO];
        _settingsPanel.title=@"LyricsBar 字体设置"; _settingsPanel.releasedWhenClosed=NO;
        NSView *view=_settingsPanel.contentView;
        NSTextField *(^label)(NSString *) = ^NSTextField *(NSString *s) { NSTextField *l=[NSTextField labelWithString:s]; l.alignment=NSTextAlignmentRight; return l; };
        _fontPopup=[[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
        [_fontPopup addItemsWithTitles:@[@"系统字体",@"等宽字体",@"圆体",@"宋体"]];
        _sizeSlider=[NSSlider sliderWithValue:12 minValue:9 maxValue:18 target:self action:@selector(fontSettingChanged:)];
        _sizeSlider.numberOfTickMarks=10; _sizeSlider.allowsTickMarkValuesOnly=YES;
        _boldCheck=[NSButton checkboxWithTitle:@"半粗体" target:self action:@selector(fontSettingChanged:)];
        _colorWell=[[NSColorWell alloc] initWithFrame:NSZeroRect]; _colorWell.target=self; _colorWell.action=@selector(fontSettingChanged:);
        _fontPopup.target=self; _fontPopup.action=@selector(fontSettingChanged:);
        NSGridView *grid=[NSGridView gridViewWithViews:@[
            @[label(@"字体："),_fontPopup], @[label(@"字号："),_sizeSlider], @[label(@"粗细："),_boldCheck], @[label(@"颜色："),_colorWell]
        ]];
        grid.translatesAutoresizingMaskIntoConstraints=NO; grid.rowSpacing=14; grid.columnSpacing=12; [view addSubview:grid];
        NSTextField *note=[NSTextField wrappingLabelWithString:@"修改会立即应用并自动保存。长歌词仍会根据菜单栏可用宽度省略。"];
        note.textColor=NSColor.secondaryLabelColor; note.translatesAutoresizingMaskIntoConstraints=NO; [view addSubview:note];
        [NSLayoutConstraint activateConstraints:@[
            [grid.leadingAnchor constraintEqualToAnchor:view.leadingAnchor constant:28], [grid.trailingAnchor constraintEqualToAnchor:view.trailingAnchor constant:-28], [grid.topAnchor constraintEqualToAnchor:view.topAnchor constant:24],
            [note.leadingAnchor constraintEqualToAnchor:view.leadingAnchor constant:28], [note.trailingAnchor constraintEqualToAnchor:view.trailingAnchor constant:-28], [note.topAnchor constraintEqualToAnchor:grid.bottomAnchor constant:18]
        ]];
    }
    NSUserDefaults *d=NSUserDefaults.standardUserDefaults; CGFloat size=[d doubleForKey:@"fontSize"]; if(size<9)size=12;
    [_fontPopup selectItemAtIndex:[d integerForKey:@"fontStyle"]]; _sizeSlider.doubleValue=size;
    _boldCheck.state=(![d objectForKey:@"fontBold"]||[d boolForKey:@"fontBold"]) ? NSControlStateValueOn:NSControlStateValueOff;
    CGFloat r=[d objectForKey:@"colorR"]?[d doubleForKey:@"colorR"]:1, g=[d objectForKey:@"colorG"]?[d doubleForKey:@"colorG"]:1, b=[d objectForKey:@"colorB"]?[d doubleForKey:@"colorB"]:1;
    _colorWell.color=[NSColor colorWithSRGBRed:r green:g blue:b alpha:1];
    [_settingsPanel center]; [_settingsPanel makeKeyAndOrderFront:nil]; [NSApp activateIgnoringOtherApps:YES];
}
- (void)fontSettingChanged:(id)sender {
    NSUserDefaults *d=NSUserDefaults.standardUserDefaults; [d setInteger:_fontPopup.indexOfSelectedItem forKey:@"fontStyle"]; [d setDouble:_sizeSlider.doubleValue forKey:@"fontSize"]; [d setBool:_boldCheck.state==NSControlStateValueOn forKey:@"fontBold"];
    NSColor *c=[_colorWell.color colorUsingColorSpace:NSColorSpace.sRGBColorSpace]; [d setDouble:c.redComponent forKey:@"colorR"]; [d setDouble:c.greenComponent forKey:@"colorG"]; [d setDouble:c.blueComponent forKey:@"colorB"];
    [self show:_statusItem.button.toolTip ?: @"♪"];
}
- (void)fetchTitle:(NSString *)title artist:(NSString *)artist album:(NSString *)album duration:(double)duration identity:(NSString *)identity {
    _loading=YES; NSURLComponents *c=[NSURLComponents componentsWithString:@"https://lrclib.net/api/get"];
    c.queryItems=@[[NSURLQueryItem queryItemWithName:@"track_name" value:title], [NSURLQueryItem queryItemWithName:@"artist_name" value:artist], [NSURLQueryItem queryItemWithName:@"album_name" value:album], [NSURLQueryItem queryItemWithName:@"duration" value:[NSString stringWithFormat:@"%.0f",duration]]];
    NSMutableURLRequest *req=[NSMutableURLRequest requestWithURL:c.URL]; [req setValue:@"LyricsBar/1.0 (macOS)" forHTTPHeaderField:@"User-Agent"];
    [[[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSArray *parsed=@[];
        if (data) {
            NSDictionary *json=[NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if ([json[@"syncedLyrics"] isKindOfClass:NSString.class]) parsed=[self parseLRC:json[@"syncedLyrics"]];
        }
        if (parsed.count) [self finishLyrics:parsed identity:identity];
        else [self searchTitle:title artist:artist duration:duration identity:identity];
    }] resume];
}
- (NSString *)cleanTitle:(NSString *)title {
    // Apple Music often appends edition metadata that is absent from LRCLIB.
    NSRegularExpression *re=[NSRegularExpression regularExpressionWithPattern:@"\\s*[\\(\\[][^\\)\\]]*(remaster|live|version|edit|mix|deluxe|bonus|from |soundtrack|acoustic|radio)[^\\)\\]]*[\\)\\]]" options:NSRegularExpressionCaseInsensitive error:nil];
    NSString *clean=[re stringByReplacingMatchesInString:title options:0 range:NSMakeRange(0,title.length) withTemplate:@""];
    NSRegularExpression *dash=[NSRegularExpression regularExpressionWithPattern:@"\\s+[-–—]\\s+.*(remaster|live|version|edit|mix|acoustic).*$" options:NSRegularExpressionCaseInsensitive error:nil];
    clean=[dash stringByReplacingMatchesInString:clean options:0 range:NSMakeRange(0,clean.length) withTemplate:@""];
    return [clean stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
}
- (void)searchTitle:(NSString *)title artist:(NSString *)artist duration:(double)duration identity:(NSString *)identity {
    NSURLComponents *c=[NSURLComponents componentsWithString:@"https://lrclib.net/api/search"];
    c.queryItems=@[[NSURLQueryItem queryItemWithName:@"track_name" value:[self cleanTitle:title]], [NSURLQueryItem queryItemWithName:@"artist_name" value:artist]];
    NSMutableURLRequest *req=[NSMutableURLRequest requestWithURL:c.URL]; [req setValue:@"LyricsBar/1.1 (macOS)" forHTTPHeaderField:@"User-Agent"];
    [[[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSArray *results=data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
        NSDictionary *best=nil; double bestScore=DBL_MAX;
        if ([results isKindOfClass:NSArray.class]) for (NSDictionary *item in results) {
            if (![item[@"syncedLyrics"] isKindOfClass:NSString.class] || ![item[@"syncedLyrics"] length]) continue;
            NSString *candidateArtist=[item[@"artistName"] description];
            NSString *candidateTitle=[item[@"trackName"] description];
            double difference=fabs([item[@"duration"] doubleValue]-duration);
            double score=difference;
            if ([candidateArtist rangeOfString:artist options:NSCaseInsensitiveSearch].location==NSNotFound && [artist rangeOfString:candidateArtist options:NSCaseInsensitiveSearch].location==NSNotFound) score+=120;
            NSString *clean=[self cleanTitle:title];
            if ([candidateTitle compare:clean options:NSCaseInsensitiveSearch]!=NSOrderedSame) score+=20;
            if (score<bestScore) { bestScore=score; best=item; }
        }
        // Reject clearly unrelated search results, even when they contain lyrics.
        NSArray *parsed=(best && bestScore<150) ? [self parseLRC:best[@"syncedLyrics"]] : @[];
        [self finishLyrics:parsed identity:identity];
    }] resume];
}
- (void)finishLyrics:(NSArray *)parsed identity:(NSString *)identity {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.loading=NO;
        if ([self.trackID isEqual:identity]) self.lines=parsed;
    });
}
- (NSArray<LyricLine *> *)parseLRC:(NSString *)lrc {
    NSRegularExpression *re=[NSRegularExpression regularExpressionWithPattern:@"\\[(\\d+):(\\d+(?:\\.\\d+)?)\\]" options:0 error:nil]; NSMutableArray *out=[NSMutableArray array];
    for (NSString *line in [lrc componentsSeparatedByCharactersInSet:NSCharacterSet.newlineCharacterSet]) {
        NSArray<NSTextCheckingResult *> *matches=[re matchesInString:line options:0 range:NSMakeRange(0,line.length)]; if (!matches.count) continue;
        NSTextCheckingResult *last=matches.lastObject; NSString *text=[[line substringFromIndex:NSMaxRange(last.range)] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet]; if (!text.length) continue;
        for (NSTextCheckingResult *m in matches) { LyricLine *item=[LyricLine new]; item.time=[[line substringWithRange:[m rangeAtIndex:1]] doubleValue]*60+[[line substringWithRange:[m rangeAtIndex:2]] doubleValue]; item.text=text; [out addObject:item]; }
    }
    [out sortUsingComparator:^NSComparisonResult(LyricLine *a,LyricLine *b){ return a.time<b.time?NSOrderedAscending:(a.time>b.time?NSOrderedDescending:NSOrderedSame); }]; return out;
}
- (void)quit:(id)sender { [NSApp terminate:nil]; }
@end

int main(int argc, const char *argv[]) { @autoreleasepool { NSApplication *app=NSApplication.sharedApplication; AppDelegate *delegate=[AppDelegate new]; app.delegate=delegate; [app setActivationPolicy:NSApplicationActivationPolicyAccessory]; [app run]; } return 0; }
