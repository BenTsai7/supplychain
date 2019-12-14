var app = angular.module("txtrans", []);
app.controller('txtransCtrl', function($scope) {
    $scope.hideError = true;
    $scope.transTx = function(){
        if( Object.keys($scope.params).length<5){
          jQuery('#Submit_Error').text("请补全所有参数");
          $scope.hideError = false;
          return;
        }
        if(isNaN(Number($scope.params.amount))|| Number($scope.params.amount)<=0){
          jQuery('#Submit_Error').text("请输入合法的额度值");
          $scope.hideError = false;
          return;
        }
        $scope.params["fundtype"]= (jQuery("#inputState").val()=="融资");
        $scope.hideError = true;
        var call_url = '/abi/txTrans';
        jQuery.ajax({
        url: call_url,
        type:"post",
        data:$scope.params,
        success: function(data){
            jQuery('#Submit_Error').text("凭证转让成功 新凭证地址: " + data);
            $scope.hideError = false;
            $scope.$apply();
        },
        error: function(data){
       		   jQuery('#Submit_Error').text("凭证转让失败");
            $scope.hideError = false;
            $scope.$apply();
        }
      });
   }
});

