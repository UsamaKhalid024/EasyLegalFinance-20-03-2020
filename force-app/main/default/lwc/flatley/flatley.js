const isBuffer = (obj) => {
  return !!obj.constructor && typeof obj.constructor.isBuffer === 'function' && obj.constructor.isBuffer(obj)
}

const flatten = (target, opts) => {
  opts = opts || {}

  let delimiter = opts.delimiter || '.'
  let maxDepth = opts.maxDepth
  let coercion = opts.coercion
  let filters = opts.filters
  let output = {}

  const transform = (key, value) => {
    if (!coercion) { return value }
    let transformed = value

    coercion.forEach((c) => {
      transformed = c.test(key, transformed) ? c.transform(transformed) : transformed
    })

    return transformed
  }

  const isFiltered = (key, value) => {
    if (!filters) { return false }

    let filtered = false
    filters.forEach((filter) => {
      if (filter.test(key, value)) {
        filtered = true
      }
    })
    return filtered
  }

  const shouldTraverse = (value, transformedValue, currentDepth, filters) => {
    let type = Object.prototype.toString.call(value)
    let isarray = opts.safe && Array.isArray(value)
    let isbuffer = isBuffer(value)
    let isobject = (
      type === '[object Object]' ||
      type === '[object Array]'
    )

    return transformedValue === value &&
      !isarray &&
      !isbuffer &&
      isobject &&
      Object.keys(value).length &&
      (!opts.maxDepth || currentDepth < maxDepth)
  }

  const step = (object, prev, currentDepth) => {
    currentDepth = currentDepth || 1
    Object.keys(object).forEach((key) => {
      let value = object[key]

      let newKey = prev
        ? prev + delimiter + key
        : key

      const transformedValue = transform(key, value)

      if (shouldTraverse(value, transformedValue, currentDepth) && !isFiltered(key, value)) {
        return step(value, newKey, currentDepth + 1)
      }

      output[newKey] = transformedValue
    })
  }

  step(target)

  return output
}

const unflatten = (target, opts) => {
  opts = opts || {}

  let delimiter = opts.delimiter || '.'
  let overwrite = opts.overwrite || false
  let result = {}

  let isbuffer = isBuffer(target)
  if (isbuffer || Object.prototype.toString.call(target) !== '[object Object]') {
    return target
  }

  // safely ensure that the key is
  // an integer.
  const getkey = (key) => {
    let parsedKey = Number(key)

    return (
      isNaN(parsedKey) ||
      key.indexOf('.') !== -1 ||
      opts.object
    ) ? key
      : parsedKey
  }

  let sortedKeys = Object.keys(target).sort((keyA, keyB) => {
    return keyA.length - keyB.length
  })

  sortedKeys.forEach((key) => {
    let split = key.split(delimiter)
    let key1 = getkey(split.shift())
    let key2 = getkey(split[0])
    let recipient = result

    while (key2 !== undefined) {
      let type = Object.prototype.toString.call(recipient[key1])
      let isobject = (
        type === '[object Object]' ||
        type === '[object Array]'
      )

      // do not write over falsey, non-undefined values if overwrite is false
      if (!overwrite && !isobject && typeof recipient[key1] !== 'undefined') {
        return
      }

      if ((overwrite && !isobject) || (!overwrite && recipient[key1] == null)) {
        recipient[key1] = (
          typeof key2 === 'number' &&
          !opts.object ? [] : {}
        )
      }

      recipient = recipient[key1]
      if (split.length > 0) {
        key1 = getkey(split.shift())
        key2 = getkey(split[0])
      }
    }

    // unflatten again for 'messy objects'
    recipient[key1] = unflatten(target[key], opts)
  })

  return result
}

export {
  flatten,
  unflatten
}