#import "DockInspector.h"

#import "DockAppDelegate.h"
#import "DockEquippedUpgrade+Addons.h"
#import "DockEquippedShip+Addons.h"
#import "DockShip+Addons.h"
#import "DockUpgrade+Addons.h"

@implementation DockInspector

static id extractSelectedItem(id controller)
{
    NSArray* selectedItems = [controller selectedObjects];
    if (selectedItems.count > 0) {
        return selectedItems[0];
    }
    return nil;
}

-(void)updateInspectorTabForItem:(id)selectedItem changeTab:(BOOL)changeTab
{
    if ([selectedItem isMemberOfClass: [DockEquippedShip class]]) {
        self.currentShip = [selectedItem ship];
        [_tabView selectTabViewItemWithIdentifier: @"ship"];
    } else if ([selectedItem isMemberOfClass: [DockEquippedUpgrade class]]) {
        DockUpgrade* upgrade = [selectedItem upgrade];
        if ([upgrade isCaptain]) {
            self.currentCaptain = (DockCaptain*)upgrade;
            if (changeTab) {
                [_tabView selectTabViewItemWithIdentifier: @"captain"];
            }
        } else if ([upgrade isPlaceholder]) {
            if (changeTab) {
                [_tabView selectTabViewItemWithIdentifier: @"blank"];
            }
       } else {
            self.currentUpgrade = upgrade;
            if (changeTab) {
                [_tabView selectTabViewItemWithIdentifier: @"upgrade"];
            }
        }
    }
}

-(void)updateInspectorTabForItem:(id)selectedItem
{
    [self updateInspectorTabForItem: selectedItem changeTab: NO];
}

-(void)observeValueForKeyPath:(NSString*)keyPath
                     ofObject:(id)object
                       change:(NSDictionary*)change
                      context:(void*)context
{
    id responder = [_mainWindow firstResponder];
    NSString* ident = [responder identifier];
    if (object == _mainWindow) {
        if ([ident isEqualToString: @"captainsTable"]) {
            self.currentCaptain = extractSelectedItem(_captains);
            [_tabView selectTabViewItemWithIdentifier: @"captain"];
        } else if ([ident isEqualToString: @"upgradeTable"]) {
            self.currentUpgrade = extractSelectedItem(_upgrades);
            [_tabView selectTabViewItemWithIdentifier: @"upgrade"];
        } else if ([ident isEqualToString: @"shipsTable"]) {
            self.currentShip = extractSelectedItem(_ships);
            [_tabView selectTabViewItemWithIdentifier: @"ship"];
        } else if ([ident isEqualToString: @"resourcesTable"]) {
            self.currentResource = extractSelectedItem(_resources);
            [_tabView selectTabViewItemWithIdentifier: @"resource"];
        } else if ([ident isEqualToString: @"squadsDetailOutline"]) {
            id selectedItem = extractSelectedItem(_squadDetail);
            [self updateInspectorTabForItem: selectedItem];
        } else {
            [_tabView selectTabViewItemWithIdentifier: @"blank"];
        }
    } else if (object == _squadDetail) {
        if ([ident isEqualToString: @"squadsDetailOutline"]) {
            id selectedItem = extractSelectedItem(_squadDetail);
            [self updateInspectorTabForItem: selectedItem changeTab: YES];
        }
    } else if (object == _captains) {
        self.currentCaptain = extractSelectedItem(_captains);
    } else if (object == _ships) {
        self.currentShip = extractSelectedItem(_ships);
    } else if (object == _upgrades) {
        self.currentUpgrade = extractSelectedItem(_upgrades);
    } else if (object == _resources) {
        self.currentResource = extractSelectedItem(_resources);
    }
}

-(void)awakeFromNib
{
    [super awakeFromNib];
    [_inspector setFloatingPanel: YES];
    [_mainWindow addObserver: self forKeyPath: @"firstResponder" options: 0 context: 0];
    [_captains addObserver: self forKeyPath: @"selectionIndexes" options: 0 context: 0];
    [_ships addObserver: self forKeyPath: @"selectionIndexes" options: 0 context: 0];
    [_upgrades addObserver: self forKeyPath: @"selectionIndexes" options: 0 context: 0];
    [_resources addObserver: self forKeyPath: @"selectionIndexes" options: 0 context: 0];
    [_squadDetail addObserver: self forKeyPath: @"selectionIndexPath" options: 0 context: 0];
}

-(void)show
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool: YES forKey: kInspectorVisible];
    [_inspector orderFront: self];
}

- (BOOL)windowShouldClose:(id)sender
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool: NO forKey: kInspectorVisible];
    return YES;
}

@end