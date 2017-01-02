module CurationConcerns
  module AdminSetBehavior
    extend ActiveSupport::Concern

    include Hydra::AccessControls::WithAccessRight
    include CurationConcerns::Noid
    include CurationConcerns::HumanReadableType
    include CurationConcerns::HasRepresentative

    included do
      validates_with HasOneTitleValidator
      class_attribute :human_readable_short_description, :indexer
      self.indexer = CurationConcerns::AdminSetIndexer

      apply_schema(CurationConcerns::Schema::AdminSetMetadata)

      has_many :members,
               predicate: ::RDF::Vocab::DC.isPartOf,
               class_name: 'ActiveFedora::Base'
    end

    def to_s
      title.present? ? title : 'No Title'
    end
  end
end
