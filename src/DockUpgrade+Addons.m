#import "DockUpgrade+Addons.h"

#import "DockCaptain+Addons.h"
#import "DockComponent+Addons.h"
#import "DockConstants.h"
#import "DockEquippedShip+Addons.h"
#import "DockEquippedUpgrade+Addons.h"
#import "DockFlagship+Addons.h"
#import "DockFleetCaptain+Addons.h"
#import "DockResource.h"
#import "DockShip+Addons.h"
#import "DockSquad+Addons.h"
#import "DockTag+Addons.h"
#import "DockTagged+Addons.h"
#import "DockTagHandler.h"
#import "DockUtils.h"
#import "DockWeaponRange.h"

NSMutableDictionary* sPlaceholderCache = nil;

@implementation DockUpgrade (Addons)

+(NSSet*)allFactions:(NSManagedObjectContext*)context
{
    NSMutableSet* allFactionsSet = [[NSMutableSet alloc] initWithCapacity: 0];
    NSEntityDescription* entity = [NSEntityDescription entityForName: @"Upgrade" inManagedObjectContext: context];
    NSFetchRequest* request = [[NSFetchRequest alloc] init];
    [request setEntity: entity];
    NSError* err;
    NSArray* existingItems = [context executeFetchRequest: request error: &err];

    if (existingItems.count > 0) {
        for (DockUpgrade* upgrade in existingItems) {
            [allFactionsSet addObjectsFromArray: upgrade.factions.allObjects];
        }
        return [NSSet setWithSet: allFactionsSet];
    }

    return nil;
}

+(DockUpgrade*)upgradeForId:(NSString*)externalId context:(NSManagedObjectContext*)context
{
    NSEntityDescription* entity = [NSEntityDescription entityForName: @"Upgrade" inManagedObjectContext: context];
    NSFetchRequest* request = [[NSFetchRequest alloc] init];
    [request setEntity: entity];
    NSPredicate* predicateTemplate = [NSPredicate predicateWithFormat: @"externalId == %@", externalId];
    [request setPredicate: predicateTemplate];
    NSError* err;
    NSArray* existingItems = [context executeFetchRequest: request error: &err];

    if (existingItems.count > 0) {
        return existingItems[0];
    }

    return nil;
}

+(DockUpgrade*)placeholder:(NSString*)upType inContext:(NSManagedObjectContext*)context
{
    DockUpgrade* placeholderUpgrade = sPlaceholderCache[upType];
    if (placeholderUpgrade != nil) {
        return placeholderUpgrade;
    }
    NSEntityDescription* entity = [NSEntityDescription entityForName: @"Upgrade" inManagedObjectContext: context];
    NSFetchRequest* request = [[NSFetchRequest alloc] init];
    [request setEntity: entity];
    NSString* pair = [DockTag categoryTag: kDockTypeCategoryType value: upType];
    NSPredicate* predicateTemplate = [NSPredicate predicateWithFormat: @"tags.value == %@ && placeholder = YES" argumentArray: @[pair]];
    [request setPredicate: predicateTemplate];
    NSError* err;
    NSArray* existingItems = [context executeFetchRequest: request error: &err];

    if (existingItems.count == 0) {
        Class upClass = [DockUpgrade class];

        placeholderUpgrade = [[upClass alloc] initWithEntity: entity insertIntoManagedObjectContext: context];
        placeholderUpgrade.title = upType;
        placeholderUpgrade.upType = upType;
        placeholderUpgrade.placeholder = @YES;
    } else {
        placeholderUpgrade = existingItems[0];
    }

    if (placeholderUpgrade != nil) {
        if (sPlaceholderCache == nil) {
            sPlaceholderCache = [[NSMutableDictionary alloc] init];
        }
        sPlaceholderCache[upType] = placeholderUpgrade;
    }
    return placeholderUpgrade;
}

+(NSArray*)findUpgrades:(NSString*)title context:(NSManagedObjectContext*)context
{
    NSEntityDescription* entity = [NSEntityDescription entityForName: @"Upgrade" inManagedObjectContext: context];
    NSFetchRequest* request = [[NSFetchRequest alloc] init];
    [request setEntity: entity];
    NSPredicate* predicateTemplate = [NSPredicate predicateWithFormat: @"title like %@", title];
    [request setPredicate: predicateTemplate];
    NSError* err;
    return [context executeFetchRequest: request error: &err];
}

