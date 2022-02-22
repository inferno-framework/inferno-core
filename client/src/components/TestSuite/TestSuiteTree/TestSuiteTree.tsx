import React, { FC } from 'react';
import { TestSuite, TestGroup, RunnableType } from 'models/testSuiteModels';
import { Box, Divider } from '@mui/material';
import useStyles from './styles';
import TreeView from '@mui/lab/TreeView';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import ListAltIcon from '@mui/icons-material/ListAlt';
import ChevronRightIcon from '@mui/icons-material/ChevronRight';
import FlagIcon from '@mui/icons-material/Flag';
import CustomTreeItem from '../../_common/TreeItem';
import TestGroupTreeItem from './TestGroupTreeItem';
import TreeItemLabel from './TreeItemLabel';

export interface TestSuiteTreeProps {
  testSuite: TestSuite;
  runTests: (runnableType: RunnableType, runnableId: string) => void;
  selectedRunnable: string;
  testRunInProgress: boolean;
  view: 'run' | 'report';
}

function addDefaultExpanded(testGroups: TestGroup[], defaultExpanded: string[]): void {
  testGroups.forEach((testGroup: TestGroup) => {
    if (testGroup.test_groups.length > 0 && !testGroup.run_as_group) {
      defaultExpanded.push(testGroup.id);
      addDefaultExpanded(testGroup.test_groups, defaultExpanded);
    }
  });
}

const TestSuiteTreeComponent: FC<TestSuiteTreeProps> = ({
  testSuite,
  selectedRunnable,
  runTests,
  testRunInProgress,
  view,
}) => {
  const styles = useStyles();

  let selectedNode = selectedRunnable;
  if (view === 'report') {
    selectedNode = `${selectedNode}/report`;
  }

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
        testRunInProgress={testRunInProgress}
      />
    ));

    return (
      <Box className={styles.testSuiteTreePanel}>
        <TreeView
          defaultCollapseIcon={<ExpandMoreIcon />}
          defaultExpandIcon={<ChevronRightIcon />}
          onNodeToggle={nodeToggle}
          expanded={expanded}
          selected={selectedNode}
        >
          <CustomTreeItem
            classes={{ content: styles.treeRoot }}
            nodeId={testSuite.id}
            label={<TreeItemLabel runnable={testSuite} />}
            icon={<ListAltIcon />}
            // eslint-disable-next-line max-len
            // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-explicit-any
            ContentProps={{ testId: testSuite.id } as any}
          />
          <Divider />
          {testGroupList}
          <Divider />
          <CustomTreeItem
            nodeId={`${testSuite.id}/report`}
            label={<TreeItemLabel title={'Report'} />}
            icon={<FlagIcon />}
            // eslint-disable-next-line max-len
            // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-explicit-any
            ContentProps={{ testId: `${testSuite.id}/report` } as any}
          />
          <Divider />
        </TreeView>
      </Box>
    );
  } else {
    return <Box>{testSuite.title}</Box>;
  }
};

export default TestSuiteTreeComponent;
