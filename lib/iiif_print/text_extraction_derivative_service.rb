require 'iiif_print/text_formats_from_alto_service'

module IiifPrint
  class TextExtractionDerivativeService < BaseDerivativeService
    # @param [Hash<Symbol,Symbol>]
    #
    # The key for the hash represents the file extension.  The key's value represents the instance
    # method to call on {IiifPrint::TextExtraction::PageOCR}
    class_attribute :ocr_derivatives, default: { txt: :plain, xml: :alto, json: :word_json }
    class_attribute :alto_derivative_service_class, default: IiifPrint::TextFormatsFromALTOService
    class_attribute :page_ocr_service_class, default: IiifPrint::TextExtraction::PageOCR
    def initialize(file_set)
      super(file_set)
    end

    def create_derivatives(src)
      from_alto = alto_derivative_service_class.new(
        file_set
      )
      return from_alto.create_derivatives(src) unless from_alto.alto_path.nil?
      create_derivatives_from_ocr(src)
    end

    def create_derivatives_from_ocr(filename)
      # TODO: Do we need this source_path instance variable?
      @source_path = filename
      ocr = page_ocr_service_class.new(filename)

      ocr_derivatives.each do |extension, method_name|
        path = prepare_path(extension.to_s)
        write(content: ocr.public_send(method_name), path: path)
      end
    end

    def write(content:, path:)
      File.open(path, 'w') do |outfile|
        outfile.write(content)
      end
    end

    def cleanup_derivatives(*)
      ocr_derivatives.keys do |extension|
        super(extension.to_s)
      end
    end
  end
end
