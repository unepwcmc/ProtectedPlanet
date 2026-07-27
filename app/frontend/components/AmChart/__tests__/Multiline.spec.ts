import { describe, it, expect, vi } from 'vitest'
import { mount } from '@vue/test-utils'

function fakeAxis() {
  return {
    renderer: {
      grid: { template: { disabled: false } },
      line: { strokeOpacity: null, strokeWidth: null, stroke: null },
      ticks: { template: { disabled: false, strokeOpacity: null, stroke: null, length: null } },
      minGridDistance: null
    },
    title: { text: '', rotation: null, valign: null, dy: null, dx: null }
  }
}

function fakeSeries() {
  return {
    dataFields: {} as Record<string, string>,
    name: '',
    stroke: null as unknown,
    strokeWidth: null as unknown,
    yAxis: null as unknown,
    bullets: { push: vi.fn((bullet: unknown) => bullet) }
  }
}

function createChartMock() {
  return {
    data: null as unknown,
    paddingTop: null as unknown,
    paddingRight: null as unknown,
    paddingLeft: null as unknown,
    background: { fill: null as unknown },
    legend: null as unknown,
    xAxes: { push: vi.fn(() => fakeAxis()) },
    yAxes: { push: vi.fn(() => fakeAxis()) },
    series: { push: vi.fn(() => fakeSeries()) },
    dispose: vi.fn()
  }
}

type ChartMock = ReturnType<typeof createChartMock>
const chartInstances: ChartMock[] = []

function lastChart() {
  return chartInstances.at(-1)!
}

vi.mock('@amcharts/amcharts4/core', () => ({
  options: { autoSetClassName: false },
  create: vi.fn(() => {
    const chart = createChartMock()
    chartInstances.push(chart)
    return chart
  }),
  color: vi.fn((value: string) => value)
}))

vi.mock('@amcharts/amcharts4/charts', () => ({
  XYChart: class {},
  DateAxis: class {},
  ValueAxis: class {},
  LineSeries: class {},
  CircleBullet: class {},
  Legend: class {}
}))

const { default: AmChartMultiline } = await import('@/components/AmChart/Multiline.vue')

const data = {
  units: 'km2',
  legend: ['National', 'ABNJ', 'Global'],
  datapoints: [{ x: '2020', 1: 10, 2: 20, 3: 30 }]
}

describe('AmChartMultiline', () => {
  it('creates one line series per datapoint key (minus x), named from data.legend', () => {
    mount(AmChartMultiline, { props: { data } })

    const chart = lastChart()
    expect(chart.data).toEqual(data.datapoints)
    expect(chart.series.push).toHaveBeenCalledTimes(3)

    const series = chart.series.push.mock.results.map(result => result.value)
    expect(series.map(s => s.name)).toEqual(data.legend)
  })

  it('adds a bullet per series only when dots is true', () => {
    mount(AmChartMultiline, { props: { data, dots: true } })

    const chart = lastChart()
    const series = chart.series.push.mock.results.map(result => result.value)
    series.forEach((s) => {
      expect(s.bullets.push).toHaveBeenCalled()
    })
  })

  it('defaults the chart background to white', () => {
    mount(AmChartMultiline, { props: { data } })
    expect(lastChart().background.fill).toBe('#ffffff')
  })

  it('disposes the chart on unmount', () => {
    const wrapper = mount(AmChartMultiline, { props: { data } })
    const chart = lastChart()

    wrapper.unmount()

    expect(chart.dispose).toHaveBeenCalled()
  })
})
