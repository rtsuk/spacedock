#import "DockUtils.h"

#import "DockUpgrade.h"

#if !TARGET_OS_IPHONE
NSAttributedString* coloredString(NSString* text, NSColor* color, NSColor* backColor)
{
    id attr = @{
        NSForegroundColorAttributeName: color,
        NSBackgroundColorAttributeName : backColor,
        NSExpansionAttributeName: @0.0
    };
    NSString* t = [NSString stringWithFormat: @" %@ ", text];
    return [[NSAttributedString alloc] initWithString: t attributes: attr];
}

#endif

NSSet* allAttributes(NSManagedObjectContext* context, NSString* entityName, NSString* attributeName)
{
    NSMutableSet* allSpecials = [NSMutableSet setWithCapacity: 0];
    NSEntityDescription* entity = [NSEntityDescription entityForName: entityName inManagedObjectContext: context];
    NSFetchRequest* request = [[NSFetchRequest alloc] init];
    [request setEntity: entity];
    NSError* err;
    NSArray* existingItems = [context executeFetchRequest: request error: &err];

    if (existingItems.count > 0) {
        for (id item in existingItems) {
            NSString* attributeValue = [item valueForKey: attributeName];

            if ([attributeValue length] > 0) {
                [allSpecials addObject: attributeValue];
            }
        }
    }

    return [NSSet setWithSet: allSpecials];
}

NSAttributedString* makeCentered(NSAttributedString* s)
{
    NSMutableAttributedString* as = [[NSMutableAttributedString alloc] initWithAttributedString: s];
    NSMutableParagraphStyle *ps = [[NSMutableParagraphStyle alloc] init];
    ps.alignment = NSCenterTextAlignment;
    NSRange r = NSMakeRange(0, s.length);
    [as addAttribute: NSParagraphStyleAttributeName value: ps range: r];
    return [[NSAttributedString alloc] initWithAttributedString: as];
}