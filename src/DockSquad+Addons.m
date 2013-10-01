#import "DockEquippedShip+Addons.h"
#import "DockEquippedUpgrade+Addons.h"
#import "DockResource.h"
#import "DockShip+Addons.h"
#import "DockSquad+Addons.h"
#import "DockUpgrade+Addons.h"

@implementation DockSquad (Addons)

+(NSSet*)keyPathsForValuesAffectingCost
{
    return [NSSet setWithObjects: @"equippedShips", @"resource", nil];
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    [self squadCompositionChanged];
}

-(void)watchForCostChange
{
    for (DockEquippedShip* es in self.equippedShips) {
        [es addObserver: self forKeyPath: @"cost" options: 0 context: 0];
    }
}

-(void)awakeFromInsert
{
    [super awakeFromInsert];
    [self watchForCostChange];
}

-(void)awakeFromFetch
{
    [super awakeFromFetch];
    [self watchForCostChange];
}

-(void)addEquippedShip:(DockEquippedShip*)ship
{
    [self willChangeValueForKey: @"cost"];
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet: self.equippedShips];
    [tempSet addObject: ship];
    self.equippedShips = tempSet;
    [self didChangeValueForKey: @"cost"];
    [ship addObserver: self forKeyPath: @"cost" options: 0 context: 0];
}

-(void)removeEquippedShip:(DockEquippedShip*)ship
{
    [self willChangeValueForKey: @"cost"];
    NSMutableOrderedSet* tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet: [self mutableOrderedSetValueForKey: @"equippedShips"]];
    NSUInteger idx = [tmpOrderedSet indexOfObject: ship];

    if (idx != NSNotFound) {
        NSIndexSet* indexes = [NSIndexSet indexSetWithIndex: idx];
        [self willChange: NSKeyValueChangeRemoval valuesAtIndexes: indexes forKey: @"equippedShips"];
        [tmpOrderedSet removeObject: ship];
        [self setPrimitiveValue: tmpOrderedSet forKey: @"equippedShips"];
        [self didChange: NSKeyValueChangeRemoval valuesAtIndexes: indexes forKey: @"equippedShips"];
    }

    [ship removeObserver:  self forKeyPath: @"cost"];
    [self didChangeValueForKey: @"cost"];
}

-(int)cost
{
    int cost = 0;

    for (DockEquippedShip* ship in self.equippedShips) {
        cost += [ship cost];
    }

    if (self.resource != nil) {
        cost += [self.resource.cost intValue];
    }

    return cost;
}

-(void)squadCompositionChanged
{
    [self willChangeValueForKey: @"cost"];
    [self didChangeValueForKey: @"cost"];
}

-(NSString*)asTextFormat
{
    NSMutableString* textFormat = [[NSMutableString alloc] init];
    NSString* header = [NSString stringWithFormat: @"Type    %@ %@  %@\n", [@"Card Title" stringByPaddingToLength : 40 withString : @" " startingAtIndex : 0], @"Faction", @"SP"];
    [textFormat appendString: header];
    int i = 1;

    for (DockEquippedShip* ship in self.equippedShips) {
        NSString* s = [NSString stringWithFormat: @"Ship %d  %@ %1@  %5d\n", i, [ship.title stringByPaddingToLength: 43 withString: @" " startingAtIndex: 0], [ship.ship.faction substringToIndex: 1], [ship.ship.cost intValue]];
        [textFormat appendString: s];

        for (DockEquippedUpgrade* upgrade in ship.sortedUpgrades) {
            if (![upgrade isPlaceholder]) {

                if ([upgrade.upgrade isCaptain]) {
                    s = [NSString stringWithFormat: @" Cap    %@ %1@  %5d\n", [upgrade.title stringByPaddingToLength: 43 withString: @" " startingAtIndex: 0], [upgrade.faction substringToIndex: 1], upgrade.cost];
                } else {
                    s = [NSString stringWithFormat: @"  %@     %@ %1@  %5d\n", [upgrade typeCode], [upgrade.title stringByPaddingToLength: 43 withString: @" " startingAtIndex: 0], [upgrade.faction substringToIndex: 1], upgrade.cost];
                }

                [textFormat appendString: s];
            }
        }
        s = [NSString stringWithFormat: @"                                                 Total %5d\n", ship.cost];
        [textFormat appendString: s];
        [textFormat appendString: @"\n"];
        i += 1;
    }
    DockResource* resource = self.resource;

    if (resource != nil) {
        NSString* resourceString = [NSString stringWithFormat: @"Resource: %@     %5d\n",
                                    [resource.title stringByPaddingToLength: 40 withString: @" " startingAtIndex: 0],
                                    [resource.cost intValue]];
        [textFormat appendString: resourceString];
    }

    [textFormat appendString: [NSString stringWithFormat: @"\nTotal Build: %d\n", self.cost]];
    return [NSString stringWithString: textFormat];
}

@end
