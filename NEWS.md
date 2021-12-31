# InterpretationEngine 0.0.0.9001

* Arbitrary curves now use the internal NASIS spline algorithm to generate control points and `splinefun()` to interpolate ratings 
* `plotEvaluation()` takes an optional `pch` argument to control the plotting character for control points; control points are stored in attributes of the interpolator function: attributes `"domain"` and `"range"` are X and Y values, respectively
* Fixed sigmoid rating curve scaling
* Added support for crisp expression functions
* Added `lookupRatingClass()` method 
* Added various hedge and operator functions for testing
* Added a `NEWS.md` file to track changes to the package.
