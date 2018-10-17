require 'asciidoctor-templates-compiler'

module Asciidoctor::TemplatesCompiler
  class RevealjsSlim < Asciidoctor::TemplatesCompiler::Slim
    def engine_options
      ::Asciidoctor::Converter::TemplateConverter::DEFAULT_ENGINE_OPTIONS[:slim].merge(
        generator: Temple::Generators::ArrayBuffer.new(capture_generator: 'ArrayBuffer')
      )
    end
  end
end
