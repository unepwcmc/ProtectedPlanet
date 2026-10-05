import { describe, it, expect, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import Banner from '@/components/Banner/Index.vue'
import type { Banner as BannerRow } from '@/types/backend'

const bannerRow = (overrides: Partial<BannerRow>): BannerRow => ({
  id: 0,
  title: null,
  content: '',
  is_active: true,
  created_at: '2026-01-01T00:00:00.000Z',
  updated_at: '2026-01-01T00:00:00.000Z',
  ...overrides
})

const single = [bannerRow({ id: 1, title: 'Hello', content: '<p>World</p>' })]
const many = [
  bannerRow({ id: 1, title: 'A', content: '<p>a</p>' }),
  bannerRow({ id: 2, title: 'B', content: '<p>b</p>' })
]

// jsdom keeps cookies between tests — clear so close-cookie assertions are isolated.
beforeEach(() => {
  document.cookie.split(';').forEach((c) => {
    const name = c.split('=')[0].trim()
    if (name) document.cookie = `${name}=; path=/; max-age=0`
  })
})

describe('Banner', () => {
  it('renders a single banner without nav controls', () => {
    const wrapper = mount(Banner, { props: { banners: single, signature: 'sig' } })

    expect(wrapper.find('.ct-banner-content__title').text()).toBe('Hello')
    expect(wrapper.find('.ct-banner-content__body').html()).toContain('<p>World</p>')
    expect(wrapper.find('.banner__nav--next').exists()).toBe(false)
    expect(wrapper.find('.banner__nav--prev').exists()).toBe(false)
  })

  it('shows nav controls and cycles (wrapping) with next/prev', async () => {
    const wrapper = mount(Banner, { props: { banners: many, signature: 'sig' } })

    const activeSlideTitle = () => wrapper.findAll('.ct-banner__slide')
      .find(slide => slide.classes().includes('ct-banner-content--is-active'))
      ?.find('.ct-banner-content__title')
      .text()

    expect(activeSlideTitle()).toBe('A')

    await wrapper.find('.banner__nav--next').trigger('click')
    expect(activeSlideTitle()).toBe('B')

    await wrapper.find('.banner__nav--next').trigger('click')
    expect(activeSlideTitle()).toBe('A') // wraps forward

    await wrapper.find('.banner__nav--prev').trigger('click')
    expect(activeSlideTitle()).toBe('B') // wraps backward
  })

  it('hides and sets the per-id cookie on close (single banner)', async () => {
    const wrapper = mount(Banner, { props: { banners: single, signature: 'sig' } })

    await wrapper.find('.ct-banner__close').trigger('click')

    expect(wrapper.find('.ct-banner').exists()).toBe(false)
    expect(document.cookie).toContain('banner_closed=1')
  })

  it('sets the signature cookie on close (multiple banners)', async () => {
    const wrapper = mount(Banner, { props: { banners: many, signature: 'sig-abc' } })

    await wrapper.find('.ct-banner__close').trigger('click')

    expect(document.cookie).toContain('banner_closed_sig=sig-abc')
  })
})
