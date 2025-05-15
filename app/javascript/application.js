console.log("✅ application.js loaded");

import "@hotwired/turbo-rails";
import "@hotwired/stimulus";
import "@hotwired/stimulus-loading";
import "@github/auto-complete-element";
import "@rails/actioncable";

import "./full_text";
import "./footer";
import "./logging";
import "./main/search";
import "./progress_bar_full";
import "./progress_bar_single";
import "./timestamp_links";

import { createPopper } from "@popperjs/core";  // Popper must be imported first
import bootstrap from "bootstrap";
import githubAutoCompleteElement from "@github/auto-complete-element";
import Blacklight from "blacklight";
