#= require jquery
#= require leaflet

# set the Mocha test interface
# see http:#visionmedia.github.com/mocha/#interfaces
mocha.ui('bdd')

# ignore the following globals during leak detection
#mocha.globals(['L'])

# or, ignore all leaks
mocha.ignoreLeaks()

# set slow test timeout in ms
mocha.timeout(5)

# Show stack trace on failing assertion.
chai.config.includeStack = true