-(void)awakeFromFetch
{
    [self setSortString: [self upSortType]];
}

-(NSString*)plainDescription
{
    if ([self isPlaceholder]) {
        return self.title;
    }

    return [NSString stringWithFormat: @"%@ (%@)", self.title, self.upType];
}

-(NSString*)disambiguatedTitle
{
    NSString* externalId = self.externalId;

    if ([externalId isEqualToString: @"quark_71786"]) {
        return [NSString stringWithFormat: @"%@ (Tech)", self.title];
    }
    if ([externalId isEqualToString: @"quark_weapon_71786"]) {
        return [NSString stringWithFormat: @"%@ (Weapon)", self.title];
    }
    if ([externalId isEqualToString: @"vulcan_high_command_2_0_71446"]) {
        return [NSString stringWithFormat: @"%@ (2/0)", self.title];
    }
    if ([externalId isEqualToString: @"vulcan_high_command_1_1_71446"]) {
        return [NSString stringWithFormat: @"%@ (1/1)", self.title];
    }
    if ([externalId isEqualToString: @"vulcan_high_command_0_2_71446"]) {
        return [NSString stringWithFormat: @"%@ (0/2)", self.title];
    }
    return self.title;
}

-(BOOL)isTalent
{
    return [self hasType: @"Talent"];
}

-(BOOL)isCrew
{
    return [self hasType: @"Crew"];
}

-(BOOL)isWeapon
{
    return [self hasType: @"Weapon"];
}

-(BOOL)isCaptain
{
    return [self hasType: @"Captain"];
}

-(BOOL)isAdmiral
{
    return [self hasType: kAdmiralUpgradeType];
}

-(BOOL)isFleetCaptain
{
    return [self hasType: kFleetCaptainUpgradeType];
}

-(BOOL)isOfficer
{
    return [self hasType: kOfficerUpgradeType];
}

-(BOOL)isTech
{
    return [self hasType: @"Tech"];
}

-(BOOL)isBorg
{
    return [self hasType: @"Borg"];
}

-(BOOL)isPlaceholder
{
    return [[self placeholder] boolValue];
}

-(BOOL)isUnique
{
    return [[self unique] boolValue];
}

-(BOOL)isDominion
{
    return [self hasFaction: @"Dominion"];
}

-(BOOL)isKlingon
{
    return [self hasFaction: @"Klingon"];
}

-(BOOL)isBajoran
{
    return [self hasFaction: @"Bajoran"];
}

-(BOOL)isFederation
{
    return [self hasFaction: @"Federation"];
}

-(BOOL)isVulcan
{
    return [self hasFaction: @"Vulcan"];
}

-(BOOL)isFactionBorg
{
    return [self hasFaction: @"Borg"];
}

-(BOOL)isRestrictedOnlyByFaction
{
    NSString* upgradeId = self.externalId;

    if ([upgradeId isEqualToString: @"tholian_punctuality_opwebprize"] || [upgradeId isEqualToString: @"first_strike_3rd_wing_attack_ship"]) {
        return NO;
    }
    return YES;
}

-(BOOL)refersToShipOrShipClass
{
    NSSet* tags = self.tags;
    for (DockTag* tag in tags) {
        DockTagHandler* handler = [DockTagHandler restrictionHandlerForTag: tag.value];
        if (handler) {
            if (handler.refersToShipOrShipClass) {
                return YES;
            }
        }
    }

    NSSet* ineligibleTechUpgrades = [NSSet setWithArray: @[
                                                           @"OnlySpecies8472Ship",
                                                           @"PenaltyOnShipOtherThanKeldonClass",
                                                           @"OnlySpecies8472Ship",
                                                           @"OnlyForRomulanScienceVessel",
                                                           @"OnlyJemHadarShips",
                                                           ]];
    return [ineligibleTechUpgrades containsObject: self.special];
}

-(BOOL)isIndependent
{
    return [self hasFaction: @"Independent"];
}

