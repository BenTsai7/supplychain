var app = angular.module("txsign", []);
app.controller('txsignCtrl', function($scope) {
    $scope.hideError = true;
    $scope.acceptTx = function(){
        var content = jQuery('#txaddress').val()
        if(content == ''){
            return;
        }
        var call_url = '/abi/txSign';
        jQuery.ajax({
        url: call_url,
        type:"post",
        data:{"address":content,"accept":true},
        success: function(data){
            jQuery('#error_msg').text("签名成功");
            $scope.hideError = false;
            $scope.$apply();
        },
        error: function(data){
             jQuery('#error_msg').text("签名错误");
             $scope.hideError = false;
             $scope.$apply();
        }
      });
   }
   $scope.confirmTx = function(){
        var content = jQuery('#txaddress').val()
        if(content == ''){
            return;
        }
        var call_url = '/abi/txSign';
        jQuery.ajax({
        url: call_url,
        type:"post",
        data:{"address":content,"accept":false},
        success: function(data){
            console.log(data);
            jQuery('#error_msg').text("签名成功");
            $scope.hideError = false;
            $scope.$apply();
        },
        error: function(data){
             jQuery('#error_msg').text("签名错误");
             $scope.hideError = false;
             $scope.$apply();
        }
      });
   }
});

