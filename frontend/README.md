# frontend
## Info
The Flutter frontend for calendai. For running it, check the outer README.

## General design
The "architecture" is pretty simple:
- Pages (screens) are found in `/pages`; each extends a `StatefulWidget` and is built upon the `BasePage` which just provides some consistent styling and design.
- Each page has a corresponding controller in `/controllers`. These maintain the page's state and hold handler functions for the page's functionality.
- Controllers usually call into their service(s) in `/services`. A service is basically the app's API layer (though the notification service instead handles device notifications)
- The router in `router` handles mapping pages to routes.
- Most data is defined inside `/models`, and is made `JsonSerializable` since they're usually passed to/from the API layer.

## Dev notes
Some useful dev notes:
- After creating a new data model in `/models`, you can generate the serialization code by running `dart run build_runner build`
