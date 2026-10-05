import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import SiteId from '@/components/Pame/Table/Row/SiteId.vue'

describe('Pame Table SiteId', () => {
  it('shows the parcel id when it differs from the site id', () => {
    const wrapper = mount(SiteId, { props: { siteId: 123, sitePid: '123-1' } })

    expect(wrapper.find('.ct-pame-table-row-site-id__site-pid').exists()).toBe(true)
    expect(wrapper.text()).toContain('123-1')
  })

  it('hides the parcel id when it matches the site id', () => {
    const wrapper = mount(SiteId, { props: { siteId: 123, sitePid: '123' } })

    expect(wrapper.find('.ct-pame-table-row-site-id__site-pid').exists()).toBe(false)
  })
})
