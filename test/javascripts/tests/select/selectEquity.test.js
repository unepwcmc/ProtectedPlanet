import { mount } from "vue-test-utils";
import SelectEquity from "components/select/SelectEquity.vue";
import SelectDropdown from "components/select/SelectDropdown.vue";

describe("SelectEquity.vue", () => {
  // Set up props
  const protectedAreas = [
    { title: "test message 1" }, 
    { title: "test message 2" }, 
    { title: "test message 3" }
  ];
  
  // Mount the component
  const component = mount(SelectEquity, {
    propsData: { protectedAreas }
  });

  const child = component.find(SelectDropdown);

  it("renders its child component correctly", () => {
    expect(child.exists()).toBe(true);
  });

  it("listens for emitted events and updates its properties in response", async () => {
    await child.find('div.select--dropdown__selected').trigger('click');
    await child.find('span.select--dropdown__option:last-child').trigger('click');
    expect(child.emitted('pa-selected').length).toBe(1);
    expect(component.vm.selected).toBe(protectedAreas[2]);
  });
});