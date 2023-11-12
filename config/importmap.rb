# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/custom",      under: "custom"; pin "jquery", to: "https://ga.jspm.io/npm:jquery@3.7.1/dist/jquery.js"
#pin "goals/new", to: "path_to_goals.js"
pin_all_from 'app/javascript', under: 'javascript'
pin_all_from "app/javascript/controllers", under: "controllers"
pin "goals", to: "goals.js"
pin "small_goals", to: "small_goals.js"