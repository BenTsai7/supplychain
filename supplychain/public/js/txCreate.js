var app = angular.module("txcreate", []);
app.controller('txcreateCtrl', function($scope) {
    /*var errorCode = "该债权凭证不存在";
    jQuery('#Tx_Error').text(errorCode);*/
    $scope.hideError = true;
    $scope.createTx = function(){
        if($scope.params == null || Object.keys($scope.params).length!=5){
          jQuery('#Submit_Error').text("请补全所有参数");
          $scope.hideError = false;
          return;
        }
        if(isNaN(Number($scope.params.amount))|| Number($scope.params.amount)<=0){
          jQuery('#Submit_Error').text("请输入合法的额度值");
          $scope.hideError = false;
          return;
        }
        var dateStr = $scope.params.duetime;
        var date = new Date($scope.params.duetime);
        //日期转换为时间戳储存
        if(isNaN(date.getTime())){
          jQuery('#Submit_Error').text("请输入合法的日期");
          $scope.hideError = false;
          return;
        }
        if((new Date()).getTime()>=date.getTime()){
          jQuery('#Submit_Error').text("债务应还日期必须大于当前日期");
          $scope.hideError = false;
          return;
        }
        $scope.hideError = true;
        var paramspost = JSON.parse(JSON.stringify($scope.params));
        paramspost.duetime = date.getTime();
        var call_url = '/abi/txCreate';
        jQuery.ajax({
        url: call_url,
        type:"post",
        data:paramspost,
        success: function(data){
            jQuery('#Submit_Error').text("凭证创建成功 地址: " + data);
            $scope.hideError = false;
            $scope.$apply();
        },
        error: function(data){
       		   jQuery('#Submit_Error').text("凭证创建失败: " + data);
            $scope.hideError = false;
            $scope.$apply();
        }
      });
   }
});

