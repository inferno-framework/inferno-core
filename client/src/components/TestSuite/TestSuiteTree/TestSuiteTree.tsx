import React, { FC } from 'react';
import {
  TestSuite,
  TestGroup,
  RunnableType,
  PresetSummary,
  ViewType,
} from '~/models/testSuiteModels';
import { Box, Divider, Typography } from '@mui/material';
import TreeView from '@mui/lab/TreeView';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import ListAltIcon from '@mui/icons-material/ListAlt';
import ChevronRightIcon from '@mui/icons-material/ChevronRight';
import FlagIcon from '@mui/icons-material/Flag';
import NotificationsIcon from '@mui/icons-material/Notifications';
import ErrorOutlineIcon from '@mui/icons-material/ErrorOutline';
import WarningAmberIcon from '@mui/icons-material/WarningAmber';
import useStyles from './styles';
import TestGroupTreeItem from './TestGroupTreeItem';
import TreeItemLabel from './TreeItemLabel';
import CustomTreeItem from '~/components/_common/TreeItem';
import PresetsSelector from '~/components/PresetsSelector/PresetsSelector';
import lightTheme from '~/styles/theme';

export interface TestSuiteTreeProps {
  testSuite: TestSuite;
  runTests: (runnableType: RunnableType, runnableId: string) => void;
  selectedRunnable: string;
  testRunInProgress: boolean;
  view: ViewType;
  presets?: PresetSummary[];
  testSessionId?: string;
  getSessionData?: (testSessionId: string) => void;
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
  presets,
  testSessionId,
  getSessionData,
}) => {
  const styles = useStyles();

  let selectedNode = selectedRunnable;
  if (view === 'report') {
    selectedNode = `${selectedNode}/report`;
  } else if (view === 'config') {
    selectedNode = `${selectedNode}/config`;
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

    const renderConfigMessagesTreeItem = () => {
      const configMessages = testSuite.configuration_messages;
      let configMessagesSeverityIcon = null;
      if (
        configMessages &&
        configMessages?.filter((message) => message.type === 'error').length > 0
      ) {
        configMessagesSeverityIcon = (
          <ErrorOutlineIcon sx={{ color: lightTheme.palette.error.main }} />
        );
      } else if (
        configMessages &&
        configMessages?.filter((message) => message.type === 'warning').length > 0
      ) {
        configMessagesSeverityIcon = (
          <WarningAmberIcon sx={{ color: lightTheme.palette.warning.main }} />
        );
      }

      return (
        <CustomTreeItem
          nodeId={`${testSuite.id}/config`}
          label={
            <Typography component="div" alignItems="center" sx={{ display: 'flex' }}>
              <TreeItemLabel title={'Configuration Messages'} />
              {configMessagesSeverityIcon}
            </Typography>
          }
          icon={<NotificationsIcon />}
          // eslint-disable-next-line max-len
          // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-explicit-any
          ContentProps={{ testId: `${testSuite.id}/config` } as any}
        />
      );
    };

    return (
      <Box className={styles.testSuiteTreePanel}>
        <TreeView
          aria-label="navigation-panel"
          defaultCollapseIcon={<ExpandMoreIcon aria-hidden={false} tabIndex={0} />}
          defaultExpandIcon={<ChevronRightIcon aria-hidden={false} tabIndex={0} />}
          onNodeToggle={nodeToggle}
          expanded={expanded}
          selected={selectedNode}
          className={styles.testSuiteTree}
        >
          {presets && presets.length > 0 && testSessionId && getSessionData && (
            <Box m={2}>
              <PresetsSelector
                presets={presets}
                testSessionId={testSessionId}
                getSessionData={getSessionData}
              />
            </Box>
          )}
          <Divider />
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
          <Box display="flex" alignItems="flex-end" flexGrow={1} mt={8}>
            {/* Box is necessary to show dividers */}
            <Box width="100%">
              <Divider />
              {renderConfigMessagesTreeItem()}
            </Box>
          </Box>
        </TreeView>
      </Box>
    );
  } else {
    return <Box>{testSuite.title}</Box>;
  }
};

export default TestSuiteTreeComponent;
