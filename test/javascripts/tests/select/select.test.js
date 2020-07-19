import { mount } from "vue-test-utils";
import SelectDropdown from "components/select/SelectDropdown.vue";


describe("SelectDropdown.vue", () => {
  const protectedAreas = [{ title: "test message 1" }, { title: "test message 2" }, 
  { title: "test message 3" }];
  const component = mount(SelectDropdown, {
    propsData: { protectedAreas }
  });
  const select = component.find('div.select--dropdown__selected');

  it("receives the full set of props it is passed", () => {
    expect(component.props().protectedAreas.length).toEqual(protectedAreas.length);
  });


  it("renders only the first prop message it is passed", () => {
    const selectedTitle = component.find('div.select--dropdown__selected > span')
    expect(selectedTitle.text()).toBe("test message 1");
  });

  it("allows selections to be made", async () => {
    await select.trigger('click');
    expect(component.vm.isActive).toBeTruthy();

    // Locates the last option of the dropdown 
    const newSelection = component.find('span.select--dropdown__option:last-child')
    expect(newSelection.text()).toEqual(protectedAreas[2].title);

    // Updates the 'selected' property of data
    newSelection.trigger('click');
    expect(component.vm.selected).toEqual(protectedAreas[2]);
  });

  it("emits the selected option", async () => {
    await select.trigger('click');

    const newSelection = component.find('span.select--dropdown__option:last-child');
    
    newSelection.trigger('click');
    expect(component.emitted('pa-selected')).toBeTruthy;
  });
});

