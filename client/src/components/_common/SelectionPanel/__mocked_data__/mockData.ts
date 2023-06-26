/* eslint-disable @typescript-eslint/no-empty-function */
import {
  ListOption,
  ListOptionSelection,
  RadioOption,
  RadioOptionSelection,
} from '~/models/selectionModels';

export const mockedListOptions: ListOption[] = [
  { id: 'one', title: 'One' },
  { id: 'two', title: 'Two' },
];

export const mockedRadioOptions: RadioOption[] = [
  {
    id: 'one',
    title: 'One',
    description: 'Option One Description',
    list_options: [
      { label: 'Choice A', id: 'choice-a', value: 'a' },
      { label: 'Choice B', id: 'choice-b', value: 'b' },
    ],
  },
  {
    id: 'two',
    title: 'Two',
    description: 'Option Two Description',
    list_options: [
      { label: 'Choice C', id: 'choice-c', value: 'c' },
      { label: 'Choice D', id: 'choice-d', value: 'd' },
    ],
  },
];

// eslint-disable-next-line @typescript-eslint/no-unused-vars
export const mockedSetSelected = (selected: ListOptionSelection | RadioOptionSelection[]) => {};

export const mockedSubmit = () => {};

export const mockedSelectionPanelData = {
  listOptions: mockedListOptions,
  radioOptions: mockedRadioOptions,
  setSelected: mockedSetSelected,
  submitAction: mockedSubmit,
};
