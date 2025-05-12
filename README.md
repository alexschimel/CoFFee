![](https://github.com/alexschimel/CoFFee/blob/master/apps/logo/coffee_banner.png?raw=true)

# *CoFFee*

Matlab toolbox for multibeam sonar data processing.

### Description

*CoFFee* is a free and open-source MATLAB toolbox (i.e., a libary of functions) for reading multibeam sonar raw data files, visualizing their contents, and applying various processsing algorithms. It serves as the engine for several apps/GUIs designed for specific applications.

### Disclaimer

*CoFFee* is the (messy) repository of functions written and edited over the authors' career, which started before they used git. As a result, many functions are obsolete, or don't work with newer functions, or even work at all. This is why this toolbox is noted as in pre-release and will remain so until the authors can clean it all up. Expect headaches if you try to use the less commonly-used functions!

## Getting Started

### Dependencies

* [MATLAB](https://au.mathworks.com/products/get-matlab.html). We are currently using R2020b, but it may work on other versions.
* Some MATLAB toolboxes (not all functions require them):
  * Mapping Toolbox
  * Parallel Computing Toolbox
  * Signal Processing Toolbox
  * Statistics and Machine Learning Toolbox
  
### Installing and using

* Clone or download the repository.
* Add the toolbox's folder and subfolders to the Matlab's path by adding the following lines at the top of your scripts:

```
coffeeFolder = 'C:\my\path\to\CoFFee';
addpath(genpath(coffeeFolder));
```

## Help

Head over to the [wiki](https://github.com/alexschimel/CoFFee/wiki) for documentation (in progress).

If you have any issues, please first check the project's [issues](https://github.com/alexschimel/CoFFee/issues) section to search for a fix. Otherwise, let the authors know by [creating a new issue](https://github.com/alexschimel/CoFFee/issues/new).

For more information, contact the [authors](#authors).

### Past versions and updates

See the [releases](https://github.com/alexschimel/CoFFee/releases) page for past released versions. 

If you want to receive notifications of future releases (recommended), you may create a github account, and on this repository click on 'Watch', then 'Custom', and choose 'Releases'. Verify in your GitHub settings that you are set to receive 'Watching' notifications.

## About

### Authors and contributors

* Alexandre Schimel (alex.schimel@proton.me)
* Yoann Ladroit (Kongsberg Discovery)
* Amy Nau (CSIRO)
* Shyam Chand (The Geological Survey of Norway)

#### Copyright

2007-2025
* Alexandre Schimel

### License

*CoFFee* is distributed under the MIT License. See `LICENSE` file for details.

*CoFFee* uses several pieces of third-party code, each being distributed under its own license. Each piece of code is contained in a separate sub-folder of the 'toolboxes' folder and includes the corresponding license file.

### Support This Project 💖

If you use *CoFFee* in your research, teaching, or professional work, please consider supporting its development. Your support helps cover development time, MATLAB license costs, and ensures continued availability of free, open-source tools for multibeam sonar data analysis.

For **monthly support**, consider [sponsoring on GitHub](https://github.com/sponsors/alexschimel). For **one-time donations**, you can use [PayPal](https://paypal.me/alexschimel).

[![Sponsor on GitHub](https://img.shields.io/badge/Sponsor-GitHub-ea4aaa.svg)](https://github.com/sponsors/alexschimel)
[![Donate via PayPal](https://img.shields.io/badge/Donate-PayPal-blue.svg)](https://paypal.me/alexschimel)

## See Also

### Apps based on CoFFee
* [*Espresso*](https://github.com/alexschimel/Espresso): Multibeam water-column data visualization and processing
* [*Iskaffe*](https://github.com/alexschimel/Iskaffe): Multibeam backscatter quality control
* [*Grounds*](https://github.com/alexschimel/Grounds): Elevation Change Analysis

### References

Articles using or about *CoFFee*, or apps based on *CoFFee*:

* Nau, A. W., Lucieer, V., Schimel, A. C. G., Kunnath, H., Ladroit, Y., & Martin, T. (2025). Advanced Detection and Classification of Kelp Habitats Using Multibeam Echosounder Water Column Point Cloud Data. Remote Sensing, 17(3), 449. https://doi.org/10.3390/rs17030449
* Schimel, A., Ladroit, Y., & Watson, S. (2024). Espresso: An Open-Source Software Tool for Visualizing and Analysing Multibeam Water-Column Data. EGU General Assembly 2024, Vienna, Austria, 14–19 Apr 2024, EGU24-11043. https://doi.org/10.5194/egusphere-egu24-11043 
* Lucieer, V., Flukes, E., Keane, J. P., Ling, S. D., Nau, A. W., & Shelamoff, V. (2023). Mapping warming reefs — An application of multibeam acoustic water column analysis to define threatened abalone habitat. Frontiers in Remote Sensing, 4(April), 1–15. https://doi.org/10.3389/frsen.2023.1149900
* Turco, F., Ladroit, Y., Watson, S. J., Seabrook, S., Law, C. S., Crutchley, G. J., Mountjoy, J., Pecher, I. A., Hillman, J. I. T., Woelz, S., & Gorman, A. R. (2022). Estimates of Methane Release From Gas Seeps at the Southern Hikurangi Margin, New Zealand. Frontiers in Earth Science, 10(March), 1–20. https://doi.org/10.3389/feart.2022.834047
* Nau, A. W., Scoulding, B., Kloser, R. J., Ladroit, Y., & Lucieer, V. (2022). Extended Detection of Shallow Water Gas Seeps From Multibeam Echosounder Water Column Data. Frontiers in Remote Sensing, 3(July), 1–18. https://doi.org/10.3389/frsen.2022.839417
* Porskamp, P., Schimel, A. C. G., Young, M., Rattray, A., Ladroit, Y., & Ierodiaconou, D. (2022). Integrating multibeam echosounder water‐column data into benthic habitat mapping. Limnology and Oceanography, 1–13. https://doi.org/10.1002/lno.12160
* Schimel, A. C. G., Brown, C. J., & Ierodiaconou, D. (2020). Automated Filtering of Multibeam Water-Column Data to Detect Relative Abundance of Giant Kelp (Macrocystis pyrifera). Remote Sensing, 12(9), 1371. https://doi.org/10.3390/rs12091371
* Mountjoy, J. J., Howarth, J. D., Orpin, A. R., Barnes, P. M., Bowden, D. A., Rowden, A. A., Schimel, A. C. G., Holden, C., Horgan, H. J., Nodder, S. D., Patton, J. R., Lamarche, G., Gerstenberger, M., Micallef, A., Pallentin, A., & Kane, T. (2018). Earthquakes drive large-scale submarine canyon development and sediment supply to deep-ocean basins. Science Advances, 4(3). https://doi.org/10.1126/sciadv.aar3748
* Nau, A. W., Lucieer, V. L., & Alexandre Schimel, C. G. (2018). Modeling the along-track sidelobe interference artifact in multibeam sonar water-column data. OCEANS 2018 MTS/IEEE Charleston, 1–5. https://doi.org/10.1109/OCEANS.2018.8604866
* Schimel, A. C. G., Ierodiaconou, D., Hulands, L., & Kennedy, D. M. (2015). Accounting for uncertainty in volumes of seabed change measured with repeat multibeam sonar surveys. Continental Shelf Research, 111, 52–68. https://doi.org/10.1016/j.csr.2015.10.019
* Schimel, A. C. G., Healy, T. R., McComb, P., & Immenga, D. (2010). Comparison of a self-processed EM3000 multibeam echosounder dataset with a QTC view habitat mapping and a sidescan sonar imagery, Tamaki Strait, New Zealand. Journal of Coastal Research, 26(4). https://doi.org/10.2112/08-1132.1

## For developers

Please maintain the *CoFFee* coding philosophy, which is that any core functionality (raw file reading, conversion, data processing, etc.) is coded as *CoFFee* functions, so that only user-interaction functionalities (display, user interface, callbacks, etc.) are coded in apps. This allows reusing core functionalities across apps. Therefore, the development of an app requires the joint development of *CoFFee*, and since there are multiple apps built on *CoFFee*, careful version-controlling and dependency-management is necessary to avoid breaking compatibility.

We use [Semantic Versioning](https://semver.org/) to attribute version numbers:
* The version of *CoFFee* is hard-coded in function `CFF_coffee_version.m`.
* The version of an app is (usually) a static property of the app (`Version`), alongside the *CoFFee* version it was built on (`CoffeeVersion`).

A careful sequence to develop an app is the following:

1. Checkout the latest commits on the main branches of both *CoFFee* and the app you wish to develop.
2. Check if that latest version of the app uses the latest version of *CoFFee* (in the code, or warning at start-up). 
3. If the app is running on an older version of *CoFFee*, fix that first:
    * Start with updating the app to use that latest version of *CoFFee*.
    * Before committing those changes, increase the app's version number and update which *CoFFee* version it runs on. 
    * After committing, remember to add the new tag on git.
4. Develop the app as you wish. Remember that all processing goes ideally in *CoFFee* and all display and user interface on the app.
5. When done, increase the app's version number (app property `Version`)
6. If *CoFFee* was modified, increase *CoFFee*'s version number (`CFF_coffee_version.m`), and update in the app which *CoFFee* version it was built on (app property `CoffeeVersion`).
7. Verify that everything works:
    * In MATLAB, run `restoredefaultpath` to ensure you get a clean path.
    * Delete the user folder to start from a clean slate.
    * Start the app, check on the start messages that all versions are correct
    * Test all features of the app.
8. Push the app up on git. Add a version tag.
9. If *CoFFee* was modified, push it up on git. Add a version tag.
10. If you wish to compile/release this new version of the app:
    * Compile:
      * Double-click on the app's `*.prj` file to start the Application Compiler with existing settings.
      * Reset dependencies:
        * Remove the app's "main file" (the `*.mlapp` file if using the app designer) to remove all the files required. This might take a few seconds.
        * Remove any remaining files and folders in the list of files required.
        * Add the "main file" again and wait for the application compiler to find all required files. This might take a few seconds.
        * Add any other files and folders in the list of files required.
      * Update the version number:
        * In the setup file name ("Packaging Options" panel, "Runtime downloaded from web" field)
        * In the "application information" panel
        * In the "Default installation folder" field.
      * Details:
        * All paths in "Settings" should be in the "Espresso\bin" folder.
      * Click on "Save".
      * Click on "Package".
    * Test that the compiled version works correctly.
      * Uninstall any previous version of the app, and delete the user folder.
      * Install the new executable with the setup file.
      * Test that the installed software runs correctly.
    * Create a new release on github
      * Go to the new tag and create a new release
      * Add binaries to the new release:
        * The binary setup (iskaffe_v***_setup.exe)
        * A zipped file of the "for_redistribution_files_only" folder
      * Fill in the release notes by copy-pasting the release notes of the previous release (Sections Download, New features, Bug fixes) and edit them
      * In the Download section, make sure to edit the links to the new release's binaries
      * Publish the new release
      * Test that the download links are correct
    * Update the link of the "Download Latest release installer" button on the app's README.md
      * Tese that the new download link works
