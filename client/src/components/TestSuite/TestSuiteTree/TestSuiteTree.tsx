import React, { FC } from 'react';
import { TestSuite, TestGroup, RunnableType, Result } from 'models/testSuiteModels';
import { CardContent, Box } from '@mui/material';
import useStyles from './styles';
import TreeView from '@mui/lab/TreeView';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import ChevronRightIcon from '@mui/icons-material/ChevronRight';
import CustomTreeItem from '../../_common/TreeItem';
import TestGroupTreeItem from './TestGroupTreeItem';
import TreeItemLabel from './TreeItemLabel';

export interface TestSuiteTreeProps {
  testSuite: TestSuite;
  runTests: (runnableType: RunnableType, runnableId: string) => void;
  selectedRunnable: string;
  currentTest: Result | null;
  testRunInProgress: boolean;
}

function addDefaultExpanded(testGroups: TestGroup[], defaultExpanded: string[]): void {
  testGroups.forEach((testGroup: TestGroup) => {
    if (testGroup.test_groups.length > 0) {
      defaultExpanded.push(testGroup.id);
      addDefaultExpanded(testGroup.test_groups, defaultExpanded);
    }
  });
}

const TestSuiteTreeComponent: FC<TestSuiteTreeProps> = ({
  testSuite,
  selectedRunnable,
  runTests,
  currentTest,
  testRunInProgress,
}) => {
  const styles = useStyles();

  const defaultExpanded: string[] = [testSuite.id];
  if (testSuite.test_groups) {
    addDefaultExpanded(testSuite.test_groups, defaultExpanded);
  }
  const [expanded, setExpanded] = React.useState(defaultExpanded);

  // types aren't set in the library
  function nodeToggle(event: unknown, nodeIds: unknown) {
    setExpanded(nodeIds as string[]);
  }

  if (testSuite.test_groups) {
    const testGroupList = testSuite.test_groups.map((testGroup) => (
      <TestGroupTreeItem
        key={testGroup.id}
        data-testid={`${testGroup.id}-treeitem`}
        testGroup={testGroup}
        runTests={runTests}
        currentTest={currentTest}
        testRunInProgress={testRunInProgress}
      />
    ));

    return (
      <Box className={styles.testSuiteTreePanel}>
        <CardContent>
          <TreeView
            defaultCollapseIcon={<ExpandMoreIcon />}
            defaultExpandIcon={<ChevronRightIcon />}
            onNodeToggle={nodeToggle}
            expanded={expanded}
            selected={selectedRunnable}
          >
            <CustomTreeItem
              classes={{ content: styles.treeRoot }}
              nodeId={testSuite.id}
              label={
                <TreeItemLabel
                  runnable={testSuite}
                  runTests={runTests}
                  currentTest={currentTest}
                  testRunInProgress={testRunInProgress}
                />
              }
              // eslint-disable-next-line max-len
              // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-explicit-any
              ContentProps={{ testId: testSuite.id } as any}
            >
              {testGroupList}
            </CustomTreeItem>
          </TreeView>
        </CardContent>
      </Box>
    );
  } else {
    return <Box>{testSuite.title}</Box>;
  }
};

export default TestSuiteTreeComponent;