-(NSComparisonResult)compareTo:(DockUpgrade*)other
{
    NSString* upTypeMe = [self sortString];
    NSString* upTypeOther = [other sortString];
    NSComparisonResult r = [upTypeMe compare: upTypeOther];

    if (r == NSOrderedSame) {
        BOOL selfIsPlaceholder = [self isPlaceholder];
        BOOL otherIsPlaceholder = [other isPlaceholder];

        if (selfIsPlaceholder == otherIsPlaceholder) {
            return [self.title caseInsensitiveCompare: other.title];
        }

        if (selfIsPlaceholder) {
            return NSOrderedDescending;
        }

        return NSOrderedAscending;
    }

    if ([upTypeMe isEqualToString: @"Captain"]) {
        return NSOrderedAscending;
    }

    if ([upTypeOther isEqualToString: @"Captain"]) {
        return NSOrderedDescending;
    }

    return r;
}

-(int)limitForShip:(DockEquippedShip*)targetShip
{
    if ([self isCaptain]) {
        return [targetShip captainCount];
    }

    if ([self isAdmiral]) {
        return [targetShip admiralCount];
    }

    if ([self isFleetCaptain]) {
        return [targetShip fleetCaptainCount];
    }

    if ([self isOfficer]) {
        return [targetShip officerLimit];
    }

    if ([self isTalent]) {
        return [targetShip talentCount];
    }

    if ([self isWeapon]) {
        return [targetShip weaponCount];
    }

    if ([self isCrew]) {
        return [targetShip crewCount];
    }

    if ([self isTech]) {
        return [targetShip techCount];
    }

    if ([self isBorg]) {
        return [targetShip borgCount];
    }

    return 0;
}

-(NSString*)upSortType
{
    if ([self isAdmiral]) {
        return @"AAAAAAdmiral";
    }

    if ([self isFleetCaptain]) {
        return @"AAAACaptain";
    }

    if ([self isCaptain]) {
        return @"AAACaptain";
    }

    if ([self isTalent]) {
        return @"AATalent";
    }

    return self.upType;
}

-(NSString*)sortStringForSet
{
    return [NSString stringWithFormat: @"%@:c:%@:%@", self.highestFaction, self.sortString, self.title];
}

-(NSString*)itemDescription
{
    return [NSString stringWithFormat: @"%@: %@", self.typeCode, self.title];
}

-(NSString*)typeCode
{
    if ([self isWeapon]) {
        return @"W";
    }

    if ([self isCrew]) {
        return @"C";
    }

    if ([self isTech]) {
        return @"T";
    }

    if ([self isTalent]) {
        return @"E";
    }

    if ([self isCaptain]) {
        return @"Cp";
    }

    if ([self isAdmiral]) {
        return @"A";
    }

    if ([self isBorg]) {
        return @"B";
    }

    if ([self isOfficer]) {
        return @"O";
    }

    return @"?";

}

-(NSString*)optionalAttack
{
    if ([self isWeapon]) {
        id attackValue = [self valueForKey: @"attack"];

        if ([attackValue intValue] > 0) {
            return attackValue;
        }
    }

    return nil;
}

-(NSString*)optionalRange
{
    if ([self isWeapon]) {
        id rangeValue = [self valueForKey: @"range"];

        if ([rangeValue length] > 0) {
            return rangeValue;
        }
    }

    return nil;
}

-(int)costForShip:(DockEquippedShip*)equippedShip
{
    return [self costForShip: equippedShip equippedUpgade: nil];
}

