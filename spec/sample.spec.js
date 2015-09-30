var frisby = require('frisby');
frisby.create('Get Brightbit Twitter feed')
.get('https://api.twitter.com/1/statuses/user_timeline.json?screen_name=brightbit')
.expectStatus(410)
.expectHeaderContains('content-type', 'application/json')
.expectJSON({
  "errors":[{
    "message":"The Twitter REST API v1 is no longer active. Please migrate to API v1.1. https://dev.twitter.com/docs/api/1.1/overview.","code":64
  }]
}).toss()
