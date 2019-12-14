var express = require('express');
var path = require('path');
var router = express.Router();

router.get('/', function(req, res, next) {
  req.session.address = null;
  req.session.username = null;
  res.redirect('/');
});

module.exports = router;
