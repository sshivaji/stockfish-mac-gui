#import "PreferencesController.h"

@implementation PreferencesController

-(id)init {
  self = [super initWithWindowNibName: @"Preferences"];
  return self;
}

-(void)windowDidLoad {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

  [analysisInMoveListSwitch 
    setState: [defaults boolForKey: @"Include Engine Analysis in Move List"]];
  [whiteScoreSwitch
    setState: [defaults boolForKey: 
			  @"Display all Scores from White's Point of View"]];
  [resignSwitch
    setState: [defaults boolForKey: @"Resign in Hopeless Positions"]];
  [hashSizeTextField 
    setIntValue: [defaults integerForKey: @"Default Hash Table Size"]];

  [darkColorWell 
    setColor: [NSUnarchiver unarchiveObjectWithData:
			      [defaults objectForKey: @"Dark Square Color"]]];
  [lightColorWell 
    setColor: [NSUnarchiver unarchiveObjectWithData:
			      [defaults objectForKey: @"Light Square Color"]]];
  [beepWhenMoveSwitch
    setState: [defaults boolForKey: @"Beep when Making Moves"]];
}

-(IBAction)changeDarkSquareColor:(id)sender {
  [[NSUserDefaults standardUserDefaults]
    setObject: [NSArchiver archivedDataWithRootObject: [sender color]]
    forKey: @"Dark Square Color"];

  // Notify about color change:
  [[NSNotificationCenter defaultCenter]
    postNotificationName: @"BoardColorsChanged" object: nil];
}

-(IBAction)changeLightSquareColor:(id)sender {
  [[NSUserDefaults standardUserDefaults]
    setObject: [NSArchiver archivedDataWithRootObject: [sender color]]
    forKey: @"Light Square Color"];

  // Notify about color change:
  [[NSNotificationCenter defaultCenter]
    postNotificationName: @"BoardColorsChanged" object: nil];
}

-(IBAction)analysisInMoveListSwitched:(id)sender {
  [[NSUserDefaults standardUserDefaults]
    setBool: [sender state] forKey: @"Include Engine Analysis in Move List"];
}

-(IBAction)hashTextFieldChanged:(id)sender {
}

-(IBAction)resignSwitched:(id)sender {
  [[NSUserDefaults standardUserDefaults]
    setBool: [sender state] forKey: @"Resign in Hopeless Positions"];
}

-(IBAction)whiteScoreSwitched:(id)sender {
  [[NSUserDefaults standardUserDefaults]
    setBool: [sender state] 
    forKey: @"Display all Scores from White's Point of View"];
}

-(IBAction)beepWhenMoveSwitched:(id)sender {
  [[NSUserDefaults standardUserDefaults]
    setBool: [sender state] forKey: @"Beep when Making Moves"];
  [[NSNotificationCenter defaultCenter]
    postNotificationName: @"BeepWhenMakingMovesChanged" object: nil];
}

-(void)controlTextDidChange:(NSNotification *)aNotification {
  int newSize = [hashSizeTextField intValue];
  if(newSize > 0) 
    [[NSUserDefaults standardUserDefaults]
      setInteger: newSize forKey: @"Default Hash Table Size"];
}

@end
