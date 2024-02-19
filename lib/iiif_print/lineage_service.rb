module IiifPrint
  # The purpose of this module is to encode lineage related services:
  #
  # - {.ancestor_ids_for}
  # - {.descendent_member_ids_for}
  # - {.ancestor_identifier_for}
  #
  # The ancestor and descendent_file_sets are useful for ensuring we index together related items.
  # For example, when I have a work that is a book, and one file set per page of that book, when I
  # search the book I want to find the text within the given book's pages.
  #
  # The methods of this module should be considered as defining an interface.
  module LineageService
    ##
    # @api public
    #
    # @param object [#in_works] An object that responds to #in_works
    # @return [Array<String>]
    #
    # @note For those implementing their own lineage service, verify that you are not returning
    #       an array of
    def self.ancestor_ids_for(object)
      ancestor_ids ||= []
      # Yes, we're fetching the works, then compressing those into identifiers.  Because in the case
      # of slugs, we need not the identifier, but the slug as the id.
      IiifPrint.object_in_works(object).each do |work|
        ancestor_ids << ancestry_identifier_for(work)
        ancestor_ids += ancestor_ids_for(work) if work.respond_to?(:is_child) && work.is_child
      end
      # We must convert these to strings as Valkyrie's identifiers will be cast to hashes when we
      # attempt to write the SolrDocument.  Also, per documentation we return an Array of strings, not
      # an Array that might include Valkyrie::ID objects.
      ancestor_ids.flatten.compact.uniq.map(&:to_s)
    end

    ##
    # @api public
    #
    # Given the :work return it's identifier
    #
    # @param [Object]
    # @return [String]
    def self.ancestry_identifier_for(work)
      IiifPrint.config.ancestory_identifier_function.call(work)
    end

    ##
    # @param object [#ordered_works, #file_sets, #member_ids]
    # @return [Array<String>] the ids of associated file sets and child works
    #
    # @see
    # https://github.com/samvera/hyrax/blob/2b807fe101176d594129ef8a8fe466d3d03a372b/app/indexers/hyrax/work_indexer.rb#L15-L18
    # for "clarification" of the comingling of file_set_ids and member_ids
    def self.descendent_member_ids_for(object)
      # enables us to return parents when searching for child OCR
      #
      # https://github.com/samvera/hydra-works/blob/c9b9dd0cf11de671920ba0a7161db68ccf9b7f6d/lib/hydra/works/models/concerns/work_behavior.rb#L90-L92
      #
      # The Hydara::Works implementation of file_set_ids is "members.select(&:file_set?).map(&:id)";
      # so no sense doing `object.file_set_ids + object.member_ids`
      file_set_ids = object.member_ids
      IiifPrint.object_ordered_works(object)&.each do |child|
        file_set_ids += descendent_member_ids_for(child)
      end
      # We must convert these to strings as Valkyrie's identifiers will be cast to hashes when we
      # attempt to write the SolrDocument.
      file_set_ids.flatten.uniq.compact.map(&:to_s)
    end
    class << self
      alias descendent_file_set_ids_for descendent_member_ids_for
    end
  end
end
