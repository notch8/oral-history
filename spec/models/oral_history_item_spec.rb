require 'rails_helper'

describe OralHistoryItem do
  it "can import item" do
    expected_imported = 2
    total_imported = OralHistoryItem.import({limit: expected_imported})
    expect(total_imported).to eq expected_imported
  end

  # Pending until false negative issue resolved
  xit "doesn't reimport duplicate records" do
    # it is possible that this may give a false negative due to sorting of records
    total_imported = OralHistoryItem.import({progress: false, limit: 1})
    expect(total_imported).to eq 1
    document_id = OralHistoryItem.fetch_first_id
    record = OralHistoryItem.find_or_new(document_id)
    expect(record.new_record?).to eq false
  end

  it "can import a specific single item" do 
    document_id = OralHistoryItem.fetch_first_id
    imported_record = OralHistoryItem.import_single(document_id)
    expect(imported_record.id).to match document_id
  end

end