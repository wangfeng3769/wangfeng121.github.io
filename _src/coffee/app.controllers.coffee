angular.module "gitblog"

.controller "IndexController", [
  "$scope"
  ($scope)->
    $scope.$root.loading = true
    $scope.blogListReady.then ->
      $scope.$root.loading = false
]

.controller "AboutController", [
  "$scope"
  ($scope)->
    $scope.$root.loading = true
    $scope.blogListReady.then ->
      $scope.$root.loading = false
]

.controller "ListController", [
  "$scope"
  "$routeParams"
  "$location"
  ($scope, $routeParams, $location)->
    $scope.$root.loading = true
    username = $routeParams.user
    reponame = $routeParams.repo
    $scope.blogListReady.then ->
      if repo = $scope.getRepo(username, reponame)
        _repo = repo._repo
        _repo.git.getTree('master', recursive:true)
        .then (tree)->
          $scope.saveCache()

          posts = []
          configFileExists = false

          postReg = /^(_posts)\/(?:[\w\.-]+\/)*(\d{4})-(\d{2})-(\d{2})-(.+?)\.md$/
          configFileReg = /^_config.yml$/
          for file in tree
            if file.type != 'blob' then continue
            if res = file.path.match postReg
              posts.push
                user:username
                repo:reponame
                type:res[1]
                date:new Date(parseInt(res[2], 10), parseInt(res[3], 10) - 1, parseInt(res[4], 10))
                urlTitle:res[5]
                info:file
            else if configFileReg.test file.path
              configFileExists = true

          if configFileExists
            $scope.$apply ->
              $scope.$root.loading = false
              $scope.reponame = reponame
              $scope.username = username
              $scope.posts = posts
      else
        console.error "blog do not exist"
        $location.path('/').replace()
]

.controller "PostController", [
  "$scope"
  "$routeParams"
  "$location"
  "$timeout"
  "uploader"
  ($scope, $routeParams, $location, $timeout, uploader)->
    $scope.$root.loading = true
    username = $routeParams.user
    reponame = $routeParams.repo
    path = $routeParams.path
    sha = $routeParams.sha
    $scope.username = username
    $scope.reponame = reponame
    $scope.filepath = path

    $scope.blogListReady.then ->
      if repo = $scope.getRepo(username, reponame)
        _repo = repo._repo
        $scope.uploader = uploader.call($scope, _repo)

        save = ->
          $scope.$root.loading = true
          branch =　_repo.getBranch "master"
          message = "Update by gitblog-io.github.io at " + (new Date()).toLocaleString()
          promise = branch.write(path, $scope.post, message, false)
          promise.then (res)->
            $scope.$evalAsync ->
              $scope.$root.loading = false
              $scope.postForm.$setPristine()
          , (err)->
            $scope.$root.loading = false
            console.error err

          promise

        deleteFunc = ->
          if window.confirm("Are you sure to delete #{$scope.filepath}?")
            $scope.$root.loading = true
            branch =　_repo.getBranch "master"
            message = "Update by gitblog-io.github.io at " + (new Date()).toLocaleString()
            promise = branch.remove(path, message)
            promise.then (res)->
              $scope.$evalAsync ->
                $scope.$root.loadingText = "Redirecting to list..."

              $timeout ->
                $location.path("/#{username}/#{reponame}")
                .replace()
              , 1500
            , (err)->
              $scope.$root.loading = false
              console.error err

            promise

        show = ->
          _repo.git.getBlob(sha)
          .then (post)->
            $scope.saveCache()

            $scope.$apply ->
              $scope.$root.loading = false
              $scope.post = post

              $scope.save = save

              $scope.delete = deleteFunc
          , (err)->
            if err.status == 404
              searchAndShow()
            else
              $scope.$root.loading = false
              console.error err.error

        searchAndShow = ->
          _repo.git.getTree('master', recursive:true)
          .then (tree)->
            $scope.saveCache()

            blob = _.findWhere tree,
              path: path
            if blob?
              sha = blob.sha
              show()
            else
              $scope.$root.loading = false
              console.error "file path not found"

        newPost = """---
          layout: post
          title:
          tagline:
          category: null
          tags: []
          published: true
          ---

          """

        unless sha?
          if path == "new"
            $scope.new = true
            $scope.$root.loading = false
            $scope.post = newPost

            $scope.save = ->
              date = new Date()
              y = date.getFullYear()
              m = date.getMonth()
              m = if m >= 10 then m + 1 else "0" + (m + 1)
              d = date.getDate()
              d = if d >= 10 then d else "0" + d
              name = $scope.frontMatter.title.replace(/\s/g, '-')
              path = "_posts/#{y}-#{m}-#{d}-#{name}.md"
              save()
              .then (res)->
                $scope.$evalAsync ->
                  $scope.$root.loading = true
                  $scope.$root.loadingText = "Redirecting to saved post.."
                $timeout ->
                  $location.path("/#{username}/#{reponame}/#{path}")
                  .replace()
                , 1500

          else
            searchAndShow()
        else
          show()
      else
        console.error "blog do not exist"
        $location.path('/').replace()
]