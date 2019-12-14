var express = require('express');
var path = require('path');
var router = express.Router();

/* GET home page. */
router.get('/', function(req, res, next) {
  if(req.session.address){
    res.redirect('home');
  }else{
    res.redirect('login');
  }
});

module.exports = router;
