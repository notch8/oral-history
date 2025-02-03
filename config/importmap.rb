# Pin npm packages by running ./bin/importmap

pin "application"
pin "bootstrap" # @5.3.3
pin "footer", to: "footer.js"
pin "full_text", to: "full_text.js"
pin "timestamp_links", to: "timestamp_links.js"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "@github/auto-complete-element", to: "https://cdn.skypack.dev/@github/auto-complete-element"
pin "@popperjs/core", to: "@popperjs--core.js" # @2.11.8
pin "@rails/actioncable", to: "actioncable.esm.js"
pin_all_from "app/javascript/channels", under: "channels"
pin_all_from "app/javascript/clappr", under: "clappr"
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/main", under: "main"
pin_all_from "app/javascript/vendor", under: "vendor"