-(int)costForShip:(DockEquippedShip*)equippedShip equippedUpgade:(DockEquippedUpgrade*)equippedUpgrade
{
    DockUpgrade* upgrade = self;
    NSString* externalId = self.externalId;

    NSString* fleetCaptainSpecial = [[equippedShip.squad.equippedFleetCaptain upgrade] special];

    DockEquippedUpgrade* equippedOnThisShipFleetCaptain = [equippedShip equippedFleetCaptain];
    DockFleetCaptain* fleetCaptainOnThisShip = (DockFleetCaptain*)equippedOnThisShipFleetCaptain.upgrade;
    int fleetCaptainOnThisShipTalentCount = [[fleetCaptainOnThisShip talentAdd] intValue];

    if ([upgrade isPlaceholder]) {
        return 0;
    }

    if ([upgrade isFleetCaptain]) {
        return [[upgrade cost] intValue];
    }

    int originalCost = [upgrade.cost intValue];
    int cost = originalCost;
    
    cost += [DockTagHandler costAdjustment: upgrade onShip: equippedShip];

    DockShip* ship = equippedShip.ship;
    DockCaptain* captain = equippedShip.captain;
    BOOL isSideboard = [equippedShip isResourceSideboard];

    if ([upgrade isCaptain]) {
        captain = (DockCaptain*)upgrade;

        if ([captain isZeroCost]) {
            return 0;
        }
    }

    NSString* captainSpecial = captain.special;

    if ([upgrade isTalent]) {
        if (fleetCaptainOnThisShipTalentCount > 0) {
            NSArray* all = [equippedShip allUpgradesOfFaction: nil upType: @"Talent"];
            NSInteger talentCount = all.count;
            if (talentCount > 0) {
                NSInteger maxTalents = [equippedShip talentCount];
                if (talentCount < maxTalents) {
                    DockEquippedUpgrade* eu = all[0];
                    if (equippedUpgrade == eu) {
                        cost = 0;
                    }
                }
            }
        }
        if ([captainSpecial isEqualToString: @"BaselineTalentCostToThree"] && self.isFederation && !isSideboard) {
            cost = 3;
        }
    } else if ([upgrade isCrew]) {
        if (([captainSpecial isEqualToString: @"CrewUpgradesCostOneLess"] || [captainSpecial isEqualToString: @"hugh_71522"] ) && !isSideboard) {
            cost -= 1;
        }

        if ([fleetCaptainSpecial isEqualToString: @"CrewUpgradesCostOneLess"] && !isSideboard) {
            cost -= 1;
        }

    } else if ([upgrade isWeapon]) {
        if ([captainSpecial isEqualToString: @"WeaponUpgradesCostOneLess"]) {
            cost -= 1;
        }
        if ([fleetCaptainSpecial isEqualToString: @"WeaponUpgradesCostOneLess"]) {
            cost -= 1;
        }
    } else if ([upgrade isTech]) {
        if ([fleetCaptainSpecial isEqualToString: @"TechUpgradesCostOneLess"]) {
            cost -= 1;
        }
    }

    if ([captainSpecial isEqualToString: @"OneDominionUpgradeCostsMinusTwo"] && !isSideboard) {
        if ([upgrade isDominion]) {
            DockEquippedUpgrade* most = [equippedShip mostExpensiveUpgradeOfFaction: @"Dominion" upType: nil];

            if (most.upgrade == self && (equippedUpgrade == nil || equippedUpgrade == most)) {
                cost -= 2;
            }
        }
    } else if ([captainSpecial isEqualToString: @"VulcanAndFedTechUpgradesMinus2"] && !isSideboard) {
        if ([upgrade isTech] && ([upgrade isFederation] || [upgrade isVulcan])) {
            cost -= 2;
        }
    } else if ([captainSpecial isEqualToString: @"AddTwoCrewSlotsDominionCostBonus"] && !isSideboard) {
        if ([upgrade isDominion]) {
            NSArray* all = [equippedShip allUpgradesOfFaction: @"Dominion" upType: @"Crew"];
            
            id upgradeCheck = ^(id obj, NSUInteger idx, BOOL* stop) {
                DockEquippedUpgrade* eu = obj;
                DockUpgrade* upgradeToTest = eu.upgrade;
                return (upgradeToTest == self && (equippedUpgrade == nil || equippedUpgrade == eu));
            };
            NSInteger position = [all indexOfObjectPassingTest: upgradeCheck];

            if (position != NSNotFound && position < 2) {
                cost -= 1;
            }
        }
    } else if ([captainSpecial isEqualToString: @"AddsHiddenTechSlot"] && !isSideboard) {
        NSArray* allTech = [equippedShip allUpgradesOfFaction: nil upType: @"Tech"];
        DockEquippedUpgrade* most = nil;

        for (DockEquippedUpgrade* eu in allTech) {
            if (![eu.upgrade refersToShipOrShipClass]) {
                most = eu;
                break;
            }
        }
        
        if (most.upgrade == self) {
            cost = 3;
        }
    }

    if (![upgrade isOfficer] && !factionsMatch(ship, self) && !equippedShip.isResourceSideboard && !factionsMatch(self, equippedShip.flagship)) {
        if ([captainSpecial isEqualToString: @"UpgradesIgnoreFactionPenalty"] && ![upgrade isCaptain] && ![upgrade isAdmiral]) {
            // do nothing
        } else if ([captainSpecial isEqualToString: @"NoPenaltyOnFederationOrBajoranShip"]  && [upgrade isCaptain]) {
            if (!([ship isFederation] || [ship isBajoran])) {
                cost += 1;
            }
        } else if ([captainSpecial isEqualToString: @"NoPenaltyOnFederationShip"]  && [upgrade isCaptain]) {
            if (!([ship isFederation])) {
                cost += 1;
            }
        } else if ([captainSpecial isEqualToString: @"CaptainAndTalentsIgnoreFactionPenalty"] &&
                   ([upgrade isTalent] || [upgrade isCaptain])) {
        } else if ([captainSpecial isEqualToString: @"hugh_71522"] &&
                   [upgrade isFactionBorg]) {
        } else if ([captainSpecial isEqualToString: @"lore_71522"] &&
                   [upgrade isTalent]) {
        } else if ([externalId isEqualToString: @"elim_garak_71786"]) {
        } else if ([fleetCaptainOnThisShip isIndependent] && [ship isIndependent] && [upgrade isCaptain]) {
        } else {
            if (upgrade.isAdmiral) {
                cost += 3;
            } else {
                cost += 1;
            }
        }

    }

    if ([[upgrade externalId] isEqualToString: @"borg_ablative_hull_armor_71283"]) {
        if ([[ship externalId] isEqualToString: @"tactical_cube_138_71444"]) {
            cost = 7;
        }
    }

    if ([upgrade isWeapon] && [equippedShip containsUpgradeWithId: @"sakonna_gavroche"] != nil) {
        if (cost <= 5) {
            cost -= 2;
        }
    }


    if (cost < 0) {
        cost = 0;
    }
    
    return cost;
}

