import { TestSuite } from 'models/testSuiteModels';

export const mockedTestSuitesReturnValue: TestSuite[] = [
  { id: 'DemoIG_STU1::DemoSuite', title: 'Demonstration Suite' },
  { id: 'infra_test', title: 'Infrastructure Test' },
];

export const mockedPostTestSuiteResponse = {
  id: '4402e8b1-8cd3-4dad-ba80-ffa593f26be4',
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
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'successful tests',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group01-DemoIG_STU1::DemoGroup-Test02',
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'warning message test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group01-DemoIG_STU1::DemoGroup-Test03',
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'error test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group01-DemoIG_STU1::DemoGroup-Test04',
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'input use example',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group01-DemoIG_STU1::DemoGroup-Test05',
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'output use example',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group01-DemoIG_STU1::DemoGroup-Test06',
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'client use examples test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group01-DemoIG_STU1::DemoGroup-Test07',
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'warning block test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group01-DemoIG_STU1::DemoGroup-Test08',
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'skip test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group01-DemoIG_STU1::DemoGroup-Test09',
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'omit test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group01-DemoIG_STU1::DemoGroup-Test10',
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'pass test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group01-DemoIG_STU1::DemoGroup-Test11',
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'skip_if test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group01-DemoIG_STU1::DemoGroup-Test12',
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'omit_if test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group01-DemoIG_STU1::DemoGroup-Test13',
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'pass_if test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group01-DemoIG_STU1::DemoGroup-Test14',
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'make named fhir request',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group01-DemoIG_STU1::DemoGroup-Test15',
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'use named fhir request',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group01-DemoIG_STU1::DemoGroup-Test16',
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'make named http request',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group01-DemoIG_STU1::DemoGroup-Test17',
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'use named http request',
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
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'successful tests',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-DEF-Test02',
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'warning message test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-DEF-Test03',
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'error test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-DEF-Test04',
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'input use example',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-DEF-Test05',
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'output use example',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-DEF-Test06',
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'client use examples test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-DEF-Test07',
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'warning block test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-DEF-Test08',
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'skip test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-DEF-Test09',
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'omit test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-DEF-Test10',
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'pass test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-DEF-Test11',
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'skip_if test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-DEF-Test12',
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'omit_if test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-DEF-Test13',
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'pass_if test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-DEF-Test14',
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'make named fhir request',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-DEF-Test15',
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'use named fhir request',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-DEF-Test16',
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'make named http request',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-DEF-Test17',
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'use named http request',
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
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'successful tests',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-GHI-Test02',
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'warning message test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-GHI-Test03',
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'error test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-GHI-Test04',
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'input use example',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-GHI-Test05',
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'output use example',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-GHI-Test06',
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'client use examples test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-GHI-Test07',
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'warning block test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-GHI-Test08',
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'skip test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-GHI-Test09',
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'omit test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-GHI-Test10',
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'pass test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-GHI-Test11',
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'skip_if test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-GHI-Test12',
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'omit_if test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-GHI-Test13',
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'pass_if test',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-GHI-Test14',
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'make named fhir request',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-GHI-Test15',
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'use named fhir request',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-GHI-Test16',
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'make named http request',
              },
              {
                id: 'DemoIG_STU1::DemoSuite-Group02-GHI-Test17',
                inputs: [
                  {
                    name: 'url',
                  },
                  {
                    name: 'patient_id',
                  },
                ],
                title: 'use named http request',
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
