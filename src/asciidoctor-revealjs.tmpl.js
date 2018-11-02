(function (Opal) {
  function initialize (Opal) {
//OPAL-GENERATED-CODE//
  }

  var mainModule

  function resolveModule (name) {
    if (!mainModule) {
      checkAsciidoctor()
      initialize(Opal)
      mainModule = Opal.const_get_qualified(Opal.Asciidoctor, 'revealjs') // FIXME: was Html5s
    }
    if (!name) {
      return mainModule
    }
    return Opal.const_get_qualified(mainModule, name)
  }

  function checkAsciidoctor () {
    if (typeof Opal.Asciidoctor === 'undefined') {
      throw new TypeError('Asciidoctor.js is not loaded')
    }
  }

  /**
   * @param {string} backend The backend name.
   * @param {Object} opts The converter options.
   * @return A new instance of `Asciidoctor::Revealjs::Converter`
   */
  function Converter (backend, opts) {
    var converter = resolveModule('Converter').$new(backend, Opal.hash(opts || {}))

    converter.convert = function (node, transform, opts) {
      return this.$convert(node, transform, Opal.hash(opts || {}))
    }
    return converter
  }

  /**
   * @return {string} Version of this extension.
   */
  function getVersion () {
    return resolveModule().$$const.VERSION.toString()
  }

  // TODO get rid of the colisttreeprocessor if I can
  /**
   * Registers the Revealjs converter and the supporting extension into Asciidoctor.
   *
   * @param registry The Asciidoctor extensions registry to register the
   *   extension into. Defaults to the global Asciidoctor registry.
   * @throws {TypeError} if the *registry* is invalid or Asciidoctor.js is not loaded.
   */
  function register (registry) {
    if (!registry) {
      checkAsciidoctor()
      registry = Opal.Asciidoctor.Extensions
    }
    /*
    var processor = AttachedColistTreeprocessor()

    // global registry
    if (typeof registry.register === 'function') {
      registry.register(function () {
        this.treeProcessor(processor)
      })
    // custom registry
    } else if (typeof registry.block === 'function') {
      registry.treeProcessor(processor)
    } else {
      throw new TypeError('Invalid registry object')
    }
    */
  }

  var facade = {
    Converter: Converter,
    getVersion: getVersion,
    register: register,
  }

  if (typeof module !== 'undefined' && module.exports) {
    module.exports = facade
  }
  return facade
})(Opal);
