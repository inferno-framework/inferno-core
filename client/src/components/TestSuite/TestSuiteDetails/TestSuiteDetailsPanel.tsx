import React, { FC } from 'react';
import useStyles from './styles';
import { TestGroup, RunnableType, TestSuite, Request, Test } from 'models/testSuiteModels';
import TestGroupListItem from './TestGroupListItem';
import TestListItem from './TestListItem/TestListItem';
import DescriptionCard from './DescriptionCard';
import TestGroupCard from './TestGroupCard';

interface TestSuiteDetailsPanelProps {
  runnable: TestSuite | TestGroup;
  runTests: (runnableType: RunnableType, runnableId: string) => void;
  updateRequest: (requestId: string, resultId: string, request: Request) => void;
  testRunInProgresss: boolean;
}

const TestSuiteDetailsPanel: FC<TestSuiteDetailsPanelProps> = ({
  runnable,
  runTests,
  updateRequest,
  testRunInProgresss,
}) => {
  const styles = useStyles();

  let listItems: JSX.Element[] = [];
  if (runnable?.test_groups && runnable.test_groups.length > 0) {
    listItems = runnable.test_groups.map((testGroup: TestGroup) => {
      return (
        <TestGroupListItem
          key={`li-${testGroup.id}`}
          {...testGroup}
          runTests={runTests}
          testRunInProgress={testRunInProgresss}
        />
      );
    });
  } else if ('tests' in runnable) {
    listItems = runnable.tests.map((test: Test) => {
      return (
        <TestListItem
          key={`li-${test.id}`}
          {...test}
          runTests={runTests}
          updateRequest={updateRequest}
          testRunInProgress={testRunInProgresss}
        />
      );
    });
  }

  const descriptionCard =
    runnable.description && runnable.description.length > 0 ? (
      <DescriptionCard description={runnable.description} />
    ) : null;

  return (
    <div className={styles.testSuiteDetailsPanel}>
      <TestGroupCard runTests={runTests} runnable={runnable} testRunInProgress={testRunInProgresss}>
        {listItems}
      </TestGroupCard>
      {descriptionCard}
    </div>
  );
};

export default TestSuiteDetailsPanel;
