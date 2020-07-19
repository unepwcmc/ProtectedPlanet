import { mount } from "vue-test-utils";
import SelectEquity from "components/select/SelectEquity.vue";

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

  it("renders its child component correctly", () => {

  })
});