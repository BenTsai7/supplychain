var app = angular.module("index", []);
app.controller('indexCtrl', function($scope) {
    var call_url = '/abi/info';
    var errorCode = "404 error";

    jQuery.ajax({
      url: call_url,
      success: function(data){
            jQuery('#NodeNumber').text(data['NodeNumber']);
            jQuery('#blockNumber').text(data['blockNumber']);
            jQuery('#txNumber').text(data["txNumber"]);
            jQuery('#pendingTxNumber').text(data["pendingTxNumber"]);
        },
       error: function(data){
          jQuery('#NodeNumber').text(errorCode);
          jQuery('#blockNumber').text(errorCode);
          jQuery('#txNumber').text(errorCode);
          jQuery('#pendingTxNumber').text(errorCode);
       }
    });

});

