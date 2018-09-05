#  DOOM for iOS 11 and tvOS for Apple TV and SmartDeviceLink
1. FYI if you want encrypted streaming, you need to put the FMCSecurity folder in the code/iphone/ folder
2. Touch events don't work. So you need to first have the phone disconnected from the system, select and start your level, THEN launch it on the vehicle.
















This is my update for DOOM for iOS to run on iOS 11, running in modern resolutions including the full width of the iPhone X. I have also made a target and version for tvOS to run on Apple TV

Improvements/Changes

- Compiles and runs in iOS 11 SDK
- Orientation and coordinate system fixed to reflect iOS 8 changes
- C warnings fixed for Xcode 9.3
- Basic MFi controller support
- Structure and View Controller usage grafted in from the DOOM-iOS2 repository and public user forks, unused code and embedded xcodeproj use eliminated
- Second project target for tvOS that takes advantage of focus model and removes on-screen controls.

This commit adds placeholder files for the "IB Images" folder and the `idGinzaNar-Md2.otf` font file. You will still need to provide your own copies of `doom.wad` and `base.iPack`. 

You can find the file `doom.wad` in any installation of DOOM, available on [Steam](http://store.steampowered.com/app/2280/Ultimate_Doom/), [GOG](https://www.gog.com/game/the_ultimate_doom), and floppy disk from 1-800-IDGAMES (note: do not call 1-800-IDGAMES I don't know where it goes anymore). 

The file `base.iPack` is not included in any DOOM installation and is specific to the iOS port. I can't include it in this repo because it contains copyrighted material and I can't tell you where to find it either, but you will need to source it yourself. The history is included in this [lengthy article](http://schnapple.com/wolfenstein-3d-and-doom-on-ios-11/) I wrote on the subject. At some point I hope to have a utility that will let you construct a `base.iPack` file but for now I don't. 

This repo contains changes from id's [DOOM-iOS2](https://github.com/id-Software/DOOM-IOS2) repo (different than the parent of this repo), changes from the [FinalJudgement](https://github.com/JadingTsunami/FinalJudgment-iOS) repo by [JadingTsunami](https://github.com/JadingTsunami/), and [MFi controller code](https://github.com/TheRohans/DOOM-IOS2/commit/5a6b69d5e9821134f4013b069faef29190dcd7a1) from [TheRohans](https://github.com/TheRohans/).

For a rundown of the effort to get it running on tvOS, I wrote a [second lenghty article](http://schnapple.com/wolfenstein-3d-and-doom-on-tvos-for-apple-tv/) on the subject. In addition to the work incorporated above, I incorporated the efforts of [yarsrevenge](https://github.com/yarsrvenge/DOOM-IOS2) in getting the basics of the tvOS version going. 

[Video of DOOM running on an iPhone X](https://www.youtube.com/watch?v=IrY5L1kn-NA)

[Video of DOOM running on an Apple TV](https://www.youtube.com/watch?v=P8QmMSabaqQ)

Have fun. For any questions I can be reached at tomkidd@gmail.com
