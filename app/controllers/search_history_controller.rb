# frozen_string_literal: true

class SearchHistoryController < ApplicationController
  include Blacklight::SearchHistory

  # The Blacklight::SearchHistory module includes all necessary functionality
  # No additional methods needed
end 