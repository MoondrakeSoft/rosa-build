RosaABF.controller 'BuildLogController', ['$scope', '$http', '$timeout', '$sanitize', ($scope, $http, $timeout, $sanitize) ->

  $scope.path           = null
  $scope.log            = null
  $scope.build_started  = true

  $scope.init = (path) ->
    $scope.path = path
    $scope.getLog()

  $scope.getLog = ->
    return unless $scope.build_started

    if $('.build-log').is(':visible')
      $http.get($scope.path, timeout: 30000).success((res) ->
        $scope.log = res.log
        $scope.build_started = res.building
      ).error(->
        $scope.log = null
      ).finally ->
        $timeout $scope.getLog, 10000
    true
]