-(int)additionalWeaponSlots
{
    NSString* special = self.special;
    NSString* externalId = self.externalId;

    if ([special isEqualToString: @"AddTwoWeaponSlots"]) {
        return 2;
    }
    if ([special isEqualToString: @"AddsOneWeaponOneTech"] || [special isEqualToString: @"addoneweaponslot"]) {
        return 1;
    }
    if ([special isEqualToString: @"sakonna_gavroche"]) {
        return 1;
    }
    if ([externalId isEqualToString: @"quark_weapon_71786"]) {
        return 1;
    }
    return 0;
}

-(int)additionalTechSlots
{
    NSString* special = self.special;
    NSString* externalId = self.externalId;

    if ([special isEqualToString: @"AddsOneWeaponOneTech"]) {
        return 1;
    }
    if ([externalId isEqualToString: @"vulcan_high_command_2_0_71446"]) {
        return 2;
    }
    if ([special isEqualToString: @"addonetechslot"] || [externalId isEqualToString: @"vulcan_high_command_1_1_71446"]) {
        return 1;
    }
    if ([externalId isEqualToString: @"quark_71786"]) {
        return 1;
    }
    return 0;
}

-(int)additionalCrewSlots
{
    NSString* externalId = self.externalId;

    if ([externalId isEqualToString: @"vulcan_high_command_0_2_71446"]) {
        return 2;
    }
    if ([externalId isEqualToString: @"vulcan_high_command_1_1_71446"]) {
        return 1;
    }
    return 0;
}

-(int)additionalTalentSlots
{
    if ([self.externalId isEqualToString: @"elim_garak_71786"]) {
        return 1;
    }
    return 0;
}

-(int)additionalHull
{
    if ([self.externalId isEqualToString: @"combat_vessel_variant_71508"]) {
        return 1;
    }
    return 0;
}

-(int)additionalAttack
{
    if ([self.externalId isEqualToString: @"combat_vessel_variant_71508"]) {
        return 1;
    }
    return 0;
}

-(NSString*)upType
{
    return [[self types] anyObject];
}

-(void)setUpType:(NSString*)upType;
{
    DockTag* typeCategoryTag = [DockTag findOrCreateCategoryTag: kDockTypeCategoryType
                                                              value: upType
                                                            context: self.managedObjectContext];
    [self addTagsObject: typeCategoryTag];
}

-(DockWeaponRange*)weaponRange
{
    return [[DockWeaponRange alloc] initWithString: self.range];
}

-(NSString*)rangeAsString
{
    return self.range;
}

-(NSString*)weaponItemDescription
{
    return [NSString stringWithFormat: @"%@: %@ (%@ @ %@)", self.typeCode, self.title, self.attack, self.range];
}

@end
