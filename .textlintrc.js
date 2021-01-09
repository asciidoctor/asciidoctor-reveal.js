module.exports = {
  plugins: [
    'asciidoc'
  ],
  rules: {
    //'spelling': true,
    'no-repetition': true,
    //'title-case': true,
    'stop-words': {
      skip: ['BlockQuote', 'CodeBlock'],
      defaultWords: false,
      words: [
        // checks correct capitalization
        ['asciidoctor', 'Asciidoctor'],
        ['npm', 'npm'],
        ['asciidoc', 'AsciiDoc'],
        ['bundler', 'Bundler'],
        ['ruby', 'Ruby'],
        ['node', 'Node'],
        // checks for use of first person pronouns.
        ['I'],
        ['I\'ve'],
        ['I\'m'],
        ['me'],
        ['myself'],
        ['mine'],
        // suggests alternatives for words that are culturally inappropriate.
        ['blacklist', 'denylist'],
        ['blacklists', 'denylist'],
        ['blacklisted', 'denylist'],
        ['blacklisting', 'denylist'],
        ['whitelist', 'allowlist'],
        ['whitelists', 'allowlist'],
        ['whitelisted', 'allowlist'],
        ['whitelisting', 'allowlist'],
        ['master', 'primary, main'],
        ['slave', 'secondary'],
        // suggests alternatives for words that are gender-specific.
        ['mankind', 'humanity, people'],
        ['manpower', 'Asciidoctor team members'],
        ['manpower', 'Asciidoctor team members'],
        ['he', 'they'],
        ['his', 'their'],
        ['she', 'they'],
        ['hers', 'their'],
        // checks for words implying ease of use, to avoid cognitive dissonance for frustrated users.
        /*
        ['easy'],
        ['easily'],
        ['handy'],
        ['simple'],
        ['simply'],
        */
      ]
    }
  }
}
