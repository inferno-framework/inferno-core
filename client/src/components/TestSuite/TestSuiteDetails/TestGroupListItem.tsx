import React, { FC } from 'react';
import useStyles from './styles';
import {
  Accordion,
  AccordionDetails,
  AccordionSummary,
  Divider,
  List,
  ListItem,
  ListItemText,
} from '@mui/material';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import { Request, RunnableType, Test, TestGroup } from 'models/testSuiteModels';
import ResultIcon from './ResultIcon';
import TestRunButton from '../TestRunButton/TestRunButton';
import TestListItem from './TestListItem/TestListItem';

interface TestGroupListItemProps {
  testGroup: TestGroup;
  runTests: (runnableType: RunnableType, runnableId: string) => void;
  updateRequest: (requestId: string, resultId: string, request: Request) => void;
  testRunInProgress: boolean;
}

const TestGroupListItem: FC<TestGroupListItemProps> = ({
  testGroup,
  runTests,
  updateRequest,
  testRunInProgress,
}) => {
  const styles = useStyles();

  let listItems: JSX.Element[] = [];
  if ('tests' in testGroup) {
    listItems = testGroup.tests.map((test: Test) => {
      return (
        <TestListItem
          key={`li-${test.id}`}
          test={test}
          runTests={runTests}
          updateRequest={updateRequest}
          testRunInProgress={testRunInProgress}
        />
      );
    });
  }

  return (
    <Accordion disableGutters className={styles.accordion}>
      <AccordionSummary
        aria-controls="panel1a-content"
        id="panel1a-header"
        // Toggle accordion expansion only on icon click
        sx={{
          pointerEvents: 'none',
        }}
        expandIcon={
          <ExpandMoreIcon
            sx={{
              pointerEvents: 'auto',
            }}
          />
        }
      >
        <ListItem className={styles.testGroupCardList}>
          <div className={styles.testIcon}>{<ResultIcon result={testGroup.result} />}</div>
          <ListItemText primary={testGroup.title} secondary={testGroup.result?.result_message} />
          <TestRunButton
            runnable={testGroup}
            runnableType={RunnableType.TestGroup}
            runTests={runTests}
            testRunInProgress={testRunInProgress}
          />
        </ListItem>
      </AccordionSummary>
      <Divider />
      <AccordionDetails className={styles.accordionDetailContainer}>
        <List className={styles.accordionDetail}>{listItems}</List>
      </AccordionDetails>
    </Accordion>
  );
};

export default TestGroupListItem;
