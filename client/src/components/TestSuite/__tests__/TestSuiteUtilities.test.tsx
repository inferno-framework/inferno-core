import { TestGroup, Test, TestSuite, RunnableType } from 'models/testSuiteModels';
import { setInCurrentTestRun } from '../TestSuiteUtilities';

describe('Marking runnables as pending', () => {
  it('recurses through a tree of different types', () => {
    const test = {
      id: 'first-test01',
      short_id: 't',
      title: 'Pass test',
      inputs: [],
      outputs: [],
      isInCurrentTestRun: false,
    } as Test;

    const testGroup = {
      id: 'demo-test_group',
      short_id: 'tg',
      title: 'demo-Group01',
      test_groups: [],
      tests: [],
      inputs: [],
      outputs: [],
      isInCurrentTestRun: false,
    } as TestGroup;

    const outerGroup = {
      id: 'demo-test_group',
      short_id: 'og',
      title: 'demo-Group01',
      test_groups: [testGroup],
      tests: [test],
      inputs: [],
      outputs: [],
      isInCurrentTestRun: false,
    } as TestGroup;

    const testSuite = {
      id: 'demo',
      title: 'Demonstration Suite',
      description: 'Demonstration Suite',
      test_groups: [outerGroup],
      isInCurrentTestRun: false,
    } as TestSuite;

    const tree = testSuite;
    const kind = RunnableType.TestSuite;

    setInCurrentTestRun(tree, kind);
    expect(tree.isInCurrentTestRun).toBeTruthy();
    expect(outerGroup.isInCurrentTestRun).toBeTruthy();
    expect(test.isInCurrentTestRun).toBeTruthy();
  });
});
