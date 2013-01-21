/* PreferencesController */

#import <Cocoa/Cocoa.h>

@interface PreferencesController : NSWindowController {
  IBOutlet id analysisInMoveListSwitch;
  IBOutlet id darkColorWell;
  IBOutlet id hashSizeTextField;
  IBOutlet id lightColorWell;
  IBOutlet id resignSwitch;
  IBOutlet id whiteScoreSwitch;
  IBOutlet id beepWhenMoveSwitch;
}

-(IBAction)changeDarkSquareColor:(id)sender;
-(IBAction)changeLightSquareColor:(id)sender;
-(IBAction)analysisInMoveListSwitched:(id)sender;
-(IBAction)hashTextFieldChanged:(id)sender;
-(IBAction)resignSwitched:(id)sender;
-(IBAction)whiteScoreSwitched:(id)sender;
-(IBAction)beepWhenMoveSwitched:(id)sender;
-(void)controlTextDidChange:(NSNotification *)aNotification;

@end
