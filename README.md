# Yet Another NFO Viewer

${\textsf{\color{red}As of October 2025, the project is abandoned, following a lack of contributors.}}$

${\textsf{\color{red}There will be no further releases created or published, in the current form.}}$

${\textsf{\color{red}People are welcome to carry the torch in a new, Swift-based version for modern macOS!}}$

## Overview

Back in 2011, the **Yet Another NFO Viewer** or simply _YaNvi_ project was intended to be a small, light and hopefully fast tool to properly view ASCII artwork files in DOS encoding (with extensions NFO, ASC and DIZ) that I created for myself and felt like sharing with the Mac community, as using the native **TextEdit.app** was simply not good enough, since it doesn't always auto-detect the encoding and the user is forced to set it manually.

It was originally planned to be a continuation/update on the **NFO Viewer** project by Kris Gybels and [his open-source code repository over at SourceForge.net](http://blockart.sourceforge.net/) for modern, larger desktop resolutions. As this original project looked like it was compiled on an older Xcode and Mac OS X setup, I was forced to completely re-write it from scratch on Mac OS X 10.6 using Xcode 3.2 so that I would be able to also produce a 64-bit binary.

Therefore, due to my current Mac environment at that time, this tool was intended for Intel-based Macs only, running on the Mac OS X 10.6 operating system.

The included (and necessary) resource **ProFontWindows** is an original bitmap font created by Tobias Jung and then kindly converted to Windows TrueType format by Mike Smith. This font was also used in *NFO Viewer* by Kris Gybels, which is the most convenient free font for ASCII art found and available, so far.

For historical reasons, the very first release posted here will be a re-compiled version from 2011, slightly newer to the one found on [MacUpdate](https://www.macupdate.com/app/mac/39748/yet-another-nfo-viewer) that was submitted quite some time ago.

## Current Status

⚠️ **Although this tool is not _abandonware_, it runs extremely low on resources and depends on the good will and time of contributors.** This explains the very few releases over time, especially due to the fact that peopple moved ahead to Swift and Swift UI, while this is an original Xcode 4.x project. Therfore this tool **may not work for you** and your macOS setup, especially recent ones.

Nevertheless, for operational issues found, you can try posting a bug by using [the appropriate section here](https://github.com/mackonsti/yet-another-nfo-viewer/issues) on GitHub. Please be concise, polite and **provide enough information (macOS, architecture, sample NFO and details on reproducing the bug)** if an issue is constantly encountered. Also, kindly use the formatting options for copying-pasting code or logs.

For new features, you are welcome to post them as well, however they can _only_ rely on the kind contribution of the involved community members, as **there is no development roadmap** ahead.

Should you wish to contribute, you are very welcome to do so via a [Pull Request](https://github.com/mackonsti/yet-another-nfo-viewer/pulls) that I'd be happy to approve.

## Installation Note

Due to stricter security measures enforced on latest macOS versions, despite the fact that the provided DMG file in [Releases](https://github.com/mackonsti/yet-another-nfo-viewer/releases) has been checked prior to it being published, there may be situations where macOS will inform you that "_the application is damaged and can't be opened_" and that "_you should move it to the Trash_" when trying to run **YaNvi** for the first time.

In the past, right-clicking on the application icon and selecting "Open" on the mini-menu [would bypass this error](https://osxdaily.com/2019/02/13/fix-app-damaged-cant-be-opened-trash-error-mac/), as it would indicate to macOS that you are consciously trying to open a third-party, non-signed or notarized application.

Recently, users reported to successfully bypass this issue by **cleaning up any extended attributes** that macOS assigns when e.g. installing it in `/Applications/` folder. Try this in your Terminal console _before_ launching **YaNvi** for the first time:

```
cd /Applications/
xattr -rc Yet\ Another\ NFO\ Viewer.app
```

You can find more information on `xattr` command [here](https://ss64.com/osx/xattr.html).

### Release 1.1.3

This release is a minor release but important for some people, especially because **longer ASCII art files** can now be read in their entirety and scrolled all the way to the bottom of the file; previously, there was a vertical limit that has been now increased.

### Release 1.1.2

Thanks to the community support, this tool can now be run on both **Intel** and **Apple Silicon** platforms (as a Universal Binary) running at least macOS High Sierra (10.13) operating system. French strings translations were also added.

### Release 1.1.1

Recently, I decided to create this repository and share the code to anyone interested into improving it and migrating the code so it can be compiled to modern Xcode versions, as since Xcode 4 a lot has changed and I have not been personally able to follow the developments.

If you are interested to contribute to this simple tool, feel free to request permission to access the repository. The only thing I have done is to open the project in Xcode 9 and compile it without errors or warnings, while including minor modern optimisations.

For issues found or new features, the best way forward is to use the appropriate section, here on GitHub. Please be concise, polite and provide enough information if a bug is found. Also, kindly use the **formatting** options for copying-pasting code or logs.
