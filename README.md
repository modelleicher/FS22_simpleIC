# FS22_simpleIC
The well known SimpleIC, easy interactive Control, Mod is back! 
With the first Release in FS22 something has changed in a big way! There are now different modes of interacting with the TriggerPoints, those modes can be set in the Ingame-Settins-Menu of FS under "SimpleIC".
You can not only chose how the triggerPoints are displayed (always, never, only when hovered) you can also change whether you want to click on the triggerPoints or active them by hovering over them.
The hover-timer Method is mainly made for hands-free use with Headtracking.

All the additional features like Attacher-Control are deactivated for the first FS22 version, only animations and the implement-balls are active for now. I will add the other features back in at a later date once the base works without issues.

# Credits
- mainly me, Modelleicher, working on this 
- Big thanks to Wopster from whom I got permission to use the Ingame-Menu Code 
 
# Changelog:

###### V 0.9.0.6
- Warning: Old shape file format version found 'weightSetBall.i3d.shapes'. fixed [issue #10]
###### V 0.9.0.5
- fixed Error on Servers - attempt to call method 'readStream' (a nil value) [issue #8]
###### V 0.9.0.4
- multiplayer synchronization fix [issue #6]
- saving of animationState fix
- losing interior sounds fix [issue #7]
- polish translation added (thanks KITT3000)
###### V 0.9.0.3
- messed up version, please update again
###### V 0.9.0.2
- fixed issue when saving simpleIC_animations.lua (81) [issue #4]
###### V 0.9.0.1
- Initial Github Release for FS22

# the most important thing:
How do I test and play this?
1. download FS22_simpleIC.zip and add to modfolder
2. download a mod that is SimpleIC ready or edit one for yourself (there is no example mod for FS22 as of right now but I will add some later - the XML is the same as in FS19 though so.. you can use that) 
3. go ingame and have fun :D 
4. report bugs if you notice any, please with Log, Description or Pictures :)

# What this is:
This is a new take on the well known Interactive Control Scripts in Farming Simulator. It has been established in FS19 as a well known and well used Mod so here it is for FS22. 
I didn't want to do this Mod again at first but nobody else wanted to do it so.. here we go. I hope you like it and appreciate it lol.

- This is a global script, which means that it doesn't have to be added to each Mod seperately, no additional modDesc.xml changes like l10n Texts etc. neccessary.
- Obviously the vehicle-xml and i3d still has to be edited, the script can't magically seperate doors and add trigger-points. But as soon as the needed lines are added, IC will be active as long as you have this mod active.
- this also means that people who don't like IC don't have to remove it all vehicle-mods, just not activate this mod.
- this also means that there's only one IC version and not 50 different ones that get into conflict with each other 
- updates to IC are global and useable in all mods


# How to add this to my Mod:
- There is an examples.xml explaining all the current possible XML entrys and what they do. If you're not brandnew to modding this should be enough to get going :) 

If you already know modding well, here's a short explanation:
(look at the linked Deutz Agrostar above to see the full XML lines)

- outsideInteractionTrigger = playerTrigger in which the player can open doors and other outside-stuff from the outside
- animationName = name of the animation for the door
- animationSpeed = speed of the animation (obvious) 
- shared animation = not added yet
- soundVolumeIncreasePercentage = by how much will the sound-volume increase if that door is opened. Values will be added together for more than one door, max is outdoorSoundVolume 
- insideTrigger and outsideTrigger = "Triggerpoints" e.g. transformGroups that mark the spot where the IC component can be clicked
- triggerPoint = index / i3dMapping name for the transformGroup
- triggerPointSize = size/radius around the triggerPoint where it still registeres as being clicked


