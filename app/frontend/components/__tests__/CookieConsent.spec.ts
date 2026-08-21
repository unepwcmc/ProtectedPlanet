import { describe, it, expect, beforeEach, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import CookieConsent from '@/components/CookieConsent.vue'

// Mirrors what layouts/partials/_cookie_consent.html.erb passes.
const props = {
  description: 'See our <a href="/legal">Privacy policy</a> page.',
  accept: 'Accept',
  reject: 'Reject'
}

// jsdom keeps cookies between tests — clear so consent-state assertions are isolated.
beforeEach(() => {
  document.cookie.split(';').forEach((c) => {
    const name = c.split('=')[0].trim()
    if (name) document.cookie = `${name}=; path=/; max-age=0`
  })
})

describe('CookieConsent', () => {
  it('renders when no consent decision has been made yet', () => {
    const wrapper = mount(CookieConsent, { props })

    expect(wrapper.find('.ct-cookie-consent').exists()).toBe(true)
    expect(wrapper.find('.ct-cookie-consent__description a').attributes('href')).toBe('/legal')
  })

  it('does not render when consent was already granted', () => {
    document.cookie = 'cookie_consent=granted; path=/'

    const wrapper = mount(CookieConsent, { props })

    expect(wrapper.find('.ct-cookie-consent').exists()).toBe(false)
  })

  it('does not render when consent was already denied', () => {
    document.cookie = 'cookie_consent=denied; path=/'

    const wrapper = mount(CookieConsent, { props })

    expect(wrapper.find('.ct-cookie-consent').exists()).toBe(false)
  })

  it('hides and records granted consent on accept, without loading scripts before the click', async () => {
    const appendChildSpy = vi.spyOn(document.head, 'appendChild')
    const wrapper = mount(CookieConsent, { props })

    expect(appendChildSpy).not.toHaveBeenCalled()

    await wrapper.find('.ct-cookie-consent__button--accept').trigger('click')

    expect(wrapper.find('.ct-cookie-consent').exists()).toBe(false)
    expect(document.cookie).toContain('cookie_consent=granted')
    expect(appendChildSpy).toHaveBeenCalled()

    appendChildSpy.mockRestore()
  })

  it('hides and records denied consent on reject, without loading any scripts', async () => {
    const appendChildSpy = vi.spyOn(document.head, 'appendChild')
    const wrapper = mount(CookieConsent, { props })

    await wrapper.find('.ct-cookie-consent__button--reject').trigger('click')

    expect(wrapper.find('.ct-cookie-consent').exists()).toBe(false)
    expect(document.cookie).toContain('cookie_consent=denied')
    expect(appendChildSpy).not.toHaveBeenCalled()

    appendChildSpy.mockRestore()
  })
})
