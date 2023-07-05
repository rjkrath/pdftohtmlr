# https://www.xpdfreader.com/pdftohtml-man.html

module Pdf2Html
  class PdfFile
    attr :path, :target, :user_pwd, :owner_pwd, :format,
         :first_page_to_convert, :last_page_to_convert

    def self.convert_from_file_path!(path, **opts)
      unless File.exist?(path)
        raise StandardError, "Invalid file path"
      end

      new(path, **opts).convert
    end

    def self.convert_from_url!(url, **opts)
      begin
        URI(url)
      rescue => e
        raise StandardError, "Invalid file url #{e.message}"
      end

      begin
        stream = open(url)&.read
      rescue => e
        raise StandardError, "Error on reading url #{e.message}"
      end

      return unless stream

      tmpfile = Tempfile.new
      File.open(tmpfile.path, 'wb') { |f| f.write(stream) }

      new(tmpfile.path, **opts).convert
    end

    def initialize(pdf_path, target_path: nil, user_pwd: nil, owner_pwd: nil, first_page: nil, last_page: nil)
      @path = pdf_path
      @target = target_path
      @user_pwd = user_pwd
      @owner_pwd = owner_pwd
      @last_page_to_convert = last_page
      @first_page_to_convert = first_page
    end

    # Convert the PDF document to HTML.  Returns a string
    def convert
      opts = ['-stdout']

      opts << @format if @format
      opts << "-upw #{@user_pwd}" if @user_pwd
      opts << "-opw #{@owner_pwd}" if @owner_pwd
      opts << "\"#{@path}\""
      opts << "\"#{@target}\"" if @target

      output = `pdftohtml #{opts.join(" ")} 2>&1`

      if output.include?("Error: May not be a PDF file")
        raise PDFToHTMLRError, "Error: May not be a PDF file (continuing anyway)"
      elsif output.include?("Error:")
        raise PDFToHTMLRError, output.split("\n").first.to_s.chomp
      else
        output
      end
    end

    # Convert the PDF document to HTML.  Returns a Nokogiri::HTML:Document
    def convert_to_document
      Nokogiri::HTML.parse(convert)
    end

    def convert_to_xml
      @format = "-xml"
      convert
    end

    def convert_to_xml_document
      @format = "-xml"
      Nokogiri::XML.parse(convert)
    end
  end
end