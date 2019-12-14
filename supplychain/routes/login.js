var express = require('express');
var path = require('path');
var router = express.Router();
var exec = require('child_process').exec;

var ip = "192.168.107.136";
var port = "5002";

/* GET users listing. */
router.get('/', function(req, res, next) {
  res.sendFile(path.join(__dirname,'../public/htmls/','login.html'));
});

router.post('/', function(req, res, next) {
  req.session.username = req.body['username']
  req.session.address = req.body['address'];
  res.send("success");
});

module.exports = router;
