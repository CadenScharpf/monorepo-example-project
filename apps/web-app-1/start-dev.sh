#!/bin/sh
echo "Serving on port $WEB_APP_1_PORT"
echo "Debugging on port $WEB_APP_1_DEBUG_PORT"
node --inspect=0.0.0.0:$WEB_APP_1_DEBUG_PORT node_modules/.bin/react-scripts start