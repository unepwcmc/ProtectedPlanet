import { mount } from "vue-test-utils";
import SelectEquity from "components/select/SelectEquity.vue";
import SelectDropdown from "components/select/SelectDropdown.vue";
import image from "../assets/images/background.jpg";


describe("SelectEquity.vue", () => {
  // Set up props
  const protectedAreas = [
    { title: "test message 1", text: "sample text 1", image: image }, 
    { title: "test message 2", text: "sample text 2" }, 
    { title: "test message 3", text: "sample text 3" }
  ];
  
  // Mount the component
  const component = mount(SelectEquity, {
    propsData: { protectedAreas }
  });

  const child = component.find(SelectDropdown);

  // Teardown funcs: reset the component's selected value to the first value of 
  // protectedAreas after each test
  afterEach(() => {
    resetComponent();
  });

  function resetComponent() {
    component.setData({ selected: protectedAreas[0] });
  }


  // Test suite
  it("renders its child component correctly", () => {
    expect(child.exists()).toBe(true);
  });

  it("listens for emitted events and updates its properties in response", async () => {
    await child.find('div.select--dropdown__selected').trigger('click');
    await child.find('span.select--dropdown__option:last-child').trigger('click');
    expect(child.emitted('pa-selected').length).toBe(1);
    expect(component.vm.selected).toBe(protectedAreas[2]);
  });

  it("displays the correct text", () => {
    const text = component.find('p')
    expect(text.text()).toEqual('sample text 1');
  });

  it("shows the correct image", () => {
    const imageUrl = component.find('img').element.src;
    expect(imageUrl).toEqual(protectedAreas[0].image);
  });
});