# Rich collection pages: an HTML body (TipTap, sanitized server-side like the
# puzzle description page) plus curated accent styling. The accents are closed
# sets (Rails enums), 0 = the default Ink & Paper look.
class AddPageFieldsToCollections < ActiveRecord::Migration[8.0]
  def change
    add_column :collections, :page_description_html, :text
    add_column :collections, :accent_color, :integer, default: 0, null: false
    add_column :collections, :bg_treatment, :integer, default: 0, null: false
    add_column :collections, :title_font, :integer, default: 0, null: false
  end
end
