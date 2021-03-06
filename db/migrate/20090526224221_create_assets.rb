class CreateAssets < ActiveRecord::Migration
  def self.up
    create_table :assets, :force => true do |t|
      t.integer   :size
      t.string    :content_type
      t.string    :filename
      t.integer   :height
      t.integer   :width
      t.integer   :parent_id
      t.string    :thumbnail
      t.timestamps
    end
    
    add_index :assets, :parent_id
  end

  def self.down
    drop_table :assets
  end
end
