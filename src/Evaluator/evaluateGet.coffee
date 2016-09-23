LiveGetter = require '../Util/LiveGetter'


liveGetter = new LiveGetter()

module.exports = get = liveGetter.get.bind(liveGetter)
