//
//  FileImport.m
//  Subler
//
//  Created by Damiano Galassi on 31/01/10.
//  Copyright 2010. All rights reserved.
//

#import "FileImport.h"
#import "MP42File.h"
#import "MP42FileImporter.h"

@implementation FileImport

- (id)initWithDelegate:(id)del andFile: (NSString *)fileUrl error:(NSError **)outError
{
	if ((self = [super initWithWindowNibName:@"FileImport"]))
	{
		delegate = del;
        file = [fileUrl retain];
        
        fileImporter = [[MP42FileImporter alloc] initWithDelegate:delegate andFile:file error:outError];
        if (!fileImporter)
            return nil;
	}
	return self;
}

- (void)awakeFromNib
{

    importCheckArray = [[NSMutableArray alloc] initWithCapacity:[[fileImporter tracksArray] count]];

    for (MP42Track *track in [fileImporter tracksArray])
        if (isTrackMuxable(track.format))
            [importCheckArray addObject: [NSNumber numberWithBool:YES]];
        else if(trackNeedConversion(track.format))
            [importCheckArray addObject: [NSNumber numberWithBool:YES]];
        else
            [importCheckArray addObject: [NSNumber numberWithBool:NO]];

    if ([fileImporter metadata])
        [importMetadata setEnabled:YES];
    else
        [importMetadata setEnabled:NO];
    
    [addTracksButton setEnabled:YES];
}

- (NSInteger) numberOfRowsInTableView: (NSTableView *) t
{
    return [[fileImporter tracksArray] count];
}

- (id) tableView:(NSTableView *)tableView 
objectValueForTableColumn:(NSTableColumn *)tableColumn 
             row:(NSInteger)rowIndex
{
    MP42Track *track = [[fileImporter tracksArray] objectAtIndex:rowIndex];

    if (!track)
        return nil;

    if( [tableColumn.identifier isEqualToString: @"check"] )
        return [importCheckArray objectAtIndex: rowIndex];

    if ([tableColumn.identifier isEqualToString:@"trackId"])
        return [NSString stringWithFormat:@"%d", track.Id];

    if ([tableColumn.identifier isEqualToString:@"trackName"])
        return track.name;

    if ([tableColumn.identifier isEqualToString:@"trackInfo"])
        return track.format;

    if ([tableColumn.identifier isEqualToString:@"trackDuration"])
        return [track timeString];

    if ([tableColumn.identifier isEqualToString:@"trackLanguage"])
        return track.language;

    return nil;
}

- (void) tableView: (NSTableView *) tableView 
    setObjectValue: (id) anObject 
    forTableColumn: (NSTableColumn *) tableColumn 
               row: (NSInteger) rowIndex
{
    if ([tableColumn.identifier isEqualToString: @"check"])
        [importCheckArray replaceObjectAtIndex:rowIndex withObject:anObject];
}

- (IBAction) closeWindow: (id) sender
{
    if ([delegate respondsToSelector:@selector(importDoneWithTracks:andMetadata:)]) 
        [delegate importDoneWithTracks:nil andMetadata:nil];
}

- (IBAction) addTracks: (id) sender
{
    NSMutableArray *tracks = [[NSMutableArray alloc] init];
    NSInteger i = 0;

    for (MP42Track * track in [fileImporter tracksArray])
        if ([[importCheckArray objectAtIndex: i++] boolValue]) {
            if (trackNeedConversion(track.format))
                track.needConversion = YES;

            if ([track.format isEqualToString:@"AC-3"] &&
                [[[NSUserDefaults standardUserDefaults] valueForKey:@"SBAudioConvertAC3"] integerValue])
                track.needConversion = YES;

            if (track.needConversion) {
                NSUInteger mixdown = [[[NSUserDefaults standardUserDefaults]
                                       valueForKey:@"SBAudioMixdown"] integerValue];
                switch(mixdown) {
                    case 4:
                        [(MP42AudioTrack*) track setMixdownType:nil];
                        break;
                    case 3:
                        [(MP42AudioTrack*) track setMixdownType:SBMonoMixdown];
                        break;
                    case 2:
                        [(MP42AudioTrack*) track setMixdownType:SBStereoMixdown];
                        break;
                    case 1:
                        [(MP42AudioTrack*) track setMixdownType:SBDolbyMixdown];
                        break;
                    case 0:
                        [(MP42AudioTrack*) track setMixdownType:SBDolbyPlIIMixdown];
                        break;
                    default:
                        [(MP42AudioTrack*) track setMixdownType:SBDolbyPlIIMixdown];
                        break;
                }
            }

            [track setTrackImporterHelper:fileImporter];
            [tracks addObject:track];
        }

    MP42Metadata *metadata = nil;
    if ([importMetadata state])
        metadata = [[[fileImporter metadata] retain] autorelease];

    if ([delegate respondsToSelector:@selector(importDoneWithTracks:andMetadata:)]) 
        [delegate importDoneWithTracks:tracks andMetadata: metadata];
    [tracks release];
}

- (void) dealloc
{
    [importCheckArray release];
	[file release];
    [fileImporter release];

    [super dealloc];
}

@end
