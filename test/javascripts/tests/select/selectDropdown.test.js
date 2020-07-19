import { mount } from "vue-test-utils";
import SelectDropdown from "components/select/SelectDropdown.vue";


describe("SelectDropdown.vue", () => {
  // Set up props
  const protectedAreas = [
  { title: "test message 1" }, 
  { title: "test message 2" }, 
  { title: "test message 3" }
  ];

  // Mount the component
  const component = mount(SelectDropdown, {
    propsData: { protectedAreas }
  });

  // Locate the select button of the dropdown (that actually allows selections)
  const select = component.find('div.select--dropdown__selected');

  // Locates the last option of the dropdown 
  const newSelection = component.find('span.select--dropdown__option:last-child')

  it("receives the full set of props it is passed", () => {
    expect(component.props().protectedAreas.length).toEqual(protectedAreas.length);
  });


  it("initially renders the first prop it is passed", () => {
    const selectedTitle = component.find('div.select--dropdown__selected > span')
    expect(selectedTitle.text()).toBe("test message 1");
  });

  it("allows selections to be made", async () => {
    await select.trigger('click');
    expect(component.vm.isActive).toBeTruthy();

    expect(newSelection.text()).toEqual(protectedAreas[2].title);

    // Updates the 'selected' property of data
    await newSelection.trigger('click');
    expect(component.vm.selected).toEqual(protectedAreas[2]);
  });

  it("emits the selected option", async () => {
    await select.trigger('click');
    await newSelection.trigger('click');
    expect(component.emitted('pa-selected')).toBeTruthy;
  });
});

