import { describe, it, expect, vi } from 'vitest'
import { mount } from '@vue/test-utils'

class FakePieSeries {
  dataFields: Record<string, string> = {}
  slices = {
    template: {
      states: { getKey: vi.fn(() => ({ properties: {} as Record<string, unknown> })) },
      stroke: null as unknown,
      strokeWidth: null as unknown,
      strokeOpacity: null as unknown,
      tooltipText: ''
    }
  }

  labels = { template: { disabled: false } }
  ticks = { template: { disabled: false } }
  colors = { list: [] as unknown[] }
  tooltip = {
    getFillFromObject: true,
    background: { fill: null as unknown, stroke: null as unknown },
    label: { fontSize: null as unknown, padding: vi.fn(), textAlign: null as unknown }
  }
}

function createChartMock() {
  return {
    data: null as unknown,
    radius: null as unknown,
    innerRadius: null as unknown,
    series: { push: vi.fn((series: FakePieSeries) => series) },
    dispose: vi.fn()
  }
}

type ChartMock = ReturnType<typeof createChartMock>
const chartInstances: ChartMock[] = []

function lastChart() {
  return chartInstances.at(-1)!
}

function lastPieSeries() {
  return lastChart().series.push.mock.results[0].value as FakePieSeries
}

vi.mock('@amcharts/amcharts4/core', () => ({
  create: vi.fn(() => {
    const chart = createChartMock()
    chartInstances.push(chart)
    return chart
  }),
  percent: vi.fn((value: number) => `${value}%`),
  color: vi.fn((value: string) => value)
}))

vi.mock('@amcharts/amcharts4/charts', () => ({
  PieChart: class {},
  PieSeries: FakePieSeries
}))

const { default: AmChartPie } = await import('@/components/AmChart/Pie.vue')

describe('AmChartPie', () => {
  it('creates a pie chart from the dataset with 12 theme colours', () => {
    const dataset = [{ id: 1, title: 'A', value: 5 }]
    mount(AmChartPie, { props: { dataset } })

    const chart = lastChart()
    expect(chart.data).toEqual(dataset)
    expect(chart.series.push).toHaveBeenCalled()

    const pieSeries = lastPieSeries()
    expect(pieSeries.colors.list).toHaveLength(12)
    expect(pieSeries.labels.template.disabled).toBe(true)
    expect(pieSeries.ticks.template.disabled).toBe(true)
  })

  it('sets innerRadius only when doughnut is true', () => {
    mount(AmChartPie, { props: { dataset: [], doughnut: true } })
    expect(lastChart().innerRadius).toBe('50%')

    mount(AmChartPie, { props: { dataset: [] } })
    expect(lastChart().innerRadius).toBeNull()
  })

  it('adds a slice stroke only when spacers is true', () => {
    mount(AmChartPie, { props: { dataset: [], spacers: true } })

    expect(lastPieSeries().slices.template.stroke).toBe('#ffffff')
  })

  it('updates chart.data when the dataset prop changes', async () => {
    const wrapper = mount(AmChartPie, { props: { dataset: [{ id: 1, title: 'A', value: 1 }] } })
    const chart = lastChart()

    const nextDataset = [{ id: 2, title: 'B', value: 2 }]
    await wrapper.setProps({ dataset: nextDataset })

    expect(chart.data).toEqual(nextDataset)
  })

  it('disposes the chart on unmount', () => {
    const wrapper = mount(AmChartPie, { props: { dataset: [] } })
    const chart = lastChart()

    wrapper.unmount()

    expect(chart.dispose).toHaveBeenCalled()
  })
})
