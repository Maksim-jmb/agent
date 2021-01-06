# agent
simple GUI and Layout profiles for jmb

not cleaned up - adapted another agent into current Basic as of 1/5/2021 after catching a comment on discord for gui and layout.  Templates got messed up switching things into Basic, didn't take that much time with it - just added a couple skin files to make it workable.  Tested it a little - seems to work

If you are not running the game in C:  you might have to change some includes.

Should be able to switch window layouts on the fly - without restarting.  Just have horizontal, vertical, and a sample custom - VFX I left out... you could add more customs or call them what you want.  My Custom layout is based off of 2 monitors 2560,1080 and 1920,1080...change according to your monitor layout

Hopefully you can just swap out the Agents folder and this will work - settings.json holds the layouts and LGUI2's: change as needed, and bwl.config is only a test file.
Agent Window's: if you close a window - reload should bring it back....as of now if you hit RELOAD a ton of times----you might have a ton of windows built up behind the main window!!! I think - just using visible/hide for now to show them - not destroying elements yet.
