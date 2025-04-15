console.log("Application.js loaded");

// import "jquery";
import "@hotwired/turbo-rails";
import "@hotwired/stimulus";
import "@hotwired/stimulus-loading";
import "@github/auto-complete-element";
// import "@popperjs/core";
import "@rails/actioncable";

import "./timestamp_links";
import "./full_text";
import "./footer";
import "./main/search";

import { createPopper } from "@popperjs/core";  // Popper must be imported first
import bootstrap from "bootstrap";
import githubAutoCompleteElement from "@github/auto-complete-element";
import Blacklight from "blacklight";
