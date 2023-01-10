![](https://github.com/alexschimel/CoFFee/blob/d7b1b86031bc83adc59aa77fdf4164101bb9fd16/apps/logo/coffee_banner.png?raw=true)

# *CoFFee*

Matlab toolbox for multibeam sonar data processing.

## Description

*CoFFee* is a free and open-source MATLAB toolbox (libary of functions) for reading multibeam sonar raw data files, visualizing their contents, and applying various processsing algorithms. It serves as the engine for several apps/GUIs designed for specific applications.

**IMPORTANT NOTE: This is a pre-release (v2), that is, still clunky. Use at your peril!**

## Getting Started

### Dependencies

* [MATLAB](https://au.mathworks.com/products/get-matlab.html). We are currently using R2020b, but it may work on other versions.
* Some MATLAB toolboxes (not all functions require them):
  * Signal Processing Toolbox
  * Mapping Toolbox
  * Statistics and Machine Learning Toolbox
  * Parallel Computing Toolbox

### Installing and using

* Clone or download the repository.
* Add the toolbox's folder and subfolders to the Matlab's path by adding the following lines at the top of your scripts:

```
coffeeFolder = 'C:\my\path\to\CoFFee';
addpath(genpath(coffeeFolder));
```

## Help

There is no documentation yet. Contact the authors.

## Authors

* Alexandre Schimel ([The Geological Survey of Norway](https://www.ngu.no), alexandre.schimel@ngu.no)
* Yoann Ladroit (NIWA)
* Amy Nay (CSIRO)

## Version History

[See the releases page](https://github.com/alexschimel/CoFFee/releases)

## License

Distributed under the MIT License. See `LICENSE.txt` for more information.

## See Also

All apps based on *CoFFee*:
* [*Grounds*](https://github.com/alexschimel/Grounds): Elevation Change Analysis
* *Espresso*: Water-column data viewing and processing (private)
* [*Iskaffe*](https://github.com/alexschimel/Iskaffe): Multibeam backscatter quality control
* [*Kopp*](https://github.com/alexschimel/Kopp): Tracking Multibeam raw data parameter changes


## References

Articles using *CoFFee*, or apps based on *CoFFee*:
* Nau, A. W., Scoulding, B., Kloser, R. J., Ladroit, Y., & Lucieer, V. (2022). Extended Detection of Shallow Water Gas Seeps From Multibeam Echosounder Water Column Data. Frontiers in Remote Sensing, 3(July), 1–18. https://doi.org/10.3389/frsen.2022.839417
* Porskamp, P., Schimel, A. C. G., Young, M., Rattray, A., Ladroit, Y., & Ierodiaconou, D. (2022). Integrating multibeam echosounder water‐column data into benthic habitat mapping. Limnology and Oceanography, 1–13. https://doi.org/10.1002/lno.12160
* Schimel, A. C. G., Brown, C. J., & Ierodiaconou, D. (2020). Automated Filtering of Multibeam Water-Column Data to Detect Relative Abundance of Giant Kelp (Macrocystis pyrifera). Remote Sensing, 12(9), 1371. https://doi.org/10.3390/rs12091371
* Mountjoy, J. J., Howarth, J. D., Orpin, A. R., Barnes, P. M., Bowden, D. A., Rowden, A. A., Schimel, A. C. G., Holden, C., Horgan, H. J., Nodder, S. D., Patton, J. R., Lamarche, G., Gerstenberger, M., Micallef, A., Pallentin, A., & Kane, T. (2018). Earthquakes drive large-scale submarine canyon development and sediment supply to deep-ocean basins. Science Advances, 4(3). https://doi.org/10.1126/sciadv.aar3748
* Nau, A. W., Lucieer, V. L., & Alexandre Schimel, C. G. (2018). Modeling the along-track sidelobe interference artifact in multibeam sonar water-column data. OCEANS 2018 MTS/IEEE Charleston, 1–5. https://doi.org/10.1109/OCEANS.2018.8604866
* Schimel, A. C. G., Ierodiaconou, D., Hulands, L., & Kennedy, D. M. (2015). Accounting for uncertainty in volumes of seabed change measured with repeat multibeam sonar surveys. Continental Shelf Research, 111, 52–68. https://doi.org/10.1016/j.csr.2015.10.019
* Schimel, A. C. G., Healy, T. R., McComb, P., & Immenga, D. (2010). Comparison of a self-processed EM3000 multibeam echosounder dataset with a QTC view habitat mapping and a sidescan sonar imagery, Tamaki Strait, New Zealand. Journal of Coastal Research, 26(4). https://doi.org/10.2112/08-1132.1


## For developers

The philosophy behind *CoFFee* and the apps built on it is that all back-end (processing) goes in *CoFFee* while all front-end (display, user interface, application) goes in those apps. As a result, the development of an app requires the joint development of *CoFFee*, and since there are multiple apps built on *CoFFee*, careful version-controlling and dependency-management is necessary to avoid breaking compatibility.

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
5. When done, if *CoFFee* was modified:
    * Increase *CoFFee*'s version number (`CFF_coffee_version.m`).
    * Increase the app's version number (property `Version`), and update which *CoFFee* version it was built on (property `CoffeeVersion`).
6. Check that everything works:
    * In MATLAB, run `restoredefaultpath` to ensure you get a clean path.
    * Delete the user folder to start from a clean slate.
    * Start the app, check on the start messages that all versions are correct
    * Test all features of the app.
7. If *CoFFee* was modified, push it up on git first. Add a tag.
8. If you wish to compile this new version of the app:
    * In MATLAB, run `restoredefaultpath` to ensure you get a clean path. 
    * Run the app and check a last time it all works fine.
    * Double-click on the app's `*.prj` file to run the application compiler with existing settings:
      * Remove the app's `*.mlapp` main file and add it again for the application compiler to find all dependencies.
      * Update the version number in the 'runtime downloaded from web', the 'application information', and the default installation folder.
      * Save.
      * Click on `Package`.
    * Install the new executable with the setup file.
    * Test that the setup works correctly.
    * Test that the installed software runs correctly.
9. Push the app up on git. Add a version tag.
10. If you compiled that new version:
    * Create a new release on github from the tag. 
    * Add the binary setup, and a zipped version of the `for_redistribution_files_only` folder.