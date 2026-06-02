# Builds the inline <script> that configures reveal.js for a converted
# presentation: a small static fix-up script followed by the Reveal.initialize
# call.
#
# The configuration used to live as a ~150 line heredoc inside the converter,
# mixing static JavaScript, Ruby interpolation and documentation comments. It is
# now expressed as a declarative table (OPTIONS): each row describes one
# reveal.js option (its JS key, how to format the value, the backing AsciiDoc
# attribute, its default and the documentation comment). A tiny renderer turns
# the table back into the exact same JavaScript, so the generated output is
# unchanged.
module Asciidoctor; module Revealjs; module RevealJsOptions
  module_function

  # Value formatters used by the OPTIONS table:
  # - :bool        => true / false
  # - :slidenumber => false or a quoted string (reveal.js slide number syntax)
  # - :string      => single-quoted string
  # - :raw         => emitted verbatim (numbers, null, Reveal.* method references)
  def format_value(type, raw)
    case type
    when :bool        then to_boolean(raw)
    when :slidenumber then to_valid_slidenumber(raw)
    when :string      then "'#{raw}'"
    else                   raw
    end
  end

  def to_boolean(val)
    val && val != 'false' && val.to_s != '0' || false
  end

  # false needs to be verbatim everything else is a string.
  # Calling side isn't responsible for quoting so we are doing it here
  def to_valid_slidenumber(val)
    # corner case: empty is empty attribute which is true
    return true if val == ""
    # using to_s here handles both the 'false' string and the false boolean
    val.to_s == 'false' ? false : "'#{val}'"
  end

  # The reveal.js options, in output order. Each entry is either:
  # - :gap                                   => a blank line (visual grouping)
  # - [js_key, type, attribute, default, *comment_lines]
  OPTIONS = [
    [:controls, :bool, 'revealjs_controls', true,
     'Display presentation control arrows'],
    [:controlsTutorial, :bool, 'revealjs_controlstutorial', true,
     'Help the user learn the controls by providing hints, for example by',
     'bouncing the down arrow when they first encounter a vertical slide'],
    [:controlsLayout, :string, 'revealjs_controlslayout', 'bottom-right',
     'Determines where controls appear, "edges" or "bottom-right"'],
    [:controlsBackArrows, :string, 'revealjs_controlsbackarrows', 'faded',
     'Visibility rule for backwards navigation arrows; "faded", "hidden"',
     'or "visible"'],
    [:progress, :bool, 'revealjs_progress', true,
     'Display a presentation progress bar'],
    [:slideNumber, :slidenumber, 'revealjs_slidenumber', false,
     'Display the page number of the current slide'],
    [:showSlideNumber, :string, 'revealjs_showslidenumber', 'all',
     'Control which views the slide number displays on'],
    [:hash, :bool, 'revealjs_hash', false,
     'Add the current slide number to the URL hash so that reloading the',
     'page/copying the URL will return you to the same slide'],
    [:history, :bool, 'revealjs_history', false,
     'Push each slide change to the browser history. Implies `hash: true`'],
    [:keyboard, :bool, 'revealjs_keyboard', true,
     'Enable keyboard shortcuts for navigation'],
    [:overview, :bool, 'revealjs_overview', true,
     'Enable the slide overview mode'],
    [:disableLayout, :bool, 'revealjs_disablelayout', false,
     'Disables the default reveal.js slide layout so that you can use custom CSS layout'],
    [:center, :bool, 'revealjs_center', true,
     'Vertical centering of slides'],
    [:touch, :bool, 'revealjs_touch', true,
     'Enables touch navigation on devices with touch input'],
    [:loop, :bool, 'revealjs_loop', false,
     'Loop the presentation'],
    [:rtl, :bool, 'revealjs_rtl', false,
     'Change the presentation direction to be RTL'],
    [:navigationMode, :string, 'revealjs_navigationmode', 'default',
     'See https://github.com/hakimel/reveal.js/#navigation-mode'],
    [:shuffle, :bool, 'revealjs_shuffle', false,
     'Randomizes the order of slides each time the presentation loads'],
    [:fragments, :bool, 'revealjs_fragments', true,
     'Turns fragments on and off globally'],
    [:fragmentInURL, :bool, 'revealjs_fragmentinurl', false,
     'Flags whether to include the current fragment in the URL,',
     'so that reloading brings you to the same fragment position'],
    [:embedded, :bool, 'revealjs_embedded', false,
     'Flags if the presentation is running in an embedded mode,',
     'i.e. contained within a limited portion of the screen'],
    [:help, :bool, 'revealjs_help', true,
     'Flags if we should show a help overlay when the questionmark',
     'key is pressed'],
    [:showNotes, :bool, 'revealjs_shownotes', false,
     'Flags if speaker notes should be visible to all viewers'],
    [:autoPlayMedia, :raw, 'revealjs_autoplaymedia', 'null',
     'Global override for autolaying embedded media (video/audio/iframe)',
     '- null: Media will only autoplay if data-autoplay is present',
     '- true: All media will autoplay, regardless of individual setting',
     '- false: No media will autoplay, regardless of individual setting'],
    [:preloadIframes, :raw, 'revealjs_preloadiframes', 'null',
     'Global override for preloading lazy-loaded iframes',
     '- null: Iframes with data-src AND data-preload will be loaded when within',
     '  the viewDistance, iframes with only data-src will be loaded when visible',
     '- true: All iframes with data-src will be loaded when within the viewDistance',
     '- false: All iframes with data-src will be loaded only when visible'],
    [:autoSlide, :raw, 'revealjs_autoslide', 0,
     'Number of milliseconds between automatically proceeding to the',
     'next slide, disabled when set to 0, this value can be overwritten',
     'by using a data-autoslide attribute on your slides'],
    [:autoSlideStoppable, :bool, 'revealjs_autoslidestoppable', true,
     'Stop auto-sliding after user input'],
    [:autoSlideMethod, :raw, 'revealjs_autoslidemethod', 'Reveal.navigateNext',
     'Use this method for navigation when auto-sliding'],
    [:defaultTiming, :raw, 'revealjs_defaulttiming', 120,
     'Specify the average time in seconds that you think you will spend',
     'presenting each slide. This is used to show a pacing timer in the',
     'speaker view'],
    [:totalTime, :raw, 'revealjs_totaltime', 0,
     'Specify the total time in seconds that is available to',
     'present.  If this is set to a nonzero value, the pacing',
     'timer will work out the time available for each slide,',
     'instead of using the defaultTiming value'],
    [:minimumTimePerSlide, :raw, 'revealjs_minimumtimeperslide', 0,
     'Specify the minimum amount of time you want to allot to',
     'each slide, if using the totalTime calculation method.  If',
     'the automated time allocation causes slide pacing to fall',
     'below this threshold, then you will see an alert in the',
     'speaker notes window'],
    [:mouseWheel, :bool, 'revealjs_mousewheel', false,
     'Enable slide navigation via mouse wheel'],
    [:hideInactiveCursor, :bool, 'revealjs_hideinactivecursor', true,
     'Hide cursor if inactive'],
    [:hideCursorTime, :raw, 'revealjs_hidecursortime', 5000,
     'Time before the cursor is hidden (in ms)'],
    [:hideAddressBar, :bool, 'revealjs_hideaddressbar', true,
     'Hides the address bar on mobile devices'],
    [:previewLinks, :bool, 'revealjs_previewlinks', false,
     'Opens links in an iframe preview overlay',
     'Add `data-preview-link` and `data-preview-link="false"` to customise each link',
     'individually'],
    [:transition, :string, 'revealjs_transition', 'slide',
     'Transition style (e.g., none, fade, slide, convex, concave, zoom)'],
    [:transitionSpeed, :string, 'revealjs_transitionspeed', 'default',
     'Transition speed (e.g., default, fast, slow)'],
    [:backgroundTransition, :string, 'revealjs_backgroundtransition', 'fade',
     'Transition style for full page slide backgrounds (e.g., none, fade, slide, convex, concave, zoom)'],
    [:viewDistance, :raw, 'revealjs_viewdistance', 3,
     'Number of slides away from the current that are visible'],
    [:mobileViewDistance, :raw, 'revealjs_mobileviewdistance', 3,
     'Number of slides away from the current that are visible on mobile',
     'devices. It is advisable to set this to a lower number than',
     'viewDistance in order to save resources.'],
    [:parallaxBackgroundImage, :string, 'revealjs_parallaxbackgroundimage', '',
     %(Parallax background image (e.g., "'https://s3.amazonaws.com/hakim-static/reveal-js/reveal-parallax-1.jpg'"))],
    [:parallaxBackgroundSize, :string, 'revealjs_parallaxbackgroundsize', '',
     'Parallax background size in CSS syntax (e.g., "2100px 900px")'],
    [:parallaxBackgroundHorizontal, :raw, 'revealjs_parallaxbackgroundhorizontal', 'null',
     'Number of pixels to move the parallax background per slide',
     '- Calculated automatically unless specified',
     '- Set to 0 to disable movement along an axis'],
    [:parallaxBackgroundVertical, :raw, 'revealjs_parallaxbackgroundvertical', 'null'],
    [:display, :string, 'revealjs_display', 'block',
     'The display mode that will be used to show slides'],
    :gap,
    [:width, :raw, 'revealjs_width', 960,
     'The "normal" size of the presentation, aspect ratio will be preserved',
     'when the presentation is scaled to fit different resolutions. Can be',
     'specified using percentage units.'],
    [:height, :raw, 'revealjs_height', 700],
    :gap,
    [:margin, :raw, 'revealjs_margin', 0.1,
     'Factor of the display size that should remain empty around the content'],
    :gap,
    [:minScale, :raw, 'revealjs_minscale', 0.2,
     'Bounds for smallest/largest possible scale to apply to content'],
    [:maxScale, :raw, 'revealjs_maxscale', 1.5],
    :gap,
    [:pdfSeparateFragments, :bool, 'revealjs_pdfseparatefragments', true,
     'PDF Export Options',
     'Put each fragment on a separate page'],
    [:pdfMaxPagesPerSlide, :raw, 'revealjs_pdfmaxpagesperslide', 1,
     'For slides that do not fit on a page, max number of pages'],
  ]

  # Static fix-up that maps AsciiDoc background colors to reveal.js, run before
  # Reveal.initialize. No Ruby interpolation: kept as a verbatim JS string.
  BACKGROUND_COLOR_FIX = <<~JS.chomp
    Array.prototype.slice.call(document.querySelectorAll('.slides section')).forEach(function(slide) {
      if (slide.getAttribute('data-background-color')) return;
      // user needs to explicitly say he wants CSS color to override otherwise we might break custom css or theme (#226)
      if (!(slide.classList.contains('canvas') || slide.classList.contains('background'))) return;
      var bgColor = getComputedStyle(slide).backgroundColor;
      if (bgColor !== 'rgba(0, 0, 0, 0)' && bgColor !== 'transparent') {
        slide.setAttribute('data-background-color', bgColor);
        slide.style.backgroundColor = 'transparent';
      }
    });
  JS

  # Renders the OPTIONS table into the body of the Reveal.initialize object.
  def render_options(node)
    OPTIONS.map do |entry|
      next '' if entry == :gap
      key, type, attr, default, *comments = entry
      value = format_value(type, node.attr(attr, default))
      (comments.map {|comment| "  // #{comment}" } << "  #{key}: #{value},").join("\n")
    end.join("\n")
  end

  # The Reveal.initialize(...) call, including the dependencies block.
  def initialize_script(node, revealjsdir)
    [
      '// More info about config & dependencies:',
      '// - https://github.com/hakimel/reveal.js#configuration',
      '// - https://github.com/hakimel/reveal.js#dependencies',
      'Reveal.initialize({',
      render_options(node),
      '',
      '  // Optional libraries used to extend on reveal.js',
      '  dependencies: [',
      "      #{revealjs_dependencies(node, revealjsdir)}",
      '  ],',
      '});',
    ].join("\n")
  end

  # The reveal.js plugin dependencies enabled for this document, formatted as
  # the entries of the Reveal.initialize +dependencies+ array.
  def revealjs_dependencies(node, revealjsdir)
    dependencies = []
    dependencies << "{ src: '#{revealjsdir}/plugin/zoom/zoom.js', async: true, callback: function () { Reveal.registerPlugin(RevealZoom) } }" unless (node.attr? 'revealjs_plugin_zoom', 'disabled')
    dependencies << "{ src: '#{revealjsdir}/plugin/notes/notes.js', async: true, callback: function () { Reveal.registerPlugin(RevealNotes) } }" unless (node.attr? 'revealjs_plugin_notes', 'disabled')
    dependencies << "{ src: '#{revealjsdir}/plugin/search/search.js', async: true, callback: function () { Reveal.registerPlugin(RevealSearch) } }" if (node.attr? 'revealjs_plugin_search', 'enabled')
    dependencies.join(",\n      ")
  end

  # The full content of the reveal.js configuration <script> element.
  def script(node, revealjsdir)
    "#{BACKGROUND_COLOR_FIX}\n\n#{initialize_script(node, revealjsdir)}"
  end
end end end