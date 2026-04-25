# Yet Another NFO Viewer (YaNVi)

${\textsf{\color{red}Work here resumes after spending some time with AI tools converting old code.}}$

${\textsf{\color{red}The project is not fully active but is being kept alive with slow changes.}}$

${\textsf{\color{red}Please be patient, as this is a hobby project and my free time is scarce.}}$

## 1. History

Back in 2011, the **Yet Another NFO Viewer** or simply _YaNVi_ project was intended to be a small, light and hopefully fast tool to properly view ASCII artwork files in DOS encoding (with extensions NFO, ASC and DIZ) that I created for myself and felt like sharing with the Mac community, as using the native **TextEdit.app** was simply not good enough, since it doesn't always auto-detect the DOS 437 encoding and the user is forced to set it manually.

It was originally planned to be a continuation/update on the **NFO Viewer** project by Kris Gybels and [his open-source code repository over at SourceForge.net](http://blockart.sourceforge.net/) for modern, larger desktop resolutions. As this original project looked like it was compiled on an older Xcode and Mac OS X setup, I was forced to completely re-write it from scratch on Mac OS X 10.6 using Xcode 3.2 so that I would be able to also compile a 64-bit binary.

Therefore, due to my current Mac environment at that time, this tool was intended for Intel-based Macs only, targeting the Mac OS X 10.6 operating system.

The included (and necessary) resource **ProFontWindows** is an original bitmap font created by Tobias Jung and then kindly converted to Windows TrueType format by Mike Smith. This font was also used in _NFO Viewer_ by Kris Gybels, which was the most convenient free font for ASCII art found and available, so far.

For historical reasons, the very first release posted here will be a re-compiled version from 2011, slightly newer to the one found on [MacUpdate](https://www.macupdate.com/app/mac/39748/yet-another-nfo-viewer) that was submitted quite some time ago.

## 2. Recent Years

Although this tool was not _abandonware_, it ran extremely low on coding resources and depended on the good will and time of a handful of contributors. This explains the very few releases over the past years, especially due to the fact that coding had moved forward to Swift and Swift UI, while this was an original Xcode 3.x project, harder to maintain. Therefore, this tool would not have worked for some users and their macOS setup, especially recent system versions and Apple Silicon Macs, later.

Nevertheless, when serious operational issues were found, some users posted a bug in the respective [Issues section](https://github.com/mackonsti/yet-another-nfo-viewer/issues) here, on GitHub. Users were requested to be concise, polite and **provide enough information** (macOS, architecture, sample NFO and details on reproducing the bug) if an issue was constantly encountered, by using the needed formatting options for copying-pasting code or logs.

New features, despite users being welcome to post them, could _only_ rely on the kind contribution of the involved community members, as **there was no development roadmap** ahead.

## 3. Current Status

In March 2026, I thought of asking AI to convert the original Xcode 3.x code to Swift 5.x out of curiosity. As the project is rather simple and straightforward, it could be built error-free in little time and work very, very well. Since this remains a **hobby project** on my own free time, I will slowly be working on it and tweaking it step-by-step. This tool is _not_ destined to become anything grand, as I intend to keep it small, yet optimised.

Every effort is made to make this tool stable, fast, as I am also using it. The scope and functionality is simple, thus once the code is fine-tuned, there shouldn't be frequent releases. **Please consider the releases "as-is" and rest assured, if there is an issue despite rigorous testing, it will be treated.**

The "Issues" section was consciously disabled as some users abused the feature and do not understand the essence of community or sharing or free time, so I am sorry to the other users that don't deserve that. However, should you wish to contribute in coding Swift 5, you are very welcome to do so via a [Pull Request](https://github.com/mackonsti/yet-another-nfo-viewer/pulls) that I'd be happy approve and exchange with you.

## 4. Installation Note

⚠️ **This application is still being built "ad-hoc" and does not contain any Developer ID, nor is it notarized, as I am not a professional developer.**

Due to the stricter security measures enforced on latest macOS versions, despite the fact that the provided DMG file in [Releases](https://github.com/mackonsti/yet-another-nfo-viewer/releases) has been checked prior to it being published, there may be situations where macOS will inform you that "_the application is damaged and can't be opened_" and that "_you should move it to the Trash_" when trying to run **YaNVi** for the first time.

In the past, right-clicking on the application icon and selecting "Open" on the mini-menu [would bypass this error](https://osxdaily.com/2019/02/13/fix-app-damaged-cant-be-opened-trash-error-mac/), as it would indicate to macOS that you are consciously trying to open a third-party, non-signed or notarized application.

Recently, users reported to successfully resolve this issue by **cleaning up any extended attributes** (most notably `com.apple.quarantine`) that macOS assigns when downloading and e.g. installing tools in `/Applications/` folder. Assuming that you installed **YaNVi** in the official Applications folder, you are encouraged to try this in your Terminal console _before_ launching **YaNVi** for the first time, or if replaced by a newer version:

```
xattr -rc /Applications/YaNVi.app
```

You can find more information on `xattr` command [here](https://ss64.com/osx/xattr.html).

# Releases

### Release 1.3.0 and 1.3.1

This release has been tested for a few days and works very well, so it's ready to be shared with the community, as this really **completes** the purpose of this tool. Main features include crash guards added to the main application as well as the Quicklook plugin; Printing support for both paper-printing and PDF exports; improved render calculation and window resizing (in both application and Quicklook plugin).

### Release 1.2.0

This release represents the revamping of the application, having converted it to Swift 5.x with the help of AI tools after hours of checking, testing, deliberating and optimising. Still comes as a Universal Binary and with a number of small under-the-hood improvements. For the time being, the minimum OS requirement is 14.5 macOS Sonoma.

### Release 1.1.3

This release is a minor release but important for some people, especially because **longer ASCII art files** can now be read in their entirety and scrolled all the way to the bottom of the file; previously, there was a vertical limit that has now been increased.

### Release 1.1.2

Thanks to the community support, this tool can now be run on both **Intel** and **Apple Silicon** platforms (as a Universal Binary) running at least macOS High Sierra (10.13) operating system. French strings translations were also added.

### Release 1.1.1

Recently, I decided to create this repository and share the code with anyone interested in improving it and migrating the code so it can be compiled with modern Xcode versions. Coding has changed a lot since Xcode 4 days and I have not been personally able to follow the developments.

If you are interested in contributing to this simple tool, feel free to request permission to access the repository. The only thing I have done is to open the project in Xcode 9 and compile it without errors or warnings, while including minor modern optimisations.

For issues found or new features, the best way forward is to use the corresponding Issues section, here on GitHub. Please be concise, polite and provide enough information if a bug is found. Also, kindly use the **formatting** options for copying-pasting code or logs.
