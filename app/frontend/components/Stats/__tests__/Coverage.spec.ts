import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import StatsCoverage from '@/components/Stats/Coverage.vue'

const baseProps = {
  protectedKm2: '1,000',
  protectedPercentage: 25,
  textCoverage: 'coverage',
  textProtected: 'protected',
  textTotal: 'total',
  title: 'Land',
  totalKm2: '4,000',
  type: 'land'
}

describe('StatsCoverage', () => {
  it('sizes the coverage square as sqrt(percentage * 100)', () => {
    const wrapper = mount(StatsCoverage, { props: baseProps })

    expect(wrapper.find('.ct-stats-coverage__area').attributes('style')).toContain(`width: ${Math.sqrt(2500)}%`)
  })

  it('only shows the national report line when both fields are present', () => {
    const withoutReport = mount(StatsCoverage, { props: baseProps })
    expect(withoutReport.find('.ct-stats-coverage__subtitle').exists()).toBe(false)

    const withReport = mount(StatsCoverage, {
      props: { ...baseProps, protectedNationalReport: 12.3456, nationalReportVersion: 2020, textNationalReport: 'NR' }
    })
    expect(withReport.text()).toContain('12.35%')
  })

  it('only shows the PAME subsection when both pame fields are present', () => {
    const withoutPame = mount(StatsCoverage, { props: baseProps })
    expect(withoutPame.find('.ct-stats-coverage__subsection').exists()).toBe(false)

    const withPame = mount(StatsCoverage, {
      props: { ...baseProps, pamePercentage: 10, pameKm2: '500', textPame: 'PAME km2', textPameAssessments: 'PAME %' }
    })
    expect(withPame.find('.ct-stats-coverage__subsection').exists()).toBe(true)
  })
})
