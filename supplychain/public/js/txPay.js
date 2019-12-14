var app = angular.module("txpay", []);
app.controller('txpayCtrl', function($scope) {
    $scope.hideMsg = true;
    $scope.payTx = function(){
        var txaddress = jQuery('#txaddress').val()
        if(txaddress == ''){
            return;
        }
        var payhash = jQuery('#payhash').val()
        if(payhash == ''){
            return;
        }
        var call_url = '/abi/txPay';
        jQuery.ajax({
        url: call_url,
        type:"post",
        data:{"address":txaddress,"payhash":payhash},
        success: function(data){
            jQuery('#msg').text("支付签名成功");
            $scope.hideMsg = false;
            $scope.$apply();
        },
        error: function(data){
             jQuery('#msg').text("支付签名错误");
             $scope.hideMsg = false;
             $scope.$apply();
        }
      });
   }
});

