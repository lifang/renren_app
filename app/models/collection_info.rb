# encoding: utf-8
class CollectionInfo < ActiveRecord::Base
  def self.update_collection_infos(paper_id, user_id, question_ids)
    info = CollectionInfo.find_by_paper_id_and_user_id(paper_id, user_id)
    if info.nil?
      CollectionInfo.create(:paper_id => paper_id, :user_id => user_id, :question_ids => question_ids.join(","))
    else
      new_arr = info.question_ids.nil? ? question_ids : (question_ids | info.question_ids.split(","))
      info.update_attributes(:question_ids => new_arr.join(","))
    end
  end
end
