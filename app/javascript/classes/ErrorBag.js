'use strict'

const pregQuote = (str, delimiter) => (str + '') // equivalent of PHP's preg_quote
  .replace(new RegExp('[.\\\\+*?\\[\\^\\]$(){}=!<>|:\\' + (delimiter || '') + '-]', 'g'), '\\$&')

const strMatch = function (inputPattern, value) {
  var patterns = Array.isArray(inputPattern) ? inputPattern : [inputPattern]

  if (patterns.length === 0) {
    return false
  }

  for (var pattern of patterns) {
    // If the given value is an exact match we can of course return true right
    // from the beginning. Otherwise, we will translate asterisks and do an
    // actual pattern match against the two strings to see if they match.
    if (pattern === value) {
      return true
    }
    pattern = pregQuote(pattern, '/')
    // Asterisks are translated into zero-or-more regular expression wildcards
    // to make it convenient to check if the strings starts with the given
    // pattern such as "library/*", making any string check convenient.
    pattern = pattern.replace('*', '.*')
    if (new RegExp('^' + pattern + '$', 'u').test(value)) {
      return true
    }
  }

  return false
}

export default class ErrorBag {

  /**
     * Create a new message bag instance.
     *
     * @param  Array  messages
     * @return void
     */
  constructor(messages) {
    this.messages = []
    this.format = ':message'
    for (var key in messages) {
      this.messages[key] = messages[key]
    }
  }


  /**
     * Get the keys present in the message bag.
     *
     * @return Array
     */
  keys () {
    return Object.keys(this.messages)
  }

  /**
     * Add a message to the message bag.
     *
     * @param  String  key
     * @param  String  message
     * @return this
     */
  add (key, message) {
    if (this.isUnique(key, message)) {
      if (!Array.isArray(this.messages[key])) {
        this.messages[key] = [this.messages[key]]
      }
      this.messages[key].push(message)
    }

    return this
  }

  /**
     * Determine if a key and message combination already exists.
     *
     * @param  String  key
     * @param  String  message
     * @return bool
     */
  isUnique (key, message) {
    var messages = this.messages

    return !(typeof messages[key] !== 'undefined') || !messages[key].includes(message)
  }

  /**
     * Determine if messages exist for all of the given keys.
     *
     * @param  Array|string  key
     * @return bool
     */
  has (key) {
    if (this.isEmpty()) {
      return false
    }

    if (typeof key === 'undefined') {
      return this.any()
    }

    var keys = Array.isArray(key) ? key : arguments

    for (var value of keys) {
      if (this.first(value) === '') {
        return false
      }
    }

    return true
  }

  /**
     * Determine if messages exist for any of the given keys.
     *
     * @param  Array|string  keys
     * @return bool
     */
  hasAny (keys = []) {
    if (this.isEmpty()) {
      return false
    }

    keys = Array.isArray(keys) ? keys : arguments

    for (var key of keys) {
      if (this.has(key)) {
        return true
      }
    }

    return false
  }

  /**
     * Get the first message from the message bag for a given key.
     *
     * @param  String  key
     * @param  String  format
     * @return string
     */
  first (key, format) {
    var messages = typeof key === 'undefined' ? this.all(format) : this.get(key, format)

    var values = Object.values(messages)

    var firstMessage = values.hasOwnProperty(0) ? values[0] : ''

    return Array.isArray(firstMessage) ? this.first(firstMessage) : firstMessage
  }

  /**
     * Get all of the messages from the message bag for a given key.
     *
     * @param  String  key
     * @return Array
     */
  get (key, format) {
    // If the message exists in the message bag, we will transform it and return
    // the message. Otherwise, we will check if the key is implicit & collect
    // all the messages that match the given key and output it as an Array.
    if (this.messages.hasOwnProperty(key)) {
      return this.transform(
        this.messages[key], this.checkFormat(format), key
      )
    }

    if (key.indexOf('*') !== -1) {
      return this.getMessagesForWildcardKey(key, format)
    }

    return []
  }

  /**
     * Get the messages for a wildcard key.
     *
     * @param  String  key
     * @param  String|null  format
     * @return Array
     */
  getMessagesForWildcardKey (key, format) {
    var messages = {}

    for (var messageKey in this.messages) {
      if (strMatch(key, messageKey)) {
        messages[messageKey] = this.transform(
          this.messages[messageKey], this.checkFormat(format), messageKey
        )
      }
    }

    return Object.values(messages)
  }

  /**
     * Get all of the messages for every key in the message bag.
     *
     * @param  String  format
     * @return Array
     */
  all (format) {
    format = this.checkFormat(format)

    var all = []

    for (var key in this.messages) {
      all = all.concat(this.transform(this.messages[key], format, key))
    }

    return all
  }

  /**
     * Get all of the unique messages for every key in the message bag.
     *
     * @param  String  format
     * @return Array
     */
  unique (format) {
    return [...new Set(this.all(format))]
  }

  /**
     * Format an Array of messages.
     *
     * @param  Array   messages
     * @param  String  format
     * @param  String  messageKey
     * @return Array
     */
  transform (messages, format, messageKey) {
    return Object.values(messages)
      .map(message => {
        // We will simply spin through the given messages and transform each one
        // replacing the :message place holder with the real message allowing
        // the messages to be easily formatted to each developer's desires.
        //
        format = format.replace(':key', messageKey)

        return format.replace(':message', message)
      })
  }

  /**
     * Get the appropriate format based on the given format.
     *
     * @param  String  format
     * @return String
     */
  checkFormat (format) {
    return format ? format : this.format
  }

  /**
     * Get the raw messages in the message bag.
     *
     * @return Array
     */
  getMessages () {
    return this.messages
  }

  /**
     * Get the default message format.
     *
     * @return string
     */
  getFormat () {
    return this.format
  }

  /**
     * Set the default message format.
     *
     * @param  String  format
     * @return this
     */
  setFormat (format = ':message') {
    this.format = format

    return this
  }

  /**
     * Determine if the message bag has any messages.
     *
     * @return bool
     */
  isEmpty () {
    return !this.any()
  }

  /**
     * Determine if the message bag has any messages.
     *
     * @return bool
     */
  isNotEmpty () {
    return this.any()
  }

  /**
     * Determine if the message bag has any messages.
     *
     * @return bool
     */
  any () {
    return this.count() > 0
  }

  /**
     * Get the number of messages in the message bag.
     *
     * @return int
     */
  count () {
    return Object.values(this.messages).length
  }

  /**
     * Get the instance as an Array.
     *
     * @return Array
     */
  toArray () {
    return this.getMessages()
  }

}
