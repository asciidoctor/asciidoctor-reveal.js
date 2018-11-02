(function (Opal) {
  function initialize (Opal) {
//OPAL-GENERATED-CODE//
  }

  var mainModule

  function resolveModule () {
    if (!mainModule) {
      checkAsciidoctor()
      initialize(Opal)
      mainModule = Opal.const_get_qualified(Opal.Asciidoctor, 'Revealjs')
    }
    return mainModule
  }

  function checkAsciidoctor () {
    if (typeof Opal.Asciidoctor === 'undefined') {
      throw new TypeError('Asciidoctor.js is not loaded')
    }
  }

  /**
   * @return {string} Version of this extension.
   */
  function getVersion () {
    return resolveModule().$$const.VERSION.toString()
  }

  /**
   * Registers the reveal.js converter.
   */
  function register () {
    return resolveModule()
  }

  var facade = {
    getVersion: getVersion,
    register: register,
  }

  if (typeof module !== 'undefined' && module.exports) {
    module.exports = facade
  }
  return facade
})(Opal);
