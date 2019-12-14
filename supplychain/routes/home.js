var express = require('express');
var path = require('path');
var router = express.Router();

router.get('/', function(req, res, next) {
  if(!req.session.address){
    res.redirect('login');
  }
  else{
  	res.sendFile(path.join(__dirname,'../public/htmls/home/','index.html'));
  }
});

module.exports = router;