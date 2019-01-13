require 'elasticsearch/model'

class Article < ActiveRecord::Base

  # validations
  validates_presence_of :title, :subtitle, :content

  # elasticsearch configuration
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  after_save :re_index

  settings index: { number_of_shards: 1 } do
    mappings dynamic: 'false' do
      indexes :title, analyzer: 'english', index_options: 'offsets'
      indexes :subtitle, analyzer: 'english'
      indexes :content, analyzer: 'english'
    end
  end

  def self.search(query)
    __elasticsearch__.search(
        {
            query: {
                multi_match: {
                    query: query,
                    fields: ['title^10', 'subtitle', 'content']
                }
            },
            highlight: {
                pre_tags: ['<em>'],
                post_tags: ['</em>'],
                fields: {
                    title: {},
                    subtitle: {},
                    content: {}
                }
            }
        }
    )
  end

  private

  def re_index
    self.__elasticsearch__.index_document
  end
end

# Delete the previous articles index in Elasticsearch
Article.__elasticsearch__.client.indices.delete index: Article.index_name rescue nil

# Create the new index with the new mapping
Article.__elasticsearch__.client.indices.create \
  index: Article.index_name,
  body: { settings: Article.settings.to_hash, mappings: Article.mappings.to_hash }

# Index all article records from the DB to Elasticsearch
Article.import force: true
