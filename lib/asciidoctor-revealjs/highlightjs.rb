# frozen_string_literal: true
module Asciidoctor
  module Revealjs
    module SyntaxHighlighter
      # Override the built-in highlight.js syntax highlighter
      class HighlightJsAdapter < Asciidoctor::SyntaxHighlighter::Base
        register_for 'highlightjs', 'highlight.js'

        # REMIND: we cannot use Highlight.js 11+ because unescaped HTML support has been removed:
        # https://github.com/highlightjs/highlight.js/issues/2889
        # We are using unescaped HTML in source blocks for callout.
        HIGHLIGHT_JS_VERSION = '10.7.3'

        def initialize *args
          super
          @name = @pre_class = 'highlightjs'
        end

        # Convert between highlight notation formats
        # In addition to Asciidoctor's linenum converter leveraging core's resolve_lines_to_highlight,
        # we also support reveal.js step-by-step highlights.
        # The steps are split using the | character
        # For example, this method makes "1..3|6,7" into "1,2,3|6,7"
        def _convert_highlight_to_revealjs node
          node.attributes['highlight'].split('|').collect { |linenums|
            node.resolve_lines_to_highlight(node.content, linenums).join(',')
          }.join('|')
        end

        def format node, lang, opts
          super node, lang, (opts.merge transform: proc { |pre, code|
            code['class'] = %(language-#{lang || 'none'} hljs)
            code['data-noescape'] = true
            if (id = node.attr('data-id'))
              pre['data-id'] = id
            end
            if node.option?('trim')
              code['data-trim'] = ''
            end

            if node.attributes.key?('highlight')
              code['data-line-numbers'] = self._convert_highlight_to_revealjs(node)
            elsif node.attributes.key?('linenums')
              code['data-line-numbers'] = ''
            end
          })
        end

        def docinfo? location
          location == :footer
        end

        def docinfo location, doc, opts
          if RUBY_ENGINE == 'opal' && JAVASCRIPT_PLATFORM == 'node'
            revealjsdir = (doc.attr :revealjsdir, 'node_modules/reveal.js')
          else
            revealjsdir = (doc.attr :revealjsdir, 'reveal.js')
          end
          if doc.attr? 'highlightjs-theme'
            theme_href = doc.attr 'highlightjs-theme'
          else
            theme_href = "#{revealjsdir}/plugin/highlight/monokai.css"
          end
          base_url = doc.attr 'highlightjsdir', %(#{opts[:cdn_base_url]}/highlight.js/#{HIGHLIGHT_JS_VERSION})
          %(<link rel="stylesheet" href="#{theme_href}"#{opts[:self_closing_tag_slash]}>
<script src="#{base_url}/highlight.min.js"></script>
#{(doc.attr? 'highlightjs-languages') ? ((doc.attr 'highlightjs-languages').split ',').map {|lang| %[<script src="#{base_url}/languages/#{lang.lstrip}.min.js"></script>\n] }.join : ''}
<script>
#{HIGHLIGHT_PLUGIN_SOURCE}
hljs.configure({
  ignoreUnescapedHTML: true,
});
hljs.highlightAll();
</script>)
        end

        # this file was copied-pasted from https://raw.githubusercontent.com/hakimel/reveal.js/4.1.2/plugin/highlight/plugin.js
        # please note that the bundled highlight.js code was removed so we can use the latest version from cdnjs.
        HIGHLIGHT_PLUGIN_SOURCE = %q{
/* highlightjs-line-numbers.js 2.6.0 | (C) 2018 Yauheni Pakala | MIT License | github.com/wcoder/highlightjs-line-numbers.js */
/* Edited by Hakim for reveal.js; removed async timeout */
!function(n,e){"use strict";function t(){var n=e.createElement("style");n.type="text/css",n.innerHTML=g(".{0}{border-collapse:collapse}.{0} td{padding:0}.{1}:before{content:attr({2})}",[v,L,b]),e.getElementsByTagName("head")[0].appendChild(n)}function r(t){"interactive"===e.readyState||"complete"===e.readyState?i(t):n.addEventListener("DOMContentLoaded",function(){i(t)})}function i(t){try{var r=e.querySelectorAll("code.hljs,code.nohighlight");for(var i in r)r.hasOwnProperty(i)&&l(r[i],t)}catch(o){n.console.error("LineNumbers error: ",o)}}function l(n,e){"object"==typeof n&&f(function(){n.innerHTML=s(n,e)})}function o(n,e){if("string"==typeof n){var t=document.createElement("code");return t.innerHTML=n,s(t,e)}}function s(n,e){e=e||{singleLine:!1};var t=e.singleLine?0:1;return c(n),a(n.innerHTML,t)}function a(n,e){var t=u(n);if(""===t[t.length-1].trim()&&t.pop(),t.length>e){for(var r="",i=0,l=t.length;i<l;i++)r+=g('<tr><td class="{0}"><div class="{1} {2}" {3}="{5}"></div></td><td class="{4}"><div class="{1}">{6}</div></td></tr>',[j,m,L,b,p,i+1,t[i].length>0?t[i]:" "]);return g('<table class="{0}">{1}</table>',[v,r])}return n}function c(n){var e=n.childNodes;for(var t in e)if(e.hasOwnProperty(t)){var r=e[t];h(r.textContent)>0&&(r.childNodes.length>0?c(r):d(r.parentNode))}}function d(n){var e=n.className;if(/hljs-/.test(e)){for(var t=u(n.innerHTML),r=0,i="";r<t.length;r++){var l=t[r].length>0?t[r]:" ";i+=g('<span class="{0}">{1}</span>\n',[e,l])}n.innerHTML=i.trim()}}function u(n){return 0===n.length?[]:n.split(y)}function h(n){return(n.trim().match(y)||[]).length}function f(e){e()}function g(n,e){return n.replace(/\{(\d+)\}/g,function(n,t){return e[t]?e[t]:n})}var v="hljs-ln",m="hljs-ln-line",p="hljs-ln-code",j="hljs-ln-numbers",L="hljs-ln-n",b="data-line-number",y=/\r\n|\r|\n/g;n.hljs?(n.hljs.initLineNumbersOnLoad=r,n.hljs.lineNumbersBlock=l,n.hljs.lineNumbersValue=o,t()):n.console.error("highlight.js not detected!")}(window,document);

/**
 * This reveal.js plugin is wrapper around the highlight.js
 * syntax highlighting library.
 */
(function( root, factory ) {
  if (typeof define === 'function' && define.amd) {
    root.RevealHighlight = factory();
  } else if( typeof exports === 'object' ) {
    module.exports = factory();
  } else {
    // Browser globals (root is window)
    root.RevealHighlight = factory();
  }
}( this, function() {

  // Function to perform a better "data-trim" on code snippets
  // Will slice an indentation amount on each line of the snippet (amount based on the line having the lowest indentation length)
  function betterTrim(snippetEl) {
    // Helper functions
    function trimLeft(val) {
      // Adapted from https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/Trim#Polyfill
      return val.replace(/^[\s\uFEFF\xA0]+/g, '');
    }
    function trimLineBreaks(input) {
      var lines = input.split('\n');

      // Trim line-breaks from the beginning
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].trim() === '') {
          lines.splice(i--, 1);
        } else break;
      }

      // Trim line-breaks from the end
      for (var i = lines.length-1; i >= 0; i--) {
        if (lines[i].trim() === '') {
          lines.splice(i, 1);
        } else break;
      }

      return lines.join('\n');
    }

    // Main function for betterTrim()
    return (function(snippetEl) {
      var content = trimLineBreaks(snippetEl.innerHTML);
      var lines = content.split('\n');
      // Calculate the minimum amount to remove on each line start of the snippet (can be 0)
      var pad = lines.reduce(function(acc, line) {
        if (line.length > 0 && trimLeft(line).length > 0 && acc > line.length - trimLeft(line).length) {
          return line.length - trimLeft(line).length;
        }
        return acc;
      }, Number.POSITIVE_INFINITY);
      // Slice each line with this amount
      return lines.map(function(line, index) {
        return line.slice(pad);
      })
        .join('\n');
    })(snippetEl);
  }

  var RevealHighlight = {

    HIGHLIGHT_STEP_DELIMITER: '|',
    HIGHLIGHT_LINE_DELIMITER: ',',
    HIGHLIGHT_LINE_RANGE_DELIMITER: '-',

    init: function( reveal ) {

      // Read the plugin config options and provide fallbacks
      var config = Reveal.getConfig().highlight || {};
      config.highlightOnLoad = typeof config.highlightOnLoad === 'boolean' ? config.highlightOnLoad : true;
      config.escapeHTML = typeof config.escapeHTML === 'boolean' ? config.escapeHTML : true;

      [].slice.call( reveal.getRevealElement().querySelectorAll( 'pre code' ) ).forEach( function( block ) {

        block.parentNode.className = 'code-wrapper';

        // Code can optionally be wrapped in script template to avoid
        // HTML being parsed by the browser (i.e. when you need to
        // include <, > or & in your code).
        let substitute = block.querySelector( 'script[type="text/template"]' );
        if( substitute ) {
          // textContent handles the HTML entity escapes for us
          block.textContent = substitute.innerHTML;
        }

        // Trim whitespace if the "data-trim" attribute is present
        if( block.hasAttribute( 'data-trim' ) && typeof block.innerHTML.trim === 'function' ) {
          block.innerHTML = betterTrim( block );
        }

        // Escape HTML tags unless the "data-noescape" attrbute is present
        if( config.escapeHTML && !block.hasAttribute( 'data-noescape' )) {
          block.innerHTML = block.innerHTML.replace( /</g,"&lt;").replace(/>/g, '&gt;' );
        }

        // Re-highlight when focus is lost (for contenteditable code)
        block.addEventListener( 'focusout', function( event ) {
          hljs.highlightElement( event.currentTarget );
        }, false );

        if( config.highlightOnLoad ) {
          RevealHighlight.highlightBlock( block );
        }
      } );

      // If we're printing to PDF, scroll the code highlights of
      // all blocks in the deck into view at once
      reveal.on( 'pdf-ready', function() {
        [].slice.call( reveal.getRevealElement().querySelectorAll( 'pre code[data-line-numbers].current-fragment' ) ).forEach( function( block ) {
          RevealHighlight.scrollHighlightedLineIntoView( block, {}, true );
        } );
      } );
    },

    /**
     * Highlights a code block. If the <code> node has the
     * 'data-line-numbers' attribute we also generate slide
     * numbers.
     *
     * If the block contains multiple line highlight steps,
     * we clone the block and create a fragment for each step.
     */
    highlightBlock: function( block ) {

      hljs.highlightElement( block );

      // Don't generate line numbers for empty code blocks
      if( block.innerHTML.trim().length === 0 ) return;

      if( block.hasAttribute( 'data-line-numbers' ) ) {
        hljs.lineNumbersBlock( block, { singleLine: true } );

        var scrollState = { currentBlock: block };

        // If there is at least one highlight step, generate
        // fragments
        var highlightSteps = RevealHighlight.deserializeHighlightSteps( block.getAttribute( 'data-line-numbers' ) );
        if( highlightSteps.length > 1 ) {

          // If the original code block has a fragment-index,
          // each clone should follow in an incremental sequence
          var fragmentIndex = parseInt( block.getAttribute( 'data-fragment-index' ), 10 );

          if( typeof fragmentIndex !== 'number' || isNaN( fragmentIndex ) ) {
            fragmentIndex = null;
          }

          // Generate fragments for all steps except the original block
          highlightSteps.slice(1).forEach( function( highlight ) {

            var fragmentBlock = block.cloneNode( true );
            fragmentBlock.setAttribute( 'data-line-numbers', RevealHighlight.serializeHighlightSteps( [ highlight ] ) );
            fragmentBlock.classList.add( 'fragment' );
            block.parentNode.appendChild( fragmentBlock );
            RevealHighlight.highlightLines( fragmentBlock );

            if( typeof fragmentIndex === 'number' ) {
              fragmentBlock.setAttribute( 'data-fragment-index', fragmentIndex );
              fragmentIndex += 1;
            }
            else {
              fragmentBlock.removeAttribute( 'data-fragment-index' );
            }

            // Scroll highlights into view as we step through them
            fragmentBlock.addEventListener( 'visible', RevealHighlight.scrollHighlightedLineIntoView.bind( Plugin, fragmentBlock, scrollState ) );
            fragmentBlock.addEventListener( 'hidden', RevealHighlight.scrollHighlightedLineIntoView.bind( Plugin, fragmentBlock.previousSibling, scrollState ) );

          } );

          block.removeAttribute( 'data-fragment-index' )
          block.setAttribute( 'data-line-numbers', RevealHighlight.serializeHighlightSteps( [ highlightSteps[0] ] ) );

        }

        // Scroll the first highlight into view when the slide
        // becomes visible. Note supported in IE11 since it lacks
        // support for Element.closest.
        var slide = typeof block.closest === 'function' ? block.closest( 'section:not(.stack)' ) : null;
        if( slide ) {
          var scrollFirstHighlightIntoView = function() {
            RevealHighlight.scrollHighlightedLineIntoView( block, scrollState, true );
            slide.removeEventListener( 'visible', scrollFirstHighlightIntoView );
          }
          slide.addEventListener( 'visible', scrollFirstHighlightIntoView );
        }

        RevealHighlight.highlightLines( block );

      }

    },

    /**
     * Animates scrolling to the first highlighted line
     * in the given code block.
     */
    scrollHighlightedLineIntoView: function( block, scrollState, skipAnimation ) {

      cancelAnimationFrame( scrollState.animationFrameID );

      // Match the scroll position of the currently visible
      // code block
      if( scrollState.currentBlock ) {
        block.scrollTop = scrollState.currentBlock.scrollTop;
      }

      // Remember the current code block so that we can match
      // its scroll position when showing/hiding fragments
      scrollState.currentBlock = block;

      var highlightBounds = RevealHighlight.getHighlightedLineBounds( block )
      var viewportHeight = block.offsetHeight;

      // Subtract padding from the viewport height
      var blockStyles = getComputedStyle( block );
      viewportHeight -= parseInt( blockStyles.paddingTop ) + parseInt( blockStyles.paddingBottom );

      // Scroll position which centers all highlights
      var startTop = block.scrollTop;
      var targetTop = highlightBounds.top + ( Math.min( highlightBounds.bottom - highlightBounds.top, viewportHeight ) - viewportHeight ) / 2;

      // Account for offsets in position applied to the
      // <table> that holds our lines of code
      var lineTable = block.querySelector( '.hljs-ln' );
      if( lineTable ) targetTop += lineTable.offsetTop - parseInt( blockStyles.paddingTop );

      // Make sure the scroll target is within bounds
      targetTop = Math.max( Math.min( targetTop, block.scrollHeight - viewportHeight ), 0 );

      if( skipAnimation === true || startTop === targetTop ) {
        block.scrollTop = targetTop;
      }
      else {

        // Don't attempt to scroll if there is no overflow
        if( block.scrollHeight <= viewportHeight ) return;

        var time = 0;
        var animate = function() {
          time = Math.min( time + 0.02, 1 );

          // Update our eased scroll position
          block.scrollTop = startTop + ( targetTop - startTop ) * RevealHighlight.easeInOutQuart( time );

          // Keep animating unless we've reached the end
          if( time < 1 ) {
            scrollState.animationFrameID = requestAnimationFrame( animate );
          }
        };

        animate();

      }

    },

    /**
     * The easing function used when scrolling.
     */
    easeInOutQuart: function( t ) {

      // easeInOutQuart
      return t<.5 ? 8*t*t*t*t : 1-8*(--t)*t*t*t;

    },

    getHighlightedLineBounds: function( block ) {

      var highlightedLines = block.querySelectorAll( '.highlight-line' );
      if( highlightedLines.length === 0 ) {
        return { top: 0, bottom: 0 };
      }
      else {
        var firstHighlight = highlightedLines[0];
        var lastHighlight = highlightedLines[ highlightedLines.length -1 ];

        return {
          top: firstHighlight.offsetTop,
          bottom: lastHighlight.offsetTop + lastHighlight.offsetHeight
        }
      }

    },

    /**
     * Visually emphasize specific lines within a code block.
     * This only works on blocks with line numbering turned on.
     *
     * @param {HTMLElement} block a <code> block
     * @param {String} [linesToHighlight] The lines that should be
     * highlighted in this format:
     * "1" 		= highlights line 1
     * "2,5"	= highlights lines 2 & 5
     * "2,5-7"	= highlights lines 2, 5, 6 & 7
     */
    highlightLines: function( block, linesToHighlight ) {

      var highlightSteps = RevealHighlight.deserializeHighlightSteps( linesToHighlight || block.getAttribute( 'data-line-numbers' ) );

      if( highlightSteps.length ) {

        highlightSteps[0].forEach( function( highlight ) {

          var elementsToHighlight = [];

          // Highlight a range
          if( typeof highlight.end === 'number' ) {
            elementsToHighlight = [].slice.call( block.querySelectorAll( 'table tr:nth-child(n+'+highlight.start+'):nth-child(-n+'+highlight.end+')' ) );
          }
          // Highlight a single line
          else if( typeof highlight.start === 'number' ) {
            elementsToHighlight = [].slice.call( block.querySelectorAll( 'table tr:nth-child('+highlight.start+')' ) );
          }

          if( elementsToHighlight.length ) {
            elementsToHighlight.forEach( function( lineElement ) {
              lineElement.classList.add( 'highlight-line' );
            } );

            block.classList.add( 'has-highlights' );
          }

        } );

      }

    },

    /**
     * Parses and formats a user-defined string of line
     * numbers to highlight.
     *
     * @example
     * RevealHighlight.deserializeHighlightSteps( '1,2|3,5-10' )
     * // [
     * //   [ { start: 1 }, { start: 2 } ],
     * //   [ { start: 3 }, { start: 5, end: 10 } ]
     * // ]
     */
    deserializeHighlightSteps: function( highlightSteps ) {

      // Remove whitespace
      highlightSteps = highlightSteps.replace( /\s/g, '' );

      // Divide up our line number groups
      highlightSteps = highlightSteps.split( RevealHighlight.HIGHLIGHT_STEP_DELIMITER );

      return highlightSteps.map( function( highlights ) {

        return highlights.split( RevealHighlight.HIGHLIGHT_LINE_DELIMITER ).map( function( highlight ) {

          // Parse valid line numbers
          if( /^[\d-]+$/.test( highlight ) ) {

            highlight = highlight.split( RevealHighlight.HIGHLIGHT_LINE_RANGE_DELIMITER );

            var lineStart = parseInt( highlight[0], 10 ),
              lineEnd = parseInt( highlight[1], 10 );

            if( isNaN( lineEnd ) ) {
              return {
                start: lineStart
              };
            }
            else {
              return {
                start: lineStart,
                end: lineEnd
              };
            }

          }
          // If no line numbers are provided, no code will be highlighted
          else {

            return {};

          }

        } );

      } );

    },

    /**
     * Serializes parsed line number data into a string so
     * that we can store it in the DOM.
     */
    serializeHighlightSteps: function( highlightSteps ) {

      return highlightSteps.map( function( highlights ) {

        return highlights.map( function( highlight ) {

          // Line range
          if( typeof highlight.end === 'number' ) {
            return highlight.start + RevealHighlight.HIGHLIGHT_LINE_RANGE_DELIMITER + highlight.end;
          }
          // Single line
          else if( typeof highlight.start === 'number' ) {
            return highlight.start;
          }
          // All lines
          else {
            return '';
          }

        } ).join( RevealHighlight.HIGHLIGHT_LINE_DELIMITER );

      } ).join( RevealHighlight.HIGHLIGHT_STEP_DELIMITER );

    }

  }

  Reveal.registerPlugin( 'highlight', RevealHighlight );

  return RevealHighlight;

}));
        }
      end
    end
  end
end
