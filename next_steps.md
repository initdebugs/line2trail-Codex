1. Please make the markers on the map turn in the same orientation as how the user has the map turned. This way for example the 1km,2km markers are always readable in every orientation.

2. Create a finish marker at the last waypoint of the route. If start/end point are the same, use a different icon for that so it's clear this is the begin/end point.

3. For the begin and end point marker, make it always visible, even when waypoint toggle is turned off.

4. Start with the integration of the roundtrip generator as seen in the index.html file in this folder. When the roundtrip generator button is clicked, open a pop-up where the user can select:
- Activity type;
- Approx distance;
And then 2 buttons: Annuleer and Select start point.

When select start point button is clicked, close the popup and enter the round trip generator mode where anything from the routebar not roundtrip generator related is hidden. Make sure the user knows they have to click a start point. Add an Annuleer rondrit button in the routebar. When clicked the routebar goes back to original layout.

When a start point is clicked, generate one route (for now) that comes as close as possible to the requested distance in the requested mode. Do the generation in the same way as in the index.html file. Make the user wait with a popup loading spinner so nothing else can be done while generating. Only add a cancel button that cancels the generation. Once done, show the route on the map like normal.