# This file has been generated!

module Asciidoctor; module Revealjs; end end
class Asciidoctor::Revealjs::Converter < ::Asciidoctor::Converter::Base

  #------------------------------ Begin of Helpers ------------------------------#

  unless RUBY_ENGINE == 'opal'
    # This helper file borrows from the Bespoke converter
    # https://github.com/asciidoctor/asciidoctor-bespoke
    require 'asciidoctor'
  end

  # This module gets mixed in to every node (the context of the template) at the
  # time the node is being converted. The properties and methods in this module
  # effectively become direct members of the template.
  module Helpers

    EOL = %(\n)
    SliceHintRx = /  +/

    def slice_text str, active = nil
      if (active || (active.nil? && (option? :slice))) && (str.include? '  ')
        (str.split SliceHintRx).map {|line| %(<span class="line">#{line}</span>) }.join EOL
      else
        str
      end
    end

    def to_boolean val
      val && val != 'false' && val.to_s != '0' || false
    end

    # false needs to be verbatim everything else is a string.
    # Calling side isn't responsible for quoting so we are doing it here
    def to_valid_slidenumber val
      # corner case: empty is empty attribute which is true
      return true if val == ""
      # using to_s here handles both the 'false' string and the false boolean
      val.to_s == 'false' ? false : "'#{val}'"
    end

    ##
    # These constants and functions are from the asciidictor-html5s project
    # https://github.com/jirutka/asciidoctor-html5s/blob/a71db48a1dd5196b668b3a3d93693c5d877c5bf3/data/templates/helpers.rb

    # Defaults
    DEFAULT_TOCLEVELS = 2
    DEFAULT_SECTNUMLEVELS = 3


    VOID_ELEMENTS = %w(area base br col command embed hr img input keygen link
                       meta param source track wbr)

    ##
    # Creates an HTML tag with the given name and optionally attributes. Can take
    # a block that will run between the opening and closing tags.
    #
    # @param name [#to_s] the name of the tag.
    # @param attributes [Hash] (default: {})
    # @param content [#to_s] the content; +nil+ to call the block. (default: nil).
    # @yield The block of Slim/HTML code within the tag (optional).
    # @return [String] a rendered HTML element.
    #

    def html_tag(name, attributes = {}, content = nil)
      attrs = attributes.inject([]) do |attrs, (k, v)|
        next attrs if !v || v.nil_or_empty?
        v = v.compact.join(' ') if v.is_a? Array
        attrs << (v == true ? k : %(#{k}="#{v}"))
      end
      attrs_str = attrs.empty? ? '' : ' ' + attrs.join(' ')


      if VOID_ELEMENTS.include? name.to_s
        %(<#{name}#{attrs_str}>)
      else
        content ||= yield if block_given?
        %(<#{name}#{attrs_str}>#{content}</#{name}>)
      end
    end


    ##
    # Returns corrected section level.
    #
    # @param sec [Asciidoctor::Section] the section node (default: self).
    # @return [Integer]
    #
    def section_level(sec = self)
      @_section_level ||= (sec.level == 0 && sec.special) ? 1 : sec.level
    end


    ##
    # Returns the captioned section's title, optionally numbered.
    #
    # @param sec [Asciidoctor::Section] the section node (default: self).
    # @return [String]
    #
    def section_title(sec = self)
      sectnumlevels = document.attr(:sectnumlevels, DEFAULT_SECTNUMLEVELS).to_i

      if sec.numbered && !sec.caption && sec.level <= sectnumlevels
        [sec.sectnum, sec.captioned_title].join(' ')
      else
        sec.captioned_title
      end
    end


    # Between delimiters (--) is code taken from asciidoctor-bespoke 1.0.0.alpha.1
    # Licensed under MIT, Copyright (C) 2015-2016 Dan Allen and the Asciidoctor Project
    #--
    # Retrieve the converted content, wrap it in a `<p>` element if
    # the content_model equals :simple and return the result.
    #
    # Returns the block content as a String, wrapped inside a `<p>` element if
    # the content_model equals `:simple`.
    def resolve_content
      @content_model == :simple ? %(<p>#{content}</p>) : content
    end
    #--

  end

  # More custom functions can be added in another namespace if required
  #module Helpers
  #end


  # Make Helpers' constants accessible from transform methods.
  Helpers.constants.each do |const|
    const_set(const, Helpers.const_get(const))
  end

  #------------------------------- End of Helpers -------------------------------#


  register_for "revealjs", "reveal.js"

  def initialize(backend, opts = {})
    super
    basebackend "html" if respond_to? :basebackend
    outfilesuffix ".html" if respond_to? :outfilesuffix
    filetype "html" if respond_to? :filetype

    delegate_backend = (opts[:delegate_backend] || "html5").to_s
    factory = ::Asciidoctor::Converter::Factory

    converter = factory.create(delegate_backend, backend_info)
    @delegate_converter = if converter == self
      factory.new.create(delegate_backend, backend_info)
    else
      converter
    end
  end

  def convert(node, transform = nil, opts = {})
    transform ||= node.node_name
    converter = respond_to?(transform) ? self : @delegate_converter

    if opts.empty?
      converter.send(transform, node)
    else
      converter.send(transform, node, opts)
    end
  end

  #----------------- Begin of generated transformation methods -----------------#


  def toc(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; _buf << ("<div id=\"toc\"".freeze); _temple_html_attributeremover1 = ''; _slim_codeattributes1 = (document.attr 'toc-class', 'toc'); if Array === _slim_codeattributes1; _slim_codeattributes1 = _slim_codeattributes1.flatten; _slim_codeattributes1.map!(&:to_s); _slim_codeattributes1.reject!(&:empty?); _temple_html_attributeremover1 << ((_slim_codeattributes1.join(" ")).to_s); else; _temple_html_attributeremover1 << ((_slim_codeattributes1).to_s); end; _temple_html_attributeremover1; if !_temple_html_attributeremover1.empty?; _buf << (" class=\"".freeze); _buf << ((_temple_html_attributeremover1).to_s); _buf << ("\"".freeze); end; _buf << ("><div id=\"toctitle\">".freeze); 
      ; _buf << (((document.attr 'toc-title')).to_s); 
      ; _buf << ("</div>".freeze); 
      ; _buf << ((converter.convert document, 'outline').to_s); 
      ; _buf << ("</div>".freeze); _buf
    end
  end

  def page_break(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; _buf << ("<div style=\"page-break-after: always;\"></div>".freeze); 
      ; _buf
    end
  end

  def open(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; if @style == 'abstract'; 
      ; if @parent == @document && @document.doctype == 'book'; 
      ; puts 'asciidoctor: WARNING: abstract block cannot be used in a document without a title when doctype is book. Excluding block content.'; 
      ; else; 
      ; _buf << ("<div".freeze); _temple_html_attributeremover1 = ''; _temple_html_attributemerger1 = []; _temple_html_attributemerger1[0] = "quoteblock"; _temple_html_attributemerger1[1] = "abstract"; _temple_html_attributemerger1[2] = ''; _slim_codeattributes1 = role; if Array === _slim_codeattributes1; _slim_codeattributes1 = _slim_codeattributes1.flatten; _slim_codeattributes1.map!(&:to_s); _slim_codeattributes1.reject!(&:empty?); _temple_html_attributemerger1[2] << ((_slim_codeattributes1.join(" ")).to_s); else; _temple_html_attributemerger1[2] << ((_slim_codeattributes1).to_s); end; _temple_html_attributemerger1[2]; _temple_html_attributeremover1 << ((_temple_html_attributemerger1.reject(&:empty?).join(" ")).to_s); _temple_html_attributeremover1; if !_temple_html_attributeremover1.empty?; _buf << (" class=\"".freeze); _buf << ((_temple_html_attributeremover1).to_s); _buf << ("\"".freeze); end; _slim_codeattributes2 = @id; if _slim_codeattributes2; if _slim_codeattributes2 == true; _buf << (" id".freeze); else; _buf << (" id=\"".freeze); _buf << ((_slim_codeattributes2).to_s); _buf << ("\"".freeze); end; end; _buf << (">".freeze); 
      ; if title?; 
      ; _buf << ("<div class=\"title\">".freeze); _buf << ((title).to_s); 
      ; _buf << ("</div>".freeze); end; _buf << ("<blockquote>".freeze); _buf << ((content).to_s); 
      ; _buf << ("</blockquote></div>".freeze); end; elsif @style == 'partintro' && (@level != 0 || @parent.context != :section || @document.doctype != 'book'); 
      ; puts 'asciidoctor: ERROR: partintro block can only be used when doctype is book and it\'s a child of a book part. Excluding block content.'; 
      ; else; 
      ; if (has_role? 'aside') or (has_role? 'speaker') or (has_role? 'notes'); 
      ; _buf << ("<aside class=\"notes\">".freeze); _buf << ((resolve_content).to_s); 
      ; _buf << ("</aside>".freeze); 
      ; else; 
      ; _buf << ("<div".freeze); _temple_html_attributeremover2 = ''; _temple_html_attributemerger2 = []; _temple_html_attributemerger2[0] = "openblock"; _temple_html_attributemerger2[1] = ''; _slim_codeattributes3 = [(@style != 'open' ? @style : nil),role]; if Array === _slim_codeattributes3; _slim_codeattributes3 = _slim_codeattributes3.flatten; _slim_codeattributes3.map!(&:to_s); _slim_codeattributes3.reject!(&:empty?); _temple_html_attributemerger2[1] << ((_slim_codeattributes3.join(" ")).to_s); else; _temple_html_attributemerger2[1] << ((_slim_codeattributes3).to_s); end; _temple_html_attributemerger2[1]; _temple_html_attributeremover2 << ((_temple_html_attributemerger2.reject(&:empty?).join(" ")).to_s); _temple_html_attributeremover2; if !_temple_html_attributeremover2.empty?; _buf << (" class=\"".freeze); _buf << ((_temple_html_attributeremover2).to_s); _buf << ("\"".freeze); end; _slim_codeattributes4 = @id; if _slim_codeattributes4; if _slim_codeattributes4 == true; _buf << (" id".freeze); else; _buf << (" id=\"".freeze); _buf << ((_slim_codeattributes4).to_s); _buf << ("\"".freeze); end; end; _buf << (">".freeze); 
      ; if title?; 
      ; _buf << ("<div class=\"title\">".freeze); _buf << ((title).to_s); 
      ; _buf << ("</div>".freeze); end; _buf << ("<div class=\"content\">".freeze); _buf << ((content).to_s); 
      ; _buf << ("</div></div>".freeze); end; end; _buf
    end
  end

  def paragraph(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; _buf << ("<div".freeze); _temple_html_attributeremover1 = ''; _temple_html_attributemerger1 = []; _temple_html_attributemerger1[0] = "paragraph"; _temple_html_attributemerger1[1] = ''; _slim_codeattributes1 = role; if Array === _slim_codeattributes1; _slim_codeattributes1 = _slim_codeattributes1.flatten; _slim_codeattributes1.map!(&:to_s); _slim_codeattributes1.reject!(&:empty?); _temple_html_attributemerger1[1] << ((_slim_codeattributes1.join(" ")).to_s); else; _temple_html_attributemerger1[1] << ((_slim_codeattributes1).to_s); end; _temple_html_attributemerger1[1]; _temple_html_attributeremover1 << ((_temple_html_attributemerger1.reject(&:empty?).join(" ")).to_s); _temple_html_attributeremover1; if !_temple_html_attributeremover1.empty?; _buf << (" class=\"".freeze); _buf << ((_temple_html_attributeremover1).to_s); _buf << ("\"".freeze); end; _slim_codeattributes2 = @id; if _slim_codeattributes2; if _slim_codeattributes2 == true; _buf << (" id".freeze); else; _buf << (" id=\"".freeze); _buf << ((_slim_codeattributes2).to_s); _buf << ("\"".freeze); end; end; _buf << (">".freeze); 
      ; if title?; 
      ; _buf << ("<div class=\"title\">".freeze); _buf << ((title).to_s); 
      ; _buf << ("</div>".freeze); end; if has_role? 'small'; 
      ; _buf << ("<small>".freeze); _buf << ((content).to_s); 
      ; _buf << ("</small>".freeze); else; 
      ; _buf << ("<p>".freeze); _buf << ((content).to_s); 
      ; _buf << ("</p>".freeze); end; _buf << ("</div>".freeze); _buf
    end
  end

  def verse(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; _buf << ("<div".freeze); _temple_html_attributeremover1 = ''; _temple_html_attributemerger1 = []; _temple_html_attributemerger1[0] = "verseblock"; _temple_html_attributemerger1[1] = ''; _slim_codeattributes1 = role; if Array === _slim_codeattributes1; _slim_codeattributes1 = _slim_codeattributes1.flatten; _slim_codeattributes1.map!(&:to_s); _slim_codeattributes1.reject!(&:empty?); _temple_html_attributemerger1[1] << ((_slim_codeattributes1.join(" ")).to_s); else; _temple_html_attributemerger1[1] << ((_slim_codeattributes1).to_s); end; _temple_html_attributemerger1[1]; _temple_html_attributeremover1 << ((_temple_html_attributemerger1.reject(&:empty?).join(" ")).to_s); _temple_html_attributeremover1; if !_temple_html_attributeremover1.empty?; _buf << (" class=\"".freeze); _buf << ((_temple_html_attributeremover1).to_s); _buf << ("\"".freeze); end; _slim_codeattributes2 = @id; if _slim_codeattributes2; if _slim_codeattributes2 == true; _buf << (" id".freeze); else; _buf << (" id=\"".freeze); _buf << ((_slim_codeattributes2).to_s); _buf << ("\"".freeze); end; end; _buf << (">".freeze); 
      ; if title?; 
      ; _buf << ("<div class=\"title\">".freeze); _buf << ((title).to_s); 
      ; _buf << ("</div>".freeze); end; _buf << ("<pre class=\"content\">".freeze); _buf << ((content).to_s); 
      ; _buf << ("</pre>".freeze); attribution = (attr? :attribution) ? (attr :attribution) : nil; 
      ; citetitle = (attr? :citetitle) ? (attr :citetitle) : nil; 
      ; if attribution || citetitle; 
      ; _buf << ("<div class=\"attribution\">".freeze); 
      ; if citetitle; 
      ; _buf << ("<cite>".freeze); _buf << ((citetitle).to_s); 
      ; _buf << ("</cite>".freeze); end; if attribution; 
      ; if citetitle; 
      ; _buf << ("<br>".freeze); 
      ; end; _buf << ("&#8212; ".freeze); _buf << ((attribution).to_s); 
      ; end; _buf << ("</div>".freeze); end; _buf << ("</div>".freeze); _buf
    end
  end

  def dlist(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; case @style; 
      ; when 'qanda'; 
      ; _buf << ("<div".freeze); _temple_html_attributeremover1 = ''; _temple_html_attributemerger1 = []; _temple_html_attributemerger1[0] = "qlist"; _temple_html_attributemerger1[1] = ''; _slim_codeattributes1 = ['qanda',role]; if Array === _slim_codeattributes1; _slim_codeattributes1 = _slim_codeattributes1.flatten; _slim_codeattributes1.map!(&:to_s); _slim_codeattributes1.reject!(&:empty?); _temple_html_attributemerger1[1] << ((_slim_codeattributes1.join(" ")).to_s); else; _temple_html_attributemerger1[1] << ((_slim_codeattributes1).to_s); end; _temple_html_attributemerger1[1]; _temple_html_attributeremover1 << ((_temple_html_attributemerger1.reject(&:empty?).join(" ")).to_s); _temple_html_attributeremover1; if !_temple_html_attributeremover1.empty?; _buf << (" class=\"".freeze); _buf << ((_temple_html_attributeremover1).to_s); _buf << ("\"".freeze); end; _slim_codeattributes2 = @id; if _slim_codeattributes2; if _slim_codeattributes2 == true; _buf << (" id".freeze); else; _buf << (" id=\"".freeze); _buf << ((_slim_codeattributes2).to_s); _buf << ("\"".freeze); end; end; _buf << (">".freeze); 
      ; if title?; 
      ; _buf << ("<div class=\"title\">".freeze); _buf << ((title).to_s); 
      ; _buf << ("</div>".freeze); end; _buf << ("<ol>".freeze); 
      ; items.each do |questions, answer|; 
      ; _buf << ("<li>".freeze); 
      ; [*questions].each do |question|; 
      ; _buf << ("<p><em>".freeze); _buf << ((question.text).to_s); 
      ; _buf << ("</em></p>".freeze); end; unless answer.nil?; 
      ; if answer.text?; 
      ; _buf << ("<p>".freeze); _buf << ((answer.text).to_s); 
      ; _buf << ("</p>".freeze); end; if answer.blocks?; 
      ; _buf << ((answer.content).to_s); 
      ; end; end; _buf << ("</li>".freeze); end; _buf << ("</ol></div>".freeze); when 'horizontal'; 
      ; _buf << ("<div".freeze); _temple_html_attributeremover2 = ''; _temple_html_attributemerger2 = []; _temple_html_attributemerger2[0] = "hdlist"; _temple_html_attributemerger2[1] = ''; _slim_codeattributes3 = role; if Array === _slim_codeattributes3; _slim_codeattributes3 = _slim_codeattributes3.flatten; _slim_codeattributes3.map!(&:to_s); _slim_codeattributes3.reject!(&:empty?); _temple_html_attributemerger2[1] << ((_slim_codeattributes3.join(" ")).to_s); else; _temple_html_attributemerger2[1] << ((_slim_codeattributes3).to_s); end; _temple_html_attributemerger2[1]; _temple_html_attributeremover2 << ((_temple_html_attributemerger2.reject(&:empty?).join(" ")).to_s); _temple_html_attributeremover2; if !_temple_html_attributeremover2.empty?; _buf << (" class=\"".freeze); _buf << ((_temple_html_attributeremover2).to_s); _buf << ("\"".freeze); end; _slim_codeattributes4 = @id; if _slim_codeattributes4; if _slim_codeattributes4 == true; _buf << (" id".freeze); else; _buf << (" id=\"".freeze); _buf << ((_slim_codeattributes4).to_s); _buf << ("\"".freeze); end; end; _buf << (">".freeze); 
      ; if title?; 
      ; _buf << ("<div class=\"title\">".freeze); _buf << ((title).to_s); 
      ; _buf << ("</div>".freeze); end; _buf << ("<table>".freeze); 
      ; if (attr? :labelwidth) || (attr? :itemwidth); 
      ; _buf << ("<colgroup><col".freeze); 
      ; _slim_codeattributes5 = ((attr? :labelwidth) ? %(width:#{(attr :labelwidth).chomp '%'}%;) : nil); if _slim_codeattributes5; if _slim_codeattributes5 == true; _buf << (" style".freeze); else; _buf << (" style=\"".freeze); _buf << ((_slim_codeattributes5).to_s); _buf << ("\"".freeze); end; end; _buf << ("><col".freeze); 
      ; _slim_codeattributes6 = ((attr? :itemwidth) ? %(width:#{(attr :itemwidth).chomp '%'}%;) : nil); if _slim_codeattributes6; if _slim_codeattributes6 == true; _buf << (" style".freeze); else; _buf << (" style=\"".freeze); _buf << ((_slim_codeattributes6).to_s); _buf << ("\"".freeze); end; end; _buf << ("></colgroup>".freeze); 
      ; end; items.each do |terms, dd|; 
      ; _buf << ("<tr><td".freeze); 
      ; _temple_html_attributeremover3 = ''; _slim_codeattributes7 = ['hdlist1',('strong' if option? 'strong')]; if Array === _slim_codeattributes7; _slim_codeattributes7 = _slim_codeattributes7.flatten; _slim_codeattributes7.map!(&:to_s); _slim_codeattributes7.reject!(&:empty?); _temple_html_attributeremover3 << ((_slim_codeattributes7.join(" ")).to_s); else; _temple_html_attributeremover3 << ((_slim_codeattributes7).to_s); end; _temple_html_attributeremover3; if !_temple_html_attributeremover3.empty?; _buf << (" class=\"".freeze); _buf << ((_temple_html_attributeremover3).to_s); _buf << ("\"".freeze); end; _buf << (">".freeze); 
      ; terms = [*terms]; 
      ; last_term = terms.last; 
      ; terms.each do |dt|; 
      ; _buf << ((dt.text).to_s); 
      ; if dt != last_term; 
      ; _buf << ("<br>".freeze); 
      ; end; end; _buf << ("</td><td class=\"hdlist2\">".freeze); 
      ; unless dd.nil?; 
      ; if dd.text?; 
      ; _buf << ("<p>".freeze); _buf << ((dd.text).to_s); 
      ; _buf << ("</p>".freeze); end; if dd.blocks?; 
      ; _buf << ((dd.content).to_s); 
      ; end; end; _buf << ("</td></tr>".freeze); end; _buf << ("</table></div>".freeze); else; 
      ; _buf << ("<div".freeze); _temple_html_attributeremover4 = ''; _temple_html_attributemerger3 = []; _temple_html_attributemerger3[0] = "dlist"; _temple_html_attributemerger3[1] = ''; _slim_codeattributes8 = [@style,role]; if Array === _slim_codeattributes8; _slim_codeattributes8 = _slim_codeattributes8.flatten; _slim_codeattributes8.map!(&:to_s); _slim_codeattributes8.reject!(&:empty?); _temple_html_attributemerger3[1] << ((_slim_codeattributes8.join(" ")).to_s); else; _temple_html_attributemerger3[1] << ((_slim_codeattributes8).to_s); end; _temple_html_attributemerger3[1]; _temple_html_attributeremover4 << ((_temple_html_attributemerger3.reject(&:empty?).join(" ")).to_s); _temple_html_attributeremover4; if !_temple_html_attributeremover4.empty?; _buf << (" class=\"".freeze); _buf << ((_temple_html_attributeremover4).to_s); _buf << ("\"".freeze); end; _slim_codeattributes9 = @id; if _slim_codeattributes9; if _slim_codeattributes9 == true; _buf << (" id".freeze); else; _buf << (" id=\"".freeze); _buf << ((_slim_codeattributes9).to_s); _buf << ("\"".freeze); end; end; _buf << (">".freeze); 
      ; if title?; 
      ; _buf << ("<div class=\"title\">".freeze); _buf << ((title).to_s); 
      ; _buf << ("</div>".freeze); end; _buf << ("<dl>".freeze); 
      ; items.each do |terms, dd|; 
      ; [*terms].each do |dt|; 
      ; _buf << ("<dt".freeze); _temple_html_attributeremover5 = ''; _slim_codeattributes10 = ('hdlist1' unless @style); if Array === _slim_codeattributes10; _slim_codeattributes10 = _slim_codeattributes10.flatten; _slim_codeattributes10.map!(&:to_s); _slim_codeattributes10.reject!(&:empty?); _temple_html_attributeremover5 << ((_slim_codeattributes10.join(" ")).to_s); else; _temple_html_attributeremover5 << ((_slim_codeattributes10).to_s); end; _temple_html_attributeremover5; if !_temple_html_attributeremover5.empty?; _buf << (" class=\"".freeze); _buf << ((_temple_html_attributeremover5).to_s); _buf << ("\"".freeze); end; _buf << (">".freeze); _buf << ((dt.text).to_s); 
      ; _buf << ("</dt>".freeze); end; unless dd.nil?; 
      ; _buf << ("<dd>".freeze); 
      ; if dd.text?; 
      ; _buf << ("<p>".freeze); _buf << ((dd.text).to_s); 
      ; _buf << ("</p>".freeze); end; if dd.blocks?; 
      ; _buf << ((dd.content).to_s); 
      ; end; _buf << ("</dd>".freeze); end; end; _buf << ("</dl></div>".freeze); end; _buf
    end
  end

  def inline_footnote(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; if @type == :xref; 
      ; _buf << ("<span class=\"footnoteref\">[<a class=\"footnote\" href=\"#_footnote_".freeze); 
      ; _buf << ((attr :index).to_s); _buf << ("\" title=\"View footnote.\">".freeze); _buf << ((attr :index).to_s); _buf << ("</a>]</span>".freeze); 
      ; else; 
      ; _buf << ("<span class=\"footnote\"".freeze); _slim_codeattributes1 = ("_footnote_#{@id}" if @id); if _slim_codeattributes1; if _slim_codeattributes1 == true; _buf << (" id".freeze); else; _buf << (" id=\"".freeze); _buf << ((_slim_codeattributes1).to_s); _buf << ("\"".freeze); end; end; _buf << (">[<a id=\"_footnoteref_".freeze); 
      ; _buf << ((attr :index).to_s); _buf << ("\" class=\"footnote\" href=\"#_footnote_".freeze); _buf << ((attr :index).to_s); _buf << ("\" title=\"View footnote.\">".freeze); _buf << ((attr :index).to_s); _buf << ("</a>]</span>".freeze); 
      ; end; _buf
    end
  end

  def asciidoctor_revealjs(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; _buf << ("<!--This CSS is generated by the Asciidoctor-Reveal.js converter to further integrate AsciiDoc's existing semantic with Reveal.js--><style type=\"text/css\">.reveal div.right {\n  float: right;\n}\n\n.reveal .listingblock.stretch > .content {\n  height: 100%;\n}\n\n.reveal .listingblock.stretch > .content > pre {\n  height: 100%;\n}\n\n.reveal .listingblock.stretch > .content > pre > code {\n  height: 100%;\n  max-height: 100%;\n}\n\n/* tables */\ntable{border-collapse:collapse;border-spacing:0}\ntable{margin-bottom:1.25em;border:solid 1px #dedede}\ntable thead tr th,table thead tr td,table tfoot tr th,table tfoot tr td{padding:.5em .625em .625em;font-size:inherit;text-align:left}\ntable tr th,table tr td{padding:.5625em .625em;font-size:inherit}\ntable thead tr th,table tfoot tr th,table tbody tr td,table tr td,table tfoot tr td{display:table-cell;line-height:1.6}\ntd.tableblock>.content{margin-bottom:1.25em}\ntd.tableblock>.content>:last-child{margin-bottom:-1.25em}\ntable.tableblock,th.tableblock,td.tableblock{border:0 solid #dedede}\ntable.grid-all>thead>tr>.tableblock,table.grid-all>tbody>tr>.tableblock{border-width:0 1px 1px 0}\ntable.grid-all>tfoot>tr>.tableblock{border-width:1px 1px 0 0}\ntable.grid-cols>*>tr>.tableblock{border-width:0 1px 0 0}\ntable.grid-rows>thead>tr>.tableblock,table.grid-rows>tbody>tr>.tableblock{border-width:0 0 1px}\ntable.grid-rows>tfoot>tr>.tableblock{border-width:1px 0 0}\ntable.grid-all>*>tr>.tableblock:last-child,table.grid-cols>*>tr>.tableblock:last-child{border-right-width:0}\ntable.grid-all>tbody>tr:last-child>.tableblock,table.grid-all>thead:last-child>tr>.tableblock,table.grid-rows>tbody>tr:last-child>.tableblock,table.grid-rows>thead:last-child>tr>.tableblock{border-bottom-width:0}\ntable.frame-all{border-width:1px}\ntable.frame-sides{border-width:0 1px}\ntable.frame-topbot,table.frame-ends{border-width:1px 0}\n.reveal table th.halign-left,.reveal table td.halign-left{text-align:left}\n.reveal table th.halign-right,.reveal table td.halign-right{text-align:right}\n.reveal table th.halign-center,.reveal table td.halign-center{text-align:center}\n.reveal table th.valign-top,.reveal table td.valign-top{vertical-align:top}\n.reveal table th.valign-bottom,.reveal table td.valign-bottom{vertical-align:bottom}\n.reveal table th.valign-middle,.reveal table td.valign-middle{vertical-align:middle}\ntable thead th,table tfoot th{font-weight:bold}\ntbody tr th{display:table-cell;line-height:1.6}\ntbody tr th,tbody tr th p,tfoot tr th,tfoot tr th p{font-weight:bold}\nthead{display:table-header-group}\n\n.reveal table.grid-none th,.reveal table.grid-none td{border-bottom:0!important}\n\n/* callouts */\n.conum[data-value]{display:inline-block;color:#fff!important;background:rgba(0,0,0,.8);-webkit-border-radius:50%;border-radius:50%;text-align:center;font-size:.75em;width:1.67em;height:1.67em;line-height:1.67em;font-family:\"Open Sans\",\"DejaVu Sans\",sans-serif;font-style:normal;font-weight:bold}\n.conum[data-value] *{color:#fff!important}\n.conum[data-value]+b{display:none}\n.conum[data-value]::after{content:attr(data-value)}\npre .conum[data-value]{position:relative;top:-.125em}\nb.conum *{color:inherit!important}\n.conum:not([data-value]):empty{display:none}</style>".freeze); 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; _buf
    end
  end

  def image(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; width = (attr? :width) ? (attr :width) : nil; 
      ; height = (attr? :height) ? (attr :height) : nil; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; if (has_role? 'stretch') && !((attr? :width) || (attr? :height)); 
      ; height = "100%"; 
      ; 
      ; end; unless attributes[1] == 'background' || attributes[1] == 'canvas'; 
      ; 
      ; _buf << ("<div".freeze); _temple_html_attributeremover1 = ''; _temple_html_attributemerger1 = []; _temple_html_attributemerger1[0] = "imageblock"; _temple_html_attributemerger1[1] = ''; _slim_codeattributes1 = roles; if Array === _slim_codeattributes1; _slim_codeattributes1 = _slim_codeattributes1.flatten; _slim_codeattributes1.map!(&:to_s); _slim_codeattributes1.reject!(&:empty?); _temple_html_attributemerger1[1] << ((_slim_codeattributes1.join(" ")).to_s); else; _temple_html_attributemerger1[1] << ((_slim_codeattributes1).to_s); end; _temple_html_attributemerger1[1]; _temple_html_attributeremover1 << ((_temple_html_attributemerger1.reject(&:empty?).join(" ")).to_s); _temple_html_attributeremover1; if !_temple_html_attributeremover1.empty?; _buf << (" class=\"".freeze); _buf << ((_temple_html_attributeremover1).to_s); _buf << ("\"".freeze); end; _slim_codeattributes2 = @id; if _slim_codeattributes2; if _slim_codeattributes2 == true; _buf << (" id".freeze); else; _buf << (" id=\"".freeze); _buf << ((_slim_codeattributes2).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes3 = [("text-align: #{attr :align}" if attr? :align),("float: #{attr :float}" if attr? :float)].compact.join('; '); if _slim_codeattributes3; if _slim_codeattributes3 == true; _buf << (" style".freeze); else; _buf << (" style=\"".freeze); _buf << ((_slim_codeattributes3).to_s); _buf << ("\"".freeze); end; end; _buf << (">".freeze); 
      ; if attr? :link; 
      ; _buf << ("<a class=\"image\"".freeze); _slim_codeattributes4 = (attr :link); if _slim_codeattributes4; if _slim_codeattributes4 == true; _buf << (" href".freeze); else; _buf << (" href=\"".freeze); _buf << ((_slim_codeattributes4).to_s); _buf << ("\"".freeze); end; end; _buf << ("><img".freeze); 
      ; _slim_codeattributes5 = image_uri(attr :target); if _slim_codeattributes5; if _slim_codeattributes5 == true; _buf << (" src".freeze); else; _buf << (" src=\"".freeze); _buf << ((_slim_codeattributes5).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes6 = (attr :alt); if _slim_codeattributes6; if _slim_codeattributes6 == true; _buf << (" alt".freeze); else; _buf << (" alt=\"".freeze); _buf << ((_slim_codeattributes6).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes7 = (width); if _slim_codeattributes7; if _slim_codeattributes7 == true; _buf << (" width".freeze); else; _buf << (" width=\"".freeze); _buf << ((_slim_codeattributes7).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes8 = (height); if _slim_codeattributes8; if _slim_codeattributes8 == true; _buf << (" height".freeze); else; _buf << (" height=\"".freeze); _buf << ((_slim_codeattributes8).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes9 = ((attr? :background) ? "background: #{attr :background}" : nil); if _slim_codeattributes9; if _slim_codeattributes9 == true; _buf << (" style".freeze); else; _buf << (" style=\"".freeze); _buf << ((_slim_codeattributes9).to_s); _buf << ("\"".freeze); end; end; _buf << ("></a>".freeze); 
      ; else; 
      ; _buf << ("<img".freeze); _slim_codeattributes10 = image_uri(attr :target); if _slim_codeattributes10; if _slim_codeattributes10 == true; _buf << (" src".freeze); else; _buf << (" src=\"".freeze); _buf << ((_slim_codeattributes10).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes11 = (attr :alt); if _slim_codeattributes11; if _slim_codeattributes11 == true; _buf << (" alt".freeze); else; _buf << (" alt=\"".freeze); _buf << ((_slim_codeattributes11).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes12 = (width); if _slim_codeattributes12; if _slim_codeattributes12 == true; _buf << (" width".freeze); else; _buf << (" width=\"".freeze); _buf << ((_slim_codeattributes12).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes13 = (height); if _slim_codeattributes13; if _slim_codeattributes13 == true; _buf << (" height".freeze); else; _buf << (" height=\"".freeze); _buf << ((_slim_codeattributes13).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes14 = ((attr? :background) ? "background: #{attr :background}" : nil); if _slim_codeattributes14; if _slim_codeattributes14 == true; _buf << (" style".freeze); else; _buf << (" style=\"".freeze); _buf << ((_slim_codeattributes14).to_s); _buf << ("\"".freeze); end; end; _buf << (">".freeze); 
      ; end; _buf << ("</div>".freeze); if title?; 
      ; _buf << ("<div class=\"title\">".freeze); _buf << ((captioned_title).to_s); 
      ; _buf << ("</div>".freeze); end; end; _buf
    end
  end

  def inline_break(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; _buf << ((@text).to_s); 
      ; _buf << ("<br>".freeze); 
      ; _buf
    end
  end

  def preamble(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; 
      ; 
      ; _buf
    end
  end

  def thematic_break(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; _buf << ("<hr>".freeze); 
      ; _buf
    end
  end

  def quote(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; _buf << ("<div".freeze); _temple_html_attributeremover1 = ''; _temple_html_attributemerger1 = []; _temple_html_attributemerger1[0] = "quoteblock"; _temple_html_attributemerger1[1] = ''; _slim_codeattributes1 = role; if Array === _slim_codeattributes1; _slim_codeattributes1 = _slim_codeattributes1.flatten; _slim_codeattributes1.map!(&:to_s); _slim_codeattributes1.reject!(&:empty?); _temple_html_attributemerger1[1] << ((_slim_codeattributes1.join(" ")).to_s); else; _temple_html_attributemerger1[1] << ((_slim_codeattributes1).to_s); end; _temple_html_attributemerger1[1]; _temple_html_attributeremover1 << ((_temple_html_attributemerger1.reject(&:empty?).join(" ")).to_s); _temple_html_attributeremover1; if !_temple_html_attributeremover1.empty?; _buf << (" class=\"".freeze); _buf << ((_temple_html_attributeremover1).to_s); _buf << ("\"".freeze); end; _slim_codeattributes2 = @id; if _slim_codeattributes2; if _slim_codeattributes2 == true; _buf << (" id".freeze); else; _buf << (" id=\"".freeze); _buf << ((_slim_codeattributes2).to_s); _buf << ("\"".freeze); end; end; _buf << (">".freeze); 
      ; if title?; 
      ; _buf << ("<div class=\"title\">".freeze); _buf << ((title).to_s); 
      ; _buf << ("</div>".freeze); end; _buf << ("<blockquote>".freeze); _buf << ((content).to_s); 
      ; _buf << ("</blockquote>".freeze); attribution = (attr? :attribution) ? (attr :attribution) : nil; 
      ; citetitle = (attr? :citetitle) ? (attr :citetitle) : nil; 
      ; if attribution || citetitle; 
      ; _buf << ("<div class=\"attribution\">".freeze); 
      ; if citetitle; 
      ; _buf << ("<cite>".freeze); _buf << ((citetitle).to_s); 
      ; _buf << ("</cite>".freeze); end; if attribution; 
      ; if citetitle; 
      ; _buf << ("<br>".freeze); 
      ; end; _buf << ("&#8212; ".freeze); _buf << ((attribution).to_s); 
      ; end; _buf << ("</div>".freeze); end; _buf << ("</div>".freeze); _buf
    end
  end

  def inline_indexterm(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; if @type == :visible; 
      ; _buf << ((@text).to_s); 
      ; end; _buf
    end
  end

  def pass(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; _buf << ((content).to_s); 
      ; _buf
    end
  end

  def table(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; 
      ; _buf << ("<table".freeze); _slim_codeattributes1 = @id; if _slim_codeattributes1; if _slim_codeattributes1 == true; _buf << (" id".freeze); else; _buf << (" id=\"".freeze); _buf << ((_slim_codeattributes1).to_s); _buf << ("\"".freeze); end; end; _temple_html_attributeremover1 = ''; _slim_codeattributes2 = ['tableblock',"frame-#{attr :frame, 'all'}","grid-#{attr :grid, 'all'}",role]; if Array === _slim_codeattributes2; _slim_codeattributes2 = _slim_codeattributes2.flatten; _slim_codeattributes2.map!(&:to_s); _slim_codeattributes2.reject!(&:empty?); _temple_html_attributeremover1 << ((_slim_codeattributes2.join(" ")).to_s); else; _temple_html_attributeremover1 << ((_slim_codeattributes2).to_s); end; _temple_html_attributeremover1; if !_temple_html_attributeremover1.empty?; _buf << (" class=\"".freeze); _buf << ((_temple_html_attributeremover1).to_s); _buf << ("\"".freeze); end; _slim_codeattributes3 = [("width:#{attr :tablepcwidth}%" unless option? 'autowidth'),("float:#{attr :float}" if attr? :float)].compact.join('; '); if _slim_codeattributes3; if _slim_codeattributes3 == true; _buf << (" style".freeze); else; _buf << (" style=\"".freeze); _buf << ((_slim_codeattributes3).to_s); _buf << ("\"".freeze); end; end; _buf << (">".freeze); 
      ; if title?; 
      ; _buf << ("<caption class=\"title\">".freeze); _buf << ((captioned_title).to_s); 
      ; _buf << ("</caption>".freeze); end; unless (attr :rowcount).zero?; 
      ; _buf << ("<colgroup>".freeze); 
      ; if option? 'autowidth'; 
      ; @columns.each do; 
      ; _buf << ("<col>".freeze); 
      ; end; else; 
      ; @columns.each do |col|; 
      ; _buf << ("<col style=\"width:".freeze); _buf << ((col.attr :colpcwidth).to_s); _buf << ("%\">".freeze); 
      ; end; end; _buf << ("</colgroup>".freeze); [:head, :foot, :body].select {|tblsec| !@rows[tblsec].empty? }.each do |tblsec|; 
      ; 
      ; _buf << ("<t".freeze); _buf << ((tblsec).to_s); _buf << (">".freeze); 
      ; @rows[tblsec].each do |row|; 
      ; _buf << ("<tr>".freeze); 
      ; row.each do |cell|; 
      ; 
      ; if tblsec == :head; 
      ; cell_content = cell.text; 
      ; else; 
      ; case cell.style; 
      ; when :literal; 
      ; cell_content = cell.text; 
      ; else; 
      ; cell_content = cell.content; 
      ; end; end; _slim_controls1 = html_tag(tblsec == :head || cell.style == :header ? 'th' : 'td',
      :class=>['tableblock', "halign-#{cell.attr :halign}", "valign-#{cell.attr :valign}"],
      :colspan=>cell.colspan, :rowspan=>cell.rowspan,
      :style=>((@document.attr? :cellbgcolor) ? %(background-color:#{@document.attr :cellbgcolor};) : nil)) do; _slim_controls2 = ''; 
      ; if tblsec == :head; 
      ; _slim_controls2 << ((cell_content).to_s); 
      ; else; 
      ; case cell.style; 
      ; when :asciidoc; 
      ; _slim_controls2 << ("<div>".freeze); _slim_controls2 << ((cell_content).to_s); 
      ; _slim_controls2 << ("</div>".freeze); when :literal; 
      ; _slim_controls2 << ("<div class=\"literal\"><pre>".freeze); _slim_controls2 << ((cell_content).to_s); 
      ; _slim_controls2 << ("</pre></div>".freeze); when :header; 
      ; cell_content.each do |text|; 
      ; _slim_controls2 << ("<p class=\"tableblock header\">".freeze); _slim_controls2 << ((text).to_s); 
      ; _slim_controls2 << ("</p>".freeze); end; else; 
      ; cell_content.each do |text|; 
      ; _slim_controls2 << ("<p class=\"tableblock\">".freeze); _slim_controls2 << ((text).to_s); 
      ; _slim_controls2 << ("</p>".freeze); end; end; end; _slim_controls2; end; _buf << ((_slim_controls1).to_s); end; _buf << ("</tr>".freeze); end; end; end; _buf << ("</table>".freeze); _buf
    end
  end

  def document(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; _buf << ("<!DOCTYPE html><html".freeze); 
      ; _slim_codeattributes1 = (attr :lang, 'en' unless attr? :nolang); if _slim_codeattributes1; if _slim_codeattributes1 == true; _buf << (" lang".freeze); else; _buf << (" lang=\"".freeze); _buf << ((_slim_codeattributes1).to_s); _buf << ("\"".freeze); end; end; _buf << ("><head><meta charset=\"utf-8\">".freeze); 
      ; 
      ; 
      ; if RUBY_ENGINE == 'opal' && JAVASCRIPT_PLATFORM == 'node'; 
      ; revealjsdir = (attr :revealjsdir, 'node_modules/reveal.js'); 
      ; else; 
      ; revealjsdir = (attr :revealjsdir, 'reveal.js'); 
      ; end; unless (asset_uri_scheme = (attr 'asset-uri-scheme', 'https')).empty?; 
      ; asset_uri_scheme = %(#{asset_uri_scheme}:); 
      ; end; cdn_base = %(#{asset_uri_scheme}//cdnjs.cloudflare.com/ajax/libs); 
      ; [:description, :keywords, :author, :copyright].each do |key|; 
      ; if attr? key; 
      ; _buf << ("<meta".freeze); _slim_codeattributes2 = key; if _slim_codeattributes2; if _slim_codeattributes2 == true; _buf << (" name".freeze); else; _buf << (" name=\"".freeze); _buf << ((_slim_codeattributes2).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes3 = (attr key); if _slim_codeattributes3; if _slim_codeattributes3 == true; _buf << (" content".freeze); else; _buf << (" content=\"".freeze); _buf << ((_slim_codeattributes3).to_s); _buf << ("\"".freeze); end; end; _buf << (">".freeze); 
      ; end; end; linkcss = (attr? 'linkcss'); 
      ; _buf << ("<title>".freeze); _buf << (((doctitle sanitize: true, use_fallback: true)).to_s); 
      ; _buf << ("</title><meta content=\"yes\" name=\"apple-mobile-web-app-capable\"><meta content=\"black-translucent\" name=\"apple-mobile-web-app-status-bar-style\"><meta content=\"width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, minimal-ui\" name=\"viewport\"><link href=\"".freeze); 
      ; 
      ; 
      ; _buf << ((revealjsdir).to_s); _buf << ("/css/reveal.css\" rel=\"stylesheet\">".freeze); 
      ; 
      ; if attr? :revealjs_customtheme; 
      ; _buf << ("<link rel=\"stylesheet\"".freeze); _slim_codeattributes4 = (attr :revealjs_customtheme); if _slim_codeattributes4; if _slim_codeattributes4 == true; _buf << (" href".freeze); else; _buf << (" href=\"".freeze); _buf << ((_slim_codeattributes4).to_s); _buf << ("\"".freeze); end; end; _buf << (" id=\"theme\">".freeze); 
      ; else; 
      ; _buf << ("<link rel=\"stylesheet\" href=\"".freeze); _buf << ((revealjsdir).to_s); _buf << ("/css/theme/".freeze); _buf << ((attr 'revealjs_theme', 'black').to_s); _buf << (".css\" id=\"theme\">".freeze); 
      ; end; _buf << ("<!--This CSS is generated by the Asciidoctor-Reveal.js converter to further integrate AsciiDoc's existing semantic with Reveal.js--><style type=\"text/css\">.reveal div.right {\n  float: right;\n}\n\n.reveal .listingblock.stretch > .content {\n  height: 100%;\n}\n\n.reveal .listingblock.stretch > .content > pre {\n  height: 100%;\n}\n\n.reveal .listingblock.stretch > .content > pre > code {\n  height: 100%;\n  max-height: 100%;\n}\n\n/* tables */\ntable{border-collapse:collapse;border-spacing:0}\ntable{margin-bottom:1.25em;border:solid 1px #dedede}\ntable thead tr th,table thead tr td,table tfoot tr th,table tfoot tr td{padding:.5em .625em .625em;font-size:inherit;text-align:left}\ntable tr th,table tr td{padding:.5625em .625em;font-size:inherit}\ntable thead tr th,table tfoot tr th,table tbody tr td,table tr td,table tfoot tr td{display:table-cell;line-height:1.6}\ntd.tableblock>.content{margin-bottom:1.25em}\ntd.tableblock>.content>:last-child{margin-bottom:-1.25em}\ntable.tableblock,th.tableblock,td.tableblock{border:0 solid #dedede}\ntable.grid-all>thead>tr>.tableblock,table.grid-all>tbody>tr>.tableblock{border-width:0 1px 1px 0}\ntable.grid-all>tfoot>tr>.tableblock{border-width:1px 1px 0 0}\ntable.grid-cols>*>tr>.tableblock{border-width:0 1px 0 0}\ntable.grid-rows>thead>tr>.tableblock,table.grid-rows>tbody>tr>.tableblock{border-width:0 0 1px}\ntable.grid-rows>tfoot>tr>.tableblock{border-width:1px 0 0}\ntable.grid-all>*>tr>.tableblock:last-child,table.grid-cols>*>tr>.tableblock:last-child{border-right-width:0}\ntable.grid-all>tbody>tr:last-child>.tableblock,table.grid-all>thead:last-child>tr>.tableblock,table.grid-rows>tbody>tr:last-child>.tableblock,table.grid-rows>thead:last-child>tr>.tableblock{border-bottom-width:0}\ntable.frame-all{border-width:1px}\ntable.frame-sides{border-width:0 1px}\ntable.frame-topbot,table.frame-ends{border-width:1px 0}\n.reveal table th.halign-left,.reveal table td.halign-left{text-align:left}\n.reveal table th.halign-right,.reveal table td.halign-right{text-align:right}\n.reveal table th.halign-center,.reveal table td.halign-center{text-align:center}\n.reveal table th.valign-top,.reveal table td.valign-top{vertical-align:top}\n.reveal table th.valign-bottom,.reveal table td.valign-bottom{vertical-align:bottom}\n.reveal table th.valign-middle,.reveal table td.valign-middle{vertical-align:middle}\ntable thead th,table tfoot th{font-weight:bold}\ntbody tr th{display:table-cell;line-height:1.6}\ntbody tr th,tbody tr th p,tfoot tr th,tfoot tr th p{font-weight:bold}\nthead{display:table-header-group}\n\n.reveal table.grid-none th,.reveal table.grid-none td{border-bottom:0!important}\n\n/* callouts */\n.conum[data-value]{display:inline-block;color:#fff!important;background:rgba(0,0,0,.8);-webkit-border-radius:50%;border-radius:50%;text-align:center;font-size:.75em;width:1.67em;height:1.67em;line-height:1.67em;font-family:\"Open Sans\",\"DejaVu Sans\",sans-serif;font-style:normal;font-weight:bold}\n.conum[data-value] *{color:#fff!important}\n.conum[data-value]+b{display:none}\n.conum[data-value]::after{content:attr(data-value)}\npre .conum[data-value]{position:relative;top:-.125em}\nb.conum *{color:inherit!important}\n.conum:not([data-value]):empty{display:none}</style>".freeze); 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; if attr? :icons, 'font'; 
      ; 
      ; if attr? 'iconfont-remote'; 
      ; _buf << ("<link rel=\"stylesheet\"".freeze); _slim_codeattributes5 = (attr 'iconfont-cdn', %(#{cdn_base}/font-awesome/5.12.0-1/css/all.min.css)); if _slim_codeattributes5; if _slim_codeattributes5 == true; _buf << (" href".freeze); else; _buf << (" href=\"".freeze); _buf << ((_slim_codeattributes5).to_s); _buf << ("\"".freeze); end; end; _buf << ("><link rel=\"stylesheet\"".freeze); 
      ; _slim_codeattributes6 = (attr 'iconfont-cdn', %(#{cdn_base}/font-awesome/5.12.0-1/css/v4-shims.min.css)); if _slim_codeattributes6; if _slim_codeattributes6 == true; _buf << (" href".freeze); else; _buf << (" href=\"".freeze); _buf << ((_slim_codeattributes6).to_s); _buf << ("\"".freeze); end; end; _buf << (">".freeze); 
      ; else; 
      ; _buf << ("<link rel=\"stylesheet\"".freeze); _slim_codeattributes7 = (normalize_web_path %(#{attr 'iconfont-name', 'font-awesome'}.css), (attr 'stylesdir', ''), false); if _slim_codeattributes7; if _slim_codeattributes7 == true; _buf << (" href".freeze); else; _buf << (" href=\"".freeze); _buf << ((_slim_codeattributes7).to_s); _buf << ("\"".freeze); end; end; _buf << (">".freeze); 
      ; end; end; if attr? :stem; 
      ; eqnums_val = (attr 'eqnums', 'none'); 
      ; eqnums_val = 'AMS' if eqnums_val == ''; 
      ; eqnums_opt = %( equationNumbers: { autoNumber: "#{eqnums_val}" } ); 
      ; _buf << ("<script type=\"text/x-mathjax-config\">MathJax.Hub.Config({\ntex2jax: {\n  inlineMath: [".freeze); 
      ; 
      ; 
      ; _buf << ((Asciidoctor::INLINE_MATH_DELIMITERS[:latexmath].to_s).to_s); _buf << ("],\n  displayMath: [".freeze); 
      ; _buf << ((Asciidoctor::BLOCK_MATH_DELIMITERS[:latexmath].to_s).to_s); _buf << ("],\n  ignoreClass: \"nostem|nolatexmath\"\n},\nasciimath2jax: {\n  delimiters: [".freeze); 
      ; 
      ; 
      ; 
      ; _buf << ((Asciidoctor::BLOCK_MATH_DELIMITERS[:asciimath].to_s).to_s); _buf << ("],\n  ignoreClass: \"nostem|noasciimath\"\n},\nTeX: {".freeze); 
      ; 
      ; 
      ; _buf << ((eqnums_opt).to_s); _buf << ("}\n});</script><script src=\"".freeze); 
      ; 
      ; _buf << ((cdn_base).to_s); _buf << ("/mathjax/2.4.0/MathJax.js?config=TeX-MML-AM_HTMLorMML\"></script>".freeze); 
      ; 
      ; end; syntax_hl = self.syntax_highlighter; 
      ; if syntax_hl && (syntax_hl.docinfo? :head); 
      ; _buf << ((syntax_hl.docinfo :head, self, cdn_base_url: cdn_base, linkcss: linkcss, self_closing_tag_slash: '/').to_s); 
      ; 
      ; end; _buf << ("<script>var link = document.createElement( 'link' );\nlink.rel = 'stylesheet';\nlink.type = 'text/css';\nlink.href = window.location.search.match( /print-pdf/gi ) ? \"".freeze); 
      ; 
      ; 
      ; 
      ; _buf << ((revealjsdir).to_s); _buf << ("/css/print/pdf.css\" : \"".freeze); _buf << ((revealjsdir).to_s); _buf << ("/css/print/paper.css\";\ndocument.getElementsByTagName( 'head' )[0].appendChild( link );</script><!--[if lt IE 9]><script src=\"".freeze); 
      ; 
      ; 
      ; _buf << ((revealjsdir).to_s); _buf << ("/lib/js/html5shiv.js\"></script><![endif]-->".freeze); 
      ; unless (docinfo_content = docinfo :header, '.html').empty?; 
      ; _buf << ((docinfo_content).to_s); 
      ; end; if attr? :customcss; 
      ; _buf << ("<link rel=\"stylesheet\"".freeze); _slim_codeattributes8 = ((customcss = attr :customcss).empty? ? 'asciidoctor-revealjs.css' : customcss); if _slim_codeattributes8; if _slim_codeattributes8 == true; _buf << (" href".freeze); else; _buf << (" href=\"".freeze); _buf << ((_slim_codeattributes8).to_s); _buf << ("\"".freeze); end; end; _buf << (">".freeze); 
      ; end; _buf << ("</head><body><div class=\"reveal\"><div class=\"slides\">".freeze); 
      ; 
      ; 
      ; 
      ; unless notitle || !has_header?; 
      ; bg_image = (attr? 'title-slide-background-image') ? (image_uri(attr 'title-slide-background-image')) : nil; 
      ; bg_video = (attr? 'title-slide-background-video') ? (media_uri(attr 'title-slide-background-video')) : nil; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; _buf << ("<section".freeze); _temple_html_attributeremover1 = ''; _temple_html_attributemerger1 = []; _temple_html_attributemerger1[0] = "title"; _temple_html_attributemerger1[1] = ''; _slim_codeattributes9 = role; if Array === _slim_codeattributes9; _slim_codeattributes9 = _slim_codeattributes9.flatten; _slim_codeattributes9.map!(&:to_s); _slim_codeattributes9.reject!(&:empty?); _temple_html_attributemerger1[1] << ((_slim_codeattributes9.join(" ")).to_s); else; _temple_html_attributemerger1[1] << ((_slim_codeattributes9).to_s); end; _temple_html_attributemerger1[1]; _temple_html_attributeremover1 << ((_temple_html_attributemerger1.reject(&:empty?).join(" ")).to_s); _temple_html_attributeremover1; if !_temple_html_attributeremover1.empty?; _buf << (" class=\"".freeze); _buf << ((_temple_html_attributeremover1).to_s); _buf << ("\"".freeze); end; _buf << (" data-state=\"title\"".freeze); _slim_codeattributes10 = (attr 'title-slide-transition'); if _slim_codeattributes10; if _slim_codeattributes10 == true; _buf << (" data-transition".freeze); else; _buf << (" data-transition=\"".freeze); _buf << ((_slim_codeattributes10).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes11 = (attr 'title-slide-transition-speed'); if _slim_codeattributes11; if _slim_codeattributes11 == true; _buf << (" data-transition-speed".freeze); else; _buf << (" data-transition-speed=\"".freeze); _buf << ((_slim_codeattributes11).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes12 = (attr 'title-slide-background'); if _slim_codeattributes12; if _slim_codeattributes12 == true; _buf << (" data-background".freeze); else; _buf << (" data-background=\"".freeze); _buf << ((_slim_codeattributes12).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes13 = (attr 'title-slide-background-size'); if _slim_codeattributes13; if _slim_codeattributes13 == true; _buf << (" data-background-size".freeze); else; _buf << (" data-background-size=\"".freeze); _buf << ((_slim_codeattributes13).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes14 = bg_image; if _slim_codeattributes14; if _slim_codeattributes14 == true; _buf << (" data-background-image".freeze); else; _buf << (" data-background-image=\"".freeze); _buf << ((_slim_codeattributes14).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes15 = bg_video; if _slim_codeattributes15; if _slim_codeattributes15 == true; _buf << (" data-background-video".freeze); else; _buf << (" data-background-video=\"".freeze); _buf << ((_slim_codeattributes15).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes16 = (attr 'title-slide-background-video-loop'); if _slim_codeattributes16; if _slim_codeattributes16 == true; _buf << (" data-background-video-loop".freeze); else; _buf << (" data-background-video-loop=\"".freeze); _buf << ((_slim_codeattributes16).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes17 = (attr 'title-slide-background-video-muted'); if _slim_codeattributes17; if _slim_codeattributes17 == true; _buf << (" data-background-video-muted".freeze); else; _buf << (" data-background-video-muted=\"".freeze); _buf << ((_slim_codeattributes17).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes18 = (attr "background-opacity"); if _slim_codeattributes18; if _slim_codeattributes18 == true; _buf << (" data-background-opacity".freeze); else; _buf << (" data-background-opacity=\"".freeze); _buf << ((_slim_codeattributes18).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes19 = (attr 'title-slide-background-iframe'); if _slim_codeattributes19; if _slim_codeattributes19 == true; _buf << (" data-background-iframe".freeze); else; _buf << (" data-background-iframe=\"".freeze); _buf << ((_slim_codeattributes19).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes20 = (attr 'title-slide-background-color'); if _slim_codeattributes20; if _slim_codeattributes20 == true; _buf << (" data-background-color".freeze); else; _buf << (" data-background-color=\"".freeze); _buf << ((_slim_codeattributes20).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes21 = (attr 'title-slide-background-repeat'); if _slim_codeattributes21; if _slim_codeattributes21 == true; _buf << (" data-background-repeat".freeze); else; _buf << (" data-background-repeat=\"".freeze); _buf << ((_slim_codeattributes21).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes22 = (attr 'title-slide-background-position'); if _slim_codeattributes22; if _slim_codeattributes22 == true; _buf << (" data-background-position".freeze); else; _buf << (" data-background-position=\"".freeze); _buf << ((_slim_codeattributes22).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes23 = (attr 'title-slide-background-transition'); if _slim_codeattributes23; if _slim_codeattributes23 == true; _buf << (" data-background-transition".freeze); else; _buf << (" data-background-transition=\"".freeze); _buf << ((_slim_codeattributes23).to_s); _buf << ("\"".freeze); end; end; _buf << (">".freeze); 
      ; if (_title_obj = doctitle partition: true, use_fallback: true).subtitle?; 
      ; _buf << ("<h1>".freeze); _buf << ((slice_text _title_obj.title, (_slice = header.option? :slice)).to_s); 
      ; _buf << ("</h1><h2>".freeze); _buf << ((slice_text _title_obj.subtitle, _slice).to_s); 
      ; _buf << ("</h2>".freeze); else; 
      ; _buf << ("<h1>".freeze); _buf << ((@header.title).to_s); 
      ; _buf << ("</h1>".freeze); end; preamble = @document.find_by context: :preamble; 
      ; unless preamble.nil? or preamble.length == 0; 
      ; _buf << ("<div class=\"preamble\">".freeze); _buf << ((preamble.pop.content).to_s); 
      ; _buf << ("</div>".freeze); end; unless author.nil?; 
      ; _buf << ("<p class=\"author\"><small>".freeze); _buf << ((author).to_s); 
      ; _buf << ("</small></p>".freeze); end; _buf << ("</section>".freeze); end; _buf << ((content).to_s); 
      ; _buf << ("</div></div><script src=\"".freeze); _buf << ((revealjsdir).to_s); _buf << ("/lib/js/head.min.js\"></script><script src=\"".freeze); 
      ; _buf << ((revealjsdir).to_s); _buf << ("/js/reveal.js\"></script><script>Array.prototype.slice.call(document.querySelectorAll('.slides section')).forEach(function(slide) {\n  if (slide.getAttribute('data-background-color')) return;\n  // user needs to explicitly say he wants CSS color to override otherwise we might break custom css or theme (#226)\n  if (!(slide.classList.contains('canvas') || slide.classList.contains('background'))) return;\n  var bgColor = getComputedStyle(slide).backgroundColor;\n  if (bgColor !== 'rgba(0, 0, 0, 0)' && bgColor !== 'transparent') {\n    slide.setAttribute('data-background-color', bgColor);\n    slide.style.backgroundColor = 'transparent';\n  }\n})\n\n// See https://github.com/hakimel/reveal.js#configuration for a full list of configuration options\nReveal.initialize({\n  // Display presentation control arrows\n  controls: ".freeze); 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; _buf << ((to_boolean(attr 'revealjs_controls', true)).to_s); _buf << (",\n  // Help the user learn the controls by providing hints, for example by\n  // bouncing the down arrow when they first encounter a vertical slide\n  controlsTutorial: ".freeze); 
      ; 
      ; 
      ; _buf << ((to_boolean(attr 'revealjs_controlstutorial', true)).to_s); _buf << (",\n  // Determines where controls appear, \"edges\" or \"bottom-right\"\n  controlsLayout: '".freeze); 
      ; 
      ; _buf << ((attr 'revealjs_controlslayout', 'bottom-right').to_s); _buf << ("',\n  // Visibility rule for backwards navigation arrows; \"faded\", \"hidden\"\n  // or \"visible\"\n  controlsBackArrows: '".freeze); 
      ; 
      ; 
      ; _buf << ((attr 'revealjs_controlsbackarrows', 'faded').to_s); _buf << ("',\n  // Display a presentation progress bar\n  progress: ".freeze); 
      ; 
      ; _buf << ((to_boolean(attr 'revealjs_progress', true)).to_s); _buf << (",\n  // Display the page number of the current slide\n  slideNumber: ".freeze); 
      ; 
      ; _buf << ((to_valid_slidenumber(attr 'revealjs_slidenumber', false)).to_s); _buf << (",\n  // Control which views the slide number displays on\n  showSlideNumber: '".freeze); 
      ; 
      ; _buf << ((attr 'revealjs_showslidenumber', 'all').to_s); _buf << ("',\n  // Push each slide change to the browser history\n  history: ".freeze); 
      ; 
      ; _buf << ((to_boolean(attr 'revealjs_history', false)).to_s); _buf << (",\n  // Enable keyboard shortcuts for navigation\n  keyboard: ".freeze); 
      ; 
      ; _buf << ((to_boolean(attr 'revealjs_keyboard', true)).to_s); _buf << (",\n  // Enable the slide overview mode\n  overview: ".freeze); 
      ; 
      ; _buf << ((to_boolean(attr 'revealjs_overview', true)).to_s); _buf << (",\n  // Vertical centering of slides\n  center: ".freeze); 
      ; 
      ; _buf << ((to_boolean(attr 'revealjs_center', true)).to_s); _buf << (",\n  // Enables touch navigation on devices with touch input\n  touch: ".freeze); 
      ; 
      ; _buf << ((to_boolean(attr 'revealjs_touch', true)).to_s); _buf << (",\n  // Loop the presentation\n  loop: ".freeze); 
      ; 
      ; _buf << ((to_boolean(attr 'revealjs_loop', false)).to_s); _buf << (",\n  // Change the presentation direction to be RTL\n  rtl: ".freeze); 
      ; 
      ; _buf << ((to_boolean(attr 'revealjs_rtl', false)).to_s); _buf << (",\n  // Randomizes the order of slides each time the presentation loads\n  shuffle: ".freeze); 
      ; 
      ; _buf << ((to_boolean(attr 'revealjs_shuffle', false)).to_s); _buf << (",\n  // Turns fragments on and off globally\n  fragments: ".freeze); 
      ; 
      ; _buf << ((to_boolean(attr 'revealjs_fragments', true)).to_s); _buf << (",\n  // Flags whether to include the current fragment in the URL,\n  // so that reloading brings you to the same fragment position\n  fragmentInURL: ".freeze); 
      ; 
      ; 
      ; _buf << ((to_boolean(attr 'revealjs_fragmentinurl', false)).to_s); _buf << (",\n  // Flags if the presentation is running in an embedded mode,\n  // i.e. contained within a limited portion of the screen\n  embedded: ".freeze); 
      ; 
      ; 
      ; _buf << ((to_boolean(attr 'revealjs_embedded', false)).to_s); _buf << (",\n  // Flags if we should show a help overlay when the questionmark\n  // key is pressed\n  help: ".freeze); 
      ; 
      ; 
      ; _buf << ((to_boolean(attr 'revealjs_help', true)).to_s); _buf << (",\n  // Flags if speaker notes should be visible to all viewers\n  showNotes: ".freeze); 
      ; 
      ; _buf << ((to_boolean(attr 'revealjs_shownotes', false)).to_s); _buf << (",\n  // Global override for autolaying embedded media (video/audio/iframe)\n  // - null: Media will only autoplay if data-autoplay is present\n  // - true: All media will autoplay, regardless of individual setting\n  // - false: No media will autoplay, regardless of individual setting\n  autoPlayMedia: ".freeze); 
      ; 
      ; 
      ; 
      ; 
      ; _buf << ((attr 'revealjs_autoplaymedia', 'null').to_s); _buf << (",\n  // Number of milliseconds between automatically proceeding to the\n  // next slide, disabled when set to 0, this value can be overwritten\n  // by using a data-autoslide attribute on your slides\n  autoSlide: ".freeze); 
      ; 
      ; 
      ; 
      ; _buf << ((attr 'revealjs_autoslide', 0).to_s); _buf << (",\n  // Stop auto-sliding after user input\n  autoSlideStoppable: ".freeze); 
      ; 
      ; _buf << ((to_boolean(attr 'revealjs_autoslidestoppable', true)).to_s); _buf << (",\n  // Use this method for navigation when auto-sliding\n  autoSlideMethod: ".freeze); 
      ; 
      ; _buf << ((attr 'revealjs_autoslidemethod', 'Reveal.navigateNext').to_s); _buf << (",\n  // Specify the average time in seconds that you think you will spend\n  // presenting each slide. This is used to show a pacing timer in the\n  // speaker view\n  defaultTiming: ".freeze); 
      ; 
      ; 
      ; 
      ; _buf << ((attr 'revealjs_defaulttiming', 120).to_s); _buf << (",\n  // Enable slide navigation via mouse wheel\n  mouseWheel: ".freeze); 
      ; 
      ; _buf << ((to_boolean(attr 'revealjs_mousewheel', false)).to_s); _buf << (",\n  // Hides the address bar on mobile devices\n  hideAddressBar: ".freeze); 
      ; 
      ; _buf << ((to_boolean(attr 'revealjs_hideaddressbar', true)).to_s); _buf << (",\n  // Opens links in an iframe preview overlay\n  // Add `data-preview-link` and `data-preview-link=\"false\"` to customise each link\n  // individually\n  previewLinks: ".freeze); 
      ; 
      ; 
      ; 
      ; _buf << ((to_boolean(attr 'revealjs_previewlinks', false)).to_s); _buf << (",\n  // Transition style (e.g., none, fade, slide, convex, concave, zoom)\n  transition: '".freeze); 
      ; 
      ; _buf << ((attr 'revealjs_transition', 'slide').to_s); _buf << ("',\n  // Transition speed (e.g., default, fast, slow)\n  transitionSpeed: '".freeze); 
      ; 
      ; _buf << ((attr 'revealjs_transitionspeed', 'default').to_s); _buf << ("',\n  // Transition style for full page slide backgrounds (e.g., none, fade, slide, convex, concave, zoom)\n  backgroundTransition: '".freeze); 
      ; 
      ; _buf << ((attr 'revealjs_backgroundtransition', 'fade').to_s); _buf << ("',\n  // Number of slides away from the current that are visible\n  viewDistance: ".freeze); 
      ; 
      ; _buf << ((attr 'revealjs_viewdistance', 3).to_s); _buf << (",\n  // Parallax background image (e.g., \"'https://s3.amazonaws.com/hakim-static/reveal-js/reveal-parallax-1.jpg'\")\n  parallaxBackgroundImage: '".freeze); 
      ; 
      ; _buf << ((attr 'revealjs_parallaxbackgroundimage', '').to_s); _buf << ("',\n  // Parallax background size in CSS syntax (e.g., \"2100px 900px\")\n  parallaxBackgroundSize: '".freeze); 
      ; 
      ; _buf << ((attr 'revealjs_parallaxbackgroundsize', '').to_s); _buf << ("',\n  // Number of pixels to move the parallax background per slide\n  // - Calculated automatically unless specified\n  // - Set to 0 to disable movement along an axis\n  parallaxBackgroundHorizontal: ".freeze); 
      ; 
      ; 
      ; 
      ; _buf << ((attr 'revealjs_parallaxbackgroundhorizontal', 'null').to_s); _buf << (",\n  parallaxBackgroundVertical: ".freeze); 
      ; _buf << ((attr 'revealjs_parallaxbackgroundvertical', 'null').to_s); _buf << (",\n  // The display mode that will be used to show slides\n  display: '".freeze); 
      ; 
      ; _buf << ((attr 'revealjs_display', 'block').to_s); _buf << ("',\n\n  // The \"normal\" size of the presentation, aspect ratio will be preserved\n  // when the presentation is scaled to fit different resolutions. Can be\n  // specified using percentage units.\n  width: ".freeze); 
      ; 
      ; 
      ; 
      ; 
      ; _buf << ((attr 'revealjs_width', 960).to_s); _buf << (",\n  height: ".freeze); 
      ; _buf << ((attr 'revealjs_height', 700).to_s); _buf << (",\n\n  // Factor of the display size that should remain empty around the content\n  margin: ".freeze); 
      ; 
      ; 
      ; _buf << ((attr 'revealjs_margin', 0.1).to_s); _buf << (",\n\n  // Bounds for smallest/largest possible scale to apply to content\n  minScale: ".freeze); 
      ; 
      ; 
      ; _buf << ((attr 'revealjs_minscale', 0.2).to_s); _buf << (",\n  maxScale: ".freeze); 
      ; _buf << ((attr 'revealjs_maxscale', 1.5).to_s); _buf << (",\n\n  // PDF Export Options\n  // Put each fragment on a separate page\n  pdfSeparateFragments: ".freeze); 
      ; 
      ; 
      ; 
      ; _buf << ((to_boolean(attr 'revealjs_pdfseparatefragments', true)).to_s); _buf << (",\n  // For slides that do not fit on a page, max number of pages\n  pdfMaxPagesPerSlide: ".freeze); 
      ; 
      ; _buf << ((attr 'revealjs_pdfmaxpagesperslide', 1).to_s); _buf << (",\n\n  // Optional libraries used to extend on reveal.js\n  dependencies: [\n      { src: '".freeze); 
      ; 
      ; 
      ; 
      ; _buf << ((revealjsdir).to_s); _buf << ("/lib/js/classList.js', condition: function() { return !document.body.classList; } },\n      ".freeze); 
      ; _buf << (((document.attr? 'source-highlighter', 'highlightjs') ? "{ src: '#{revealjsdir}/plugin/highlight/highlight.js', async: true, callback: function() { hljs.initHighlightingOnLoad(); } }," : nil).to_s); 
      ; _buf << ("\n      ".freeze); _buf << (((attr? 'revealjs_plugin_zoom', 'disabled') ? "" :  "{ src: '#{revealjsdir}/plugin/zoom-js/zoom.js', async: true }," ).to_s); 
      ; _buf << ("\n      ".freeze); _buf << (((attr? 'revealjs_plugin_notes', 'disabled') ? "" :  "{ src: '#{revealjsdir}/plugin/notes/notes.js', async: true }," ).to_s); 
      ; _buf << ("\n      ".freeze); _buf << (((attr? 'revealjs_plugin_marked', 'enabled') ? "{ src: '#{revealjsdir}/plugin/markdown/marked.js', condition: function() { return !!document.querySelector( '[data-markdown]' ); } }," : "" ).to_s); 
      ; _buf << ("\n      ".freeze); _buf << (((attr? 'revealjs_plugin_markdown', 'enabled') ? "{ src: '#{revealjsdir}/plugin/markdown/markdown.js', condition: function() { return !!document.querySelector( '[data-markdown]' ); } }," : "" ).to_s); 
      ; _buf << ("\n      ".freeze); _buf << (((attr? 'revealjs_plugin_pdf', 'enabled') ? "{ src: '#{revealjsdir}/plugin/print-pdf/print-pdf.js', async: true }," :  "" ).to_s); 
      ; _buf << ("\n      ".freeze); _buf << (((attr? 'revealjs_plugins') ? File.read(attr('revealjs_plugins', '')) : "").to_s); 
      ; _buf << ("\n  ],\n\n  ".freeze); 
      ; 
      ; _buf << (((attr? 'revealjs_plugins_configuration') ? File.read(attr('revealjs_plugins_configuration', '')) : "").to_s); 
      ; _buf << ("\n\n});</script>".freeze); 
      ; 
      ; if syntax_hl && (syntax_hl.docinfo? :footer); 
      ; _buf << ((syntax_hl.docinfo :footer, self, cdn_base_url: cdn_base, linkcss: linkcss, self_closing_tag_slash: '/').to_s); 
      ; 
      ; end; unless (docinfo_content = (docinfo :footer, '.html')).empty?; 
      ; _buf << ((docinfo_content).to_s); 
      ; end; _buf << ("</body></html>".freeze); _buf
    end
  end

  def inline_callout(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; if @document.attr? :icons, 'font'; 
      ; _buf << ("<i class=\"conum\"".freeze); _slim_codeattributes1 = @text; if _slim_codeattributes1; if _slim_codeattributes1 == true; _buf << (" data-value".freeze); else; _buf << (" data-value=\"".freeze); _buf << ((_slim_codeattributes1).to_s); _buf << ("\"".freeze); end; end; _buf << ("></i><b>".freeze); 
      ; _buf << (("(#{@text})").to_s); 
      ; _buf << ("</b>".freeze); elsif @document.attr? :icons; 
      ; _buf << ("<img".freeze); _slim_codeattributes2 = icon_uri("callouts/#{@text}"); if _slim_codeattributes2; if _slim_codeattributes2 == true; _buf << (" src".freeze); else; _buf << (" src=\"".freeze); _buf << ((_slim_codeattributes2).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes3 = @text; if _slim_codeattributes3; if _slim_codeattributes3 == true; _buf << (" alt".freeze); else; _buf << (" alt=\"".freeze); _buf << ((_slim_codeattributes3).to_s); _buf << ("\"".freeze); end; end; _buf << (">".freeze); 
      ; else; 
      ; _buf << ("<b>".freeze); _buf << (("(#{@text})").to_s); 
      ; _buf << ("</b>".freeze); end; _buf
    end
  end

  def notes(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; _buf << ("<aside class=\"notes\">".freeze); _buf << ((resolve_content).to_s); 
      ; _buf << ("</aside>".freeze); _buf
    end
  end

  def inline_image(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; _buf << ("<span".freeze); _temple_html_attributeremover1 = ''; _slim_codeattributes1 = [@type,role]; if Array === _slim_codeattributes1; _slim_codeattributes1 = _slim_codeattributes1.flatten; _slim_codeattributes1.map!(&:to_s); _slim_codeattributes1.reject!(&:empty?); _temple_html_attributeremover1 << ((_slim_codeattributes1.join(" ")).to_s); else; _temple_html_attributeremover1 << ((_slim_codeattributes1).to_s); end; _temple_html_attributeremover1; if !_temple_html_attributeremover1.empty?; _buf << (" class=\"".freeze); _buf << ((_temple_html_attributeremover1).to_s); _buf << ("\"".freeze); end; _slim_codeattributes2 = ("float: #{attr :float}" if attr? :float); if _slim_codeattributes2; if _slim_codeattributes2 == true; _buf << (" style".freeze); else; _buf << (" style=\"".freeze); _buf << ((_slim_codeattributes2).to_s); _buf << ("\"".freeze); end; end; _buf << (">".freeze); 
      ; if @type == 'icon' && (@document.attr? :icons, 'font'); 
      ; style_class = ["fa fa-#{@target}"]; 
      ; style_class << "fa-#{attr :size}" if attr? :size; 
      ; style_class << "fa-rotate-#{attr :rotate}" if attr? :rotate; 
      ; style_class << "fa-flip-#{attr :flip}" if attr? :flip; 
      ; if attr? :link; 
      ; _buf << ("<a class=\"image\"".freeze); _slim_codeattributes3 = (attr :link); if _slim_codeattributes3; if _slim_codeattributes3 == true; _buf << (" href".freeze); else; _buf << (" href=\"".freeze); _buf << ((_slim_codeattributes3).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes4 = (attr :window); if _slim_codeattributes4; if _slim_codeattributes4 == true; _buf << (" target".freeze); else; _buf << (" target=\"".freeze); _buf << ((_slim_codeattributes4).to_s); _buf << ("\"".freeze); end; end; _buf << ("><i".freeze); 
      ; _temple_html_attributeremover2 = ''; _slim_codeattributes5 = style_class; if Array === _slim_codeattributes5; _slim_codeattributes5 = _slim_codeattributes5.flatten; _slim_codeattributes5.map!(&:to_s); _slim_codeattributes5.reject!(&:empty?); _temple_html_attributeremover2 << ((_slim_codeattributes5.join(" ")).to_s); else; _temple_html_attributeremover2 << ((_slim_codeattributes5).to_s); end; _temple_html_attributeremover2; if !_temple_html_attributeremover2.empty?; _buf << (" class=\"".freeze); _buf << ((_temple_html_attributeremover2).to_s); _buf << ("\"".freeze); end; _slim_codeattributes6 = (attr :title); if _slim_codeattributes6; if _slim_codeattributes6 == true; _buf << (" title".freeze); else; _buf << (" title=\"".freeze); _buf << ((_slim_codeattributes6).to_s); _buf << ("\"".freeze); end; end; _buf << ("></i></a>".freeze); 
      ; else; 
      ; _buf << ("<i".freeze); _temple_html_attributeremover3 = ''; _slim_codeattributes7 = style_class; if Array === _slim_codeattributes7; _slim_codeattributes7 = _slim_codeattributes7.flatten; _slim_codeattributes7.map!(&:to_s); _slim_codeattributes7.reject!(&:empty?); _temple_html_attributeremover3 << ((_slim_codeattributes7.join(" ")).to_s); else; _temple_html_attributeremover3 << ((_slim_codeattributes7).to_s); end; _temple_html_attributeremover3; if !_temple_html_attributeremover3.empty?; _buf << (" class=\"".freeze); _buf << ((_temple_html_attributeremover3).to_s); _buf << ("\"".freeze); end; _slim_codeattributes8 = (attr :title); if _slim_codeattributes8; if _slim_codeattributes8 == true; _buf << (" title".freeze); else; _buf << (" title=\"".freeze); _buf << ((_slim_codeattributes8).to_s); _buf << ("\"".freeze); end; end; _buf << ("></i>".freeze); 
      ; end; elsif @type == 'icon' && !(@document.attr? :icons); 
      ; if attr? :link; 
      ; _buf << ("<a class=\"image\"".freeze); _slim_codeattributes9 = (attr :link); if _slim_codeattributes9; if _slim_codeattributes9 == true; _buf << (" href".freeze); else; _buf << (" href=\"".freeze); _buf << ((_slim_codeattributes9).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes10 = (attr :window); if _slim_codeattributes10; if _slim_codeattributes10 == true; _buf << (" target".freeze); else; _buf << (" target=\"".freeze); _buf << ((_slim_codeattributes10).to_s); _buf << ("\"".freeze); end; end; _buf << (">[".freeze); 
      ; _buf << ((attr :alt).to_s); _buf << ("]</a>".freeze); 
      ; else; 
      ; _buf << ("[".freeze); _buf << ((attr :alt).to_s); _buf << ("]".freeze); 
      ; end; else; 
      ; src = (@type == 'icon' ? (icon_uri @target) : (image_uri @target)); 
      ; if attr? :link; 
      ; _buf << ("<a class=\"image\"".freeze); _slim_codeattributes11 = (attr :link); if _slim_codeattributes11; if _slim_codeattributes11 == true; _buf << (" href".freeze); else; _buf << (" href=\"".freeze); _buf << ((_slim_codeattributes11).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes12 = (attr :window); if _slim_codeattributes12; if _slim_codeattributes12 == true; _buf << (" target".freeze); else; _buf << (" target=\"".freeze); _buf << ((_slim_codeattributes12).to_s); _buf << ("\"".freeze); end; end; _buf << ("><img".freeze); 
      ; _slim_codeattributes13 = src; if _slim_codeattributes13; if _slim_codeattributes13 == true; _buf << (" src".freeze); else; _buf << (" src=\"".freeze); _buf << ((_slim_codeattributes13).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes14 = (attr :alt); if _slim_codeattributes14; if _slim_codeattributes14 == true; _buf << (" alt".freeze); else; _buf << (" alt=\"".freeze); _buf << ((_slim_codeattributes14).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes15 = (attr :width); if _slim_codeattributes15; if _slim_codeattributes15 == true; _buf << (" width".freeze); else; _buf << (" width=\"".freeze); _buf << ((_slim_codeattributes15).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes16 = (attr :height); if _slim_codeattributes16; if _slim_codeattributes16 == true; _buf << (" height".freeze); else; _buf << (" height=\"".freeze); _buf << ((_slim_codeattributes16).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes17 = (attr :title); if _slim_codeattributes17; if _slim_codeattributes17 == true; _buf << (" title".freeze); else; _buf << (" title=\"".freeze); _buf << ((_slim_codeattributes17).to_s); _buf << ("\"".freeze); end; end; _buf << ("></a>".freeze); 
      ; else; 
      ; _buf << ("<img".freeze); _slim_codeattributes18 = src; if _slim_codeattributes18; if _slim_codeattributes18 == true; _buf << (" src".freeze); else; _buf << (" src=\"".freeze); _buf << ((_slim_codeattributes18).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes19 = (attr :alt); if _slim_codeattributes19; if _slim_codeattributes19 == true; _buf << (" alt".freeze); else; _buf << (" alt=\"".freeze); _buf << ((_slim_codeattributes19).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes20 = (attr :width); if _slim_codeattributes20; if _slim_codeattributes20 == true; _buf << (" width".freeze); else; _buf << (" width=\"".freeze); _buf << ((_slim_codeattributes20).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes21 = (attr :height); if _slim_codeattributes21; if _slim_codeattributes21 == true; _buf << (" height".freeze); else; _buf << (" height=\"".freeze); _buf << ((_slim_codeattributes21).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes22 = (attr :title); if _slim_codeattributes22; if _slim_codeattributes22 == true; _buf << (" title".freeze); else; _buf << (" title=\"".freeze); _buf << ((_slim_codeattributes22).to_s); _buf << ("\"".freeze); end; end; _buf << (">".freeze); 
      ; end; end; _buf << ("</span>".freeze); _buf
    end
  end

  def video(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; 
      ; 
      ; no_stretch = ((attr? :width) || (attr? :height)); 
      ; width = (attr? :width) ? (attr :width) : "100%"; 
      ; height = (attr? :height) ? (attr :height) : "100%"; 
      ; 
      ; _buf << ("<div".freeze); _temple_html_attributeremover1 = ''; _temple_html_attributemerger1 = []; _temple_html_attributemerger1[0] = "videoblock"; _temple_html_attributemerger1[1] = ''; _slim_codeattributes1 = [@style,role,(no_stretch ? nil : "stretch")]; if Array === _slim_codeattributes1; _slim_codeattributes1 = _slim_codeattributes1.flatten; _slim_codeattributes1.map!(&:to_s); _slim_codeattributes1.reject!(&:empty?); _temple_html_attributemerger1[1] << ((_slim_codeattributes1.join(" ")).to_s); else; _temple_html_attributemerger1[1] << ((_slim_codeattributes1).to_s); end; _temple_html_attributemerger1[1]; _temple_html_attributeremover1 << ((_temple_html_attributemerger1.reject(&:empty?).join(" ")).to_s); _temple_html_attributeremover1; if !_temple_html_attributeremover1.empty?; _buf << (" class=\"".freeze); _buf << ((_temple_html_attributeremover1).to_s); _buf << ("\"".freeze); end; _slim_codeattributes2 = @id; if _slim_codeattributes2; if _slim_codeattributes2 == true; _buf << (" id".freeze); else; _buf << (" id=\"".freeze); _buf << ((_slim_codeattributes2).to_s); _buf << ("\"".freeze); end; end; _buf << (">".freeze); 
      ; if title?; 
      ; _buf << ("<div class=\"title\">".freeze); _buf << ((captioned_title).to_s); 
      ; _buf << ("</div>".freeze); end; case attr :poster; 
      ; when 'vimeo'; 
      ; unless (asset_uri_scheme = (attr :asset_uri_scheme, 'https')).empty?; 
      ; asset_uri_scheme = %(#{asset_uri_scheme}:); 
      ; end; start_anchor = (attr? :start) ? "#at=#{attr :start}" : nil; 
      ; delimiter = '?'; 
      ; loop_param = (option? 'loop') ? "#{delimiter}loop=1" : nil; 
      ; src = %(#{asset_uri_scheme}//player.vimeo.com/video/#{attr :target}#{start_anchor}#{loop_param}); 
      ; 
      ; 
      ; _buf << ("<iframe".freeze); _slim_codeattributes3 = (width); if _slim_codeattributes3; if _slim_codeattributes3 == true; _buf << (" width".freeze); else; _buf << (" width=\"".freeze); _buf << ((_slim_codeattributes3).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes4 = (height); if _slim_codeattributes4; if _slim_codeattributes4 == true; _buf << (" height".freeze); else; _buf << (" height=\"".freeze); _buf << ((_slim_codeattributes4).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes5 = src; if _slim_codeattributes5; if _slim_codeattributes5 == true; _buf << (" src".freeze); else; _buf << (" src=\"".freeze); _buf << ((_slim_codeattributes5).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes6 = 0; if _slim_codeattributes6; if _slim_codeattributes6 == true; _buf << (" frameborder".freeze); else; _buf << (" frameborder=\"".freeze); _buf << ((_slim_codeattributes6).to_s); _buf << ("\"".freeze); end; end; _buf << (" webkitAllowFullScreen mozallowfullscreen allowFullScreen".freeze); _slim_codeattributes7 = (option? 'autoplay'); if _slim_codeattributes7; if _slim_codeattributes7 == true; _buf << (" data-autoplay".freeze); else; _buf << (" data-autoplay=\"".freeze); _buf << ((_slim_codeattributes7).to_s); _buf << ("\"".freeze); end; end; _buf << ("></iframe>".freeze); 
      ; 
      ; 
      ; when 'youtube'; 
      ; unless (asset_uri_scheme = (attr :asset_uri_scheme, 'https')).empty?; 
      ; asset_uri_scheme = %(#{asset_uri_scheme}:); 
      ; end; params = ['rel=0']; 
      ; params << "start=#{attr :start}" if attr? :start; 
      ; params << "end=#{attr :end}" if attr? :end; 
      ; params << "loop=1" if option? 'loop'; 
      ; params << "controls=0" if option? 'nocontrols'; 
      ; src = %(#{asset_uri_scheme}//www.youtube.com/embed/#{attr :target}?#{params * '&amp;'}); 
      ; 
      ; 
      ; _buf << ("<iframe".freeze); _slim_codeattributes8 = (width); if _slim_codeattributes8; if _slim_codeattributes8 == true; _buf << (" width".freeze); else; _buf << (" width=\"".freeze); _buf << ((_slim_codeattributes8).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes9 = (height); if _slim_codeattributes9; if _slim_codeattributes9 == true; _buf << (" height".freeze); else; _buf << (" height=\"".freeze); _buf << ((_slim_codeattributes9).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes10 = src; if _slim_codeattributes10; if _slim_codeattributes10 == true; _buf << (" src".freeze); else; _buf << (" src=\"".freeze); _buf << ((_slim_codeattributes10).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes11 = 0; if _slim_codeattributes11; if _slim_codeattributes11 == true; _buf << (" frameborder".freeze); else; _buf << (" frameborder=\"".freeze); _buf << ((_slim_codeattributes11).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes12 = !(option? 'nofullscreen'); if _slim_codeattributes12; if _slim_codeattributes12 == true; _buf << (" allowfullscreen".freeze); else; _buf << (" allowfullscreen=\"".freeze); _buf << ((_slim_codeattributes12).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes13 = (option? 'autoplay'); if _slim_codeattributes13; if _slim_codeattributes13 == true; _buf << (" data-autoplay".freeze); else; _buf << (" data-autoplay=\"".freeze); _buf << ((_slim_codeattributes13).to_s); _buf << ("\"".freeze); end; end; _buf << ("></iframe>".freeze); 
      ; else; 
      ; 
      ; 
      ; 
      ; _buf << ("<video".freeze); _slim_codeattributes14 = media_uri(attr :target); if _slim_codeattributes14; if _slim_codeattributes14 == true; _buf << (" src".freeze); else; _buf << (" src=\"".freeze); _buf << ((_slim_codeattributes14).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes15 = (width); if _slim_codeattributes15; if _slim_codeattributes15 == true; _buf << (" width".freeze); else; _buf << (" width=\"".freeze); _buf << ((_slim_codeattributes15).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes16 = (height); if _slim_codeattributes16; if _slim_codeattributes16 == true; _buf << (" height".freeze); else; _buf << (" height=\"".freeze); _buf << ((_slim_codeattributes16).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes17 = ((attr :poster) ? media_uri(attr :poster) : nil); if _slim_codeattributes17; if _slim_codeattributes17 == true; _buf << (" poster".freeze); else; _buf << (" poster=\"".freeze); _buf << ((_slim_codeattributes17).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes18 = (option? 'autoplay'); if _slim_codeattributes18; if _slim_codeattributes18 == true; _buf << (" data-autoplay".freeze); else; _buf << (" data-autoplay=\"".freeze); _buf << ((_slim_codeattributes18).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes19 = !(option? 'nocontrols'); if _slim_codeattributes19; if _slim_codeattributes19 == true; _buf << (" controls".freeze); else; _buf << (" controls=\"".freeze); _buf << ((_slim_codeattributes19).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes20 = (option? 'loop'); if _slim_codeattributes20; if _slim_codeattributes20 == true; _buf << (" loop".freeze); else; _buf << (" loop=\"".freeze); _buf << ((_slim_codeattributes20).to_s); _buf << ("\"".freeze); end; end; _buf << (">Your browser does not support the video tag.</video>".freeze); 
      ; 
      ; end; _buf << ("</div>".freeze); _buf
    end
  end

  def literal(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; _buf << ("<div".freeze); _temple_html_attributeremover1 = ''; _temple_html_attributemerger1 = []; _temple_html_attributemerger1[0] = "literalblock"; _temple_html_attributemerger1[1] = ''; _slim_codeattributes1 = role; if Array === _slim_codeattributes1; _slim_codeattributes1 = _slim_codeattributes1.flatten; _slim_codeattributes1.map!(&:to_s); _slim_codeattributes1.reject!(&:empty?); _temple_html_attributemerger1[1] << ((_slim_codeattributes1.join(" ")).to_s); else; _temple_html_attributemerger1[1] << ((_slim_codeattributes1).to_s); end; _temple_html_attributemerger1[1]; _temple_html_attributeremover1 << ((_temple_html_attributemerger1.reject(&:empty?).join(" ")).to_s); _temple_html_attributeremover1; if !_temple_html_attributeremover1.empty?; _buf << (" class=\"".freeze); _buf << ((_temple_html_attributeremover1).to_s); _buf << ("\"".freeze); end; _slim_codeattributes2 = @id; if _slim_codeattributes2; if _slim_codeattributes2 == true; _buf << (" id".freeze); else; _buf << (" id=\"".freeze); _buf << ((_slim_codeattributes2).to_s); _buf << ("\"".freeze); end; end; _buf << (">".freeze); 
      ; if title?; 
      ; _buf << ("<div class=\"title\">".freeze); _buf << ((title).to_s); 
      ; _buf << ("</div>".freeze); end; _buf << ("<div class=\"content\"><pre".freeze); _temple_html_attributeremover2 = ''; _slim_codeattributes3 = (!(@document.attr? :prewrap) || (option? 'nowrap') ? 'nowrap' : nil); if Array === _slim_codeattributes3; _slim_codeattributes3 = _slim_codeattributes3.flatten; _slim_codeattributes3.map!(&:to_s); _slim_codeattributes3.reject!(&:empty?); _temple_html_attributeremover2 << ((_slim_codeattributes3.join(" ")).to_s); else; _temple_html_attributeremover2 << ((_slim_codeattributes3).to_s); end; _temple_html_attributeremover2; if !_temple_html_attributeremover2.empty?; _buf << (" class=\"".freeze); _buf << ((_temple_html_attributeremover2).to_s); _buf << ("\"".freeze); end; _buf << (">".freeze); _buf << ((content).to_s); 
      ; _buf << ("</pre></div></div>".freeze); _buf
    end
  end

  def floating_title(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; _slim_htag_filter1 = ((level + 1)).to_s; _buf << ("<h".freeze); _buf << ((_slim_htag_filter1).to_s); _slim_codeattributes1 = id; if _slim_codeattributes1; if _slim_codeattributes1 == true; _buf << (" id".freeze); else; _buf << (" id=\"".freeze); _buf << ((_slim_codeattributes1).to_s); _buf << ("\"".freeze); end; end; _temple_html_attributeremover1 = ''; _slim_codeattributes2 = [style, role]; if Array === _slim_codeattributes2; _slim_codeattributes2 = _slim_codeattributes2.flatten; _slim_codeattributes2.map!(&:to_s); _slim_codeattributes2.reject!(&:empty?); _temple_html_attributeremover1 << ((_slim_codeattributes2.join(" ")).to_s); else; _temple_html_attributeremover1 << ((_slim_codeattributes2).to_s); end; _temple_html_attributeremover1; if !_temple_html_attributeremover1.empty?; _buf << (" class=\"".freeze); _buf << ((_temple_html_attributeremover1).to_s); _buf << ("\"".freeze); end; _buf << (">".freeze); 
      ; _buf << ((title).to_s); 
      ; _buf << ("</h".freeze); _buf << ((_slim_htag_filter1).to_s); _buf << (">".freeze); _buf
    end
  end

  def embedded(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; unless notitle || !has_header?; 
      ; _buf << ("<h1".freeze); _slim_codeattributes1 = @id; if _slim_codeattributes1; if _slim_codeattributes1 == true; _buf << (" id".freeze); else; _buf << (" id=\"".freeze); _buf << ((_slim_codeattributes1).to_s); _buf << ("\"".freeze); end; end; _buf << (">".freeze); _buf << ((@header.title).to_s); 
      ; _buf << ("</h1>".freeze); end; _buf << ((content).to_s); 
      ; unless !footnotes? || attr?(:nofootnotes); 
      ; _buf << ("<div id=\"footnotes\"><hr>".freeze); 
      ; 
      ; footnotes.each do |fn|; 
      ; _buf << ("<div class=\"footnote\" id=\"_footnote_".freeze); _buf << ((fn.index).to_s); _buf << ("\"><a href=\"#_footnoteref_".freeze); 
      ; _buf << ((fn.index).to_s); _buf << ("\">".freeze); _buf << ((fn.index).to_s); _buf << ("</a>. ".freeze); _buf << ((fn.text).to_s); 
      ; _buf << ("</div>".freeze); end; _buf << ("</div>".freeze); end; _buf
    end
  end

  def sidebar(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; if (has_role? 'aside') or (has_role? 'speaker') or (has_role? 'notes'); 
      ; _buf << ("<aside class=\"notes\">".freeze); _buf << ((resolve_content).to_s); 
      ; _buf << ("</aside>".freeze); 
      ; else; 
      ; _buf << ("<div".freeze); _temple_html_attributeremover1 = ''; _temple_html_attributemerger1 = []; _temple_html_attributemerger1[0] = "sidebarblock"; _temple_html_attributemerger1[1] = ''; _slim_codeattributes1 = role; if Array === _slim_codeattributes1; _slim_codeattributes1 = _slim_codeattributes1.flatten; _slim_codeattributes1.map!(&:to_s); _slim_codeattributes1.reject!(&:empty?); _temple_html_attributemerger1[1] << ((_slim_codeattributes1.join(" ")).to_s); else; _temple_html_attributemerger1[1] << ((_slim_codeattributes1).to_s); end; _temple_html_attributemerger1[1]; _temple_html_attributeremover1 << ((_temple_html_attributemerger1.reject(&:empty?).join(" ")).to_s); _temple_html_attributeremover1; if !_temple_html_attributeremover1.empty?; _buf << (" class=\"".freeze); _buf << ((_temple_html_attributeremover1).to_s); _buf << ("\"".freeze); end; _slim_codeattributes2 = @id; if _slim_codeattributes2; if _slim_codeattributes2 == true; _buf << (" id".freeze); else; _buf << (" id=\"".freeze); _buf << ((_slim_codeattributes2).to_s); _buf << ("\"".freeze); end; end; _buf << ("><div class=\"content\">".freeze); 
      ; 
      ; if title?; 
      ; _buf << ("<div class=\"title\">".freeze); _buf << ((title).to_s); 
      ; _buf << ("</div>".freeze); end; _buf << ((content).to_s); 
      ; _buf << ("</div></div>".freeze); end; _buf
    end
  end

  def outline(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; unless sections.empty?; 
      ; toclevels ||= (document.attr 'toclevels', DEFAULT_TOCLEVELS).to_i; 
      ; slevel = section_level sections.first; 
      ; _buf << ("<ol class=\"sectlevel".freeze); _buf << ((slevel).to_s); _buf << ("\">".freeze); 
      ; sections.each do |sec|; 
      ; _buf << ("<li><a href=\"#".freeze); 
      ; _buf << ((sec.id).to_s); _buf << ("\">".freeze); _buf << ((section_title sec).to_s); 
      ; _buf << ("</a>".freeze); if (sec.level < toclevels) && (child_toc = converter.convert sec, 'outline'); 
      ; _buf << ((child_toc).to_s); 
      ; end; _buf << ("</li>".freeze); end; _buf << ("</ol>".freeze); end; _buf
    end
  end

  def listing(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; nowrap = (option? 'nowrap') || !(document.attr? 'prewrap'); 
      ; syntax_hl = document.syntax_highlighter; 
      ; if @style == 'source'; 
      ; lang = attr :language; 
      ; if syntax_hl; 
      ; doc_attrs = document.attributes; 
      ; css_mode = (doc_attrs[%(#{syntax_hl.name}-css)] || :class).to_sym; 
      ; style = doc_attrs[%(#{syntax_hl.name}-style)]; 
      ; opts = syntax_hl.highlight? ? { css_mode: css_mode, style: style } : {}; 
      ; opts[:nowrap] = nowrap; 
      ; else; 
      ; pre_open = %(<pre class="highlight#{nowrap ? ' nowrap' : ''}"><code#{lang ? %[ class="language-#{lang}" data-lang="#{lang}"] : ''}>); 
      ; pre_close = '</code></pre>'; 
      ; end; else; 
      ; pre_open = %(<pre#{nowrap ? ' class="nowrap"' : ''}>); 
      ; pre_close = '</pre>'; 
      ; end; id_attribute = id ? %( id="#{id}") : ''; 
      ; title_element = title? ? %(<div class="title">#{captioned_title}</div>\n) : ''; 
      ; _buf << ((%(<div#{id_attribute} class="listingblock#{(role = self.role) ? " #{role}" : ''}">#{title_element}<div class="content">#{syntax_hl ? (syntax_hl.format self, lang, opts) : pre_open + (content || '') + pre_close}</div></div>)).to_s); 
      ; _buf
    end
  end

  def inline_kbd(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; if (keys = attr 'keys').size == 1; 
      ; _buf << ("<kbd>".freeze); _buf << ((keys.first).to_s); 
      ; _buf << ("</kbd>".freeze); else; 
      ; _buf << ("<span class=\"keyseq\">".freeze); 
      ; keys.each_with_index do |key, idx|; 
      ; unless idx.zero?; 
      ; _buf << ("+".freeze); 
      ; end; _buf << ("<kbd>".freeze); _buf << ((key).to_s); 
      ; _buf << ("</kbd>".freeze); end; _buf << ("</span>".freeze); end; _buf
    end
  end

  def section(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; 
      ; 
      ; titleless = (title = self.title) == '!'; 
      ; hide_title = (titleless || (option? :notitle) || (option? :conceal)); 
      ; 
      ; vertical_slides = find_by(context: :section) {|section| section.level == 2 }; 
      ; 
      ; 
      ; 
      ; data_background_image, data_background_size, data_background_repeat,
      data_background_position, data_background_transition = nil; 
      ; 
      ; 
      ; section_images = blocks.map do |block|; 
      ; if (ctx = block.context) == :image; 
      ; ['background', 'canvas'].include?(block.attributes[1]) ? block : []; 
      ; elsif ctx == :section; 
      ; []; 
      ; else; 
      ; block.find_by(context: :image) {|image| ['background', 'canvas'].include?(image.attributes[1]) } || []; 
      ; end; end; if (bg_image = section_images.flatten.first); 
      ; data_background_image = image_uri(bg_image.attr 'target'); 
      ; 
      ; data_background_size = bg_image.attr 'size'; 
      ; data_background_repeat = bg_image.attr 'repeat'; 
      ; data_background_transition = bg_image.attr 'transition'; 
      ; data_background_position = bg_image.attr 'position'; 
      ; 
      ; 
      ; end; if attr? 'background-image'; 
      ; data_background_image = image_uri(attr 'background-image'); 
      ; 
      ; end; if attr? 'background-color'; 
      ; data_background_color = attr 'background-color'; 
      ; 
      ; 
      ; 
      ; end; if @level == 1 && !vertical_slides.empty?; 
      ; _buf << ("<section><section".freeze); 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; _slim_codeattributes1 = (titleless ? nil : id); if _slim_codeattributes1; if _slim_codeattributes1 == true; _buf << (" id".freeze); else; _buf << (" id=\"".freeze); _buf << ((_slim_codeattributes1).to_s); _buf << ("\"".freeze); end; end; _temple_html_attributeremover1 = ''; _slim_codeattributes2 = roles; if Array === _slim_codeattributes2; _slim_codeattributes2 = _slim_codeattributes2.flatten; _slim_codeattributes2.map!(&:to_s); _slim_codeattributes2.reject!(&:empty?); _temple_html_attributeremover1 << ((_slim_codeattributes2.join(" ")).to_s); else; _temple_html_attributeremover1 << ((_slim_codeattributes2).to_s); end; _temple_html_attributeremover1; if !_temple_html_attributeremover1.empty?; _buf << (" class=\"".freeze); _buf << ((_temple_html_attributeremover1).to_s); _buf << ("\"".freeze); end; _slim_codeattributes3 = (attr 'transition'); if _slim_codeattributes3; if _slim_codeattributes3 == true; _buf << (" data-transition".freeze); else; _buf << (" data-transition=\"".freeze); _buf << ((_slim_codeattributes3).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes4 = (attr 'transition-speed'); if _slim_codeattributes4; if _slim_codeattributes4 == true; _buf << (" data-transition-speed".freeze); else; _buf << (" data-transition-speed=\"".freeze); _buf << ((_slim_codeattributes4).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes5 = data_background_color; if _slim_codeattributes5; if _slim_codeattributes5 == true; _buf << (" data-background-color".freeze); else; _buf << (" data-background-color=\"".freeze); _buf << ((_slim_codeattributes5).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes6 = data_background_image; if _slim_codeattributes6; if _slim_codeattributes6 == true; _buf << (" data-background-image".freeze); else; _buf << (" data-background-image=\"".freeze); _buf << ((_slim_codeattributes6).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes7 = (data_background_size || attr('background-size')); if _slim_codeattributes7; if _slim_codeattributes7 == true; _buf << (" data-background-size".freeze); else; _buf << (" data-background-size=\"".freeze); _buf << ((_slim_codeattributes7).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes8 = (data_background_repeat || attr('background-repeat')); if _slim_codeattributes8; if _slim_codeattributes8 == true; _buf << (" data-background-repeat".freeze); else; _buf << (" data-background-repeat=\"".freeze); _buf << ((_slim_codeattributes8).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes9 = (data_background_transition || attr('background-transition')); if _slim_codeattributes9; if _slim_codeattributes9 == true; _buf << (" data-background-transition".freeze); else; _buf << (" data-background-transition=\"".freeze); _buf << ((_slim_codeattributes9).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes10 = (data_background_position || attr('background-position')); if _slim_codeattributes10; if _slim_codeattributes10 == true; _buf << (" data-background-position".freeze); else; _buf << (" data-background-position=\"".freeze); _buf << ((_slim_codeattributes10).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes11 = (attr "background-iframe"); if _slim_codeattributes11; if _slim_codeattributes11 == true; _buf << (" data-background-iframe".freeze); else; _buf << (" data-background-iframe=\"".freeze); _buf << ((_slim_codeattributes11).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes12 = (attr "background-video"); if _slim_codeattributes12; if _slim_codeattributes12 == true; _buf << (" data-background-video".freeze); else; _buf << (" data-background-video=\"".freeze); _buf << ((_slim_codeattributes12).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes13 = ((attr? 'background-video-loop') || (option? 'loop')); if _slim_codeattributes13; if _slim_codeattributes13 == true; _buf << (" data-background-video-loop".freeze); else; _buf << (" data-background-video-loop=\"".freeze); _buf << ((_slim_codeattributes13).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes14 = ((attr? 'background-video-muted') || (option? 'muted')); if _slim_codeattributes14; if _slim_codeattributes14 == true; _buf << (" data-background-video-muted".freeze); else; _buf << (" data-background-video-muted=\"".freeze); _buf << ((_slim_codeattributes14).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes15 = (attr "background-opacity"); if _slim_codeattributes15; if _slim_codeattributes15 == true; _buf << (" data-background-opacity".freeze); else; _buf << (" data-background-opacity=\"".freeze); _buf << ((_slim_codeattributes15).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes16 = (attr 'state'); if _slim_codeattributes16; if _slim_codeattributes16 == true; _buf << (" data-state".freeze); else; _buf << (" data-state=\"".freeze); _buf << ((_slim_codeattributes16).to_s); _buf << ("\"".freeze); end; end; _buf << (">".freeze); 
      ; 
      ; unless hide_title; 
      ; _buf << ("<h2>".freeze); _buf << ((title).to_s); 
      ; _buf << ("</h2>".freeze); end; (blocks - vertical_slides).each do |block|; 
      ; _buf << ((block.convert).to_s); 
      ; end; _buf << ("</section>".freeze); vertical_slides.each do |subsection|; 
      ; _buf << ((subsection.convert).to_s); 
      ; 
      ; end; _buf << ("</section>".freeze); 
      ; else; 
      ; if @level >= 3; 
      ; 
      ; _slim_htag_filter1 = ((@level)).to_s; _buf << ("<h".freeze); _buf << ((_slim_htag_filter1).to_s); _buf << (">".freeze); _buf << ((title).to_s); 
      ; _buf << ("</h".freeze); _buf << ((_slim_htag_filter1).to_s); _buf << (">".freeze); _buf << ((content.chomp).to_s); 
      ; else; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; _buf << ("<section".freeze); _slim_codeattributes17 = (titleless ? nil : id); if _slim_codeattributes17; if _slim_codeattributes17 == true; _buf << (" id".freeze); else; _buf << (" id=\"".freeze); _buf << ((_slim_codeattributes17).to_s); _buf << ("\"".freeze); end; end; _temple_html_attributeremover2 = ''; _slim_codeattributes18 = roles; if Array === _slim_codeattributes18; _slim_codeattributes18 = _slim_codeattributes18.flatten; _slim_codeattributes18.map!(&:to_s); _slim_codeattributes18.reject!(&:empty?); _temple_html_attributeremover2 << ((_slim_codeattributes18.join(" ")).to_s); else; _temple_html_attributeremover2 << ((_slim_codeattributes18).to_s); end; _temple_html_attributeremover2; if !_temple_html_attributeremover2.empty?; _buf << (" class=\"".freeze); _buf << ((_temple_html_attributeremover2).to_s); _buf << ("\"".freeze); end; _slim_codeattributes19 = (attr 'transition'); if _slim_codeattributes19; if _slim_codeattributes19 == true; _buf << (" data-transition".freeze); else; _buf << (" data-transition=\"".freeze); _buf << ((_slim_codeattributes19).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes20 = (attr 'transition-speed'); if _slim_codeattributes20; if _slim_codeattributes20 == true; _buf << (" data-transition-speed".freeze); else; _buf << (" data-transition-speed=\"".freeze); _buf << ((_slim_codeattributes20).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes21 = data_background_color; if _slim_codeattributes21; if _slim_codeattributes21 == true; _buf << (" data-background-color".freeze); else; _buf << (" data-background-color=\"".freeze); _buf << ((_slim_codeattributes21).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes22 = data_background_image; if _slim_codeattributes22; if _slim_codeattributes22 == true; _buf << (" data-background-image".freeze); else; _buf << (" data-background-image=\"".freeze); _buf << ((_slim_codeattributes22).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes23 = (data_background_size || attr('background-size')); if _slim_codeattributes23; if _slim_codeattributes23 == true; _buf << (" data-background-size".freeze); else; _buf << (" data-background-size=\"".freeze); _buf << ((_slim_codeattributes23).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes24 = (data_background_repeat || attr('background-repeat')); if _slim_codeattributes24; if _slim_codeattributes24 == true; _buf << (" data-background-repeat".freeze); else; _buf << (" data-background-repeat=\"".freeze); _buf << ((_slim_codeattributes24).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes25 = (data_background_transition || attr('background-transition')); if _slim_codeattributes25; if _slim_codeattributes25 == true; _buf << (" data-background-transition".freeze); else; _buf << (" data-background-transition=\"".freeze); _buf << ((_slim_codeattributes25).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes26 = (data_background_position || attr('background-position')); if _slim_codeattributes26; if _slim_codeattributes26 == true; _buf << (" data-background-position".freeze); else; _buf << (" data-background-position=\"".freeze); _buf << ((_slim_codeattributes26).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes27 = (attr "background-iframe"); if _slim_codeattributes27; if _slim_codeattributes27 == true; _buf << (" data-background-iframe".freeze); else; _buf << (" data-background-iframe=\"".freeze); _buf << ((_slim_codeattributes27).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes28 = (attr "background-video"); if _slim_codeattributes28; if _slim_codeattributes28 == true; _buf << (" data-background-video".freeze); else; _buf << (" data-background-video=\"".freeze); _buf << ((_slim_codeattributes28).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes29 = ((attr? 'background-video-loop') || (option? 'loop')); if _slim_codeattributes29; if _slim_codeattributes29 == true; _buf << (" data-background-video-loop".freeze); else; _buf << (" data-background-video-loop=\"".freeze); _buf << ((_slim_codeattributes29).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes30 = ((attr? 'background-video-muted') || (option? 'muted')); if _slim_codeattributes30; if _slim_codeattributes30 == true; _buf << (" data-background-video-muted".freeze); else; _buf << (" data-background-video-muted=\"".freeze); _buf << ((_slim_codeattributes30).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes31 = (attr "background-opacity"); if _slim_codeattributes31; if _slim_codeattributes31 == true; _buf << (" data-background-opacity".freeze); else; _buf << (" data-background-opacity=\"".freeze); _buf << ((_slim_codeattributes31).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes32 = (attr 'state'); if _slim_codeattributes32; if _slim_codeattributes32 == true; _buf << (" data-state".freeze); else; _buf << (" data-state=\"".freeze); _buf << ((_slim_codeattributes32).to_s); _buf << ("\"".freeze); end; end; _buf << (">".freeze); 
      ; 
      ; unless hide_title; 
      ; _buf << ("<h2>".freeze); _buf << ((title).to_s); 
      ; _buf << ("</h2>".freeze); end; _buf << ((content.chomp).to_s); 
      ; _buf << ("</section>".freeze); end; end; _buf
    end
  end

  def example(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; _buf << ("<div".freeze); _temple_html_attributeremover1 = ''; _temple_html_attributemerger1 = []; _temple_html_attributemerger1[0] = "exampleblock"; _temple_html_attributemerger1[1] = ''; _slim_codeattributes1 = role; if Array === _slim_codeattributes1; _slim_codeattributes1 = _slim_codeattributes1.flatten; _slim_codeattributes1.map!(&:to_s); _slim_codeattributes1.reject!(&:empty?); _temple_html_attributemerger1[1] << ((_slim_codeattributes1.join(" ")).to_s); else; _temple_html_attributemerger1[1] << ((_slim_codeattributes1).to_s); end; _temple_html_attributemerger1[1]; _temple_html_attributeremover1 << ((_temple_html_attributemerger1.reject(&:empty?).join(" ")).to_s); _temple_html_attributeremover1; if !_temple_html_attributeremover1.empty?; _buf << (" class=\"".freeze); _buf << ((_temple_html_attributeremover1).to_s); _buf << ("\"".freeze); end; _slim_codeattributes2 = @id; if _slim_codeattributes2; if _slim_codeattributes2 == true; _buf << (" id".freeze); else; _buf << (" id=\"".freeze); _buf << ((_slim_codeattributes2).to_s); _buf << ("\"".freeze); end; end; _buf << (">".freeze); 
      ; if title?; 
      ; _buf << ("<div class=\"title\">".freeze); _buf << ((captioned_title).to_s); 
      ; _buf << ("</div>".freeze); end; _buf << ("<div class=\"content\">".freeze); _buf << ((content).to_s); 
      ; _buf << ("</div></div>".freeze); _buf
    end
  end

  def inline_button(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; _buf << ("<b class=\"button\">".freeze); _buf << ((@text).to_s); 
      ; _buf << ("</b>".freeze); _buf
    end
  end

  def inline_menu(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; menu = attr 'menu'; 
      ; menuitem = attr 'menuitem'; 
      ; if !(submenus = attr 'submenus').empty?; 
      ; _buf << ("<span class=\"menuseq\"><span class=\"menu\">".freeze); 
      ; _buf << ((menu).to_s); 
      ; _buf << ("</span>&#160;&#9656;&#32;".freeze); 
      ; _buf << ((submenus.map {|submenu| %(<span class="submenu">#{submenu}</span>&#160;&#9656;&#32;) }.join).to_s); 
      ; _buf << ("<span class=\"menuitem\">".freeze); _buf << ((menuitem).to_s); 
      ; _buf << ("</span></span>".freeze); elsif !menuitem.nil?; 
      ; _buf << ("<span class=\"menuseq\"><span class=\"menu\">".freeze); 
      ; _buf << ((menu).to_s); 
      ; _buf << ("</span>&#160;&#9656;&#32;<span class=\"menuitem\">".freeze); 
      ; _buf << ((menuitem).to_s); 
      ; _buf << ("</span></span>".freeze); else; 
      ; _buf << ("<span class=\"menu\">".freeze); _buf << ((menu).to_s); 
      ; _buf << ("</span>".freeze); end; _buf
    end
  end

  def audio(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; _buf << ("<div".freeze); _temple_html_attributeremover1 = ''; _temple_html_attributemerger1 = []; _temple_html_attributemerger1[0] = "audioblock"; _temple_html_attributemerger1[1] = ''; _slim_codeattributes1 = [@style,role]; if Array === _slim_codeattributes1; _slim_codeattributes1 = _slim_codeattributes1.flatten; _slim_codeattributes1.map!(&:to_s); _slim_codeattributes1.reject!(&:empty?); _temple_html_attributemerger1[1] << ((_slim_codeattributes1.join(" ")).to_s); else; _temple_html_attributemerger1[1] << ((_slim_codeattributes1).to_s); end; _temple_html_attributemerger1[1]; _temple_html_attributeremover1 << ((_temple_html_attributemerger1.reject(&:empty?).join(" ")).to_s); _temple_html_attributeremover1; if !_temple_html_attributeremover1.empty?; _buf << (" class=\"".freeze); _buf << ((_temple_html_attributeremover1).to_s); _buf << ("\"".freeze); end; _slim_codeattributes2 = @id; if _slim_codeattributes2; if _slim_codeattributes2 == true; _buf << (" id".freeze); else; _buf << (" id=\"".freeze); _buf << ((_slim_codeattributes2).to_s); _buf << ("\"".freeze); end; end; _buf << (">".freeze); 
      ; if title?; 
      ; _buf << ("<div class=\"title\">".freeze); _buf << ((captioned_title).to_s); 
      ; _buf << ("</div>".freeze); end; _buf << ("<div class=\"content\"><audio".freeze); 
      ; _slim_codeattributes3 = media_uri(attr :target); if _slim_codeattributes3; if _slim_codeattributes3 == true; _buf << (" src".freeze); else; _buf << (" src=\"".freeze); _buf << ((_slim_codeattributes3).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes4 = (option? 'autoplay'); if _slim_codeattributes4; if _slim_codeattributes4 == true; _buf << (" autoplay".freeze); else; _buf << (" autoplay=\"".freeze); _buf << ((_slim_codeattributes4).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes5 = !(option? 'nocontrols'); if _slim_codeattributes5; if _slim_codeattributes5 == true; _buf << (" controls".freeze); else; _buf << (" controls=\"".freeze); _buf << ((_slim_codeattributes5).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes6 = (option? 'loop'); if _slim_codeattributes6; if _slim_codeattributes6 == true; _buf << (" loop".freeze); else; _buf << (" loop=\"".freeze); _buf << ((_slim_codeattributes6).to_s); _buf << ("\"".freeze); end; end; _buf << (">Your browser does not support the audio tag.</audio></div></div>".freeze); 
      ; 
      ; _buf
    end
  end

  def stem(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; open, close = Asciidoctor::BLOCK_MATH_DELIMITERS[@style.to_sym]; 
      ; equation = content.strip; 
      ; if (@subs.nil? || @subs.empty?) && !(attr? 'subs'); 
      ; equation = sub_specialcharacters equation; 
      ; end; unless (equation.start_with? open) && (equation.end_with? close); 
      ; equation = %(#{open}#{equation}#{close}); 
      ; end; _buf << ("<div".freeze); _temple_html_attributeremover1 = ''; _temple_html_attributemerger1 = []; _temple_html_attributemerger1[0] = "stemblock"; _temple_html_attributemerger1[1] = ''; _slim_codeattributes1 = role; if Array === _slim_codeattributes1; _slim_codeattributes1 = _slim_codeattributes1.flatten; _slim_codeattributes1.map!(&:to_s); _slim_codeattributes1.reject!(&:empty?); _temple_html_attributemerger1[1] << ((_slim_codeattributes1.join(" ")).to_s); else; _temple_html_attributemerger1[1] << ((_slim_codeattributes1).to_s); end; _temple_html_attributemerger1[1]; _temple_html_attributeremover1 << ((_temple_html_attributemerger1.reject(&:empty?).join(" ")).to_s); _temple_html_attributeremover1; if !_temple_html_attributeremover1.empty?; _buf << (" class=\"".freeze); _buf << ((_temple_html_attributeremover1).to_s); _buf << ("\"".freeze); end; _slim_codeattributes2 = @id; if _slim_codeattributes2; if _slim_codeattributes2 == true; _buf << (" id".freeze); else; _buf << (" id=\"".freeze); _buf << ((_slim_codeattributes2).to_s); _buf << ("\"".freeze); end; end; _buf << (">".freeze); 
      ; if title?; 
      ; _buf << ("<div class=\"title\">".freeze); _buf << ((title).to_s); 
      ; _buf << ("</div>".freeze); end; _buf << ("<div class=\"content\">".freeze); _buf << ((equation).to_s); 
      ; _buf << ("</div></div>".freeze); _buf
    end
  end

  def olist(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; _buf << ("<div".freeze); _temple_html_attributeremover1 = ''; _temple_html_attributemerger1 = []; _temple_html_attributemerger1[0] = "olist"; _temple_html_attributemerger1[1] = ''; _slim_codeattributes1 = [@style,role]; if Array === _slim_codeattributes1; _slim_codeattributes1 = _slim_codeattributes1.flatten; _slim_codeattributes1.map!(&:to_s); _slim_codeattributes1.reject!(&:empty?); _temple_html_attributemerger1[1] << ((_slim_codeattributes1.join(" ")).to_s); else; _temple_html_attributemerger1[1] << ((_slim_codeattributes1).to_s); end; _temple_html_attributemerger1[1]; _temple_html_attributeremover1 << ((_temple_html_attributemerger1.reject(&:empty?).join(" ")).to_s); _temple_html_attributeremover1; if !_temple_html_attributeremover1.empty?; _buf << (" class=\"".freeze); _buf << ((_temple_html_attributeremover1).to_s); _buf << ("\"".freeze); end; _slim_codeattributes2 = @id; if _slim_codeattributes2; if _slim_codeattributes2 == true; _buf << (" id".freeze); else; _buf << (" id=\"".freeze); _buf << ((_slim_codeattributes2).to_s); _buf << ("\"".freeze); end; end; _buf << (">".freeze); 
      ; if title?; 
      ; _buf << ("<div class=\"title\">".freeze); _buf << ((title).to_s); 
      ; _buf << ("</div>".freeze); end; _buf << ("<ol".freeze); _temple_html_attributeremover2 = ''; _slim_codeattributes3 = @style; if Array === _slim_codeattributes3; _slim_codeattributes3 = _slim_codeattributes3.flatten; _slim_codeattributes3.map!(&:to_s); _slim_codeattributes3.reject!(&:empty?); _temple_html_attributeremover2 << ((_slim_codeattributes3.join(" ")).to_s); else; _temple_html_attributeremover2 << ((_slim_codeattributes3).to_s); end; _temple_html_attributeremover2; if !_temple_html_attributeremover2.empty?; _buf << (" class=\"".freeze); _buf << ((_temple_html_attributeremover2).to_s); _buf << ("\"".freeze); end; _slim_codeattributes4 = (attr :start); if _slim_codeattributes4; if _slim_codeattributes4 == true; _buf << (" start".freeze); else; _buf << (" start=\"".freeze); _buf << ((_slim_codeattributes4).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes5 = list_marker_keyword; if _slim_codeattributes5; if _slim_codeattributes5 == true; _buf << (" type".freeze); else; _buf << (" type=\"".freeze); _buf << ((_slim_codeattributes5).to_s); _buf << ("\"".freeze); end; end; _buf << (">".freeze); 
      ; items.each do |item|; 
      ; _buf << ("<li".freeze); _temple_html_attributeremover3 = ''; _slim_codeattributes6 = ('fragment' if (option? :step) or (has_role? 'step')); if Array === _slim_codeattributes6; _slim_codeattributes6 = _slim_codeattributes6.flatten; _slim_codeattributes6.map!(&:to_s); _slim_codeattributes6.reject!(&:empty?); _temple_html_attributeremover3 << ((_slim_codeattributes6.join(" ")).to_s); else; _temple_html_attributeremover3 << ((_slim_codeattributes6).to_s); end; _temple_html_attributeremover3; if !_temple_html_attributeremover3.empty?; _buf << (" class=\"".freeze); _buf << ((_temple_html_attributeremover3).to_s); _buf << ("\"".freeze); end; _buf << ("><p>".freeze); 
      ; _buf << ((item.text).to_s); 
      ; _buf << ("</p>".freeze); if item.blocks?; 
      ; _buf << ((item.content).to_s); 
      ; end; _buf << ("</li>".freeze); end; _buf << ("</ol></div>".freeze); _buf
    end
  end

  def inline_anchor(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; case @type; 
      ; when :xref; 
      ; refid = (attr :refid) || @target; 
      ; _buf << ("<a".freeze); _slim_codeattributes1 = @target; if _slim_codeattributes1; if _slim_codeattributes1 == true; _buf << (" href".freeze); else; _buf << (" href=\"".freeze); _buf << ((_slim_codeattributes1).to_s); _buf << ("\"".freeze); end; end; _buf << (">".freeze); _buf << (((@text || @document.references[:ids].fetch(refid, "[#{refid}]")).tr_s("\n", ' ')).to_s); 
      ; _buf << ("</a>".freeze); when :ref; 
      ; _buf << ("<a".freeze); _slim_codeattributes2 = @target; if _slim_codeattributes2; if _slim_codeattributes2 == true; _buf << (" id".freeze); else; _buf << (" id=\"".freeze); _buf << ((_slim_codeattributes2).to_s); _buf << ("\"".freeze); end; end; _buf << ("></a>".freeze); 
      ; when :bibref; 
      ; _buf << ("<a".freeze); _slim_codeattributes3 = @target; if _slim_codeattributes3; if _slim_codeattributes3 == true; _buf << (" id".freeze); else; _buf << (" id=\"".freeze); _buf << ((_slim_codeattributes3).to_s); _buf << ("\"".freeze); end; end; _buf << ("></a>[".freeze); 
      ; _buf << ((@target).to_s); _buf << ("]".freeze); 
      ; else; 
      ; _buf << ("<a".freeze); _slim_codeattributes4 = @target; if _slim_codeattributes4; if _slim_codeattributes4 == true; _buf << (" href".freeze); else; _buf << (" href=\"".freeze); _buf << ((_slim_codeattributes4).to_s); _buf << ("\"".freeze); end; end; _temple_html_attributeremover1 = ''; _slim_codeattributes5 = role; if Array === _slim_codeattributes5; _slim_codeattributes5 = _slim_codeattributes5.flatten; _slim_codeattributes5.map!(&:to_s); _slim_codeattributes5.reject!(&:empty?); _temple_html_attributeremover1 << ((_slim_codeattributes5.join(" ")).to_s); else; _temple_html_attributeremover1 << ((_slim_codeattributes5).to_s); end; _temple_html_attributeremover1; if !_temple_html_attributeremover1.empty?; _buf << (" class=\"".freeze); _buf << ((_temple_html_attributeremover1).to_s); _buf << ("\"".freeze); end; _slim_codeattributes6 = (attr :window); if _slim_codeattributes6; if _slim_codeattributes6 == true; _buf << (" target".freeze); else; _buf << (" target=\"".freeze); _buf << ((_slim_codeattributes6).to_s); _buf << ("\"".freeze); end; end; _buf << (">".freeze); _buf << ((@text).to_s); 
      ; _buf << ("</a>".freeze); end; _buf
    end
  end

  def admonition(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; if (has_role? 'aside') or (has_role? 'speaker') or (has_role? 'notes'); 
      ; _buf << ("<aside class=\"notes\">".freeze); _buf << ((resolve_content).to_s); 
      ; _buf << ("</aside>".freeze); 
      ; else; 
      ; _buf << ("<div".freeze); _temple_html_attributeremover1 = ''; _temple_html_attributemerger1 = []; _temple_html_attributemerger1[0] = "admonitionblock"; _temple_html_attributemerger1[1] = ''; _slim_codeattributes1 = [(attr :name),role]; if Array === _slim_codeattributes1; _slim_codeattributes1 = _slim_codeattributes1.flatten; _slim_codeattributes1.map!(&:to_s); _slim_codeattributes1.reject!(&:empty?); _temple_html_attributemerger1[1] << ((_slim_codeattributes1.join(" ")).to_s); else; _temple_html_attributemerger1[1] << ((_slim_codeattributes1).to_s); end; _temple_html_attributemerger1[1]; _temple_html_attributeremover1 << ((_temple_html_attributemerger1.reject(&:empty?).join(" ")).to_s); _temple_html_attributeremover1; if !_temple_html_attributeremover1.empty?; _buf << (" class=\"".freeze); _buf << ((_temple_html_attributeremover1).to_s); _buf << ("\"".freeze); end; _slim_codeattributes2 = @id; if _slim_codeattributes2; if _slim_codeattributes2 == true; _buf << (" id".freeze); else; _buf << (" id=\"".freeze); _buf << ((_slim_codeattributes2).to_s); _buf << ("\"".freeze); end; end; _buf << ("><table><tr><td class=\"icon\">".freeze); 
      ; 
      ; 
      ; if @document.attr? :icons, 'font'; 
      ; icon_mapping = Hash['caution', 'fire', 'important', 'exclamation-circle', 'note', 'info-circle', 'tip', 'lightbulb-o', 'warning', 'warning']; 
      ; _buf << ("<i".freeze); _temple_html_attributeremover2 = ''; _slim_codeattributes3 = %(fa fa-#{icon_mapping[attr :name]}); if Array === _slim_codeattributes3; _slim_codeattributes3 = _slim_codeattributes3.flatten; _slim_codeattributes3.map!(&:to_s); _slim_codeattributes3.reject!(&:empty?); _temple_html_attributeremover2 << ((_slim_codeattributes3.join(" ")).to_s); else; _temple_html_attributeremover2 << ((_slim_codeattributes3).to_s); end; _temple_html_attributeremover2; if !_temple_html_attributeremover2.empty?; _buf << (" class=\"".freeze); _buf << ((_temple_html_attributeremover2).to_s); _buf << ("\"".freeze); end; _slim_codeattributes4 = (attr :textlabel || @caption); if _slim_codeattributes4; if _slim_codeattributes4 == true; _buf << (" title".freeze); else; _buf << (" title=\"".freeze); _buf << ((_slim_codeattributes4).to_s); _buf << ("\"".freeze); end; end; _buf << ("></i>".freeze); 
      ; elsif @document.attr? :icons; 
      ; _buf << ("<img".freeze); _slim_codeattributes5 = icon_uri(attr :name); if _slim_codeattributes5; if _slim_codeattributes5 == true; _buf << (" src".freeze); else; _buf << (" src=\"".freeze); _buf << ((_slim_codeattributes5).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes6 = @caption; if _slim_codeattributes6; if _slim_codeattributes6 == true; _buf << (" alt".freeze); else; _buf << (" alt=\"".freeze); _buf << ((_slim_codeattributes6).to_s); _buf << ("\"".freeze); end; end; _buf << (">".freeze); 
      ; else; 
      ; _buf << ("<div class=\"title\">".freeze); _buf << (((attr :textlabel) || @caption).to_s); 
      ; _buf << ("</div>".freeze); end; _buf << ("</td><td class=\"content\">".freeze); 
      ; if title?; 
      ; _buf << ("<div class=\"title\">".freeze); _buf << ((title).to_s); 
      ; _buf << ("</div>".freeze); end; _buf << ((content).to_s); 
      ; _buf << ("</td></tr></table></div>".freeze); end; _buf
    end
  end

  def inline_quoted(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; unless @id.nil?; 
      ; _buf << ("<a".freeze); _slim_codeattributes1 = @id; if _slim_codeattributes1; if _slim_codeattributes1 == true; _buf << (" id".freeze); else; _buf << (" id=\"".freeze); _buf << ((_slim_codeattributes1).to_s); _buf << ("\"".freeze); end; end; _buf << ("></a>".freeze); 
      ; end; case @type; 
      ; when :emphasis; 
      ; _buf << ("<em".freeze); _temple_html_attributeremover1 = ''; _slim_codeattributes2 = role; if Array === _slim_codeattributes2; _slim_codeattributes2 = _slim_codeattributes2.flatten; _slim_codeattributes2.map!(&:to_s); _slim_codeattributes2.reject!(&:empty?); _temple_html_attributeremover1 << ((_slim_codeattributes2.join(" ")).to_s); else; _temple_html_attributeremover1 << ((_slim_codeattributes2).to_s); end; _temple_html_attributeremover1; if !_temple_html_attributeremover1.empty?; _buf << (" class=\"".freeze); _buf << ((_temple_html_attributeremover1).to_s); _buf << ("\"".freeze); end; _buf << (">".freeze); _buf << ((@text).to_s); 
      ; _buf << ("</em>".freeze); when :strong; 
      ; _buf << ("<strong".freeze); _temple_html_attributeremover2 = ''; _slim_codeattributes3 = role; if Array === _slim_codeattributes3; _slim_codeattributes3 = _slim_codeattributes3.flatten; _slim_codeattributes3.map!(&:to_s); _slim_codeattributes3.reject!(&:empty?); _temple_html_attributeremover2 << ((_slim_codeattributes3.join(" ")).to_s); else; _temple_html_attributeremover2 << ((_slim_codeattributes3).to_s); end; _temple_html_attributeremover2; if !_temple_html_attributeremover2.empty?; _buf << (" class=\"".freeze); _buf << ((_temple_html_attributeremover2).to_s); _buf << ("\"".freeze); end; _buf << (">".freeze); _buf << ((@text).to_s); 
      ; _buf << ("</strong>".freeze); when :monospaced; 
      ; _buf << ("<code".freeze); _temple_html_attributeremover3 = ''; _slim_codeattributes4 = role; if Array === _slim_codeattributes4; _slim_codeattributes4 = _slim_codeattributes4.flatten; _slim_codeattributes4.map!(&:to_s); _slim_codeattributes4.reject!(&:empty?); _temple_html_attributeremover3 << ((_slim_codeattributes4.join(" ")).to_s); else; _temple_html_attributeremover3 << ((_slim_codeattributes4).to_s); end; _temple_html_attributeremover3; if !_temple_html_attributeremover3.empty?; _buf << (" class=\"".freeze); _buf << ((_temple_html_attributeremover3).to_s); _buf << ("\"".freeze); end; _buf << (">".freeze); _buf << ((@text).to_s); 
      ; _buf << ("</code>".freeze); when :superscript; 
      ; _buf << ("<sup".freeze); _temple_html_attributeremover4 = ''; _slim_codeattributes5 = role; if Array === _slim_codeattributes5; _slim_codeattributes5 = _slim_codeattributes5.flatten; _slim_codeattributes5.map!(&:to_s); _slim_codeattributes5.reject!(&:empty?); _temple_html_attributeremover4 << ((_slim_codeattributes5.join(" ")).to_s); else; _temple_html_attributeremover4 << ((_slim_codeattributes5).to_s); end; _temple_html_attributeremover4; if !_temple_html_attributeremover4.empty?; _buf << (" class=\"".freeze); _buf << ((_temple_html_attributeremover4).to_s); _buf << ("\"".freeze); end; _buf << (">".freeze); _buf << ((@text).to_s); 
      ; _buf << ("</sup>".freeze); when :subscript; 
      ; _buf << ("<sub".freeze); _temple_html_attributeremover5 = ''; _slim_codeattributes6 = role; if Array === _slim_codeattributes6; _slim_codeattributes6 = _slim_codeattributes6.flatten; _slim_codeattributes6.map!(&:to_s); _slim_codeattributes6.reject!(&:empty?); _temple_html_attributeremover5 << ((_slim_codeattributes6.join(" ")).to_s); else; _temple_html_attributeremover5 << ((_slim_codeattributes6).to_s); end; _temple_html_attributeremover5; if !_temple_html_attributeremover5.empty?; _buf << (" class=\"".freeze); _buf << ((_temple_html_attributeremover5).to_s); _buf << ("\"".freeze); end; _buf << (">".freeze); _buf << ((@text).to_s); 
      ; _buf << ("</sub>".freeze); when :double; 
      ; _buf << ((role? ? %(<span class="#{role}">&#8220;#{@text}&#8221;</span>) : %(&#8220;#{@text}&#8221;)).to_s); 
      ; when :single; 
      ; _buf << ((role? ? %(<span class="#{role}">&#8216;#{@text}&#8217;</span>) : %(&#8216;#{@text}&#8217;)).to_s); 
      ; when :asciimath, :latexmath; 
      ; open, close = Asciidoctor::INLINE_MATH_DELIMITERS[@type]; 
      ; _buf << ((open).to_s); _buf << ((@text).to_s); _buf << ((close).to_s); 
      ; else; 
      ; _buf << ((role? ? %(<span class="#{role}">#{@text}</span>) : @text).to_s); 
      ; end; _buf
    end
  end

  def ulist(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; if (checklist = (option? :checklist) ? 'checklist' : nil); 
      ; if option? :interactive; 
      ; marker_checked = '<input type="checkbox" data-item-complete="1" checked>'; 
      ; marker_unchecked = '<input type="checkbox" data-item-complete="0">'; 
      ; else; 
      ; if @document.attr? :icons, 'font'; 
      ; marker_checked = '<i class="icon-check"></i>'; 
      ; marker_unchecked = '<i class="icon-check-empty"></i>'; 
      ; else; 
      ; 
      ; marker_checked = '<input type="checkbox" data-item-complete="1" checked disabled>'; 
      ; marker_unchecked = '<input type="checkbox" data-item-complete="0" disabled>'; 
      ; end; end; end; _buf << ("<div".freeze); _temple_html_attributeremover1 = ''; _temple_html_attributemerger1 = []; _temple_html_attributemerger1[0] = "ulist"; _temple_html_attributemerger1[1] = ''; _slim_codeattributes1 = [checklist,@style,role]; if Array === _slim_codeattributes1; _slim_codeattributes1 = _slim_codeattributes1.flatten; _slim_codeattributes1.map!(&:to_s); _slim_codeattributes1.reject!(&:empty?); _temple_html_attributemerger1[1] << ((_slim_codeattributes1.join(" ")).to_s); else; _temple_html_attributemerger1[1] << ((_slim_codeattributes1).to_s); end; _temple_html_attributemerger1[1]; _temple_html_attributeremover1 << ((_temple_html_attributemerger1.reject(&:empty?).join(" ")).to_s); _temple_html_attributeremover1; if !_temple_html_attributeremover1.empty?; _buf << (" class=\"".freeze); _buf << ((_temple_html_attributeremover1).to_s); _buf << ("\"".freeze); end; _slim_codeattributes2 = @id; if _slim_codeattributes2; if _slim_codeattributes2 == true; _buf << (" id".freeze); else; _buf << (" id=\"".freeze); _buf << ((_slim_codeattributes2).to_s); _buf << ("\"".freeze); end; end; _buf << (">".freeze); 
      ; if title?; 
      ; _buf << ("<div class=\"title\">".freeze); _buf << ((title).to_s); 
      ; _buf << ("</div>".freeze); end; _buf << ("<ul".freeze); _temple_html_attributeremover2 = ''; _slim_codeattributes3 = (checklist || @style); if Array === _slim_codeattributes3; _slim_codeattributes3 = _slim_codeattributes3.flatten; _slim_codeattributes3.map!(&:to_s); _slim_codeattributes3.reject!(&:empty?); _temple_html_attributeremover2 << ((_slim_codeattributes3.join(" ")).to_s); else; _temple_html_attributeremover2 << ((_slim_codeattributes3).to_s); end; _temple_html_attributeremover2; if !_temple_html_attributeremover2.empty?; _buf << (" class=\"".freeze); _buf << ((_temple_html_attributeremover2).to_s); _buf << ("\"".freeze); end; _buf << (">".freeze); 
      ; items.each do |item|; 
      ; _buf << ("<li".freeze); _temple_html_attributeremover3 = ''; _slim_codeattributes4 = ('fragment' if (option? :step) || (has_role? 'step')); if Array === _slim_codeattributes4; _slim_codeattributes4 = _slim_codeattributes4.flatten; _slim_codeattributes4.map!(&:to_s); _slim_codeattributes4.reject!(&:empty?); _temple_html_attributeremover3 << ((_slim_codeattributes4.join(" ")).to_s); else; _temple_html_attributeremover3 << ((_slim_codeattributes4).to_s); end; _temple_html_attributeremover3; if !_temple_html_attributeremover3.empty?; _buf << (" class=\"".freeze); _buf << ((_temple_html_attributeremover3).to_s); _buf << ("\"".freeze); end; _buf << ("><p>".freeze); 
      ; 
      ; if checklist && (item.attr? :checkbox); 
      ; _buf << ((%(#{(item.attr? :checked) ? marker_checked : marker_unchecked}#{item.text})).to_s); 
      ; else; 
      ; _buf << ((item.text).to_s); 
      ; end; _buf << ("</p>".freeze); if item.blocks?; 
      ; _buf << ((item.content).to_s); 
      ; end; _buf << ("</li>".freeze); end; _buf << ("</ul></div>".freeze); _buf
    end
  end

  def ruler(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; _buf << ("<hr>".freeze); 
      ; _buf
    end
  end

  def colist(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; _buf << ("<div".freeze); _temple_html_attributeremover1 = ''; _temple_html_attributemerger1 = []; _temple_html_attributemerger1[0] = "colist"; _temple_html_attributemerger1[1] = ''; _slim_codeattributes1 = [@style,role]; if Array === _slim_codeattributes1; _slim_codeattributes1 = _slim_codeattributes1.flatten; _slim_codeattributes1.map!(&:to_s); _slim_codeattributes1.reject!(&:empty?); _temple_html_attributemerger1[1] << ((_slim_codeattributes1.join(" ")).to_s); else; _temple_html_attributemerger1[1] << ((_slim_codeattributes1).to_s); end; _temple_html_attributemerger1[1]; _temple_html_attributeremover1 << ((_temple_html_attributemerger1.reject(&:empty?).join(" ")).to_s); _temple_html_attributeremover1; if !_temple_html_attributeremover1.empty?; _buf << (" class=\"".freeze); _buf << ((_temple_html_attributeremover1).to_s); _buf << ("\"".freeze); end; _slim_codeattributes2 = @id; if _slim_codeattributes2; if _slim_codeattributes2 == true; _buf << (" id".freeze); else; _buf << (" id=\"".freeze); _buf << ((_slim_codeattributes2).to_s); _buf << ("\"".freeze); end; end; _buf << (">".freeze); 
      ; if title?; 
      ; _buf << ("<div class=\"title\">".freeze); _buf << ((title).to_s); 
      ; _buf << ("</div>".freeze); end; if @document.attr? :icons; 
      ; font_icons = @document.attr? :icons, 'font'; 
      ; _buf << ("<table>".freeze); 
      ; items.each_with_index do |item, i|; 
      ; num = i + 1; 
      ; _buf << ("<tr><td>".freeze); 
      ; 
      ; if font_icons; 
      ; _buf << ("<i class=\"conum\"".freeze); _slim_codeattributes3 = num; if _slim_codeattributes3; if _slim_codeattributes3 == true; _buf << (" data-value".freeze); else; _buf << (" data-value=\"".freeze); _buf << ((_slim_codeattributes3).to_s); _buf << ("\"".freeze); end; end; _buf << ("></i><b>".freeze); 
      ; _buf << ((num).to_s); 
      ; _buf << ("</b>".freeze); else; 
      ; _buf << ("<img".freeze); _slim_codeattributes4 = icon_uri("callouts/#{num}"); if _slim_codeattributes4; if _slim_codeattributes4 == true; _buf << (" src".freeze); else; _buf << (" src=\"".freeze); _buf << ((_slim_codeattributes4).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes5 = num; if _slim_codeattributes5; if _slim_codeattributes5 == true; _buf << (" alt".freeze); else; _buf << (" alt=\"".freeze); _buf << ((_slim_codeattributes5).to_s); _buf << ("\"".freeze); end; end; _buf << (">".freeze); 
      ; end; _buf << ("</td><td>".freeze); _buf << ((item.text).to_s); 
      ; _buf << ("</td></tr>".freeze); end; _buf << ("</table>".freeze); else; 
      ; _buf << ("<ol>".freeze); 
      ; items.each do |item|; 
      ; _buf << ("<li><p>".freeze); _buf << ((item.text).to_s); 
      ; _buf << ("</p></li>".freeze); end; _buf << ("</ol>".freeze); end; _buf << ("</div>".freeze); _buf
    end
  end
  #------------------ End of generated transformation methods ------------------#

  def set_local_variables(binding, vars)
    vars.each do |key, val|
      binding.local_variable_set(key.to_sym, val)
    end
  end

end
