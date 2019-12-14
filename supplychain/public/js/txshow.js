var app = angular.module("txshow", []);
app.controller('showCtrl', function($scope) {
    var errorCode = "该债权凭证不存在";
    jQuery('#Tx_Error').text(errorCode);
    $scope.hideError = true;
    $scope.hideTable = true;
    $scope.getTxInfo = function(){
        var content = jQuery('#TxAddress').val()
        if(content == ''){
            return;
        }
        var call_url = '/abi/txSearch';
        jQuery.ajax({
        url: call_url,
        type:"post",
        data:{"address":content},
        success: function(data){
            $scope.data = data;
            $scope.hideError = true;
            $scope.hideTable = false;
            $scope.$apply();
        },
        error: function(data){
       		   $scope.data = null;
             $scope.hideError = false;
             $scope.hideTable = true;
             $scope.$apply();
        }
      });
   }
});

