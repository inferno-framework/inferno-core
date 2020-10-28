import { TestSuite } from 'models/testSuiteModels';

export const mockedTestSuitesReturnValue: TestSuite[] = [
  { id: 'DemoIG_STU1::DemoSuite', title: 'Demonstration Suite' },
  { id: 'infra_test', title: 'Infrastructure Test' },
];

export const mockedPostTestSuiteResponse = {
  id: 'b19c1d17-1937-4ef8-a7b0-baeb0fa5c136',
  test_suite: {
    id: 'DemoIG_STU1::DemoSuite',
    test_groups: [
      {
        id: 'DemoIG_STU1::DemoSuite-Group01',
        inputs: [],
        test_groups: [
          {
            id: 'DemoIG_STU1::DemoSuite-Group01-DemoIG_STU1::DemoGroup',
            inputs: [
              {
                name: 'url',
              },
              {
                name: 'patient_id',
              },
            ],
            test_groups: [],
            tests: [
              {
                id: 'DemoIG_STU1::DemoSuite-Group01-DemoIG_STU1::DemoGroup-Test01',
                title: 'successful tests',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group01-DemoIG_STU1::DemoGroup-Test02',
                title: 'warning message test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group01-DemoIG_STU1::DemoGroup-Test03',
                title: 'error test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group01-DemoIG_STU1::DemoGroup-Test04',
                title: 'input use example',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group01-DemoIG_STU1::DemoGroup-Test05',
                title: 'output use example',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group01-DemoIG_STU1::DemoGroup-Test06',
                title: 'client use examples test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group01-DemoIG_STU1::DemoGroup-Test07',
                title: 'warning block test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group01-DemoIG_STU1::DemoGroup-Test08',
                title: 'skip test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group01-DemoIG_STU1::DemoGroup-Test09',
                title: 'omit test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group01-DemoIG_STU1::DemoGroup-Test10',
                title: 'pass test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group01-DemoIG_STU1::DemoGroup-Test11',
                title: 'skip_if test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group01-DemoIG_STU1::DemoGroup-Test12',
                title: 'omit_if test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group01-DemoIG_STU1::DemoGroup-Test13',
                title: 'pass_if test',
              },
            ],
            title: 'Demo Group Instance 1',
          },
        ],
        tests: [],
        title: 'Group 1',
      },
      {
        id: 'DemoIG_STU1::DemoSuite-Group02',
        inputs: [],
        test_groups: [
          {
            id: 'DemoIG_STU1::DemoSuite-Group02-DEF',
            inputs: [
              {
                name: 'url',
              },
              {
                name: 'patient_id',
              },
            ],
            test_groups: [],
            tests: [
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-DEF-Test01',
                title: 'successful tests',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-DEF-Test02',
                title: 'warning message test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-DEF-Test03',
                title: 'error test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-DEF-Test04',
                title: 'input use example',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-DEF-Test05',
                title: 'output use example',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-DEF-Test06',
                title: 'client use examples test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-DEF-Test07',
                title: 'warning block test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-DEF-Test08',
                title: 'skip test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-DEF-Test09',
                title: 'omit test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-DEF-Test10',
                title: 'pass test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-DEF-Test11',
                title: 'skip_if test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-DEF-Test12',
                title: 'omit_if test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-DEF-Test13',
                title: 'pass_if test',
              },
            ],
            title: 'Demo Group Instance 2',
          },
          {
            id: 'DemoIG_STU1::DemoSuite-Group02-GHI',
            inputs: [
              {
                name: 'url',
              },
              {
                name: 'patient_id',
              },
            ],
            test_groups: [],
            tests: [
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-GHI-Test01',
                title: 'successful tests',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-GHI-Test02',
                title: 'warning message test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-GHI-Test03',
                title: 'error test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-GHI-Test04',
                title: 'input use example',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-GHI-Test05',
                title: 'output use example',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-GHI-Test06',
                title: 'client use examples test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-GHI-Test07',
                title: 'warning block test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-GHI-Test08',
                title: 'skip test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-GHI-Test09',
                title: 'omit test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-GHI-Test10',
                title: 'pass test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-GHI-Test11',
                title: 'skip_if test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-GHI-Test12',
                title: 'omit_if test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-GHI-Test13',
                title: 'pass_if test',
              },
            ],
            title: 'Demo Group Instance 3',
          },
        ],
        tests: [],
        title: 'Group 2',
      },
    ],
    title: 'Demonstration Suite',
  },
  test_suite_id: 'DemoIG_STU1::DemoSuite',
};
